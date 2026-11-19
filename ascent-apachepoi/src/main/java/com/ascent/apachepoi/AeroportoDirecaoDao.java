package com.ascent.apachepoi;

import org.springframework.jdbc.core.JdbcTemplate;

public class AeroportoDirecaoDao {

    private final JdbcTemplate jdbcTemplate;

    public AeroportoDirecaoDao(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public void save(AeroportoDirecao aeroportoDirecao) {
        if (aeroportoDirecao.getFkAeroporto() == null || aeroportoDirecao.getFkVoo() == null) return;
        if (aeroportoDirecao.getDia() == null || aeroportoDirecao.getHora() == null) return;

        jdbcTemplate.update(
                "INSERT INTO aeroportoDirecao (fkAeroporto, fkVoo, direcao, dia, hora) VALUES (?,?,?,?,?)" +
                " ON DUPLICATE KEY UPDATE direcao=VALUES(direcao), dia=VALUES(dia), hora=VALUES(hora)",
                aeroportoDirecao.getFkAeroporto(),
                aeroportoDirecao.getFkVoo(),
                aeroportoDirecao.getDirecao(),
                java.sql.Date.valueOf(aeroportoDirecao.getDia()),
                java.sql.Time.valueOf(aeroportoDirecao.getHora()));
    }
}
