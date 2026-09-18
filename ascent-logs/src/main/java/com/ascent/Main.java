package com.ascent;

import org.springframework.cglib.core.Local;
import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import com.ascent.Conexao;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Scanner;

public class Main {

    static Scanner scnNumeros = new Scanner(System.in);
    static Scanner scnTextos = new Scanner(System.in);
    static Conexao bancoAscent;
    static JdbcTemplate bd;


    public static void main(String[] args) {

        bancoAscent = new Conexao();
        bd = new JdbcTemplate(bancoAscent.getConexao());

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
                default:
                    System.out.println("Opção inválida! Tente novamente.");
            }
        } while (opcao != 0);

    }

    public static void exibirMenu() {
        System.out.print("""
                
                =================================
                Olá, o que deseja fazer?
                1- Cadastrar Novo Usuario
                2- Alterar Senha
                3- Ver todos os logs
                0- Sair
                =================================
                Digite a sua opcao: """);
    }

    public static void esperarUsuario() {
        System.out.println("\nAperte ENTER para continuar...");
        scnTextos.nextLine();
    }

    public static void novoLogBanco(String categoria, String servico, String mensagem, LocalDateTime dataHora, String origemCadastro){
        bd.update("INSERT INTO logsServico (categoria, servico, mensagem, dataHora, origemCadastro) VALUES (?, ?, ?, ?, ?);",
                categoria, servico, mensagem, LocalDateTime.now(), origemCadastro);
    }

    public static void cadastrarNovoUsuario(){
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

        if (senha.equals(confirmarSenha)){
            bd.update("INSERT INTO usuario (nome, cpf, email, senha, fkCompanhia, fkCargo) VALUES (?, ?, ?, ?, ?, ?);",
                    nome, cpf, email, senha, fkCompanhia, fkCargo);

            novoLogBanco("INFO", "auth", "Usuario " + nome + " cadastrado", LocalDateTime.now(), "Java");
        }else{
            System.out.println("Senhas Nao Coincidem!!!!!!!!");
            novoLogBanco("ERROR", "auth", "Usuario " + nome + " nao foi cadastrado", LocalDateTime.now(), "Java");
        }

    }

    public static void trocarSenha(){
        System.out.println("CPF do usuario que deseja editar: ");
        String cpf = scnTextos.nextLine();

        System.out.println("Nova Senha: ");
        String senha = scnTextos.nextLine();

        System.out.println("Confirme a senha: ");
        String confirmarSenha = scnTextos.nextLine();

        if (senha.equals(confirmarSenha)){
            bd.update("UPDATE usuario SET senha = ? WHERE cpf = ?;", senha, cpf);

            novoLogBanco("INFO", "auth", "Usuario com cpf " + cpf + " alterou a senha!", LocalDateTime.now(), "Java");
        }else{
            System.out.println("Senhas Nao Coincidem!!!!!!!!");
            novoLogBanco("ERROR", "auth", "Usuario com cpf " + cpf + " nao alterou a senha!", LocalDateTime.now(), "Java");
        }

    }

    public static void exibirTodosOsLogs(){
        List<Log> logs =  bd.query("SELECT * FROM logsServico", new BeanPropertyRowMapper<>(Log.class));
        System.out.println(logs);

    }




}