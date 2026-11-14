package com.ascent.apachepoi;

import org.springframework.jdbc.core.JdbcTemplate;

import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

public class MainApp {

    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("HH:mm:ss");

    private static JdbcTemplate      jdbcTemplate;
    private static CompanhiaDao      companhiaDao;
    private static AviaoDao          aviaoDao;
    private static AeroportoDao      aeroportoDao;
    private static VooDao            vooDao;
    private static AeroportoDirecaoDao aeroportoDirecaoDao;

    // <editor-fold desc="Logs">
    private static void log(String msg) {
        System.out.printf("[%s] %s%n", LocalDateTime.now().format(FMT), msg);
    }

    private static void logErro(String msg) {
        System.err.printf("[%s] ERRO: %s%n", LocalDateTime.now().format(FMT), msg);
    }
    // </editor-fold>

    public static void main(String[] args) {
        carregarEnv();

        jdbcTemplate        = new JdbcTemplate(new Conexao().getConexao());
        companhiaDao        = new CompanhiaDao(jdbcTemplate);
        aviaoDao            = new AviaoDao(jdbcTemplate);
        aeroportoDao        = new AeroportoDao(jdbcTemplate);
        vooDao              = new VooDao(jdbcTemplate);
        aeroportoDirecaoDao = new AeroportoDirecaoDao(jdbcTemplate);

        String bucket      = LeitorExcel.getEnvOrProp("AWS_BUCKET", "ascent-base-de-dados");
        String prefixo     = LeitorExcel.getEnvOrProp("AWS_PREFIXO_ARQUIVOS", "anac_part_");
        String region      = LeitorExcel.getEnvOrProp("AWS_REGION", "us-east-1");
        int    totalPartes = Integer.parseInt(LeitorExcel.getEnvOrProp("AWS_TOTAL_PARTES", "23"));

        log("╔══════════════════════════════════════════════╗");
        log("║        Ascent — Importação S3 → MySQL        ║");
        log("╚══════════════════════════════════════════════╝");
        log("Bucket : s3://" + bucket);
        log("Prefixo: " + prefixo + " | Partes: " + totalPartes + " | Região: " + region);

        if (!awsCliDisponivel()) {
            logErro("AWS CLI não encontrado na imagem. Abortando.");
            System.exit(1);
        }

        File tmpDir = new File("/tmp/ascent-s3");
        tmpDir.mkdirs();

        int partesOk   = 0;
        int partesErro = 0;

        for (int i = 1; i <= totalPartes; i++) {
            String nomeArquivo = String.format("%s%03d.xlsx", prefixo, i);
            String s3Uri       = String.format("s3://%s/%s", bucket, nomeArquivo);
            File   destino     = new File(tmpDir, nomeArquivo);

            log("────────────────────────────────────────────────");
            log(String.format("[%d/%d] Baixando %s ...", i, totalPartes, s3Uri));

            if (!baixarDoS3(s3Uri, destino.getAbsolutePath(), region)) {
                logErro("Falha ao baixar " + nomeArquivo + ". Pulando.");
                partesErro++;
                continue;
            }

            log(String.format("[%d/%d] Arquivo baixado (%.1f MB). Lendo...", i, totalPartes, destino.length() / 1_048_576.0));

            try {
                LeitorExcel leitor = new LeitorExcel();
                LeitorExcel.ResultadoLeitura resultado = leitor.extrairDeArquivo(destino);

                log(String.format("[%d/%d] Leitura concluída — %d encontradas | %d válidas | %d rejeitadas | status: %s",
                        i, totalPartes,
                        resultado.getLinhasEncontradas(),
                        resultado.getLinhasLidas(),
                        resultado.getLinhasRejeitadas(),
                        resultado.getStatusLeitura()));

                registrarLogLeitura(resultado);

                log(String.format("[%d/%d] Inserindo no banco...", i, totalPartes));
                int[] contadores = inserirDadosNoBanco(resultado);
                log(String.format("[%d/%d] ✔ %d companhias | %d aviões | %d aeroportos | %d voos | %d direções",
                        i, totalPartes,
                        contadores[0], contadores[1], contadores[2], contadores[3], contadores[4]));

                partesOk++;

            } catch (Exception e) {
                logErro(String.format("[%d/%d] Falha ao processar %s: %s", i, totalPartes, nomeArquivo, e.getMessage()));
                partesErro++;
            } finally {
                destino.delete();
            }
        }

        log("────────────────────────────────────────────────");
        log("╔══════════════════════════════════════════════╗");
        log(String.format("║ Importação concluída: %d OK | %d com erro      ║", partesOk, partesErro));
        log("╚══════════════════════════════════════════════╝");

        tmpDir.delete();
    }

    // Insere todos os dados de um ResultadoLeitura no banco usando os DAOs
    private static int[] inserirDadosNoBanco(LeitorExcel.ResultadoLeitura resultado) {
        // Caches para evitar consultas repetidas ao banco
        List<Integer> cacheCompChave = new ArrayList<>();
        List<Integer> cacheCompId   = new ArrayList<>();
        List<String>  cacheAvChave  = new ArrayList<>();
        List<Integer> cacheAvId     = new ArrayList<>();
        List<String>  cacheAeroChave = new ArrayList<>();
        List<Integer> cacheAeroId   = new ArrayList<>();

        // --- Companhias ---
        for (Companhia c : resultado.getCompanhias()) {
            if (c.getCodCompanhia() == null) continue;
            if (indexOf(cacheCompChave, c.getCodCompanhia()) != -1) continue;

            Integer id = companhiaDao.findIdByCodCompanhia(c.getCodCompanhia());
            if (id == null) id = companhiaDao.save(c);
            if (id != null) {
                cacheCompChave.add(c.getCodCompanhia());
                cacheCompId.add(id);
            }
        }

        // --- Aviões ---
        for (Aviao a : resultado.getAvioes()) {
            if (a.getModelo() == null || a.getModelo().isBlank()) continue;
            if (indexOf(cacheAvChave, a.getModelo()) != -1) continue;

            Integer id = aviaoDao.findIdByModelo(a.getModelo());
            if (id == null) id = aviaoDao.save(a);
            if (id != null) {
                cacheAvChave.add(a.getModelo());
                cacheAvId.add(id);
            }
        }

        // --- Aeroportos ---
        for (Aeroporto a : resultado.getAeroportos()) {
            String chave = (a.getIcao() != null && !a.getIcao().isBlank()) ? a.getIcao() : a.getNomeAeroporto();
            if (chave == null) continue;
            if (indexOf(cacheAeroChave, chave) != -1) continue;

            Integer id = aeroportoDao.findIdByNomeOuIcao(a.getNomeAeroporto(), a.getIcao());
            if (id == null) id = aeroportoDao.save(a);
            if (id != null) {
                cacheAeroChave.add(chave);
                cacheAeroId.add(id);
            }
        }

        Integer compPadrao = cacheCompId.isEmpty() ? null : cacheCompId.get(0);
        Integer avPadrao   = cacheAvId.isEmpty()   ? aviaoDao.findAny() : cacheAvId.get(0);

        // --- Voos ---
        int voosInseridos = 0;
        List<Voo>              voos    = resultado.getVoos();
        List<Companhia>        comps   = resultado.getCompanhias();
        List<Aviao>            avioes  = resultado.getAvioes();

        for (int i = 0; i < voos.size(); i++) {
            Voo       v = voos.get(i);
            Companhia c = i < comps.size()  ? comps.get(i)  : null;
            Aviao     a = i < avioes.size() ? avioes.get(i) : null;

            int idxC = (c != null && c.getCodCompanhia() != null) ? indexOf(cacheCompChave, c.getCodCompanhia()) : -1;
            int idxA = (a != null && a.getModelo() != null)       ? indexOf(cacheAvChave,   a.getModelo())       : -1;

            v.setFkCompanhia(idxC != -1 ? cacheCompId.get(idxC) : compPadrao);
            v.setFkAviao    (idxA != -1 ? cacheAvId.get(idxA)   : avPadrao);

            Integer idVoo = vooDao.save(v);
            if (idVoo != null) {
                v.setIdVoo(idVoo);
                voosInseridos++;
            }
        }

        // --- AeroportoDirecoes ---
        int direcoesInseridas = 0;
        List<AeroportoDirecao> direcoes  = resultado.getAeroportoDirecoes();
        List<Aeroporto>        aeroportos = resultado.getAeroportos();

        for (int i = 0; i < direcoes.size(); i++) {
            AeroportoDirecao ad   = direcoes.get(i);
            Aeroporto        aero = i < aeroportos.size() ? aeroportos.get(i) : null;
            int idxVoo = i / 2;
            if (idxVoo >= voos.size()) break;

            Voo voo = voos.get(idxVoo);
            if (voo.getIdVoo() == null) continue;

            if (aero == null) continue;
            String chave = (aero.getIcao() != null && !aero.getIcao().isBlank()) ? aero.getIcao() : aero.getNomeAeroporto();
            int idxAero = indexOf(cacheAeroChave, chave);
            if (idxAero == -1) continue;

            ad.setFkAeroporto(cacheAeroId.get(idxAero));
            ad.setFkVoo(voo.getIdVoo());

            try {
                aeroportoDirecaoDao.save(ad);
                direcoesInseridas++;
            } catch (Exception ignored) {}
        }

        return new int[]{cacheCompChave.size(), cacheAvChave.size(), cacheAeroChave.size(), voosInseridos, direcoesInseridas};
    }

    private static void registrarLogLeitura(LeitorExcel.ResultadoLeitura resultado) {
        String categoria = switch (resultado.getStatusLeitura()) {
            case "LIDO"              -> "INFO";
            case "PARCIALMENTE_LIDO" -> "WARN";
            default                  -> "ERROR";
        };
        String mensagem = String.format("Leitura %s: %d encontradas, %d lidas, %d rejeitadas.",
                resultado.getStatusLeitura(),
                resultado.getLinhasEncontradas(),
                resultado.getLinhasLidas(),
                resultado.getLinhasRejeitadas());
        try {
            jdbcTemplate.update(
                    "INSERT INTO logsServico (categoria, servico, mensagem, dataHora, origemCadastro," +
                    " nomeArquivo, statusLeitura, linhasEncontradas, linhasLidas, linhasRejeitadas, detalheErro)" +
                    " VALUES (?,?,?,?,?,?,?,?,?,?,?)",
                    categoria, "importacao", mensagem, LocalDateTime.now(), "Java",
                    resultado.getNomeArquivo(),
                    resultado.getStatusLeitura(),
                    resultado.getLinhasEncontradas(),
                    resultado.getLinhasLidas(),
                    resultado.getLinhasRejeitadas(),
                    resultado.getDetalheErro());
        } catch (Exception e) {
            logErro("Falha ao registrar log no banco: " + e.getMessage());
        }
    }

    // <editor-fold desc="AWS CLI">
    private static boolean baixarDoS3(String s3Uri, String destino, String region) {
        try {
            ProcessBuilder pb = new ProcessBuilder("aws", "s3", "cp", s3Uri, destino, "--region", region, "--no-progress");
            pb.redirectErrorStream(true);
            Process p = pb.start();
            StringBuilder saida = new StringBuilder();
            try (BufferedReader br = new BufferedReader(new InputStreamReader(p.getInputStream()))) {
                String linha;
                while ((linha = br.readLine()) != null) saida.append(linha).append("\n");
            }
            int exit = p.waitFor();
            if (exit != 0) { logErro("aws s3 cp falhou (exit " + exit + "): " + saida.toString().trim()); return false; }
            return true;
        } catch (Exception e) {
            logErro("Erro ao executar aws cli: " + e.getMessage());
            return false;
        }
    }

    private static boolean awsCliDisponivel() {
        try {
            Process p = new ProcessBuilder("aws", "--version").redirectErrorStream(true).start();
            p.waitFor();
            return p.exitValue() == 0;
        } catch (Exception e) {
            return false;
        }
    }
    // </editor-fold>

    // <editor-fold desc="Helpers">
    private static <T> int indexOf(List<T> lista, T valor) {
        for (int i = 0; i < lista.size(); i++) {
            if (lista.get(i) != null && lista.get(i).equals(valor)) return i;
        }
        return -1;
    }

    private static void carregarEnv() {
        File f = new File(".env");
        if (!f.exists()) f = new File("../.env");
        if (!f.exists()) return;
        try (BufferedReader br = new BufferedReader(new java.io.FileReader(f))) {
            String linha;
            while ((linha = br.readLine()) != null) {
                linha = linha.trim();
                if (linha.isEmpty() || linha.startsWith("#") || !linha.contains("=")) continue;
                int eq = linha.indexOf('=');
                String chave = linha.substring(0, eq).trim();
                String valor = linha.substring(eq + 1).trim();
                if ((valor.startsWith("\"") && valor.endsWith("\"")) ||
                    (valor.startsWith("'")  && valor.endsWith("'")))  valor = valor.substring(1, valor.length() - 1);
                if (valor.isEmpty()) continue;
                if (System.getProperty(chave) == null) System.setProperty(chave, valor);
                switch (chave.toUpperCase()) {
                    case "AWS_ACCESS_KEY_ID"     -> System.setProperty("aws.accessKeyId",    valor);
                    case "AWS_SECRET_ACCESS_KEY" -> System.setProperty("aws.secretAccessKey", valor);
                    case "AWS_SESSION_TOKEN"     -> System.setProperty("aws.sessionToken",   valor);
                    case "AWS_REGION"            -> System.setProperty("aws.region",         valor);
                }
            }
        } catch (Exception ignored) {}
    }
    // </editor-fold>
}
