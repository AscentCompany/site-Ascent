package com.ascent;

import org.springframework.jdbc.datasource.DriverManagerDataSource;

import javax.sql.DataSource;

public class Conexao {

    private DataSource conexao;

    public Conexao(){

        DriverManagerDataSource driver =    new DriverManagerDataSource();
        driver.setUsername("admin");
        driver.setPassword("admin");
        driver.setUrl("jdbc:mysql://localhost:3306/ascent");
        driver.setDriverClassName("com.mysql.cj.jdbc.Driver");
        this.conexao = driver;

    }

    public DataSource getConexao(){
        return this.conexao;
    }

}
