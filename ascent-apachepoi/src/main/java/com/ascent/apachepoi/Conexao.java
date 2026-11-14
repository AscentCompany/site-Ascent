package com.ascent.apachepoi;

import org.springframework.jdbc.datasource.DriverManagerDataSource;
import javax.sql.DataSource;
import java.nio.file.Files;
import java.nio.file.Path;

public class Conexao {

    private static final String HOST_DOCKER = "mysql";
    private static final String HOST_LOCAL  = "localhost";

    private DataSource conexao;

    public Conexao() {
        // Resolve o host de acordo com o ambiente:
        //  - dentro de container Docker o banco atende pelo nome do serviço ("mysql");
        //  - fora do Docker (IDE / java -jar na EC2) usa "localhost".
        // Isso evita o clássico java.net.ConnectException: Connection refused
        // quando o .env aponta para "localhost" dentro do container (ou vice-versa).
        String host = resolverHost(LeitorExcel.getEnvOrProp("DB_HOST", null));
        String port = LeitorExcel.getEnvOrProp("DB_PORT", "3306");
        String database = LeitorExcel.getEnvOrProp("DB_DATABASE", "ascent");
        String user = LeitorExcel.getEnvOrProp("DB_USER", "admin");
        String password = LeitorExcel.getEnvOrProp("DB_PASSWORD", "admin");

        DriverManagerDataSource driver = new DriverManagerDataSource();
        driver.setDriverClassName("com.mysql.cj.jdbc.Driver");
        driver.setUrl(String.format(
                "jdbc:mysql://%s:%s/%s?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&connectTimeout=5000",
                host, port, database));
        driver.setUsername(user);
        driver.setPassword(password);
        this.conexao = driver;

        System.out.printf("[Conexao] MySQL: jdbc:mysql://%s:%s/%s%n", host, port, database);
    }

    private static String resolverHost(String host) {
        boolean emContainer = Files.exists(Path.of("/.dockerenv"))
                || Files.exists(Path.of("/run/.containerenv"));

        if (host == null || host.isBlank()) {
            return emContainer ? HOST_DOCKER : HOST_LOCAL;
        }

        host = host.trim();
        boolean hostLocal = host.equalsIgnoreCase("localhost") || host.equals("127.0.0.1");
        boolean hostDocker = host.equalsIgnoreCase("mysql") || host.equalsIgnoreCase("ascent-mysql");

        if (emContainer && hostLocal) {
            System.err.printf("[Conexao] DB_HOST=%s não funciona dentro do container. Usando '%s'.%n", host, HOST_DOCKER);
            return HOST_DOCKER;
        }

        if (!emContainer && hostDocker) {
            System.err.printf("[Conexao] DB_HOST=%s só existe na rede Docker. Usando '%s'.%n", host, HOST_LOCAL);
            return HOST_LOCAL;
        }

        return host;
    }

    public DataSource getConexao() {
        return this.conexao;
    }
}
