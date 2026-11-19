package com.ascent.apachepoi;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;

import java.sql.PreparedStatement;
import java.sql.Statement;

public class VooDao {

    private final JdbcTemplate jdbcTemplate;

    public VooDao(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public Integer save(Voo voo) {
        if (voo.getFkCompanhia() == null || voo.getFkAviao() == null) return null;

        KeyHolder keyHolder = new GeneratedKeyHolder();
        jdbcTemplate.update(con -> {
            PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO voo (numVoo, tipoVoo, qtdPassageiros, fkCompanhia, fkAviao) VALUES (?,?,?,?,?)",
                    Statement.RETURN_GENERATED_KEYS);
            ps.setInt(1, voo.getNumVoo()         != null ? voo.getNumVoo()         : 0);
            ps.setInt(2, voo.getTipoVoo()        != null ? voo.getTipoVoo()        : 0);
            ps.setInt(3, voo.getQtdPassageiros() != null ? voo.getQtdPassageiros() : 0);
            ps.setInt(4, voo.getFkCompanhia());
            ps.setInt(5, voo.getFkAviao());
            return ps;
        }, keyHolder);

        return keyHolder.getKey() != null ? keyHolder.getKey().intValue() : null;
    }
}
