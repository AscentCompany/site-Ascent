package com.ascent.apachepoi;

import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;

public class LeitorLogServico {

    private final JdbcTemplate jdbcTemplate;

    public LeitorLogServico() {
        this.jdbcTemplate = new JdbcTemplate(new Conexao().getConexao());
    }

    public LeitorLogServico(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    
    public List<LogServico> buscarTodosLogs() {
        String sql = "SELECT idLogServico, categoria, servico, mensagem, dataHora, origemCadastro, fkUsuario FROM logsServico ORDER BY dataHora ASC";
        return jdbcTemplate.query(sql, new BeanPropertyRowMapper<>(LogServico.class));
    }

    
    public void exibirLogsFormatados() {
        List<LogServico> logs = buscarTodosLogs();
        if (logs.isEmpty()) {
            System.out.println("Nenhum log encontrado na tabela logsServico.");
            return;
        }

        System.out.println("=======================================================");
        for (LogServico log : logs) {
            System.out.println(log.formatarLog());
        }
        System.out.println("Total de logs: " + logs.size());
    }


    public static void main(String[] args) {
        LeitorLogServico leitor = new LeitorLogServico();
        leitor.exibirLogsFormatados();
    }
}
