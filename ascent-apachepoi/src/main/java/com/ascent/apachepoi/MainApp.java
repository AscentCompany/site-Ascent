package com.ascent.apachepoi;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.PreparedStatementCreator;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

public class MainApp {

    private static JdbcTemplate bd;
    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("HH:mm:ss");

    private static void log(String msg)     { System.out.printf("[%s] %s%n", LocalDateTime.now().format(FMT), msg); }
    private static void logErro(String msg) { System.err.printf("[%s] %s%n",  LocalDateTime.now().format(FMT), msg); }

    public static void main(String[] args) {
        carregarEnv();
        bd = new JdbcTemplate(new Conexao().getConexao());

        String arquivo = "/home/lucasveneroso/Sptech/Pi/Ascent/output/anac_part_023.xlsx";
        log("Lendo arquivo: " + arquivo);

        try {
            LeitorExcel leitor = new LeitorExcel();
            LeitorExcel.ResultadoLeitura dados = leitor.extrairDeArquivo(new java.io.File(arquivo));
            dados.nomeArquivo = "anac_part_023.xlsx";
            log("Leitura concluida — " + dados.linhasLidas + " linhas validas, " + dados.linhasRejeitadas + " rejeitadas");
            registrarLogLeitura(dados);
            log("Iniciando insercao no banco...");
            inserirDadosNoBanco(dados);
        } catch (Exception e) {
            logErro("Falha: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private static void registrarLogLeitura(LeitorExcel.ResultadoLeitura dados) {
        String categoria = switch (dados.statusLeitura) {
            case "LIDO"              -> "INFO";
            case "PARCIALMENTE_LIDO" -> "WARN";
            default                  -> "ERROR";
        };
        String mensagem = String.format("Leitura %s: %d encontradas, %d lidas, %d rejeitadas.",
                dados.statusLeitura, dados.linhasEncontradas, dados.linhasLidas, dados.linhasRejeitadas);
        try {
            bd.update(
                "INSERT INTO logsServico (categoria, servico, mensagem, dataHora, origemCadastro," +
                " nomeArquivo, statusLeitura, linhasEncontradas, linhasLidas, linhasRejeitadas, detalheErro)" +
                " VALUES (?,?,?,?,?,?,?,?,?,?,?)",
                categoria, "importacao", mensagem, LocalDateTime.now(), "Java",
                dados.nomeArquivo, dados.statusLeitura,
                dados.linhasEncontradas, dados.linhasLidas, dados.linhasRejeitadas, dados.detalheErro);
        } catch (Exception e) {
            logErro("Falha ao registrar log: " + e.getMessage());
        }
    }

    private static void carregarEnv() {
        java.io.File f = new java.io.File(".env");
        if (!f.exists()) {
            f = new java.io.File("../.env");
        }
        if (!f.exists()) {
            return;
        }
        try (java.io.BufferedReader br = new java.io.BufferedReader(new java.io.FileReader(f))) {
            String linha;
            while ((linha = br.readLine()) != null) {
                linha = linha.trim();
                if (linha.isEmpty() || linha.startsWith("#") || !linha.contains("=")) {
                    continue;
                }
                int eq       = linha.indexOf('=');
                String chave = linha.substring(0, eq).trim();
                String valor = linha.substring(eq + 1).trim();
                if ((valor.startsWith("\"") && valor.endsWith("\"")) || (valor.startsWith("'") && valor.endsWith("'"))) {
                    valor = valor.substring(1, valor.length() - 1);
                }
                if (valor.isEmpty()) {
                    continue;
                }
                if (System.getProperty(chave) == null) {
                    System.setProperty(chave, valor);
                }
                if ("AWS_ACCESS_KEY_ID".equalsIgnoreCase(chave)) {
                    System.setProperty("aws.accessKeyId", valor);
                } else if ("AWS_SECRET_ACCESS_KEY".equalsIgnoreCase(chave)) {
                    System.setProperty("aws.secretAccessKey", valor);
                } else if ("AWS_SESSION_TOKEN".equalsIgnoreCase(chave)) {
                    System.setProperty("aws.sessionToken", valor);
                } else if ("AWS_REGION".equalsIgnoreCase(chave)) {
                    System.setProperty("aws.region", valor);
                }
            }
        } catch (Exception ignored) {}
    }

    public static void inserirDadosNoBanco(LeitorExcel.ResultadoLeitura dados) {
        List<Integer> cacheCompChave = new ArrayList<>();
        List<Integer> cacheCompId    = new ArrayList<>();
        List<String>  cacheAvChave   = new ArrayList<>();
        List<Integer> cacheAvId      = new ArrayList<>();
        List<String>  cacheAeroChave = new ArrayList<>();
        List<Integer> cacheAeroId    = new ArrayList<>();

        for (Companhia c : dados.companhias) {
            if (c.codCompanhia == null || buscarNaLista(cacheCompChave, c.codCompanhia) != -1) {
                continue;
            }
            Integer id = buscarId("SELECT idCompanhia FROM companhia WHERE codCompanhia = ? LIMIT 1", c.codCompanhia);
            if (id != null) {
                cacheCompChave.add(c.codCompanhia);
                cacheCompId.add(id);
            } else {
                KeyHolder kh = new GeneratedKeyHolder();
                bd.update((Connection con) -> {
                    PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO companhia (codCompanhia, nomeCompanhia, paisCompanhia, razaoSocial, cnpj) VALUES (?,?,?,?,?)",
                        Statement.RETURN_GENERATED_KEYS);
                    ps.setInt(1, c.codCompanhia);
                    if (c.nomeCompanhia != null) {
                        ps.setString(2, c.nomeCompanhia);
                    } else {
                        ps.setString(2, "DESCONHECIDA");
                    }
                    if (c.paisCompanhia != null) {
                        ps.setString(3, c.paisCompanhia);
                    } else {
                        ps.setString(3, "BRASIL");
                    }
                    if (c.razaoSocial != null) {
                        ps.setString(4, c.razaoSocial);
                    } else {
                        ps.setString(4, "");
                    }
                    if (c.cnpj != null) {
                        ps.setString(5, c.cnpj);
                    } else {
                        ps.setString(5, "");
                    }
                    return ps;
                }, kh);
                if (kh.getKey() != null) {
                    cacheCompChave.add(c.codCompanhia);
                    cacheCompId.add(kh.getKey().intValue());
                }
            }
        }

        for (Aviao a : dados.avioes) {
            if (a.modelo == null || a.modelo.isBlank() || buscarNaLista(cacheAvChave, a.modelo) != -1) {
                continue;
            }
            Integer id = buscarId("SELECT idAviao FROM aviao WHERE modelo = ? LIMIT 1", a.modelo);
            if (id != null) {
                cacheAvChave.add(a.modelo);
                cacheAvId.add(id);
            } else {
                KeyHolder kh = new GeneratedKeyHolder();
                bd.update((Connection con) -> {
                    PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO aviao (numAssentos, modelo) VALUES (?,?)", Statement.RETURN_GENERATED_KEYS);
                    if (a.numAssentos != null) {
                        ps.setInt(1, a.numAssentos);
                    } else {
                        ps.setInt(1, 0);
                    }
                    ps.setString(2, a.modelo);
                    return ps;
                }, kh);
                if (kh.getKey() != null) {
                    cacheAvChave.add(a.modelo);
                    cacheAvId.add(kh.getKey().intValue());
                }
            }
        }

        for (Aeroporto a : dados.aeroportos) {
            String chave;
            if (a.icao != null && !a.icao.isEmpty()) {
                chave = a.icao;
            } else {
                chave = a.nomeAeroporto;
            }
            if (chave == null || buscarNaLista(cacheAeroChave, chave) != -1) {
                continue;
            }
            Integer id;
            if (a.icao != null && !a.icao.isEmpty()) {
                id = buscarId("SELECT idAeroporto FROM aeroporto WHERE nomeAeroporto = ? OR nomeAeroporto = ? LIMIT 1", a.nomeAeroporto, a.icao);
            } else {
                id = buscarId("SELECT idAeroporto FROM aeroporto WHERE nomeAeroporto = ? LIMIT 1", a.nomeAeroporto);
            }
            if (id != null) {
                cacheAeroChave.add(chave);
                cacheAeroId.add(id);
            } else {
                KeyHolder kh = new GeneratedKeyHolder();
                bd.update((Connection con) -> {
                    PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO aeroporto (nomeAeroporto, municipio, uf, regiao, pais) VALUES (?,?,?,?,?)",
                        Statement.RETURN_GENERATED_KEYS);
                    if (a.nomeAeroporto != null) {
                        ps.setString(1, a.nomeAeroporto);
                    } else {
                        ps.setString(1, "");
                    }
                    if (a.municipio != null) {
                        ps.setString(2, a.municipio);
                    } else {
                        ps.setString(2, "");
                    }
                    if (a.uf != null) {
                        ps.setString(3, a.uf);
                    } else {
                        ps.setString(3, "");
                    }
                    if (a.regiao != null) {
                        ps.setString(4, a.regiao);
                    } else {
                        ps.setString(4, "");
                    }
                    if (a.pais != null) {
                        ps.setString(5, a.pais);
                    } else {
                        ps.setString(5, "BRASIL");
                    }
                    return ps;
                }, kh);
                if (kh.getKey() != null) {
                    cacheAeroChave.add(chave);
                    cacheAeroId.add(kh.getKey().intValue());
                }
            }
        }

        Integer compPadrao;
        if (cacheCompId.isEmpty()) {
            compPadrao = buscarId("SELECT idCompanhia FROM companhia LIMIT 1");
        } else {
            compPadrao = cacheCompId.get(0);
        }

        Integer avPadrao;
        if (cacheAvId.isEmpty()) {
            avPadrao = buscarId("SELECT idAviao FROM aviao LIMIT 1");
        } else {
            avPadrao = cacheAvId.get(0);
        }

        int voosInseridos = 0;
        for (int i = 0; i < Math.min(dados.voos.size(), dados.companhias.size()); i++) {
            Voo       v = dados.voos.get(i);
            Companhia c = dados.companhias.get(i);

            Aviao a;
            if (i < dados.avioes.size()) {
                a = dados.avioes.get(i);
            } else {
                a = null;
            }

            int idxC;
            if (c != null && c.codCompanhia != null) {
                idxC = buscarNaLista(cacheCompChave, c.codCompanhia);
            } else {
                idxC = -1;
            }

            int idxA;
            if (a != null && a.modelo != null) {
                idxA = buscarNaLista(cacheAvChave, a.modelo);
            } else {
                idxA = -1;
            }

            final Integer fkC;
            if (idxC != -1) {
                fkC = cacheCompId.get(idxC);
            } else {
                fkC = compPadrao;
            }

            final Integer fkA;
            if (idxA != -1) {
                fkA = cacheAvId.get(idxA);
            } else {
                fkA = avPadrao;
            }

            if (fkC == null || fkA == null) {
                continue;
            }

            KeyHolder kh = new GeneratedKeyHolder();
            bd.update((Connection con) -> {
                PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO voo (numVoo, tipoVoo, qtdPassageiros, fkCompanhia, fkAviao) VALUES (?,?,?,?,?)",
                    Statement.RETURN_GENERATED_KEYS);
                if (v.numVoo != null) {
                    ps.setInt(1, v.numVoo);
                } else {
                    ps.setInt(1, 0);
                }
                if (v.tipoVoo != null) {
                    ps.setInt(2, v.tipoVoo);
                } else {
                    ps.setInt(2, 0);
                }
                if (v.qtdPassageiros != null) {
                    ps.setInt(3, v.qtdPassageiros);
                } else {
                    ps.setInt(3, 0);
                }
                ps.setInt(4, fkC);
                ps.setInt(5, fkA);
                return ps;
            }, kh);
            if (kh.getKey() != null) {
                v.idVoo = kh.getKey().intValue();
                voosInseridos++;
            }
        }

        int direcoesInseridas = 0;
        for (int i = 0; i < Math.min(dados.aeroportoDirecoes.size(), dados.aeroportos.size()); i++) {
            AeroportoDirecao ad   = dados.aeroportoDirecoes.get(i);
            Aeroporto        aero = dados.aeroportos.get(i);
            int idxVoo = i / 2;
            if (idxVoo >= dados.voos.size()) {
                break;
            }
            Voo voo = dados.voos.get(idxVoo);
            if (voo.idVoo == null) {
                continue;
            }
            String chave;
            if (aero.icao != null && !aero.icao.isEmpty()) {
                chave = aero.icao;
            } else {
                chave = aero.nomeAeroporto;
            }
            int idxAero = buscarNaLista(cacheAeroChave, chave);
            if (idxAero == -1) {
                continue;
            }
            try {
                bd.update(
                    "INSERT INTO aeroportoDirecao (fkAeroporto, fkVoo, direcao, dia, hora) VALUES (?,?,?,?,?)" +
                    " ON DUPLICATE KEY UPDATE direcao=VALUES(direcao), dia=VALUES(dia), hora=VALUES(hora)",
                    cacheAeroId.get(idxAero), voo.idVoo, ad.direcao,
                    java.sql.Date.valueOf(ad.dia), java.sql.Time.valueOf(ad.hora));
                direcoesInseridas++;
            } catch (Exception ignored) {}
        }

        log(String.format("Concluido — %d companhias | %d avioes | %d aeroportos | %d voos | %d direcoes inseridos",
            cacheCompChave.size(), cacheAvChave.size(), cacheAeroChave.size(), voosInseridos, direcoesInseridas));
    }

    private static <T> int buscarNaLista(List<T> lista, T valor) {
        for (int i = 0; i < lista.size(); i++) {
            if (lista.get(i) != null && lista.get(i).equals(valor)) {
                return i;
            }
        }
        return -1;
    }

    private static Integer buscarId(String sql, Object... params) {
        try {
            List<Integer> r = bd.queryForList(sql, Integer.class, params);
            if (r != null && !r.isEmpty()) {
                return r.get(0);
            }
            return null;
        } catch (Exception ignored) {
            return null;
        }
    }
}
