package com.ascent.apachepoi;

import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.PreparedStatementCreator;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;

import java.io.InputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.Scanner;

public class MainApp {
    private static final Scanner scnNumeros = new Scanner(System.in);
    private static final Scanner scnTextos = new Scanner(System.in);
    private static Conexao bancoAscent;
    private static JdbcTemplate bd;

    public static void main(String[] args) {
        bancoAscent = new Conexao();
        bd = new JdbcTemplate(bancoAscent.getConexao());

        // garante cargo padrão
        garantirCargoPadrao();

        // importação automática via S3 se a variável de ambiente estiver habilitada
        if ("true".equalsIgnoreCase(System.getenv("AUTO_IMPORT"))) {
            importarDadosAnac();
        }
        System.out.println("Serviço Apache POI pronto. Use as funções de importação conforme necessidade.");
    }

    private static void garantirCargoPadrao() {
        try {
            Integer qtd = bd.queryForObject("SELECT COUNT(*) FROM cargo WHERE idCargo = 1", Integer.class);
            if (qtd == null || qtd == 0) {
                bd.update("INSERT INTO cargo (cargo) VALUES ('Padrão')");
            }
        } catch (Exception e) {
            System.err.println("Aviso ao verificar cargo: " + e.getMessage());
        }
    }

    // ---------------------------------------------------------------
    // Importação automática da base ANAC via S3 com Apache POI e JDBC
    // ---------------------------------------------------------------
    public static void importarDadosAnac() {
        System.out.println("\n=== Iniciando importacao da base ANAC do S3 ===");
        try {
            LeitorExcel leitorExcel = new LeitorExcel();
            LeitorExcel.ResultadoLeitura dados = leitorExcel.extrairDados();
            inserirDadosNoBanco(dados);
        } catch (Exception e) {
            System.err.println("\n=== ERRO NA IMPORTACAO DO S3 ===");
            System.err.println(e.getMessage());
            e.printStackTrace();
            novoLogBanco("ERROR", "importacao", "Falha na importacao S3: " + e.getMessage(), LocalDateTime.now(), "Java");
        }
    }

    public static void importarDadosArquivoLocal(String caminho) {
        System.out.println("\n=== Iniciando importacao do arquivo local ===");
        try (InputStream is = new java.io.FileInputStream(caminho)) {
            LeitorExcel leitorExcel = new LeitorExcel();
            LeitorExcel.ResultadoLeitura dados = leitorExcel.extrairDeInputStream(is);
            inserirDadosNoBanco(dados);
        } catch (Exception e) {
            System.err.println("\n=== ERRO NA IMPORTACAO DO ARQUIVO LOCAL ===");
            System.err.println(e.getMessage());
            e.printStackTrace();
            novoLogBanco("ERROR", "importacao", "Falha na importacao local: " + e.getMessage(), LocalDateTime.now(), "Java");
        }
    }

    // ---------------------------------------------------------------
    // Inserção no banco de dados via JDBC com resolução de chaves e FKs
    // ---------------------------------------------------------------
    public static void inserirDadosNoBanco(LeitorExcel.ResultadoLeitura dados) {
        System.out.println("\n=== Gravando registros no Banco de Dados via JDBC ===");
        Map<Integer, Integer> cacheCompanhias = new HashMap<>();
        Map<String, Integer> cacheAvioes = new HashMap<>();
        Map<String, Integer> cacheAeroportos = new HashMap<>();

        // 1. Companhias
        System.out.println("[1/5] Inserindo companhias...");
        for (Companhia c : dados.companhias) {
            if (c.codCompanhia == null || cacheCompanhias.containsKey(c.codCompanhia)) continue;
            Integer idExistente = buscarId("SELECT idCompanhia FROM companhia WHERE codCompanhia = ? LIMIT 1", c.codCompanhia);
            if (idExistente != null) {
                cacheCompanhias.put(c.codCompanhia, idExistente);
            } else {
                KeyHolder keyHolder = new GeneratedKeyHolder();
                bd.update(new PreparedStatementCreator() {
                    @Override
                    public PreparedStatement createPreparedStatement(Connection con) throws java.sql.SQLException {
                        PreparedStatement ps = con.prepareStatement(
                            "INSERT INTO companhia (codCompanhia, nomeCompanhia, paisCompanhia, razaoSocial, cnpj, fkCargo) VALUES (?, ?, ?, ?, ?, ?)",
                            Statement.RETURN_GENERATED_KEYS);
                        ps.setInt(1, c.codCompanhia);
                        ps.setString(2, c.nomeCompanhia != null ? c.nomeCompanhia : "DESCONHECIDA");
                        ps.setString(3, c.paisCompanhia != null ? c.paisCompanhia : "BRASIL");
                        ps.setString(4, c.razaoSocial != null ? c.razaoSocial : "");
                        ps.setString(5, c.cnpj != null ? c.cnpj : "");
                        ps.setInt(6, 1); // cargo padrão
                        return ps;
                    }
                }, keyHolder);
                Number generatedId = keyHolder.getKey();
                if (generatedId != null) cacheCompanhias.put(c.codCompanhia, generatedId.intValue());
            }
        }
        System.out.printf("Total de companhias em cache: %d%n", cacheCompanhias.size());

        // 2. Aviões
        System.out.println("[2/5] Inserindo avioes...");
        for (Aviao a : dados.avioes) {
            if (a.modelo == null || a.modelo.trim().isEmpty() || cacheAvioes.containsKey(a.modelo)) continue;
            Integer idExistente = buscarId("SELECT idAviao FROM aviao WHERE modelo = ? LIMIT 1", a.modelo);
            if (idExistente != null) {
                cacheAvioes.put(a.modelo, idExistente);
            } else {
                KeyHolder keyHolder = new GeneratedKeyHolder();
                bd.update(new PreparedStatementCreator() {
                    @Override
                    public PreparedStatement createPreparedStatement(Connection con) throws java.sql.SQLException {
                        PreparedStatement ps = con.prepareStatement(
                            "INSERT INTO aviao (numAssentos, modelo) VALUES (?, ?)",
                            Statement.RETURN_GENERATED_KEYS);
                        ps.setInt(1, a.numAssentos != null ? a.numAssentos : 0);
                        ps.setString(2, a.modelo);
                        return ps;
                    }
                }, keyHolder);
                Number generatedId = keyHolder.getKey();
                if (generatedId != null) cacheAvioes.put(a.modelo, generatedId.intValue());
            }
        }
        System.out.printf("Total de modelos de avioes em cache: %d%n", cacheAvioes.size());

        // 3. Aeroportos
        System.out.println("[3/5] Inserindo aeroportos...");
        for (Aeroporto a : dados.aeroportos) {
            String chave = (a.icao != null && !a.icao.isEmpty()) ? a.icao : a.nomeAeroporto;
            if (chave == null || cacheAeroportos.containsKey(chave)) continue;
            Integer idExistente = null;
            if (a.icao != null && !a.icao.isEmpty()) {
                idExistente = buscarId("SELECT idAeroporto FROM aeroporto WHERE nomeAeroporto = ? OR nomeAeroporto = ? LIMIT 1",
                        a.nomeAeroporto, a.icao);
            } else {
                idExistente = buscarId("SELECT idAeroporto FROM aeroporto WHERE nomeAeroporto = ? LIMIT 1", a.nomeAeroporto);
            }
            if (idExistente != null) {
                cacheAeroportos.put(chave, idExistente);
            } else {
                KeyHolder keyHolder = new GeneratedKeyHolder();
                bd.update(new PreparedStatementCreator() {
                    @Override
                    public PreparedStatement createPreparedStatement(Connection con) throws java.sql.SQLException {
                        PreparedStatement ps = con.prepareStatement(
                            "INSERT INTO aeroporto (nomeAeroporto, municipio, uf, regiao, pais) VALUES (?, ?, ?, ?, ?)",
                            Statement.RETURN_GENERATED_KEYS);
                        ps.setString(1, a.nomeAeroporto != null ? a.nomeAeroporto : "");
                        ps.setString(2, a.municipio != null ? a.municipio : "");
                        ps.setString(3, a.uf != null ? a.uf : "");
                        ps.setString(4, a.regiao != null ? a.regiao : "");
                        ps.setString(5, a.pais != null ? a.pais : "BRASIL");
                        return ps;
                    }
                }, keyHolder);
                Number generatedId = keyHolder.getKey();
                if (generatedId != null) cacheAeroportos.put(chave, generatedId.intValue());
            }
        }
        System.out.printf("Total de aeroportos em cache: %d%n", cacheAeroportos.size());

        // 4. Voos
        System.out.println("[4/5] Inserindo voos...");
        Integer idCompanhiaPadrao = cacheCompanhias.values().stream().findFirst().orElse(null);
        if (idCompanhiaPadrao == null) idCompanhiaPadrao = buscarId("SELECT idCompanhia FROM companhia LIMIT 1");
        Integer idAviaoPadrao = cacheAvioes.values().stream().findFirst().orElse(null);
        if (idAviaoPadrao == null) idAviaoPadrao = buscarId("SELECT idAviao FROM aviao LIMIT 1");
        int voosInseridos = 0;
        int maxVoos = Math.min(dados.voos.size(), dados.companhias.size());
        for (int i = 0; i < maxVoos; i++) {
            Voo v = dados.voos.get(i);
            Companhia c = (i < dados.companhias.size()) ? dados.companhias.get(i) : null;
            Aviao a = (i < dados.avioes.size()) ? dados.avioes.get(i) : null;
            Integer fkCompanhia = (c != null && cacheCompanhias.containsKey(c.codCompanhia))
                    ? cacheCompanhias.get(c.codCompanhia) : idCompanhiaPadrao;
            Integer fkAviao = (a != null && cacheAvioes.containsKey(a.modelo))
                    ? cacheAvioes.get(a.modelo) : idAviaoPadrao;
            if (fkCompanhia == null || fkAviao == null) continue;
            KeyHolder keyHolder = new GeneratedKeyHolder();
            final Integer finalFkComp = fkCompanhia;
            final Integer finalFkAv = fkAviao;
            bd.update(new PreparedStatementCreator() {
                @Override
                public PreparedStatement createPreparedStatement(Connection con) throws java.sql.SQLException {
                    PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO voo (numVoo, tipoVoo, qtdPassageiros, fkCompanhia, fkAviao) VALUES (?, ?, ?, ?, ?)",
                        Statement.RETURN_GENERATED_KEYS);
                    ps.setInt(1, v.numVoo != null ? v.numVoo : 0);
                    ps.setInt(2, v.tipoVoo != null ? v.tipoVoo : 0);
                    ps.setInt(3, v.qtdPassageiros != null ? v.qtdPassageiros : 0);
                    ps.setInt(4, finalFkComp);
                    ps.setInt(5, finalFkAv);
                    return ps;
                }
            }, keyHolder);
            Number idGerado = keyHolder.getKey();
            if (idGerado != null) {
                v.idVoo = idGerado.intValue();
                voosInseridos++;
            }
        }
        System.out.printf("Total de voos inseridos: %d%n", voosInseridos);

        // 5. AeroportoDirecao
        System.out.println("[5/5] Inserindo direcoes de aeroporto...");
        int direcoesInseridas = 0;
        int maxDirecoes = Math.min(dados.aeroportoDirecoes.size(), dados.aeroportos.size());
        for (int i = 0; i < maxDirecoes; i++) {
            AeroportoDirecao ad = dados.aeroportoDirecoes.get(i);
            Aeroporto aero = dados.aeroportos.get(i);
            int idxVoo = i / 2; // duas direções por voo
            if (idxVoo >= dados.voos.size()) break;
            Voo vooRelacionado = dados.voos.get(idxVoo);
            if (vooRelacionado.idVoo == null) continue;
            String chaveAero = (aero.icao != null && !aero.icao.isEmpty()) ? aero.icao : aero.nomeAeroporto;
            Integer fkAeroporto = cacheAeroportos.get(chaveAero);
            if (fkAeroporto == null) continue;
            try {
                bd.update(
                    "INSERT INTO aeroportoDirecao (fkAeroporto, fkVoo, direcao, dia, hora) VALUES (?, ?, ?, ?, ?) " +
                    "ON DUPLICATE KEY UPDATE direcao = VALUES(direcao), dia = VALUES(dia), hora = VALUES(hora)",
                    fkAeroporto,
                    vooRelacionado.idVoo,
                    ad.direcao,
                    java.sql.Date.valueOf(ad.dia),
                    java.sql.Time.valueOf(ad.hora)
                );
                direcoesInseridas++;
            } catch (Exception e) {
                // ignora duplicados ou falhas menores
            }
        }
        System.out.printf("Total de direcoes inseridas: %d%n", direcoesInseridas);
        System.out.println("\n=== Importacao e insercao concluidas com sucesso! ===");
        novoLogBanco("INFO", "importacao",
                String.format("Base ANAC importada via Apache POI e inserida no BD: %d companhias, %d avioes, %d aeroportos, %d voos.",
                        cacheCompanhias.size(), cacheAvioes.size(), cacheAeroportos.size(), voosInseridos),
                LocalDateTime.now(), "Java");
    }

    private static Integer buscarId(String sql, Object... params) {
        try {
            java.util.List<Integer> list = bd.queryForList(sql, Integer.class, params);
            if (list != null && !list.isEmpty()) {
                return list.get(0);
            }
        } catch (Exception ignored) {}
        return null;
    }

    public static void novoLogBanco(String categoria, String servico, String mensagem, LocalDateTime dataHora, String origemCadastro) {
        try {
            bd.update("INSERT INTO logsServico (categoria, servico, mensagem, dataHora, origemCadastro) VALUES (?, ?, ?, ?, ?);",
                    categoria, servico, mensagem, LocalDateTime.now(), origemCadastro);
        } catch (Exception e) {
            System.err.println("Falha ao registrar log no banco: " + e.getMessage());
        }
    }
}
