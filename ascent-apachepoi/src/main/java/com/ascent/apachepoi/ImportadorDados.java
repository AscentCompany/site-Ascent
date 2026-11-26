package com.ascent.apachepoi;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Time;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

/**
 * Importador em lote.
 *
 * Estratégia:
 *  - uma única conexão para todo o processo;
 *  - caches em memória (HashMap) das chaves já existentes no banco, evitando SELECT por linha;
 *  - INSERTs de voo e aeroportoDirecao agrupados com addBatch/executeBatch;
 *  - commit por lote, mantendo o volume de dados pendente baixo;
 *  - as chaves geradas dos voos são usadas para amarrar as direções.
 */
public class ImportadorDados extends LeitorExcel.ConsumidorLinha {

    private static final int TAMANHO_LOTE = 5_000;

    private final Connection        conexao;
    private final PreparedStatement insertCompanhia;
    private final PreparedStatement insertAviao;
    private final PreparedStatement insertAeroporto;
    private final PreparedStatement updateAeroportoIcao;
    private final PreparedStatement insertVoo;
    private final PreparedStatement insertDirecao;

    private final HashMap<Integer, Integer> companhiaPorCodigo = new HashMap<>();
    private final HashMap<String, Integer>  aviaoPorModelo     = new HashMap<>();
    private final HashMap<String, Integer>  aeroportoPorNome   = new HashMap<>();
    private final HashMap<Integer, Boolean> aeroportoTemIcao   = new HashMap<>();

    private final HashMap<Integer, Boolean> companhiasVistas = new HashMap<>();
    private final HashMap<String, Boolean>  avioesVistos     = new HashMap<>();
    private final HashMap<String, Boolean>  aeroportosVistos = new HashMap<>();

    private Integer idCompanhiaPadrao = null;
    private Integer idAviaoPadrao     = null;

    private final List<DirecaoPendente> direcoesPendentes = new ArrayList<>();
    private int voosNoLote = 0;

    private int voosInseridos     = 0;
    private int direcoesInseridas = 0;

    private static final class DirecaoPendente {
        private final int       indiceVoo;
        private final int       fkAeroporto;
        private final String    direcao;
        private final LocalDate dia;
        private final LocalTime hora;

        private DirecaoPendente(int indiceVoo, int fkAeroporto, String direcao, LocalDate dia, LocalTime hora) {
            this.indiceVoo  = indiceVoo;
            this.fkAeroporto = fkAeroporto;
            this.direcao    = direcao;
            this.dia        = dia;
            this.hora       = hora;
        }
    }

    public ImportadorDados(DataSource dataSource) throws SQLException {
        this.conexao = dataSource.getConnection();
        this.conexao.setAutoCommit(false);

        this.insertCompanhia = conexao.prepareStatement(
                "INSERT INTO companhia (codCompanhia, nomeCompanhia, paisCompanhia, razaoSocial, cnpj) VALUES (?,?,?,?,?)",
                Statement.RETURN_GENERATED_KEYS);
        this.insertAviao = conexao.prepareStatement(
                "INSERT INTO aviao (numAssentos, modelo) VALUES (?,?)",
                Statement.RETURN_GENERATED_KEYS);
        this.insertAeroporto = conexao.prepareStatement(
                "INSERT INTO aeroporto (nomeAeroporto, municipio, uf, regiao, pais, icao) VALUES (?,?,?,?,?,?)",
                Statement.RETURN_GENERATED_KEYS);
        this.updateAeroportoIcao = conexao.prepareStatement(
                "UPDATE aeroporto SET icao = ? WHERE idAeroporto = ? AND (icao IS NULL OR icao = '')");
        this.insertVoo = conexao.prepareStatement(
                "INSERT INTO voo (numVoo, tipoVoo, qtdPassageiros, fkCompanhia, fkAviao) VALUES (?,?,?,?,?)",
                Statement.RETURN_GENERATED_KEYS);
        this.insertDirecao = conexao.prepareStatement(
                "INSERT INTO aeroportoDirecao (fkAeroporto, fkVoo, direcao, dia, hora) VALUES (?,?,?,?,?)" +
                " ON DUPLICATE KEY UPDATE direcao=VALUES(direcao), dia=VALUES(dia), hora=VALUES(hora)");

        recarregarCaches();
    }

    // <editor-fold desc="Ciclo por arquivo">

    public void iniciarArquivo() {
        companhiasVistas.clear();
        avioesVistos.clear();
        aeroportosVistos.clear();
        voosInseridos     = 0;
        direcoesInseridas = 0;
    }

    public void finalizar() {
        try {
            descarregarLote();
        } catch (SQLException e) {
            throw new RuntimeException("Falha ao gravar o lote final: " + e.getMessage(), e);
        }
    }

    /**
     * Maior idVoo existente no banco. Serve de marco zero do arquivo: tudo que
     * for inserido depois deste id pertence ao arquivo que está sendo processado.
     */
    public long maiorIdVoo() {
        try (Statement st = conexao.createStatement();
             ResultSet rs = st.executeQuery("SELECT COALESCE(MAX(idVoo), 0) FROM voo")) {
            return rs.next() ? rs.getLong(1) : 0L;
        } catch (SQLException e) {
            throw new RuntimeException("Falha ao ler o maior idVoo: " + e.getMessage(), e);
        }
    }

    /**
     * Remove os voos (e as direções ligadas a eles) gravados por uma importação
     * interrompida, permitindo reprocessar o arquivo sem duplicar dados.
     * As tabelas de apoio (companhia, aviao, aeroporto) são preservadas: elas
     * são compartilhadas entre arquivos e os caches continuam válidos.
     */
    public void limparParcial(long idInicialVoo) {
        try {
            direcoesPendentes.clear();
            voosNoLote = 0;
            insertVoo.clearBatch();
            insertDirecao.clearBatch();

            try (PreparedStatement delDirecao = conexao.prepareStatement(
                    "DELETE ad FROM aeroportoDirecao ad " +
                    "INNER JOIN voo v ON ad.fkVoo = v.idVoo WHERE v.idVoo > ?")) {
                delDirecao.setLong(1, idInicialVoo);
                delDirecao.executeUpdate();
            }
            try (PreparedStatement delVoo = conexao.prepareStatement(
                    "DELETE FROM voo WHERE idVoo > ?")) {
                delVoo.setLong(1, idInicialVoo);
                delVoo.executeUpdate();
            }
            conexao.commit();

            voosInseridos     = 0;
            direcoesInseridas = 0;
        } catch (SQLException e) {
            throw new RuntimeException("Falha ao limpar dados parciais (idVoo > " +
                    idInicialVoo + "): " + e.getMessage(), e);
        }
    }

    /**
     * Desfaz o lote pendente e recarrega os caches, garantindo que nenhum id
     * em memória aponte para um registro que foi desfeito pelo rollback.
     */
    public void reverter() {
        try { conexao.rollback(); } catch (SQLException ignored) { }
        direcoesPendentes.clear();
        voosNoLote = 0;
        try {
            insertVoo.clearBatch();
            insertDirecao.clearBatch();
        } catch (SQLException ignored) { }
        try {
            recarregarCaches();
        } catch (SQLException e) {
            throw new RuntimeException("Falha ao recarregar os caches: " + e.getMessage(), e);
        }
    }

    public int getCompanhiasDistintas() { return companhiasVistas.size(); }
    public int getAvioesDistintos()     { return avioesVistos.size(); }
    public int getAeroportosDistintos() { return aeroportosVistos.size(); }
    public int getVoosInseridos()       { return voosInseridos; }
    public int getDirecoesInseridas()   { return direcoesInseridas; }

    // </editor-fold>

    @Override
    public void consumir(LinhaVoo linha) {
        Integer idCompanhia = obterOuCriarCompanhia(linha.getCompanhia());
        if (idCompanhia == null) return;

        Integer idAviao = obterOuCriarAviao(linha.getAviao());
        if (idAviao == null) idAviao = obterAviaoPadrao();

        Integer idOrigem = obterOuCriarAeroporto(linha.getAeroportoOrigem());
        if (idOrigem == null) return;

        Voo voo = linha.getVoo();
        try {
            insertVoo.setInt(1, valor(voo.getNumVoo()));
            insertVoo.setInt(2, valor(voo.getTipoVoo()));
            insertVoo.setInt(3, valor(voo.getQtdPassageiros()));
            insertVoo.setInt(4, idCompanhia);
            insertVoo.setInt(5, idAviao);
            insertVoo.addBatch();
        } catch (SQLException e) {
            throw new RuntimeException("Falha ao preparar voo: " + e.getMessage(), e);
        }

        int indiceVoo = voosNoLote++;
        adicionarDirecao(linha.getPartida(), indiceVoo, idOrigem);

        Integer idDestino = obterOuCriarAeroporto(linha.getAeroportoDestino());
        if (idDestino != null) {
            adicionarDirecao(linha.getChegada(), indiceVoo, idDestino);
        }

        if (voosNoLote >= TAMANHO_LOTE) {
            try {
                descarregarLote();
            } catch (SQLException e) {
                throw new RuntimeException("Falha ao gravar lote de voos: " + e.getMessage(), e);
            }
        }
    }

    private void adicionarDirecao(AeroportoDirecao ad, int indiceVoo, int fkAeroporto) {
        // Mantém a validação: direção sem data ou hora é descartada.
        if (ad == null || ad.getDia() == null || ad.getHora() == null) return;
        direcoesPendentes.add(new DirecaoPendente(
                indiceVoo, fkAeroporto, ad.getDirecao(), ad.getDia(), ad.getHora()));
    }

    private void descarregarLote() throws SQLException {
        if (voosNoLote == 0) return;

        int totalVoos = voosNoLote;
        insertVoo.executeBatch();

        int[] ids = new int[totalVoos];
        int   qtd = 0;
        try (ResultSet chaves = insertVoo.getGeneratedKeys()) {
            while (chaves.next()) {
                if (qtd < totalVoos) ids[qtd] = chaves.getInt(1);
                qtd++;
            }
        }
        if (qtd != totalVoos) {
            throw new SQLException("Quantidade de chaves geradas (" + qtd +
                    ") diferente da quantidade de voos do lote (" + totalVoos + ").");
        }

        for (DirecaoPendente d : direcoesPendentes) {
            insertDirecao.setInt(1, d.fkAeroporto);
            insertDirecao.setInt(2, ids[d.indiceVoo]);
            insertDirecao.setString(3, d.direcao);
            insertDirecao.setDate(4, Date.valueOf(d.dia));
            insertDirecao.setTime(5, Time.valueOf(d.hora));
            insertDirecao.addBatch();
        }
        if (!direcoesPendentes.isEmpty()) {
            insertDirecao.executeBatch();
        }

        conexao.commit();

        voosInseridos     += totalVoos;
        direcoesInseridas += direcoesPendentes.size();

        direcoesPendentes.clear();
        voosNoLote = 0;
        insertVoo.clearBatch();
        insertDirecao.clearBatch();
    }

    // <editor-fold desc="Caches e inserts auxiliares">

    private void recarregarCaches() throws SQLException {
        companhiaPorCodigo.clear();
        aviaoPorModelo.clear();
        aeroportoPorNome.clear();
        aeroportoTemIcao.clear();

        try (Statement st = conexao.createStatement()) {
            try (ResultSet rs = st.executeQuery("SELECT codCompanhia, idCompanhia FROM companhia")) {
                while (rs.next()) {
                    int cod = rs.getInt(1);
                    if (!rs.wasNull()) companhiaPorCodigo.put(cod, rs.getInt(2));
                }
            }
            try (ResultSet rs = st.executeQuery("SELECT modelo, idAviao FROM aviao")) {
                while (rs.next()) {
                    String modelo = rs.getString(1);
                    if (modelo != null) aviaoPorModelo.put(modelo, rs.getInt(2));
                }
            }
            try (ResultSet rs = st.executeQuery("SELECT nomeAeroporto, idAeroporto, icao FROM aeroporto")) {
                while (rs.next()) {
                    String nome = rs.getString(1);
                    int idAero = rs.getInt(2);
                    String icao = rs.getString(3);
                    if (nome != null) {
                        aeroportoPorNome.put(nome, idAero);
                        aeroportoTemIcao.put(idAero, icao != null && !icao.isBlank());
                    }
                }
            }
        }
    }

    private Integer obterOuCriarCompanhia(Companhia c) {
        if (c == null || c.getCodCompanhia() == null) return obterCompanhiaPadrao();

        Integer id = companhiaPorCodigo.get(c.getCodCompanhia());
        if (id != null) {
            companhiasVistas.put(c.getCodCompanhia(), Boolean.TRUE);
            return id;
        }

        try {
            insertCompanhia.setInt(1, c.getCodCompanhia());
            insertCompanhia.setString(2, texto(c.getNomeCompanhia(), "DESCONHECIDA"));
            insertCompanhia.setString(3, texto(c.getPaisCompanhia(), "BRASIL"));
            insertCompanhia.setString(4, texto(c.getRazaoSocial(), ""));
            insertCompanhia.setString(5, texto(c.getCnpj(), ""));
            insertCompanhia.executeUpdate();

            Integer novo = chaveGerada(insertCompanhia);
            if (novo != null) {
                companhiaPorCodigo.put(c.getCodCompanhia(), novo);
                companhiasVistas.put(c.getCodCompanhia(), Boolean.TRUE);
            }
            return novo;
        } catch (SQLException e) {
            throw new RuntimeException("Falha ao inserir companhia: " + e.getMessage(), e);
        }
    }

    private Integer obterCompanhiaPadrao() {
        if (idCompanhiaPadrao != null) return idCompanhiaPadrao;

        Integer existente = companhiaPorCodigo.get(-1);
        if (existente != null) {
            idCompanhiaPadrao = existente;
            return existente;
        }

        try {
            insertCompanhia.setInt(1, -1);
            insertCompanhia.setString(2, "DESCONHECIDA");
            insertCompanhia.setString(3, "BRASIL");
            insertCompanhia.setString(4, "");
            insertCompanhia.setString(5, "");
            insertCompanhia.executeUpdate();
            idCompanhiaPadrao = chaveGerada(insertCompanhia);
            if (idCompanhiaPadrao != null) companhiaPorCodigo.put(-1, idCompanhiaPadrao);
            return idCompanhiaPadrao;
        } catch (SQLException e) {
            throw new RuntimeException("Falha ao inserir companhia padrão: " + e.getMessage(), e);
        }
    }

    private Integer obterOuCriarAviao(Aviao a) {
        if (a == null || a.getModelo() == null || a.getModelo().isBlank()) return obterAviaoPadrao();

        String modelo = a.getModelo();
        Integer id = aviaoPorModelo.get(modelo);
        if (id != null) {
            avioesVistos.put(modelo, Boolean.TRUE);
            return id;
        }

        try {
            insertAviao.setInt(1, a.getNumAssentos() != null ? a.getNumAssentos() : 0);
            insertAviao.setString(2, modelo);
            insertAviao.executeUpdate();

            Integer novo = chaveGerada(insertAviao);
            if (novo != null) {
                aviaoPorModelo.put(modelo, novo);
                avioesVistos.put(modelo, Boolean.TRUE);
            }
            return novo;
        } catch (SQLException e) {
            throw new RuntimeException("Falha ao inserir avião: " + e.getMessage(), e);
        }
    }

    private Integer obterAviaoPadrao() {
        if (idAviaoPadrao != null) return idAviaoPadrao;

        Integer existente = aviaoPorModelo.get("DESCONHECIDO");
        if (existente != null) {
            idAviaoPadrao = existente;
            return existente;
        }

        try {
            insertAviao.setInt(1, 0);
            insertAviao.setString(2, "DESCONHECIDO");
            insertAviao.executeUpdate();
            idAviaoPadrao = chaveGerada(insertAviao);
            if (idAviaoPadrao != null) aviaoPorModelo.put("DESCONHECIDO", idAviaoPadrao);
            return idAviaoPadrao;
        } catch (SQLException e) {
            throw new RuntimeException("Falha ao inserir avião padrão: " + e.getMessage(), e);
        }
    }

    private Integer obterOuCriarAeroporto(Aeroporto a) {
        if (a == null || a.getNomeAeroporto() == null || a.getNomeAeroporto().isBlank()) return null;

        String nome = a.getNomeAeroporto();
        String icao = texto(a.getIcao(), "");
        Integer id = aeroportoPorNome.get(nome);
        if (id != null) {
            if (!icao.isEmpty() && !Boolean.TRUE.equals(aeroportoTemIcao.get(id))) {
                try {
                    updateAeroportoIcao.setString(1, icao);
                    updateAeroportoIcao.setInt(2, id);
                    updateAeroportoIcao.executeUpdate();
                    aeroportoTemIcao.put(id, Boolean.TRUE);
                } catch (SQLException e) {
                    throw new RuntimeException("Falha ao atualizar ICAO do aeroporto: " + e.getMessage(), e);
                }
            }
            aeroportosVistos.put(nome, Boolean.TRUE);
            return id;
        }

        try {
            insertAeroporto.setString(1, nome);
            insertAeroporto.setString(2, texto(a.getMunicipio(), ""));
            insertAeroporto.setString(3, texto(a.getUf(), ""));
            insertAeroporto.setString(4, texto(a.getRegiao(), ""));
            insertAeroporto.setString(5, texto(a.getPais(), "BRASIL"));
            insertAeroporto.setString(6, icao);
            insertAeroporto.executeUpdate();

            Integer novo = chaveGerada(insertAeroporto);
            if (novo != null) {
                aeroportoPorNome.put(nome, novo);
                aeroportoTemIcao.put(novo, !icao.isEmpty());
                aeroportosVistos.put(nome, Boolean.TRUE);
            }
            return novo;
        } catch (SQLException e) {
            throw new RuntimeException("Falha ao inserir aeroporto: " + e.getMessage(), e);
        }
    }

    private Integer chaveGerada(PreparedStatement ps) throws SQLException {
        try (ResultSet rs = ps.getGeneratedKeys()) {
            return rs.next() ? rs.getInt(1) : null;
        }
    }

    // </editor-fold>

    private static int valor(Integer v) { return v != null ? v : 0; }

    private static String texto(String v, String padrao) {
        return (v != null && !v.isBlank()) ? v : padrao;
    }

    public void fechar() {
        try { insertCompanhia.close(); } catch (SQLException ignored) { }
        try { insertAviao.close(); }         catch (SQLException ignored) { }
        try { insertAeroporto.close(); }     catch (SQLException ignored) { }
        try { updateAeroportoIcao.close(); } catch (SQLException ignored) { }
        try { insertVoo.close(); }           catch (SQLException ignored) { }
        try { insertDirecao.close(); }   catch (SQLException ignored) { }
        try { conexao.close(); }         catch (SQLException ignored) { }
    }
}
