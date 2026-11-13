package com.ascent.apachepoi;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.PreparedStatementCreator;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;

import java.io.File;
import java.io.BufferedReader;
import java.io.InputStreamReader;
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
    private static void logErro(String msg) { System.err.printf("[%s] ERRO: %s%n", LocalDateTime.now().format(FMT), msg); }

    public static void main(String[] args) {
        carregarEnv();
        bd = new JdbcTemplate(new Conexao().getConexao());

        String bucket  = LeitorExcel.getEnvOrProp("AWS_BUCKET", "ascent-base-de-dados");
        String prefixo = LeitorExcel.getEnvOrProp("AWS_PREFIXO_ARQUIVOS", "anac_part_");
        String region  = LeitorExcel.getEnvOrProp("AWS_REGION", "us-east-1");
        int totalPartes;
        try {
            totalPartes = Integer.parseInt(LeitorExcel.getEnvOrProp("AWS_TOTAL_PARTES", "23"));
        } catch (NumberFormatException e) {
            totalPartes = 23;
        }

        log("=== Iniciando importacao do S3 ===");
        log("Bucket : s3://" + bucket);
        log("Prefixo: " + prefixo);
        log("Partes : " + totalPartes);
        log("Regiao : " + region);

        // Verifica se o AWS CLI está disponível
        if (!awsCliDisponivel()) {
            logErro("AWS CLI não encontrado. Instale o AWS CLI na imagem ou na EC2.");
            System.exit(1);
        }

        File tmpDir = new File("/tmp/ascent-s3");
        tmpDir.mkdirs();

        int partesProcessadas = 0;
        int partesComErro     = 0;

        for (int i = 1; i <= totalPartes; i++) {
            String nomeArquivo = String.format("%s%03d.xlsx", prefixo, i);
            String s3Uri       = String.format("s3://%s/%s", bucket, nomeArquivo);
            File   destino     = new File(tmpDir, nomeArquivo);

            log(String.format("[%d/%d] Baixando %s ...", i, totalPartes, s3Uri));

            // Baixa via AWS CLI (usa IAM Role da EC2 automaticamente)
            boolean baixou = baixarDoS3(s3Uri, destino.getAbsolutePath(), region);
            if (!baixou) {
                logErro("Falha ao baixar " + s3Uri + ". Pulando.");
                partesComErro++;
                continue;
            }

            log(String.format("[%d/%d] Processando %s (%.1f MB)...",
                i, totalPartes, nomeArquivo, destino.length() / 1_048_576.0));

            try {
                LeitorExcel leitor = new LeitorExcel();
                LeitorExcel.ResultadoLeitura dados = leitor.extrairDeArquivo(destino);
                dados.nomeArquivo = nomeArquivo;
                log(String.format("[%d/%d] Leitura concluida — %d linhas validas, %d rejeitadas",
                    i, totalPartes, dados.linhasLidas, dados.linhasRejeitadas));

                registrarLogLeitura(dados);
                inserirDadosNoBanco(dados);
                partesProcessadas++;
            } catch (Exception e) {
                logErro("Falha ao processar " + nomeArquivo + ": " + e.getMessage());
                partesComErro++;
            } finally {
                // Remove arquivo temporário para liberar espaço em disco
                destino.delete();
            }
        }

        log("=== Importacao concluida ===");
        log("Partes processadas: " + partesProcessadas);
        log("Partes com erro   : " + partesComErro);

        // Limpa o diretório temporário
        tmpDir.delete();
    }

    // Baixa um arquivo do S3 usando AWS CLI (aproveita IAM Role da EC2 automaticamente)
    private static boolean baixarDoS3(String s3Uri, String destino, String region) {
        try {
            ProcessBuilder pb = new ProcessBuilder(
                "aws", "s3", "cp", s3Uri, destino,
                "--region", region,
                "--no-progress"
            );
            pb.redirectErrorStream(true);
            Process processo = pb.start();

            StringBuilder saida = new StringBuilder();
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(processo.getInputStream()))) {
                String linha;
                while ((linha = reader.readLine()) != null) {
                    saida.append(linha).append("\n");
                }
            }

            int exitCode = processo.waitFor();
            if (exitCode != 0) {
                logErro("aws s3 cp falhou (exit " + exitCode + "): " + saida.toString().trim());
                return false;
            }
            return true;
        } catch (Exception e) {
            logErro("Erro ao executar aws cli: " + e.getMessage());
            return false;
        }
    }

    // Verifica se o AWS CLI está instalado
    private static boolean awsCliDisponivel() {
        try {
            ProcessBuilder pb = new ProcessBuilder("aws", "--version");
            pb.redirectErrorStream(true);
            Process p = pb.start();
            p.waitFor();
            return p.exitValue() == 0;
        } catch (Exception e) {
            return false;
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
        if (!f.exists()) f = new java.io.File("../.env");
        if (!f.exists()) return;
        try (java.io.BufferedReader br = new java.io.BufferedReader(new java.io.FileReader(f))) {
            String linha;
            while ((linha = br.readLine()) != null) {
                linha = linha.trim();
                if (linha.isEmpty() || linha.startsWith("#") || !linha.contains("=")) continue;
                int eq       = linha.indexOf('=');
                String chave = linha.substring(0, eq).trim();
                String valor = linha.substring(eq + 1).trim();
                if ((valor.startsWith("\"") && valor.endsWith("\"")) ||
                    (valor.startsWith("'")  && valor.endsWith("'"))) {
                    valor = valor.substring(1, valor.length() - 1);
                }
                if (valor.isEmpty()) continue;
                if (System.getProperty(chave) == null) System.setProperty(chave, valor);
                if ("AWS_ACCESS_KEY_ID".equalsIgnoreCase(chave))       System.setProperty("aws.accessKeyId",    valor);
                else if ("AWS_SECRET_ACCESS_KEY".equalsIgnoreCase(chave)) System.setProperty("aws.secretAccessKey", valor);
                else if ("AWS_SESSION_TOKEN".equalsIgnoreCase(chave))  System.setProperty("aws.sessionToken",   valor);
                else if ("AWS_REGION".equalsIgnoreCase(chave))         System.setProperty("aws.region",         valor);
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
            if (c.codCompanhia == null || buscarNaLista(cacheCompChave, c.codCompanhia) != -1) continue;
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
                    ps.setString(2, c.nomeCompanhia != null ? c.nomeCompanhia : "DESCONHECIDA");
                    ps.setString(3, c.paisCompanhia != null ? c.paisCompanhia : "BRASIL");
                    ps.setString(4, c.razaoSocial   != null ? c.razaoSocial   : "");
                    ps.setString(5, c.cnpj          != null ? c.cnpj          : "");
                    return ps;
                }, kh);
                if (kh.getKey() != null) {
                    cacheCompChave.add(c.codCompanhia);
                    cacheCompId.add(kh.getKey().intValue());
                }
            }
        }

        for (Aviao a : dados.avioes) {
            if (a.modelo == null || a.modelo.isBlank() || buscarNaLista(cacheAvChave, a.modelo) != -1) continue;
            Integer id = buscarId("SELECT idAviao FROM aviao WHERE modelo = ? LIMIT 1", a.modelo);
            if (id != null) {
                cacheAvChave.add(a.modelo);
                cacheAvId.add(id);
            } else {
                KeyHolder kh = new GeneratedKeyHolder();
                bd.update((Connection con) -> {
                    PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO aviao (numAssentos, modelo) VALUES (?,?)", Statement.RETURN_GENERATED_KEYS);
                    ps.setInt(1, a.numAssentos != null ? a.numAssentos : 0);
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
            String chave = (a.icao != null && !a.icao.isEmpty()) ? a.icao : a.nomeAeroporto;
            if (chave == null || buscarNaLista(cacheAeroChave, chave) != -1) continue;
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
                    ps.setString(1, a.nomeAeroporto != null ? a.nomeAeroporto : "");
                    ps.setString(2, a.municipio     != null ? a.municipio     : "");
                    ps.setString(3, a.uf            != null ? a.uf            : "");
                    ps.setString(4, a.regiao        != null ? a.regiao        : "");
                    ps.setString(5, a.pais          != null ? a.pais          : "BRASIL");
                    return ps;
                }, kh);
                if (kh.getKey() != null) {
                    cacheAeroChave.add(chave);
                    cacheAeroId.add(kh.getKey().intValue());
                }
            }
        }

        Integer compPadrao = cacheCompId.isEmpty() ? buscarId("SELECT idCompanhia FROM companhia LIMIT 1") : cacheCompId.get(0);
        Integer avPadrao   = cacheAvId.isEmpty()   ? buscarId("SELECT idAviao FROM aviao LIMIT 1")         : cacheAvId.get(0);

        int voosInseridos = 0;
        for (int i = 0; i < Math.min(dados.voos.size(), dados.companhias.size()); i++) {
            Voo       v = dados.voos.get(i);
            Companhia c = dados.companhias.get(i);
            Aviao     a = i < dados.avioes.size() ? dados.avioes.get(i) : null;

            int idxC = (c != null && c.codCompanhia != null) ? buscarNaLista(cacheCompChave, c.codCompanhia) : -1;
            int idxA = (a != null && a.modelo != null)       ? buscarNaLista(cacheAvChave,   a.modelo)       : -1;

            final Integer fkC = idxC != -1 ? cacheCompId.get(idxC) : compPadrao;
            final Integer fkA = idxA != -1 ? cacheAvId.get(idxA)   : avPadrao;
            if (fkC == null || fkA == null) continue;

            KeyHolder kh = new GeneratedKeyHolder();
            bd.update((Connection con) -> {
                PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO voo (numVoo, tipoVoo, qtdPassageiros, fkCompanhia, fkAviao) VALUES (?,?,?,?,?)",
                    Statement.RETURN_GENERATED_KEYS);
                ps.setInt(1, v.numVoo         != null ? v.numVoo         : 0);
                ps.setInt(2, v.tipoVoo        != null ? v.tipoVoo        : 0);
                ps.setInt(3, v.qtdPassageiros != null ? v.qtdPassageiros : 0);
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
            if (idxVoo >= dados.voos.size()) break;
            Voo voo = dados.voos.get(idxVoo);
            if (voo.idVoo == null) continue;
            String chave = (aero.icao != null && !aero.icao.isEmpty()) ? aero.icao : aero.nomeAeroporto;
            int idxAero = buscarNaLista(cacheAeroChave, chave);
            if (idxAero == -1) continue;
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
            if (lista.get(i) != null && lista.get(i).equals(valor)) return i;
        }
        return -1;
    }

    private static Integer buscarId(String sql, Object... params) {
        try {
            List<Integer> r = bd.queryForList(sql, Integer.class, params);
            return (r != null && !r.isEmpty()) ? r.get(0) : null;
        } catch (Exception ignored) {
            return null;
        }
    }
}
