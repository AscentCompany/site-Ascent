package com.ascent.apachepoi;

import org.springframework.jdbc.core.JdbcTemplate;

import javax.sql.DataSource;
import java.io.BufferedReader;
import java.io.File;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * MainAppLocal - Versão simplificada do MainApp para importação de arquivos Excel locais.
 * 
 * Esta versão foi criada especificamente para diagnóstico e testes, importando apenas
 * o arquivo anac_part_023.xlsx de uma pasta local sem necessidade de AWS S3.
 * 
 * USO:
 * 1. Configure as variáveis de ambiente no .env (DB_HOST, DB_PORT, DB_DATABASE, DB_USER, DB_PASSWORD)
 * 2. Coloque o arquivo anac_part_023.xlsx em C:\Users\Pichau\Downloads\output\
 * 3. Execute: mvn clean package && java -jar target/ascent-apachepoi-1.0.jar local
 * 
 * IMPORTANTE:
 * - Este código importa APENAS 1 arquivo para teste rápido
 * - Para importação completa dos 23 arquivos, use o MainApp original com S3
 * - Logs detalhados são exibidos no console
 */
public class MainAppLocal {

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
        log("╔══════════════════════════════════════════════╗");
        log("║   Ascent — Importação Local (Diagnóstico)    ║");
        log("╚══════════════════════════════════════════════╝");
        
        carregarEnv();

        DataSource dataSource = new Conexao().getConexao();
        jdbcTemplate     = new JdbcTemplate(dataSource);
        logImportacaoDao = new LogImportacaoDao(jdbcTemplate);

        // Configuração para arquivo local
        String caminhoArquivo = LeitorExcel.getEnvOrProp("ARQUIVO_LOCAL", 
            "C:\\Users\\Pichau\\Downloads\\output\\anac_part_023.xlsx");
        
        File arquivo = new File(caminhoArquivo);
        
        if (!arquivo.exists()) {
            logErro("Arquivo não encontrado: " + caminhoArquivo);
            logErro("Verifique se o arquivo existe no caminho especificado.");
            logErro("Você pode alterar o caminho definindo a variável ARQUIVO_LOCAL no .env");
            System.exit(1);
        }

        log("Arquivo: " + arquivo.getAbsolutePath());
        log("Tamanho: " + String.format("%.1f MB", arquivo.length() / 1_048_576.0));

        // Uma única conexão/caches para o arquivo
        ImportadorDados importador;
        try {
            importador = new ImportadorDados(dataSource);
        } catch (Exception e) {
            logErro("Falha ao abrir conexão de importação: " + e.getMessage());
            e.printStackTrace();
            System.exit(2);
            return;
        }

        String nomeArquivo = arquivo.getName();
        boolean sucesso = false;

        try {
            log("────────────────────────────────────────────────");
            
            // Verificar se arquivo já foi importado
            if (logImportacaoDao.jaFoiImportado(nomeArquivo)) {
                log("✔ " + nomeArquivo + " já foi importado anteriormente.");
                log("Para reimportar, apague o registro na tabela logLeitura ou use outro arquivo.");
                sucesso = true;
                return;
            }

            // Verificar se há importação pendente
            Long pendente = logImportacaoDao.buscarIdInicialPendente(nomeArquivo);
            long idInicial;
            
            if (pendente != null) {
                log("Retomando " + nomeArquivo + " — removendo dados parciais (idVoo > " + pendente + ")...");
                importador.limparParcial(pendente);
                idInicial = pendente;
            } else {
                idInicial = importador.maiorIdVoo();
            }

            // Registrar início da importação
            LogLeitura logInicio = new LogLeitura(
                null, "INFO", "importacao", 
                "Importação LOCAL em andamento (diagnóstico).",
                LocalDateTime.now(), "Java-Local", null,
                nomeArquivo, StatusLeitura.EM_ANDAMENTO, 
                null, null, null, null, idInicial
            );
            logImportacaoDao.iniciarArquivo(logInicio);
            log(logInicio.formatarLog());

            log("Iniciando leitura e inserção no banco de dados...");
            log("Aguarde... Este processo pode demorar alguns minutos.");

            try {
                importador.iniciarArquivo();

                LeitorExcel leitor = new LeitorExcel();
                LeitorExcel.ResultadoLeitura resultado = leitor.ler(arquivo, importador);
                importador.finalizar();

                log("────────────────────────────────────────────────");
                log("Leitura concluída:");
                log(String.format("  • Linhas encontradas: %,d", resultado.getLinhasEncontradas()));
                log(String.format("  • Linhas válidas (lidas): %,d", resultado.getLinhasLidas()));
                log(String.format("  • Linhas rejeitadas: %,d", resultado.getLinhasRejeitadas()));
                log(String.format("  • Status: %s", resultado.getStatusLeitura()));

                log("────────────────────────────────────────────────");
                log("Dados inseridos no banco:");
                log(String.format("  • Companhias distintas: %d", importador.getCompanhiasDistintas()));
                log(String.format("  • Aviões distintos: %d", importador.getAvioesDistintos()));
                log(String.format("  • Aeroportos distintos: %d", importador.getAeroportosDistintos()));
                log(String.format("  • Voos inseridos: %,d", importador.getVoosInseridos()));
                log(String.format("  • Direções inseridas: %,d", importador.getDirecoesInseridas()));

                // Registrar conclusão
                String categoria = "ERROR";
                if (resultado.getStatusLeitura() == StatusLeitura.LIDO) {
                    categoria = "INFO";
                } else if (resultado.getStatusLeitura() == StatusLeitura.PARCIALMENTE_LIDO) {
                    categoria = "WARN";
                }
                
                String mensagem = String.format(
                    "Leitura LOCAL %s: %d encontradas, %d lidas, %d rejeitadas.",
                    resultado.getStatusLeitura(),
                    resultado.getLinhasEncontradas(),
                    resultado.getLinhasLidas(),
                    resultado.getLinhasRejeitadas()
                );

                LogLeitura logConclusao = new LogLeitura(
                    null, categoria, "importacao", mensagem,
                    LocalDateTime.now(), "Java-Local", null,
                    nomeArquivo, resultado.getStatusLeitura(),
                    resultado.getLinhasEncontradas(),
                    resultado.getLinhasLidas(),
                    resultado.getLinhasRejeitadas(),
                    resultado.getDetalheErro(), null
                );
                logImportacaoDao.concluirArquivo(logConclusao);
                log(logConclusao.formatarLog());

                sucesso = true;

            } catch (Exception e) {
                try {
                    importador.reverter();
                } catch (Exception ex) {
                    logErro("Falha ao reverter lote pendente: " + ex.getMessage());
                }
                
                try {
                    LogLeitura logErroLeitura = new LogLeitura(
                        null, "ERROR", "importacao",
                        "Importação LOCAL interrompida.",
                        LocalDateTime.now(), "Java-Local", null,
                        nomeArquivo, StatusLeitura.EM_ANDAMENTO, 
                        null, null, null, e.getMessage(), null
                    );
                    logImportacaoDao.marcarErro(logErroLeitura);
                    logErro(logErroLeitura.formatarLog());
                } catch (Exception ex) {
                    logErro("Falha ao registrar o erro no banco: " + ex.getMessage());
                }
                
                logErro("Falha ao processar " + nomeArquivo + ": " + e.getMessage());
                e.printStackTrace();
            }

        } finally {
            importador.fechar();
        }

        log("────────────────────────────────────────────────");
        if (sucesso) {
            log("╔══════════════════════════════════════════════╗");
            log("║      ✅ Importação concluída com sucesso      ║");
            log("╚══════════════════════════════════════════════╝");
            log("");
            log("PRÓXIMOS PASSOS:");
            log("1. Execute o script 'diagnostico-alertas.sql' para verificar os dados");
            log("2. Acesse a interface de Configurar Alertas");
            log("3. Crie uma regra de teste com ocupação < 90%");
            log("4. Verifique se alertas foram gerados na Central de Alertas");
            System.exit(0);
        } else {
            log("╔══════════════════════════════════════════════╗");
            log("║       ❌ Importação falhou - veja erros       ║");
            log("╚══════════════════════════════════════════════╝");
            System.exit(1);
        }
    }

    // <editor-fold desc="Helpers">
    private static void carregarEnv() {
        File f = new File(".env");
        if (!f.exists()) f = new File("../.env");
        if (!f.exists()) {
            log("Arquivo .env não encontrado. Usando variáveis de ambiente do sistema.");
            return;
        }
        
        try (BufferedReader br = new BufferedReader(new java.io.FileReader(f))) {
            String linha;
            while ((linha = br.readLine()) != null) {
                linha = linha.trim();
                if (linha.isEmpty() || linha.startsWith("#") || !linha.contains("=")) continue;
                
                int eq = linha.indexOf('=');
                String chave = linha.substring(0, eq).trim();
                String valor = linha.substring(eq + 1).trim();
                
                if ((valor.startsWith("\"") && valor.endsWith("\"")) ||
                    (valor.startsWith("'")  && valor.endsWith("'")))  
                    valor = valor.substring(1, valor.length() - 1);
                
                if (valor.isEmpty()) continue;
                
                if (System.getProperty(chave) == null) 
                    System.setProperty(chave, valor);
            }
            log("Variáveis carregadas de: " + f.getAbsolutePath());
        } catch (Exception e) {
            log("Aviso: Não foi possível ler o .env: " + e.getMessage());
        }
    }
    // </editor-fold>
}
