package com.ascent;

import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;

import java.io.InputStream;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

public class LeitorExcel {

    private static final String BUCKET  = "ascent-database-318401088884-us-east-1-an";
    private static final String ARQUIVO = "anac_brazil.xlsx";
    private static final Region REGIAO  = Region.US_EAST_1;

    private static final DateTimeFormatter FMT_DATA = DateTimeFormatter.ofPattern("dd/MM/yyyy");
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
        ResultadoLeitura resultado = new ResultadoLeitura();

        System.out.println("Conectando ao S3...");
        System.out.printf("Bucket : %s%n", BUCKET);
        System.out.printf("Arquivo: %s%n", ARQUIVO);

        S3Client s3 = S3Client.builder()
                .region(REGIAO)
                .build();

        GetObjectRequest pedido = GetObjectRequest.builder()
                .bucket(BUCKET)
                .key(ARQUIVO)
                .build();

        try (
            InputStream stream   = s3.getObject(pedido);
            Workbook    workbook = new XSSFWorkbook(stream)
        ) {
            System.out.printf("Iniciando leitura do arquivo %s%n", ARQUIVO);

            Sheet sheet = workbook.getSheetAt(0);

            for (Row row : sheet) {

                // Linha 0 é o cabeçalho — imprime e pula
                if (row.getRowNum() == 0) {
                    printarCabecalho(row);
                    continue;
                }

                System.out.println("Lendo linha " + row.getRowNum());

                // --- Companhia ---
                Companhia companhia = new Companhia();
                companhia.codCompanhia  = (int) row.getCell(getColunaIndice("id_empresa")).getNumericCellValue();
                companhia.nomeCompanhia = row.getCell(getColunaIndice("nm_empresa")).getStringCellValue();
                companhia.paisCompanhia = row.getCell(getColunaIndice("nm_pais_origem")).getStringCellValue();
                resultado.companhias.add(companhia);

                // --- Aviao ---
                Aviao aviao = new Aviao();
                aviao.numAssentos = (int) row.getCell(getColunaIndice("nr_assentos_ofertados")).getNumericCellValue();
                aviao.modelo      = row.getCell(getColunaIndice("ds_modelo")).getStringCellValue();
                resultado.avioes.add(aviao);

                // --- Voo ---
                Voo voo = new Voo();
                voo.numVoo         = (int) row.getCell(getColunaIndice("nr_voo")).getNumericCellValue();
                voo.tipoVoo        = (int) row.getCell(getColunaIndice("cd_di")).getNumericCellValue();
                int passagosPagos  = (int) row.getCell(getColunaIndice("nr_passag_pagos")).getNumericCellValue();
                int passagosGratis = (int) row.getCell(getColunaIndice("nr_passag_gratis")).getNumericCellValue();
                voo.qtdPassageiros = passagosPagos + passagosGratis;
                resultado.voos.add(voo);

                // --- Aeroporto Origem ---
                Aeroporto origem = new Aeroporto();
                origem.nomeAeroporto = row.getCell(getColunaIndice("nm_aerodromo_origem")).getStringCellValue();
                origem.municipio     = row.getCell(getColunaIndice("nm_municipio_origem")).getStringCellValue();
                origem.uf            = row.getCell(getColunaIndice("sg_uf_origem")).getStringCellValue();
                origem.regiao        = row.getCell(getColunaIndice("nm_regiao_origem")).getStringCellValue();
                origem.pais          = row.getCell(getColunaIndice("nm_pais_origem")).getStringCellValue();
                origem.icao          = row.getCell(getColunaIndice("sg_icao_origem")).getStringCellValue();
                resultado.aeroportos.add(origem);

                // --- Aeroporto Destino ---
                Aeroporto destino = new Aeroporto();
                destino.nomeAeroporto = row.getCell(getColunaIndice("nm_aerodromo_destino")).getStringCellValue();
                destino.municipio     = row.getCell(getColunaIndice("nm_municipio_destino")).getStringCellValue();
                destino.uf            = row.getCell(getColunaIndice("sg_uf_destino")).getStringCellValue();
                destino.regiao        = row.getCell(getColunaIndice("nm_regiao_destino")).getStringCellValue();
                destino.pais          = row.getCell(getColunaIndice("nm_pais_destino")).getStringCellValue();
                destino.icao          = row.getCell(getColunaIndice("sg_icao_destino")).getStringCellValue();
                resultado.aeroportos.add(destino);

                // --- AeroportoDirecao Partida ---
                AeroportoDirecao partida = new AeroportoDirecao();
                partida.direcao = "Partida";
                partida.dia  = row.getCell(getColunaIndice("dt_partida_real")).getLocalDateTimeCellValue().toLocalDate();
                partida.hora = row.getCell(getColunaIndice("hr_partida_real")).getLocalDateTimeCellValue().toLocalTime();
                resultado.aeroportoDirecoes.add(partida);

                // --- AeroportoDirecao Destino ---
                AeroportoDirecao chegada = new AeroportoDirecao();
                chegada.direcao = "Destino";
                chegada.dia  = row.getCell(getColunaIndice("dt_chegada_real")).getLocalDateTimeCellValue().toLocalDate();
                chegada.hora = row.getCell(getColunaIndice("hr_chegada_real")).getLocalDateTimeCellValue().toLocalTime();
                resultado.aeroportoDirecoes.add(chegada);
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
            // Para a aplicação e informa o erro exato para correção
            throw new RuntimeException("Erro ao ler a planilha: " + e.getMessage(), e);
        }

        return resultado;
    }

    // ---------------------------------------------------------------
    // Mapeamento: nome da coluna ANAC → índice na planilha
    // Ajuste os índices caso a ordem das colunas mude no arquivo
    // ---------------------------------------------------------------
    private int getColunaIndice(String nomeColuna) {
        return switch (nomeColuna) {
            case "dt_partida_real"       -> 0;
            case "dt_chegada_real"       -> 1;
            case "id_aerodromo_origem"   -> 2;
            case "id_aerodromo_destino"  -> 3;
            case "nm_aerodromo_origem"   -> 4;
            case "nm_aerodromo_destino"  -> 5;
            case "nm_municipio_origem"   -> 6;
            case "nm_municipio_destino"  -> 7;
            case "sg_uf_origem"          -> 8;
            case "sg_uf_destino"         -> 9;
            case "nm_regiao_origem"      -> 10;
            case "nm_regiao_destino"     -> 11;
            case "nm_pais_origem"        -> 12;
            case "nm_pais_destino"       -> 13;
            case "nr_assentos_ofertados" -> 14;
            case "nr_passag_pagos"       -> 15;
            case "nr_passag_gratis"      -> 16;
            case "id_empresa"            -> 17;
            case "sg_empresa_icao"       -> 18;
            case "nm_empresa"            -> 19;
            case "nr_voo"                -> 20;
            case "ds_tipo_linha"         -> 21;
            case "hr_partida_real"       -> 22;
            case "hr_chegada_real"       -> 23;
            case "sg_icao_origem"        -> 24;
            case "sg_icao_destino"       -> 25;
            case "cd_di"                 -> 26;
            case "ds_di"                 -> 27;
            case "ds_modelo"             -> 28;
            case "nm_pais"               -> 29;
            default -> throw new IllegalArgumentException("Coluna nao mapeada: " + nomeColuna);
        };
    }

    private void printarCabecalho(Row row) {
        printarLinhas();
        System.out.println("Lendo cabecalho");
        for (int i = 0; i < row.getLastCellNum(); i++) {
            if (row.getCell(i) != null) {
                System.out.println("Coluna " + i + ": " + row.getCell(i).getStringCellValue());
            }
        }
        printarLinhas();
    }

    private void printarLinhas() {
        System.out.println("-".repeat(40));
    }
}
