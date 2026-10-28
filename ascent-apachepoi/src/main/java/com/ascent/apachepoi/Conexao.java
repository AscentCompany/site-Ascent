package com.ascent.apachepoi;

import org.springframework.jdbc.datasource.DriverManagerDataSource;
import javax.sql.DataSource;

public class Conexao {
    private DataSource conexao;

    public Conexao() {
        String host = System.getenv("DB_HOST") != null ? System.getenv("DB_HOST") : "localhost";
        String port = System.getenv("DB_PORT") != null ? System.getenv("DB_PORT") : "3306";
        String database = System.getenv("DB_DATABASE") != null ? System.getenv("DB_DATABASE") : "ascent";
        String user = System.getenv("DB_USER") != null ? System.getenv("DB_USER") : "admin";
        String password = System.getenv("DB_PASSWORD") != null ? System.getenv("DB_PASSWORD") : "admin";

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
