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

    public static void main(String[] args) {
        LeitorLogServico leitor = new LeitorLogServico();
        leitor.exibirLogsFormatados();
    }
}
