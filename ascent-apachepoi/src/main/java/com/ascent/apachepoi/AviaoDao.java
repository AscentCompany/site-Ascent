package com.ascent.apachepoi;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;

import java.sql.PreparedStatement;
import java.sql.Statement;
import java.util.List;

public class AviaoDao {

    private final JdbcTemplate jdbcTemplate;

    public AviaoDao(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public Integer findIdByModelo(String modelo) {
        if (modelo == null || modelo.isBlank()) return null;
        List<Integer> resultado = jdbcTemplate.queryForList(
                "SELECT idAviao FROM aviao WHERE modelo = ? LIMIT 1",
                Integer.class, modelo);
        return resultado.isEmpty() ? null : resultado.get(0);
    }

    public Integer findAny() {
        List<Integer> resultado = jdbcTemplate.queryForList(
                "SELECT idAviao FROM aviao LIMIT 1", Integer.class);
        return resultado.isEmpty() ? null : resultado.get(0);
    }

    public Integer save(Aviao aviao) {
        if (aviao.getModelo() == null || aviao.getModelo().isBlank()) return null;

        KeyHolder keyHolder = new GeneratedKeyHolder();
        jdbcTemplate.update(con -> {
            PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO aviao (numAssentos, modelo) VALUES (?,?)",
                    Statement.RETURN_GENERATED_KEYS);
            ps.setInt(1, aviao.getNumAssentos() != null ? aviao.getNumAssentos() : 0);
            ps.setString(2, aviao.getModelo());
            return ps;
        }, keyHolder);

        return keyHolder.getKey() != null ? keyHolder.getKey().intValue() : null;
    }
}
