package com.ascent;

import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.PreparedStatementCreator;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Time;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Scanner;

public class Main {

    static Scanner scnNumeros = new Scanner(System.in);
    static Scanner scnTextos  = new Scanner(System.in);
    static Conexao bancoAscent;
    static JdbcTemplate bd;

    public static void main(String[] args) {

        bancoAscent = new Conexao();
        bd = new JdbcTemplate(bancoAscent.getConexao());

        // Garante que haja ao menos o cargo padrão no banco
        garantirCargoPadrao();

        // Leitura automática (via S3 ou arquivo configurado)
        // Se a variável AUTO_IMPORT=true estiver definida, roda na inicialização
        if ("true".equalsIgnoreCase(System.getenv("AUTO_IMPORT"))) {
            importarDadosAnac();
        }

        Integer opcao;
        do {
            exibirMenu();
            opcao = scnNumeros.nextInt();

            switch (opcao) {
                case 0:
                    System.out.println("Encerrando o sistema. Até Breve!");
                    break;
                case 1:
                    cadastrarNovoUsuario();
                    esperarUsuario();
                    break;
                case 2:
                    trocarSenha();
                    esperarUsuario();
                    break;
                case 3:
                    exibirTodosOsLogs();
                    esperarUsuario();
                    break;
                case 4:
                    importarDadosAnac();
                    esperarUsuario();
                    break;
                case 5:
                    importarDadosArquivoLocal();
                    esperarUsuario();
                    break;
                default:
                    System.out.println("Opção inválida! Tente novamente.");
            }
        } while (opcao != 0);
    }

    private static void garantirCargoPadrao() {
        try {
            Integer qtd = bd.queryForObject("SELECT COUNT(*) FROM cargo WHERE idCargo = 1", Integer.class);
            if (qtd == null || qtd == 0) {
                bd.update("INSERT INTO cargo (idCargo, cargo) VALUES (1, 'Padrão')");
            }
        } catch (Exception e) {
            System.err.println("Aviso ao verificar cargo: " + e.getMessage());
        }
    }

    // ---------------------------------------------------------------
    // Importação automática da base ANAC via S3 com Apache POI e JDBC
    // ---------------------------------------------------------------
    public static void importarDadosAnac() {
        System.out.println("\n=== Iniciando importacao da base ANAC do S3 ===");
        try {
            LeitorExcel leitorExcel = new LeitorExcel();
            LeitorExcel.ResultadoLeitura dados = leitorExcel.extrairDados();
            inserirDadosNoBanco(dados);
        } catch (Exception e) {
            System.err.println("\n=== ERRO NA IMPORTACAO DO S3 ===");
            System.err.println(e.getMessage());
            e.printStackTrace();
            novoLogBanco("ERROR", "importacao", "Falha na importacao S3: " + e.getMessage(), LocalDateTime.now(), "Java");
        }
    }

    public static void importarDadosArquivoLocal() {
        System.out.print("Caminho do arquivo .xlsx local: ");
        String caminho = scnTextos.nextLine();
        File arq = new File(caminho);
        if (!arq.exists()) {
            System.out.println("Arquivo não encontrado: " + caminho);
            return;
        }

        System.out.println("\n=== Iniciando importacao do arquivo local ===");
        try (InputStream is = new FileInputStream(arq)) {
            LeitorExcel leitorExcel = new LeitorExcel();
            LeitorExcel.ResultadoLeitura dados = leitorExcel.extrairDeInputStream(is);
            inserirDadosNoBanco(dados);
        } catch (Exception e) {
            System.err.println("\n=== ERRO NA IMPORTACAO DO ARQUIVO LOCAL ===");
            System.err.println(e.getMessage());
            e.printStackTrace();
            novoLogBanco("ERROR", "importacao", "Falha na importacao local: " + e.getMessage(), LocalDateTime.now(), "Java");
        }
    }

    // ---------------------------------------------------------------
    // Inserção no banco de dados via JDBC com resolução de chaves e FKs
    // ---------------------------------------------------------------
    public static void inserirDadosNoBanco(LeitorExcel.ResultadoLeitura dados) {
        System.out.println("\n=== Gravando registros no Banco de Dados via JDBC ===");

        // Cache para mapear entidades já existentes / inseridas
        Map<Integer, Integer> cacheCompanhias = new HashMap<>(); // codCompanhia -> idCompanhia
        Map<String, Integer>  cacheAvioes      = new HashMap<>(); // modelo -> idAviao
        Map<String, Integer>  cacheAeroportos  = new HashMap<>(); // icao/nome -> idAeroporto

        // 1. Inserir Companhias
        System.out.println("\n[1/5] Inserindo / vinculando companhias...");
        for (Companhia c : dados.companhias) {
            if (c.codCompanhia == null || cacheCompanhias.containsKey(c.codCompanhia)) {
                continue;
            }

            Integer idExistente = buscarId(
                "SELECT idCompanhia FROM companhia WHERE codCompanhia = ? LIMIT 1",
                c.codCompanhia
            );

            if (idExistente != null) {
                cacheCompanhias.put(c.codCompanhia, idExistente);
            } else {
                KeyHolder keyHolder = new GeneratedKeyHolder();
                bd.update(new PreparedStatementCreator() {
                    @Override
                    public PreparedStatement createPreparedStatement(Connection con) throws SQLException {
                        PreparedStatement ps = con.prepareStatement(
                            "INSERT INTO companhia (codCompanhia, nomeCompanhia, paisCompanhia, razaoSocial, cnpj, fkCargo) VALUES (?, ?, ?, ?, ?, ?)",
                            Statement.RETURN_GENERATED_KEYS
                        );
                        ps.setInt(1, c.codCompanhia);
                        ps.setString(2, c.nomeCompanhia != null ? c.nomeCompanhia : "DESCONHECIDA");
                        ps.setString(3, c.paisCompanhia != null ? c.paisCompanhia : "BRASIL");
                        ps.setString(4, c.razaoSocial != null ? c.razaoSocial : "");
                        ps.setString(5, c.cnpj != null ? c.cnpj : "");
                        ps.setInt(6, 1); // Cargo padrão 1
                        return ps;
                    }
                }, keyHolder);

                Number generatedId = keyHolder.getKey();
                if (generatedId != null) {
                    cacheCompanhias.put(c.codCompanhia, generatedId.intValue());
                }
            }
        }
        System.out.printf("Total de companhias ativas em cache: %d%n", cacheCompanhias.size());

        // 2. Inserir Aviões
        System.out.println("\n[2/5] Inserindo / vinculando avioes...");
        for (Aviao a : dados.avioes) {
            if (a.modelo == null || a.modelo.trim().isEmpty() || cacheAvioes.containsKey(a.modelo)) {
                continue;
            }

            Integer idExistente = buscarId(
                "SELECT idAviao FROM aviao WHERE modelo = ? LIMIT 1",
                a.modelo
            );

            if (idExistente != null) {
                cacheAvioes.put(a.modelo, idExistente);
            } else {
                KeyHolder keyHolder = new GeneratedKeyHolder();
                bd.update(new PreparedStatementCreator() {
                    @Override
                    public PreparedStatement createPreparedStatement(Connection con) throws SQLException {
                        PreparedStatement ps = con.prepareStatement(
                            "INSERT INTO aviao (numAssentos, modelo) VALUES (?, ?)",
                            Statement.RETURN_GENERATED_KEYS
                        );
                        ps.setInt(1, a.numAssentos != null ? a.numAssentos : 0);
                        ps.setString(2, a.modelo);
                        return ps;
                    }
                }, keyHolder);

                Number generatedId = keyHolder.getKey();
                if (generatedId != null) {
                    cacheAvioes.put(a.modelo, generatedId.intValue());
                }
            }
        }
        System.out.printf("Total de modelos de avioes em cache: %d%n", cacheAvioes.size());

        // 3. Inserir Aeroportos
        System.out.println("\n[3/5] Inserindo / vinculando aeroportos...");
        for (Aeroporto a : dados.aeroportos) {
            String chave = (a.icao != null && !a.icao.isEmpty()) ? a.icao : a.nomeAeroporto;
            if (chave == null || cacheAeroportos.containsKey(chave)) {
                continue;
            }

            Integer idExistente = null;
            if (a.icao != null && !a.icao.isEmpty()) {
                idExistente = buscarId("SELECT idAeroporto FROM aeroporto WHERE nomeAeroporto = ? OR nomeAeroporto = ? LIMIT 1",
                        a.nomeAeroporto, a.icao);
            } else {
                idExistente = buscarId("SELECT idAeroporto FROM aeroporto WHERE nomeAeroporto = ? LIMIT 1", a.nomeAeroporto);
            }

            if (idExistente != null) {
                cacheAeroportos.put(chave, idExistente);
            } else {
                KeyHolder keyHolder = new GeneratedKeyHolder();
                bd.update(new PreparedStatementCreator() {
                    @Override
                    public PreparedStatement createPreparedStatement(Connection con) throws SQLException {
                        PreparedStatement ps = con.prepareStatement(
                            "INSERT INTO aeroporto (nomeAeroporto, municipio, uf, regiao, pais) VALUES (?, ?, ?, ?, ?)",
                            Statement.RETURN_GENERATED_KEYS
                        );
                        ps.setString(1, a.nomeAeroporto != null ? a.nomeAeroporto : "");
                        ps.setString(2, a.municipio != null ? a.municipio : "");
                        ps.setString(3, a.uf != null ? a.uf : "");
                        ps.setString(4, a.regiao != null ? a.regiao : "");
                        ps.setString(5, a.pais != null ? a.pais : "BRASIL");
                        return ps;
                    }
                }, keyHolder);

                Number generatedId = keyHolder.getKey();
                if (generatedId != null) {
                    cacheAeroportos.put(chave, generatedId.intValue());
                }
            }
        }
        System.out.printf("Total de aeroportos em cache: %d%n", cacheAeroportos.size());

        // 4. Inserir Voos com as FKs corretas
        System.out.println("\n[4/5] Inserindo voos...");
        Integer idCompanhiaPadrao = cacheCompanhias.values().stream().findFirst().orElse(null);
        if (idCompanhiaPadrao == null) {
            idCompanhiaPadrao = buscarId("SELECT idCompanhia FROM companhia LIMIT 1");
        }
        Integer idAviaoPadrao = cacheAvioes.values().stream().findFirst().orElse(null);
        if (idAviaoPadrao == null) {
            idAviaoPadrao = buscarId("SELECT idAviao FROM aviao LIMIT 1");
        }

        int voosInseridos = 0;
        int maxVoos = Math.min(dados.voos.size(), dados.companhias.size());
        for (int i = 0; i < maxVoos; i++) {
            Voo v = dados.voos.get(i);
            Companhia c = (i < dados.companhias.size()) ? dados.companhias.get(i) : null;
            Aviao a = (i < dados.avioes.size()) ? dados.avioes.get(i) : null;

            Integer fkCompanhia = (c != null && cacheCompanhias.containsKey(c.codCompanhia))
                    ? cacheCompanhias.get(c.codCompanhia) : idCompanhiaPadrao;
            Integer fkAviao = (a != null && cacheAvioes.containsKey(a.modelo))
                    ? cacheAvioes.get(a.modelo) : idAviaoPadrao;

            if (fkCompanhia == null || fkAviao == null) {
                continue;
            }

            KeyHolder keyHolder = new GeneratedKeyHolder();
            final Integer finalFkComp = fkCompanhia;
            final Integer finalFkAv = fkAviao;

            bd.update(new PreparedStatementCreator() {
                @Override
                public PreparedStatement createPreparedStatement(Connection con) throws SQLException {
                    PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO voo (numVoo, tipoVoo, qtdPassageiros, fkCompanhia, fkAviao) VALUES (?, ?, ?, ?, ?)",
                        Statement.RETURN_GENERATED_KEYS
                    );
                    ps.setInt(1, v.numVoo != null ? v.numVoo : 0);
                    ps.setInt(2, v.tipoVoo != null ? v.tipoVoo : 0);
                    ps.setInt(3, v.qtdPassageiros != null ? v.qtdPassageiros : 0);
                    ps.setInt(4, finalFkComp);
                    ps.setInt(5, finalFkAv);
                    return ps;
                }
            }, keyHolder);

            Number idGerado = keyHolder.getKey();
            if (idGerado != null) {
                v.idVoo = idGerado.intValue();
                voosInseridos++;
            }
        }
        System.out.printf("Total de voos inseridos: %d%n", voosInseridos);

        // 5. Inserir AeroportoDirecao associando ao Voo e Aeroporto correspondentes
        System.out.println("\n[5/5] Inserindo direcoes de aeroporto...");
        int direcoesInseridas = 0;
        int maxDirecoes = Math.min(dados.aeroportoDirecoes.size(), dados.aeroportos.size());

        for (int i = 0; i < maxDirecoes; i++) {
            AeroportoDirecao ad = dados.aeroportoDirecoes.get(i);
            Aeroporto aero = dados.aeroportos.get(i);
            int idxVoo = i / 2; // Cada voo tem partida e chegada (2 aeroportos e 2 direções)
            if (idxVoo >= dados.voos.size()) break;

            Voo vooRelacionado = dados.voos.get(idxVoo);
            if (vooRelacionado.idVoo == null) continue;

            String chaveAero = (aero.icao != null && !aero.icao.isEmpty()) ? aero.icao : aero.nomeAeroporto;
            Integer fkAeroporto = cacheAeroportos.get(chaveAero);
            if (fkAeroporto == null) continue;

            try {
                bd.update(
                    "INSERT INTO aeroportoDirecao (fkAeroporto, fkVoo, direcao, dia, hora) VALUES (?, ?, ?, ?, ?) " +
                    "ON DUPLICATE KEY UPDATE direcao = VALUES(direcao), dia = VALUES(dia), hora = VALUES(hora)",
                    fkAeroporto,
                    vooRelacionado.idVoo,
                    ad.direcao,
                    Date.valueOf(ad.dia),
                    Time.valueOf(ad.hora)
                );
                direcoesInseridas++;
            } catch (Exception e) {
                // Registro duplicado ou violação ignorada com log suave
            }
        }
        System.out.printf("Total de direcoes inseridas: %d%n", direcoesInseridas);

        System.out.println("\n=== Importacao e insercao concluidas com sucesso! ===");
        novoLogBanco("INFO", "importacao",
                String.format("Base ANAC importada via Apache POI e inserida no BD: %d companhias, %d avioes, %d aeroportos, %d voos.",
                        cacheCompanhias.size(), cacheAvioes.size(), cacheAeroportos.size(), voosInseridos),
                LocalDateTime.now(), "Java");
    }

    private static Integer buscarId(String sql, Object... params) {
        try {
            List<Integer> list = bd.queryForList(sql, Integer.class, params);
            if (list != null && !list.isEmpty()) {
                return list.get(0);
            }
        } catch (Exception ignored) {}
        return null;
    }

    public static void exibirMenu() {
        System.out.print("""
                
                =================================
                Olá, o que deseja fazer?
                1- Cadastrar Novo Usuario
                2- Alterar Senha
                3- Ver todos os logs
                4- Importar base ANAC via S3 (Apache POI -> JDBC)
                5- Importar planilha local (Apache POI -> JDBC)
                0- Sair
                =================================
                Digite a sua opcao: """);
    }

    public static void esperarUsuario() {
        System.out.println("\nAperte ENTER para continuar...");
        scnTextos.nextLine();
    }

    public static void novoLogBanco(String categoria, String servico, String mensagem, LocalDateTime dataHora, String origemCadastro) {
        try {
            bd.update("INSERT INTO logsServico (categoria, servico, mensagem, dataHora, origemCadastro) VALUES (?, ?, ?, ?, ?);",
                    categoria, servico, mensagem, LocalDateTime.now(), origemCadastro);
        } catch (Exception e) {
            System.err.println("Falha ao registrar log no banco: " + e.getMessage());
        }
    }

    public static void cadastrarNovoUsuario() {
        System.out.print("Nome do Usuario: ");
        String nome = scnTextos.nextLine();

        System.out.println("CPF do Usuario: ");
        String cpf = scnTextos.nextLine();

        System.out.println("Email: ");
        String email = scnTextos.nextLine();

        System.out.println("Senha: ");
        String senha = scnTextos.nextLine();

        System.out.println("Confirme a senha: ");
        String confirmarSenha = scnTextos.nextLine();

        System.out.println("ID da Companhia que Trabalha: ");
        Integer fkCompanhia = scnNumeros.nextInt();

        System.out.println("Cargo do Usuario: ");
        Integer fkCargo = scnNumeros.nextInt();

        if (senha.equals(confirmarSenha)) {
            bd.update("INSERT INTO usuario (nome, cpf, email, senha, fkCompanhia, fkCargo) VALUES (?, ?, ?, ?, ?, ?);",
                    nome, cpf, email, senha, fkCompanhia, fkCargo);
            novoLogBanco("INFO", "auth", "Usuario " + nome + " cadastrado", LocalDateTime.now(), "Java");
        } else {
            System.out.println("Senhas Nao Coincidem!!!!!!!!");
            novoLogBanco("ERROR", "auth", "Usuario " + nome + " nao foi cadastrado", LocalDateTime.now(), "Java");
        }
    }

    public static void trocarSenha() {
        System.out.println("CPF do usuario que deseja editar: ");
        String cpf = scnTextos.nextLine();

        System.out.println("Nova Senha: ");
        String senha = scnTextos.nextLine();

        System.out.println("Confirme a senha: ");
        String confirmarSenha = scnTextos.nextLine();

        if (senha.equals(confirmarSenha)) {
            bd.update("UPDATE usuario SET senha = ? WHERE cpf = ?;", senha, cpf);
            novoLogBanco("INFO", "auth", "Usuario com cpf " + cpf + " alterou a senha!", LocalDateTime.now(), "Java");
        } else {
            System.out.println("Senhas Nao Coincidem!!!!!!!!");
            novoLogBanco("ERROR", "auth", "Usuario com cpf " + cpf + " nao alterou a senha!", LocalDateTime.now(), "Java");
        }
    }

    public static void exibirTodosOsLogs() {
        List<Log> logs = bd.query("SELECT * FROM logsServico", new BeanPropertyRowMapper<>(Log.class));
        System.out.println(logs);
    }
}
