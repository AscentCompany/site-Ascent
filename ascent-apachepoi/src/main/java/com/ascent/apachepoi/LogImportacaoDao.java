package com.ascent.apachepoi;

import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;

public class LogImportacaoDao {

    private final JdbcTemplate jdbcTemplate;

    public LogImportacaoDao(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    // Retorna true se o arquivo já foi importado com sucesso anteriormente
    public boolean jaFoiImportado(String nomeArquivo) {
        List<Integer> resultado = jdbcTemplate.queryForList(
                "SELECT 1 FROM logsServico " +
                "WHERE nomeArquivo = ? AND statusLeitura = 'LIDO' AND servico = 'importacao' LIMIT 1",
                Integer.class, nomeArquivo);
        return !resultado.isEmpty();
    }
}
