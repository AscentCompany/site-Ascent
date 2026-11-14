package com.ascent.apachepoi;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;

import java.sql.PreparedStatement;
import java.sql.Statement;
import java.util.List;

public class CompanhiaDao {

    private final JdbcTemplate jdbcTemplate;

    public CompanhiaDao(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public Integer findIdByCodCompanhia(Integer codCompanhia) {
        if (codCompanhia == null) return null;
        List<Integer> resultado = jdbcTemplate.queryForList(
                "SELECT idCompanhia FROM companhia WHERE codCompanhia = ? LIMIT 1",
                Integer.class, codCompanhia);
        return resultado.isEmpty() ? null : resultado.get(0);
    }

    public Integer save(Companhia companhia) {
        if (companhia.getCodCompanhia() == null) return null;

        KeyHolder keyHolder = new GeneratedKeyHolder();
        jdbcTemplate.update(con -> {
            PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO companhia (codCompanhia, nomeCompanhia, paisCompanhia, razaoSocial, cnpj) VALUES (?,?,?,?,?)",
                    Statement.RETURN_GENERATED_KEYS);
            ps.setInt(1, companhia.getCodCompanhia());
            ps.setString(2, companhia.getNomeCompanhia() != null ? companhia.getNomeCompanhia() : "DESCONHECIDA");
            ps.setString(3, companhia.getPaisCompanhia() != null ? companhia.getPaisCompanhia() : "BRASIL");
            ps.setString(4, companhia.getRazaoSocial()   != null ? companhia.getRazaoSocial()   : "");
            ps.setString(5, companhia.getCnpj()          != null ? companhia.getCnpj()          : "");
            return ps;
        }, keyHolder);

        return keyHolder.getKey() != null ? keyHolder.getKey().intValue() : null;
    }
}
