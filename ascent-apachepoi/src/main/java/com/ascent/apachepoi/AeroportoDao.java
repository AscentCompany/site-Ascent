package com.ascent.apachepoi;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;

import java.sql.PreparedStatement;
import java.sql.Statement;
import java.util.List;

public class AeroportoDao {

    private final JdbcTemplate jdbcTemplate;

    public AeroportoDao(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public Integer findIdByNomeOuIcao(String nomeAeroporto, String icao) {
        List<Integer> resultado;
        if (icao != null && !icao.isBlank()) {
            resultado = jdbcTemplate.queryForList(
                    "SELECT idAeroporto FROM aeroporto WHERE nomeAeroporto = ? OR nomeAeroporto = ? LIMIT 1",
                    Integer.class, nomeAeroporto, icao);
        } else {
            resultado = jdbcTemplate.queryForList(
                    "SELECT idAeroporto FROM aeroporto WHERE nomeAeroporto = ? LIMIT 1",
                    Integer.class, nomeAeroporto);
        }
        return resultado.isEmpty() ? null : resultado.get(0);
    }

    public Integer save(Aeroporto aeroporto) {
        KeyHolder keyHolder = new GeneratedKeyHolder();
        jdbcTemplate.update(con -> {
            PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO aeroporto (nomeAeroporto, municipio, uf, regiao, pais) VALUES (?,?,?,?,?)",
                    Statement.RETURN_GENERATED_KEYS);
            ps.setString(1, aeroporto.getNomeAeroporto() != null ? aeroporto.getNomeAeroporto() : "");
            ps.setString(2, aeroporto.getMunicipio()     != null ? aeroporto.getMunicipio()     : "");
            ps.setString(3, aeroporto.getUf()            != null ? aeroporto.getUf()            : "");
            ps.setString(4, aeroporto.getRegiao()        != null ? aeroporto.getRegiao()        : "");
            ps.setString(5, aeroporto.getPais()          != null ? aeroporto.getPais()          : "BRASIL");
            return ps;
        }, keyHolder);

        return keyHolder.getKey() != null ? keyHolder.getKey().intValue() : null;
    }
}
