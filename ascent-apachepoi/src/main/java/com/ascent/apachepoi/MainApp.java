package com.ascent.apachepoi;

import org.springframework.jdbc.core.JdbcTemplate;

import javax.sql.DataSource;
import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

public class MainApp {

    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("HH:mm:ss");

    private static JdbcTemplate     jdbcTemplate;
    private static LogImportacaoDao logImportacaoDao;

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

        DataSource dataSource = new Conexao().getConexao();
        jdbcTemplate     = new JdbcTemplate(dataSource);
        logImportacaoDao = new LogImportacaoDao(jdbcTemplate);

        String bucket      = LeitorExcel.getEnvOrProp("AWS_BUCKET", "ascent-base-de-dados");
        String prefixo     = LeitorExcel.getEnvOrProp("AWS_PREFIXO_ARQUIVOS", "anac_part_");
        String region      = LeitorExcel.getEnvOrProp("AWS_REGION", "us-east-1");
        Integer    totalPartes = Integer.parseInt(LeitorExcel.getEnvOrProp("AWS_TOTAL_PARTES", "23"));

        log("╔══════════════════════════════════════════════╗");
        log("║        Ascent — Importação S3 → MySQL        ║");
        log("╚══════════════════════════════════════════════╝");
        log("Bucket : s3://" + bucket);
        log("Prefixo: " + prefixo + " | Partes: " + totalPartes + " | Região: " + region);

        if (!awsCliDisponivel()) {
            logErro("AWS CLI não encontrado na imagem. Abortando.");
            System.exit(1);
        }

        // Falha cedo e com mensagem clara quando as credenciais estão inválidas.
        // Sem isso o job tentava os 23 arquivos, falhava em todos e saía com 0,
        // parecendo "concluído" sem ter importado nada.
        if (!acessoS3Valido(bucket, String.format("%s%03d.xlsx", prefixo, 1), region)) {
            logErro("Sem acesso ao S3. Verifique AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY," +
                    " AWS_SESSION_TOKEN e AWS_REGION no .env (credenciais expiradas são a causa mais comum).");
            System.exit(2);
        }

        File tmpDir = new File("/tmp/ascent-s3");
        tmpDir.mkdirs();

        // Uma única conexão/caches para todos os arquivos.
        ImportadorDados importador;
        try {
            importador = new ImportadorDados(dataSource);
        } catch (Exception e) {
            logErro("Falha ao abrir conexão de importação: " + e.getMessage());
            System.exit(2);
            return;
        }

        int partesOk   = 0;
        int partesErro = 0;

        try {
            for (int i = 1; i <= totalPartes; i++) {
                String nomeArquivo = String.format("%s%03d.xlsx", prefixo, i);
                String s3Uri       = String.format("s3://%s/%s", bucket, nomeArquivo);
                File   destino     = new File(tmpDir, nomeArquivo);

                log("────────────────────────────────────────────────");

                // Arquivo já gravado (LIDO ou PARCIALMENTE_LIDO) não é reprocessado.
                if (logImportacaoDao.jaFoiImportado(nomeArquivo)) {
                    log(String.format("[%d/%d] ✔ %s já importado anteriormente. Pulando.", i, totalPartes, nomeArquivo));
                    partesOk++;
                    continue;
                }

                // Importação interrompida: apaga o que ficou gravado daquele arquivo
                // antes de recomeçar. Isso evita voos duplicados.
                Long pendente = logImportacaoDao.buscarIdInicialPendente(nomeArquivo);
                long idInicial;
                if (pendente != null) {
                    log(String.format("[%d/%d] Retomando %s — removendo dados parciais (idVoo > %d)...",
                            i, totalPartes, nomeArquivo, pendente));
                    importador.limparParcial(pendente);
                    idInicial = pendente;
                } else {
                    idInicial = importador.maiorIdVoo();
                }

                LogLeitura logInicio = new LogLeitura(null, "INFO", "importacao", "Importação em andamento.",
                        LocalDateTime.now(), "Java", null,
                        nomeArquivo, StatusLeitura.EM_ANDAMENTO, null, null, null, null, idInicial);
                logImportacaoDao.iniciarArquivo(logInicio);
                log(logInicio.formatarLog());

                log(String.format("[%d/%d] Baixando %s ...", i, totalPartes, s3Uri));

                if (!baixarDoS3(s3Uri, destino.getAbsolutePath(), region)) {
                    LogLeitura logFalha = new LogLeitura(null, "ERROR", "importacao",
                            "Importação interrompida; será retomada na próxima execução.",
                            LocalDateTime.now(), "Java", null,
                            nomeArquivo, StatusLeitura.EM_ANDAMENTO, null, null, null, "Falha ao baixar do S3.", null);
                    logImportacaoDao.marcarErro(logFalha);
                    logErro(logFalha.formatarLog());
                    logErro("Falha ao baixar " + nomeArquivo + ". Pulando.");
                    partesErro++;
                    continue;
                }

                log(String.format("[%d/%d] Arquivo baixado (%.1f MB). Lendo e inserindo...",
                        i, totalPartes, destino.length() / 1_048_576.0));

                try {
                    importador.iniciarArquivo();

                    LeitorExcel leitor = new LeitorExcel();
                    LeitorExcel.ResultadoLeitura resultado = leitor.ler(destino, importador);
                    importador.finalizar();

                    log(String.format("[%d/%d] Leitura concluída — %d encontradas | %d válidas | %d rejeitadas | status: %s",
                            i, totalPartes,
                            resultado.getLinhasEncontradas(),
                            resultado.getLinhasLidas(),
                            resultado.getLinhasRejeitadas(),
                            resultado.getStatusLeitura()));

                    log(String.format("[%d/%d] ✔ %d companhias | %d aviões | %d aeroportos | %d voos | %d direções",
                            i, totalPartes,
                            importador.getCompanhiasDistintas(),
                            importador.getAvioesDistintos(),
                            importador.getAeroportosDistintos(),
                            importador.getVoosInseridos(),
                            importador.getDirecoesInseridas()));

                    // Só fecha o arquivo depois que os dados foram gravados.
                    String categoria = "ERROR";
                    if (resultado.getStatusLeitura() == StatusLeitura.LIDO) {
                        categoria = "INFO";
                    } else if (resultado.getStatusLeitura() == StatusLeitura.PARCIALMENTE_LIDO) {
                        categoria = "WARN";
                    }
                    String mensagem = String.format("Leitura %s: %d encontradas, %d lidas, %d rejeitadas.",
                            resultado.getStatusLeitura(),
                            resultado.getLinhasEncontradas(),
                            resultado.getLinhasLidas(),
                            resultado.getLinhasRejeitadas());

                    LogLeitura logConclusao = new LogLeitura(null, categoria, "importacao", mensagem,
                            LocalDateTime.now(), "Java", null,
                            nomeArquivo, resultado.getStatusLeitura(),
                            resultado.getLinhasEncontradas(),
                            resultado.getLinhasLidas(),
                            resultado.getLinhasRejeitadas(),
                            resultado.getDetalheErro(), null);
                    logImportacaoDao.concluirArquivo(logConclusao);
                    log(logConclusao.formatarLog());

                    partesOk++;

                } catch (Exception e) {
                    try {
                        importador.reverter();
                    } catch (Exception ex) {
                        logErro("Falha ao reverter lote pendente: " + ex.getMessage());
                    }
                    try {
                        LogLeitura logErroLeitura = new LogLeitura(null, "ERROR", "importacao",
                                "Importação interrompida; será retomada na próxima execução.",
                                LocalDateTime.now(), "Java", null,
                                nomeArquivo, StatusLeitura.EM_ANDAMENTO, null, null, null, e.getMessage(), null);
                        logImportacaoDao.marcarErro(logErroLeitura);
                        logErro(logErroLeitura.formatarLog());
                    } catch (Exception ex) {
                        logErro("Falha ao registrar o erro no banco: " + ex.getMessage());
                    }
                    logErro(String.format("[%d/%d] Falha ao processar %s: %s", i, totalPartes, nomeArquivo, e.getMessage()));
                    partesErro++;
                } finally {
                    destino.delete();
                }
            }
        } finally {
            importador.fechar();
        }

        log("────────────────────────────────────────────────");
        log("╔══════════════════════════════════════════════╗");
        log(String.format("║ Importação concluída: %d OK | %d com erro      ║", partesOk, partesErro));
        log("╚══════════════════════════════════════════════╝");

        tmpDir.delete();

        // Exit code != 0 quando nada foi importado ou quando algo falhou, para o
        // start.sh não marcar a importação como concluída por engano.
        if (partesErro > 0 || partesOk == 0) {
            System.exit(1);
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

    /**
     * Faz um HEAD no primeiro arquivo para validar credenciais, região e permissão
     * antes de começar. É o mesmo acesso que o import usa, então o diagnóstico é fiel.
     */
    private static boolean acessoS3Valido(String bucket, String chave, String region) {
        try {
            ProcessBuilder pb = new ProcessBuilder(
                    "aws", "s3api", "head-object",
                    "--bucket", bucket, "--key", chave, "--region", region);
            pb.redirectErrorStream(true);
            Process p = pb.start();
            StringBuilder saida = new StringBuilder();
            try (BufferedReader br = new BufferedReader(new InputStreamReader(p.getInputStream()))) {
                String linha;
                while ((linha = br.readLine()) != null) saida.append(linha).append("\n");
            }
            int exit = p.waitFor();
            if (exit != 0) {
                logErro("Diagnóstico do S3: " + saida.toString().trim());
                return false;
            }
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
