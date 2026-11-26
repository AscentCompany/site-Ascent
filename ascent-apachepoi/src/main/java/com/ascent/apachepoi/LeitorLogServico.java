package com.ascent.apachepoi;

import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

public class LeitorLogServico {

    private static final String HOST_AWS_PADRAO = "ascentambientedevelop.duckdns.org";

    private final JdbcTemplate jdbcTemplate;

    public LeitorLogServico() {
        this.jdbcTemplate = new JdbcTemplate(new Conexao().getConexao());
    }

    public LeitorLogServico(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public List<LogServico> buscarLogsServico() {
        String sql = "SELECT idLogServico, categoria, servico, mensagem, dataHora, origemCadastro, fkUsuario"
                + " FROM logsServico WHERE nomeArquivo IS NULL ORDER BY dataHora ASC";
        return jdbcTemplate.query(sql, new BeanPropertyRowMapper<>(LogServico.class));
    }

    public List<LogLeitura> buscarLogsLeitura() {
        String sql = "SELECT idLogServico, categoria, servico, mensagem, dataHora, origemCadastro, fkUsuario,"
                + " nomeArquivo, statusLeitura, linhasEncontradas, linhasLidas, linhasRejeitadas, detalheErro, idInicialVoo"
                + " FROM logsServico WHERE nomeArquivo IS NOT NULL ORDER BY dataHora ASC";
        return jdbcTemplate.query(sql, new BeanPropertyRowMapper<>(LogLeitura.class));
    }

    public List<LogServico> buscarTodosLogs() {
        List<LogServico> todos = new ArrayList<>();
        todos.addAll(buscarLogsServico());
        todos.addAll(buscarLogsLeitura());
        return todos;
    }

    public void exibirLogsFormatados() {
        List<LogServico> logs = buscarTodosLogs();
        if (logs.isEmpty()) {
            System.out.println("Nenhum log encontrado na tabela logsServico.");
            return;
        }

        System.out.println("===================Total de logs: " + logs.size() + "=======================");
        for (int i = logs.size() - 1; i >= 0; i--) {
            System.out.println(logs.get(i).formatarLog());
        }
    }

    private static String lerOuPadrao(Scanner scanner, String label, String padrao) {
        System.out.printf("%s [Enter = %s]: ", label, padrao);
        String entrada = scanner.nextLine().trim();
        return entrada.isEmpty() ? padrao : entrada;
    }

    public static void main(String[] args) {
        try (Scanner scanner = new Scanner(System.in)) {
            System.out.println("===========================================");
            System.out.println("   Ascent - Leitor de Logs de Serviço");
            System.out.println("===========================================");
            System.out.println("Onde está o banco de dados?");
            System.out.println("1 - Local");
            System.out.println("2 - AWS (EC2)");
            System.out.print("Escolha (1 ou 2): ");

            String opcao = scanner.nextLine().trim();
            LeitorLogServico leitor;

            if ("2".equals(opcao)) {
                String host = lerOuPadrao(scanner, "IP ou domínio da EC2", HOST_AWS_PADRAO);
                String porta = lerOuPadrao(scanner, "Porta do MySQL", "3306");
                String banco = lerOuPadrao(scanner, "Nome do banco", "ascent");
                String usuario = lerOuPadrao(scanner, "Usuário do banco", "admin");
                System.out.print("Senha do banco: ");
                String senha = scanner.nextLine().trim();

                Conexao conexaoAws = new Conexao(host, porta, banco, usuario, senha);
                leitor = new LeitorLogServico(new JdbcTemplate(conexaoAws.getConexao()));
            } else if ("1".equals(opcao)) {
                leitor = new LeitorLogServico();
            } else {
                System.out.println("Opção inválida. Digite 1 para Local ou 2 para AWS.");
                return;
            }

            try {
                leitor.exibirLogsFormatados();
            } catch (Exception e) {
                Throwable causa = e;
                while (causa.getCause() != null) {
                    causa = causa.getCause();
                }
                System.err.println("\nErro ao conectar/ler logs no MySQL: " + e.getMessage());
                if (causa != e) {
                    System.err.println("Causa raiz: " + causa.getClass().getSimpleName() + ": " + causa.getMessage());
                }
                if ("2".equals(opcao)) {
                    System.err.println("Dica (AWS): verifique se a porta 3306 está publicada no container e liberada no Security Group da EC2 (ou se o túnel SSH está ativo) e se usuário/senha estão corretos.");
                }
            }
        }
    }
}
