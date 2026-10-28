package com.ascent.apachepoi;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.PreparedStatementCreator;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;

import java.io.InputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

public class MainApp {
    private static final Scanner scnNumeros = new Scanner(System.in);
    private static final Scanner scnTextos  = new Scanner(System.in);
    private static Conexao     bancoAscent;
    private static JdbcTemplate bd;

    public static void main(String[] args) {
        bancoAscent = new Conexao();
        bd = new JdbcTemplate(bancoAscent.getConexao());

        garantirCargoPadrao();

        boolean rodarS3 = "true".equalsIgnoreCase(System.getenv("AUTO_IMPORT"))
                || (args.length > 0 && ("--s3".equalsIgnoreCase(args[0]) || "s3".equalsIgnoreCase(args[0])));

        if (rodarS3) {
            importarDadosAnac();
        } else {
            System.out.println("Servico Apache POI pronto.");
            System.out.println("Para importar os dados do S3, execute com AUTO_IMPORT=true ou passe o argumento '--s3'.");
        }
    }

    private static void garantirCargoPadrao() {
        try {
            Integer qtd = bd.queryForObject("SELECT COUNT(*) FROM cargo WHERE idCargo = 1", Integer.class);
            if (qtd == null || qtd == 0) {
                bd.update("INSERT INTO cargo (cargo) VALUES ('Padrao')");
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
    // Inserção no banco de dados via JDBC
    // Caches implementados como duas listas paralelas (chave + id).
    // A busca é realizada por iteração linear.
    // ---------------------------------------------------------------
    public static void inserirDadosNoBanco(LeitorExcel.ResultadoLeitura dados) {
        System.out.println("\n=== Gravando registros no Banco de Dados via JDBC ===");

        // Cache de companhias: codCompanhia (Integer) → idCompanhia (Integer)
        List<Integer> cacheCompanhiasChave = new ArrayList<>();
        List<Integer> cacheCompanhiasId    = new ArrayList<>();

        // Cache de avioes: modelo (String) → idAviao (Integer)
        List<String>  cacheAvioesChave = new ArrayList<>();
        List<Integer> cacheAvioesId    = new ArrayList<>();

        // Cache de aeroportos: icao ou nomeAeroporto (String) → idAeroporto (Integer)
        List<String>  cacheAeroportosChave = new ArrayList<>();
        List<Integer> cacheAeroportosId    = new ArrayList<>();

        // 1. Companhias
        System.out.println("[1/5] Inserindo companhias...");
        for (Companhia c : dados.companhias) {
            if (c.codCompanhia == null) continue;
            if (buscarNaLista(cacheCompanhiasChave, c.codCompanhia) != -1) continue;

            Integer idExistente = buscarId(
                "SELECT idCompanhia FROM companhia WHERE codCompanhia = ? LIMIT 1", c.codCompanhia);

            if (idExistente != null) {
                cacheCompanhiasChave.add(c.codCompanhia);
                cacheCompanhiasId.add(idExistente);
            } else {
                KeyHolder keyHolder = new GeneratedKeyHolder();
                bd.update(new PreparedStatementCreator() {
                    @Override
                    public PreparedStatement createPreparedStatement(Connection con) throws java.sql.SQLException {
                        PreparedStatement ps = con.prepareStatement(
                            "INSERT INTO companhia (codCompanhia, nomeCompanhia, paisCompanhia, razaoSocial, cnpj)" +
                            " VALUES (?, ?, ?, ?, ?)",
                            Statement.RETURN_GENERATED_KEYS);
                        ps.setInt(1, c.codCompanhia);
                        ps.setString(2, c.nomeCompanhia  != null ? c.nomeCompanhia  : "DESCONHECIDA");
                        ps.setString(3, c.paisCompanhia  != null ? c.paisCompanhia  : "BRASIL");
                        ps.setString(4, c.razaoSocial    != null ? c.razaoSocial    : "");
                        ps.setString(5, c.cnpj           != null ? c.cnpj           : "");
                        return ps;
                    }
                }, keyHolder);
                Number gerado = keyHolder.getKey();
                if (gerado != null) {
                    cacheCompanhiasChave.add(c.codCompanhia);
                    cacheCompanhiasId.add(gerado.intValue());
                }
            }
        }
        System.out.printf("Total de companhias em cache: %d%n", cacheCompanhiasChave.size());

        // 2. Aviões
        System.out.println("[2/5] Inserindo avioes...");
        for (Aviao a : dados.avioes) {
            if (a.modelo == null || a.modelo.trim().isEmpty()) continue;
            if (buscarNaLista(cacheAvioesChave, a.modelo) != -1) continue;

            Integer idExistente = buscarId(
                "SELECT idAviao FROM aviao WHERE modelo = ? LIMIT 1", a.modelo);

            if (idExistente != null) {
                cacheAvioesChave.add(a.modelo);
                cacheAvioesId.add(idExistente);
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
                Number gerado = keyHolder.getKey();
                if (gerado != null) {
                    cacheAvioesChave.add(a.modelo);
                    cacheAvioesId.add(gerado.intValue());
                }
            }
        }
        System.out.printf("Total de modelos de avioes em cache: %d%n", cacheAvioesChave.size());

        // 3. Aeroportos
        System.out.println("[3/5] Inserindo aeroportos...");
        for (Aeroporto a : dados.aeroportos) {
            String chave = (a.icao != null && !a.icao.isEmpty()) ? a.icao : a.nomeAeroporto;
            if (chave == null) continue;
            if (buscarNaLista(cacheAeroportosChave, chave) != -1) continue;

            Integer idExistente;
            if (a.icao != null && !a.icao.isEmpty()) {
                idExistente = buscarId(
                    "SELECT idAeroporto FROM aeroporto WHERE nomeAeroporto = ? OR nomeAeroporto = ? LIMIT 1",
                    a.nomeAeroporto, a.icao);
            } else {
                idExistente = buscarId(
                    "SELECT idAeroporto FROM aeroporto WHERE nomeAeroporto = ? LIMIT 1",
                    a.nomeAeroporto);
            }

            if (idExistente != null) {
                cacheAeroportosChave.add(chave);
                cacheAeroportosId.add(idExistente);
            } else {
                KeyHolder keyHolder = new GeneratedKeyHolder();
                bd.update(new PreparedStatementCreator() {
                    @Override
                    public PreparedStatement createPreparedStatement(Connection con) throws java.sql.SQLException {
                        PreparedStatement ps = con.prepareStatement(
                            "INSERT INTO aeroporto (nomeAeroporto, municipio, uf, regiao, pais) VALUES (?, ?, ?, ?, ?)",
                            Statement.RETURN_GENERATED_KEYS);
                        ps.setString(1, a.nomeAeroporto != null ? a.nomeAeroporto : "");
                        ps.setString(2, a.municipio     != null ? a.municipio     : "");
                        ps.setString(3, a.uf            != null ? a.uf            : "");
                        ps.setString(4, a.regiao        != null ? a.regiao        : "");
                        ps.setString(5, a.pais          != null ? a.pais          : "BRASIL");
                        return ps;
                    }
                }, keyHolder);
                Number gerado = keyHolder.getKey();
                if (gerado != null) {
                    cacheAeroportosChave.add(chave);
                    cacheAeroportosId.add(gerado.intValue());
                }
            }
        }
        System.out.printf("Total de aeroportos em cache: %d%n", cacheAeroportosChave.size());

        // 4. Voos
        System.out.println("[4/5] Inserindo voos...");
        Integer idCompanhiaPadrao = cacheCompanhiasId.isEmpty()
                ? buscarId("SELECT idCompanhia FROM companhia LIMIT 1")
                : cacheCompanhiasId.get(0);
        Integer idAviaoPadrao = cacheAvioesId.isEmpty()
                ? buscarId("SELECT idAviao FROM aviao LIMIT 1")
                : cacheAvioesId.get(0);

        int voosInseridos = 0;
        int maxVoos = Math.min(dados.voos.size(), dados.companhias.size());
        for (int i = 0; i < maxVoos; i++) {
            Voo       v = dados.voos.get(i);
            Companhia c = dados.companhias.get(i);
            Aviao     a = (i < dados.avioes.size()) ? dados.avioes.get(i) : null;

            int idxComp  = (c != null && c.codCompanhia != null)
                    ? buscarNaLista(cacheCompanhiasChave, c.codCompanhia) : -1;
            int idxAviao = (a != null && a.modelo != null)
                    ? buscarNaLista(cacheAvioesChave, a.modelo) : -1;

            Integer fkCompanhia = idxComp  != -1 ? cacheCompanhiasId.get(idxComp)  : idCompanhiaPadrao;
            Integer fkAviao     = idxAviao != -1 ? cacheAvioesId.get(idxAviao)     : idAviaoPadrao;

            if (fkCompanhia == null || fkAviao == null) continue;

            final Integer finalFkComp = fkCompanhia;
            final Integer finalFkAv   = fkAviao;

            KeyHolder keyHolder = new GeneratedKeyHolder();
            bd.update(new PreparedStatementCreator() {
                @Override
                public PreparedStatement createPreparedStatement(Connection con) throws java.sql.SQLException {
                    PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO voo (numVoo, tipoVoo, qtdPassageiros, fkCompanhia, fkAviao) VALUES (?, ?, ?, ?, ?)",
                        Statement.RETURN_GENERATED_KEYS);
                    ps.setInt(1, v.numVoo         != null ? v.numVoo         : 0);
                    ps.setInt(2, v.tipoVoo        != null ? v.tipoVoo        : 0);
                    ps.setInt(3, v.qtdPassageiros  != null ? v.qtdPassageiros : 0);
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
            AeroportoDirecao ad   = dados.aeroportoDirecoes.get(i);
            Aeroporto        aero = dados.aeroportos.get(i);

            int idxVoo = i / 2; // duas direções por voo (partida + destino)
            if (idxVoo >= dados.voos.size()) break;
            Voo vooRelacionado = dados.voos.get(idxVoo);
            if (vooRelacionado.idVoo == null) continue;

            String chaveAero = (aero.icao != null && !aero.icao.isEmpty()) ? aero.icao : aero.nomeAeroporto;
            int idxAero = buscarNaLista(cacheAeroportosChave, chaveAero);
            if (idxAero == -1) continue;
            Integer fkAeroporto = cacheAeroportosId.get(idxAero);

            try {
                bd.update(
                    "INSERT INTO aeroportoDirecao (fkAeroporto, fkVoo, direcao, dia, hora) VALUES (?, ?, ?, ?, ?)" +
                    " ON DUPLICATE KEY UPDATE direcao = VALUES(direcao), dia = VALUES(dia), hora = VALUES(hora)",
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
        novoLogLeitura(
            "INFO", "importacao",
            String.format("Base ANAC importada: %d companhias, %d avioes, %d aeroportos, %d voos.",
                cacheCompanhiasChave.size(), cacheAvioesChave.size(), cacheAeroportosChave.size(), voosInseridos),
            LocalDateTime.now(), "Java", dados
        );
    }

    // ---------------------------------------------------------------
    // Busca o índice de um valor em uma lista.
    // Retorna -1 se não encontrar.
    // ---------------------------------------------------------------
    private static <T> int buscarNaLista(List<T> lista, T valor) {
        for (int i = 0; i < lista.size(); i++) {
            if (lista.get(i) != null && lista.get(i).equals(valor)) {
                return i;
            }
        }
        return -1;
    }

    // ---------------------------------------------------------------
    // Executa uma query que retorna um único inteiro (ex: SELECT id...)
    // ---------------------------------------------------------------
    private static Integer buscarId(String sql, Object... params) {
        try {
            List<Integer> list = bd.queryForList(sql, Integer.class, params);
            if (list != null && !list.isEmpty()) {
                return list.get(0);
            }
        } catch (Exception ignored) {}
        return null;
    }

    // ---------------------------------------------------------------
    // Log simples (erros sem contexto de arquivo)
    // ---------------------------------------------------------------
    public static void novoLogBanco(String categoria, String servico, String mensagem,
                                    LocalDateTime dataHora, String origemCadastro) {
        try {
            bd.update(
                "INSERT INTO logsServico (categoria, servico, mensagem, dataHora, origemCadastro)" +
                " VALUES (?, ?, ?, ?, ?)",
                categoria, servico, mensagem, dataHora, origemCadastro);
        } catch (Exception e) {
            System.err.println("Falha ao registrar log no banco: " + e.getMessage());
        }
    }

    // ---------------------------------------------------------------
    // Log completo de leitura — preenche todos os campos do logsServico
    // incluindo métricas de linhas e status de leitura
    // ---------------------------------------------------------------
    public static void novoLogLeitura(String categoria, String servico, String mensagem,
                                      LocalDateTime dataHora, String origemCadastro,
                                      LeitorExcel.ResultadoLeitura resultado) {
        try {
            bd.update(
                "INSERT INTO logsServico" +
                " (categoria, servico, mensagem, dataHora, origemCadastro," +
                "  nomeArquivo, statusLeitura, linhasEncontradas, linhasLidas, linhasRejeitadas, detalheErro)" +
                " VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                categoria,
                servico,
                mensagem,
                dataHora,
                origemCadastro,
                resultado.nomeArquivo,
                resultado.statusLeitura,
                resultado.linhasEncontradas,
                resultado.linhasLidas,
                resultado.linhasRejeitadas,
                resultado.detalheErro
            );
        } catch (Exception e) {
            System.err.println("Falha ao registrar log de leitura no banco: " + e.getMessage());
        }
    }
}
