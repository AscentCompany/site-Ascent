package com.ascent;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

public class Main {

    static Scanner scnNumeros = new Scanner(System.in);
    static Scanner scnTextos = new Scanner(System.in);
    static Integer simuladorDeId = 1;

    public static void main(String[] args) {

        List<Voo> listaDeVoos = new ArrayList<>();
        List<Log> listaDeLogs = new ArrayList<>();
        Integer opcao;

        do {
            exibirMenu();
            opcao = scnNumeros.nextInt();

            switch (opcao) {
                case 0:
                    System.out.println("Encerrando o sistema. Até Breve!");
                    break;
                case 1:
                    cadastrarNovoVoo(listaDeVoos, listaDeLogs);
                    esperarUsuario();
                    break;
                case 2:
                    listarTodosOsVoos(listaDeVoos);
                    esperarUsuario();
                    break;
                case 3:
                    exibirLogs(listaDeLogs);
                    esperarUsuario();
                    break;
                case 4:
                    editarVoo(listaDeVoos, listaDeLogs);
                    esperarUsuario();
                    break;
                case 5:
                    excluirVoo(listaDeVoos, listaDeLogs);
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
                1- Cadastrar Novo voo
                2- Ver todos os voos
                3- Ver todos os logs
                4- Editar um voo
                5- Excluir um voo
                0- Sair
                =================================
                Digite a sua opcao: """);
    }

    public static void esperarUsuario() {
        System.out.println("\nAperte ENTER para continuar...");
        scnTextos.nextLine();
    }

    public static void cadastrarNovoVoo(List<Voo> voos, List<Log> logs) {
        Voo novoVoo = new Voo();

        novoVoo.idVoo = simuladorDeId++;
        novoVoo.dataPartida = LocalDate.now();
        novoVoo.horaPartida = LocalTime.now();

        System.out.print("Digite o Nome da Companhia Aérea: ");
        novoVoo.nomeCompanhia = scnTextos.nextLine();

        System.out.print("Digite a quantidade de Assentos Disponíveis: ");
        novoVoo.numAssentos = scnNumeros.nextInt();

        System.out.print("Digite a quantidade de Passageiros: ");
        novoVoo.numPassageiros = scnNumeros.nextInt();

        System.out.print("Quanto de Combustível foi Gasto no com.ascent.Voo em Litros: ");
        novoVoo.combustivelGasto = scnNumeros.nextDouble();

        voos.add(novoVoo);

        cadastrarNovoLog(logs, "Cadastrou o voo ID " + novoVoo.idVoo + " da companhia: " + novoVoo.nomeCompanhia);
        System.out.println("com.ascent.Voo Cadastrado com Sucesso!!");
    }

    public static void listarTodosOsVoos(List<Voo> voos) {
        if (voos == null || voos.size() == 0) {
            System.out.println("Nenhum voo cadastrado no momento.");
            return;
        }

        System.out.println("\n==== LISTA DE VOOS ====");
        for (Voo v : voos) {
            System.out.print("""
                    ID do com.ascent.Voo: %d
                    Companhia: %s
                    Data/Hora: %s às %s
                    Assentos Disponíveis: %d
                    Quantidade de Passageiros: %d
                    Combustível Utilizado: %.2fL
                    ------------------------------
                    """.formatted(v.idVoo, v.nomeCompanhia, v.dataPartida, v.horaPartida, v.numAssentos, v.numPassageiros, v.combustivelGasto));
        }
    }

    public static void editarVoo(List<Voo> voos, List<Log> logs) {
        System.out.print("Digite o ID do voo que deseja editar: ");
        Integer idBusca = scnNumeros.nextInt();

        for (Voo v : voos) {
            if (v.idVoo == idBusca) {
                System.out.println("Editando voo da companhia: " + v.nomeCompanhia);

                System.out.print("Nova quantidade de Passageiros (Atual: " + v.numPassageiros + "): ");
                v.numPassageiros = scnNumeros.nextInt();

                cadastrarNovoLog(logs, "Editou informações do voo ID " + v.idVoo);
                System.out.println("com.ascent.Voo atualizado com sucesso!");
                return;
            }
        }
        System.out.println("com.ascent.Voo com ID " + idBusca + " não encontrado.");
    }

    public static void excluirVoo(List<Voo> voos, List<Log> logs) {
        System.out.print("Digite o ID do voo que deseja excluir: ");
        int idBusca = scnNumeros.nextInt();

        for (int i = 0; i < voos.size(); i++) {
            if (voos.get(i).idVoo == idBusca) {
                Voo vooRemovido = voos.remove(i);
                cadastrarNovoLog(logs, "Excluiu o voo ID " + vooRemovido.idVoo + " da companhia " + vooRemovido.nomeCompanhia);
                System.out.println("com.ascent.Voo excluído com sucesso!");
                return;
            }
        }
        System.out.println("com.ascent.Voo com ID " + idBusca + " não encontrado.");
    }

    public static void cadastrarNovoLog(List<Log> logs, String acao) {
        Log novoLog = new Log();
        novoLog.usuario = "XPTO";
        novoLog.acao = acao;
        novoLog.dataHora = LocalDateTime.now();
        logs.add(novoLog);
    }

    public static void exibirLogs(List<Log> logs) {
        if (logs == null || logs.size() == 0) {
            System.out.println("Nenhum log registrado ainda.");
            return;
        }

        System.out.println("\n==== REGISTRO DE ATIVIDADES ====");
        for (Log l : logs) {
            System.out.println("[" + l.dataHora + "] O usuário '" + l.usuario + "' realizou a ação: " + l.acao);
        }
    }
}