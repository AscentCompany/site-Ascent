package com.ascent.apachepoi;

import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellType;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.apache.poi.util.IOUtils;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;

import java.io.InputStream;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class LeitorExcel {

    private static final String BUCKET  = System.getenv("AWS_BUCKET") != null ?
            System.getenv("AWS_BUCKET") : "ascent-database-318401088884-us-east-1-an";
    private static final String ARQUIVO = System.getenv("AWS_ARQUIVO_ANAC") != null ?
            System.getenv("AWS_ARQUIVO_ANAC") : "anac_brazil.xlsx";
    private static final Region REGIAO  = Region.US_EAST_1;

    private static final DateTimeFormatter FMT_DATA = DateTimeFormatter.ofPattern("yyyy-MM-dd");
    private static final DateTimeFormatter FMT_DATA_BR = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    private static final DateTimeFormatter FMT_HORA = DateTimeFormatter.ofPattern("HH:mm:ss");

    // Resultado da leitura — todas as entidades extraídas da planilha
    public static class ResultadoLeitura {
        public List<Companhia>        companhias        = new ArrayList<>();
        public List<Aviao>            avioes            = new ArrayList<>();
        public List<Voo>              voos              = new ArrayList<>();
        public List<Aeroporto>        aeroportos        = new ArrayList<>();
        public List<AeroportoDirecao> aeroportoDirecoes = new ArrayList<>();
    }

    // ---------------------------------------------------------------
    // Ponto de entrada: conecta ao S3 e extrai os dados da planilha
    // Autenticação via variáveis de ambiente:
    //   AWS_ACCESS_KEY_ID
    //   AWS_SECRET_ACCESS_KEY
    // ---------------------------------------------------------------
    public ResultadoLeitura extrairDados() {
        System.out.println("Conectando ao S3...");
        System.out.printf("Bucket : %s%n", BUCKET);
        System.out.printf("Arquivo: %s%n", ARQUIVO);

        S3Client s3 = S3Client.builder().region(REGIAO).build();

        GetObjectRequest pedido = GetObjectRequest.builder().bucket(BUCKET).key(ARQUIVO).build();

        try (InputStream stream = s3.getObject(pedido)) {
            return extrairDeInputStream(stream);
        } catch (Exception e) {
            throw new RuntimeException("Erro ao obter planilha do S3: " + e.getMessage(), e);
        }
    }

    public ResultadoLeitura extrairDeInputStream(InputStream stream) {
        ResultadoLeitura resultado = new ResultadoLeitura();
        IOUtils.setByteArrayMaxOverride(1000_000_000);

        try (Workbook workbook = new XSSFWorkbook(stream)) {
            System.out.println("Iniciando leitura do workbook...");

            Sheet sheet = workbook.getSheetAt(0);
            Map<String, Integer> colunas = new HashMap<>();

            for (Row row : sheet) {
                // Linha 0 é o cabeçalho — mapeia dinamicamente os nomes das colunas
                if (row.getRowNum() == 0) {
                    colunas = mapearCabecalho(row);
                    continue;
                }

                // --- Companhia ---
                Integer codEmpresa = getInt(row, colunas, "id_empresa");
                String nmEmpresa = getString(row, colunas, "nm_empresa");
                String paisEmpresa = getString(row, colunas, "nm_pais");
                if (paisEmpresa == null || paisEmpresa.isEmpty()) {
                    paisEmpresa = getString(row, colunas, "nm_pais_origem");
                }
                if (codEmpresa != null && nmEmpresa != null && !nmEmpresa.isEmpty()) {
                    Companhia companhia = new Companhia();
                    companhia.codCompanhia = codEmpresa;
                    companhia.nomeCompanhia = nmEmpresa;
                    companhia.paisCompanhia = (paisEmpresa != null && !paisEmpresa.isEmpty()) ? paisEmpresa : "BRASIL";
                    resultado.companhias.add(companhia);
                }

                // --- Aviao ---
                String modelo = getString(row, colunas, "ds_modelo");
                Integer assentos = getInt(row, colunas, "nr_assentos_ofertados");
                if (modelo != null && !modelo.isEmpty()) {
                    Aviao aviao = new Aviao();
                    aviao.modelo = modelo;
                    aviao.numAssentos = assentos != null ? assentos : 0;
                    resultado.avioes.add(aviao);
                }

                // --- Voo ---
                Integer nrVoo = getInt(row, colunas, "nr_voo");
                Integer tipoVoo = getInt(row, colunas, "cd_di");
                Integer passagosPagos = getInt(row, colunas, "nr_passag_pagos");
                Integer passagosGratis = getInt(row, colunas, "nr_passag_gratis");
                int qtdPassageiros = (passagosPagos != null ? passagosPagos : 0) + (passagosGratis != null ? passagosGratis : 0);

                if (nrVoo != null) {
                    Voo voo = new Voo();
                    voo.numVoo = nrVoo;
                    voo.tipoVoo = tipoVoo != null ? tipoVoo : 0;
                    voo.qtdPassageiros = qtdPassageiros;
                    resultado.voos.add(voo);
                }

                // --- Aeroporto Origem ---
                String nmAerodromoOrigem = getString(row, colunas, "nm_aerodromo_origem");
                String sgIcaoOrigem = getString(row, colunas, "sg_icao_origem");
                if (nmAerodromoOrigem != null && !nmAerodromoOrigem.isEmpty()) {
                    Aeroporto origem = new Aeroporto();
                    origem.nomeAeroporto = nmAerodromoOrigem;
                    origem.municipio = getString(row, colunas, "nm_municipio_origem");
                    origem.uf = getString(row, colunas, "sg_uf_origem");
                    origem.regiao = getString(row, colunas, "nm_regiao_origem");
                    origem.pais = getString(row, colunas, "nm_pais_origem");
                    origem.icao = sgIcaoOrigem;
                    resultado.aeroportos.add(origem);
                }

                // --- Aeroporto Destino ---
                String nmAerodromoDestino = getString(row, colunas, "nm_aerodromo_destino");
                String sgIcaoDestino = getString(row, colunas, "sg_icao_destino");
                if (nmAerodromoDestino != null && !nmAerodromoDestino.isEmpty()) {
                    Aeroporto destino = new Aeroporto();
                    destino.nomeAeroporto = nmAerodromoDestino;
                    destino.municipio = getString(row, colunas, "nm_municipio_destino");
                    destino.uf = getString(row, colunas, "sg_uf_destino");
                    destino.regiao = getString(row, colunas, "nm_regiao_destino");
                    destino.pais = getString(row, colunas, "nm_pais_destino");
                    destino.icao = sgIcaoDestino;
                    resultado.aeroportos.add(destino);
                }

                // --- AeroportoDirecao Partida ---
                LocalDate dtPartida = getLocalDate(row, colunas, "dt_partida_real");
                LocalTime hrPartida = getLocalTime(row, colunas, "hr_partida_real");
                if (dtPartida != null && hrPartida != null) {
                    AeroportoDirecao partida = new AeroportoDirecao();
                    partida.direcao = "Partida";
                    partida.dia = dtPartida;
                    partida.hora = hrPartida;
                    resultado.aeroportoDirecoes.add(partida);
                }

                // --- AeroportoDirecao Destino ---
                LocalDate dtChegada = getLocalDate(row, colunas, "dt_chegada_real");
                LocalTime hrChegada = getLocalTime(row, colunas, "hr_chegada_real");
                if (dtChegada != null && hrChegada != null) {
                    AeroportoDirecao chegada = new AeroportoDirecao();
                    chegada.direcao = "Destino";
                    chegada.dia = dtChegada;
                    chegada.hora = hrChegada;
                    resultado.aeroportoDirecoes.add(chegada);
                }
            }

            printarLinhas();
            System.out.println("Leitura do arquivo finalizada");
            System.out.println("Companhias : " + resultado.companhias.size());
            System.out.println("Avioes     : " + resultado.avioes.size());
            System.out.println("Voos       : " + resultado.voos.size());
            System.out.println("Aeroportos : " + resultado.aeroportos.size());
            System.out.println("Direcoes   : " + resultado.aeroportoDirecoes.size());
            printarLinhas();

        } catch (Exception e) {
            throw new RuntimeException("Erro ao ler a planilha: " + e.getMessage(), e);
        }

        return resultado;
    }

    private Map<String, Integer> mapearCabecalho(Row row) {
        printarLinhas();
        System.out.println("Lendo e indexando cabecalho...");
        Map<String, Integer> mapa = new HashMap<>();
        for (int i = 0; i < row.getLastCellNum(); i++) {
            Cell cell = row.getCell(i);
            if (cell != null) {
                String nome = cell.getStringCellValue();
                if (nome != null && !nome.trim().isEmpty()) {
                    mapa.put(nome.trim().toLowerCase(), i);
                }
            }
        }
        System.out.println("Total de colunas indexadas: " + mapa.size());
        printarLinhas();
        return mapa;
    }

    private String getString(Row row, Map<String, Integer> colunas, String nomeColuna) {
        Integer idx = colunas.get(nomeColuna.toLowerCase());
        if (idx == null) return null;
        Cell cell = row.getCell(idx);
        if (cell == null) return null;
        if (cell.getCellType() == CellType.STRING) {
            return cell.getStringCellValue().trim();
        }
        if (cell.getCellType() == CellType.NUMERIC) {
            return String.valueOf((long) cell.getNumericCellValue());
        }
        return cell.toString().trim();
    }

    private Integer getInt(Row row, Map<String, Integer> colunas, String nomeColuna) {
        Integer idx = colunas.get(nomeColuna.toLowerCase());
        if (idx == null) return null;
        Cell cell = row.getCell(idx);
        if (cell == null) return null;
        try {
            if (cell.getCellType() == CellType.NUMERIC) {
                return (int) cell.getNumericCellValue();
            }
            if (cell.getCellType() == CellType.STRING) {
                String val = cell.getStringCellValue().trim();
                if (val.isEmpty()) return null;
                return (int) Double.parseDouble(val);
            }
        } catch (Exception ignored) {}
        return null;
    }

    private LocalDate getLocalDate(Row row, Map<String, Integer> colunas, String nomeColuna) {
        Integer idx = colunas.get(nomeColuna.toLowerCase());
        if (idx == null) return null;
        Cell cell = row.getCell(idx);
        if (cell == null) return null;
        try {
            if (cell.getCellType() == CellType.NUMERIC && cell.getLocalDateTimeCellValue() != null) {
                return cell.getLocalDateTimeCellValue().toLocalDate();
            }
            String str = cell.getStringCellValue().trim();
            if (str.isEmpty()) return null;
            if (str.contains("-")) {
                return LocalDate.parse(str, FMT_DATA);
            } else if (str.contains("/")) {
                return LocalDate.parse(str, FMT_DATA_BR);
            }
        } catch (Exception ignored) {}
        return null;
    }

    private LocalTime getLocalTime(Row row, Map<String, Integer> colunas, String nomeColuna) {
        Integer idx = colunas.get(nomeColuna.toLowerCase());
        if (idx == null) return null;
        Cell cell = row.getCell(idx);
        if (cell == null) return null;
        try {
            if (cell.getCellType() == CellType.NUMERIC && cell.getLocalDateTimeCellValue() != null) {
                return cell.getLocalDateTimeCellValue().toLocalTime();
            }
            String str = cell.getStringCellValue().trim();
            if (str.isEmpty()) return null;
            return LocalTime.parse(str, FMT_HORA);
        } catch (Exception ignored) {}
        return null;
    }

    private void printarLinhas() {
        System.out.println("-".repeat(40));
    }
}
