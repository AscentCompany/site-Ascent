package com.ascent.apachepoi;

import org.springframework.jdbc.datasource.DriverManagerDataSource;
import javax.sql.DataSource;

public class Conexao {
    private DataSource conexao;

    public Conexao() {
        String host = LeitorExcel.getEnvOrProp("DB_HOST", "localhost");
        String port = LeitorExcel.getEnvOrProp("DB_PORT", "3306");
        String database = LeitorExcel.getEnvOrProp("DB_DATABASE", "ascent");
        String user = LeitorExcel.getEnvOrProp("DB_USER", "admin");
        String password = LeitorExcel.getEnvOrProp("DB_PASSWORD", "admin");

        DriverManagerDataSource driver = new DriverManagerDataSource();
        driver.setDriverClassName("com.mysql.cj.jdbc.Driver");
        driver.setUrl(String.format("jdbc:mysql://%s:%s/%s?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC", host, port, database));
        driver.setUsername(user);
        driver.setPassword(password);
        this.conexao = driver;
    }

    public DataSource getConexao() {
        return this.conexao;
    }
}
