package com.ascent.apachepoi;

import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.ArrayList;
import java.util.List;

public class LeitorLogServico {

    private final JdbcTemplate jdbcTemplate;

    public LeitorLogServico() {
        this.jdbcTemplate = new JdbcTemplate(new Conexao().getConexao());
    }

    public LeitorLogServico(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    // Logs padrao: registros que nao sao de leitura de arquivo.
    public List<LogServico> buscarLogsServico() {
        String sql = "SELECT idLogServico, categoria, servico, mensagem, dataHora, origemCadastro, fkUsuario"
                + " FROM logsServico WHERE nomeArquivo IS NULL ORDER BY dataHora ASC";
        return jdbcTemplate.query(sql, new BeanPropertyRowMapper<>(LogServico.class));
    }

    // Logs de leitura: registros que possuem nomeArquivo.
    public List<LogLeitura> buscarLogsLeitura() {
        String sql = "SELECT idLogServico, categoria, servico, mensagem, dataHora, origemCadastro, fkUsuario,"
                + " nomeArquivo, statusLeitura, linhasEncontradas, linhasLidas, linhasRejeitadas, detalheErro, idInicialVoo"
                + " FROM logsServico WHERE nomeArquivo IS NOT NULL ORDER BY dataHora ASC";
        return jdbcTemplate.query(sql, new BeanPropertyRowMapper<>(LogLeitura.class));
    }

    // Junta todos os tipos de log em uma unica lista.
    // Como LogLeitura herda de LogServico, ele pode entrar na mesma lista.
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
            // Se o log for um LogLeitura, o formatarLog dele e chamado automaticamente.
            System.out.println(logs.get(i).formatarLog());
        }
    }

    public static void main(String[] args) {
        LeitorLogServico leitor = new LeitorLogServico();
        leitor.exibirLogsFormatados();
    }
}
