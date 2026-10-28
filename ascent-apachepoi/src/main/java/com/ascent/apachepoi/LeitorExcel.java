package com.ascent.apachepoi;

import org.apache.poi.openxml4j.opc.OPCPackage;
import org.apache.poi.openxml4j.opc.PackageAccess;
import org.apache.poi.openxml4j.util.ZipSecureFile;
import org.apache.poi.util.IOUtils;
import org.apache.poi.xssf.eventusermodel.ReadOnlySharedStringsTable;
import org.apache.poi.xssf.eventusermodel.XSSFReader;
import org.apache.poi.xssf.eventusermodel.XSSFReader.SheetIterator;
import org.apache.poi.xssf.model.SharedStrings;
import org.apache.poi.xssf.model.StylesTable;
import org.apache.poi.xssf.usermodel.XSSFRichTextString;

import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;

import javax.xml.stream.XMLInputFactory;
import javax.xml.stream.XMLStreamReader;

import java.io.InputStream;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class LeitorExcel {

    public static String getEnvOrProp(String chave, String padrao) {
        // Prioriza system properties (carregadas do .env local) sobre env vars do shell
        String val = System.getProperty(chave);
        if (val != null && !val.trim().isEmpty()) {
            return val.trim();
        }
        val = System.getenv(chave);
        if (val != null && !val.trim().isEmpty()) {
            return val.trim();
        }
        return padrao;
    }

    private static String obterBucket() {
        return getEnvOrProp("AWS_BUCKET", "ascent-base-de-dados");
    }

    private static Region obterRegiao() {
        String reg = getEnvOrProp("AWS_REGION", "us-east-1");
        return Region.of(reg);
    }

    private static final DateTimeFormatter FMT_DATA    = DateTimeFormatter.ofPattern("yyyy-MM-dd");
    private static final DateTimeFormatter FMT_DATA_BR = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    private static final DateTimeFormatter FMT_HORA    = DateTimeFormatter.ofPattern("HH:mm:ss");

    // ---------------------------------------------------------------
    // Resultado da leitura
    // ---------------------------------------------------------------
    public static class ResultadoLeitura {
        public List<Companhia>        companhias        = new ArrayList<>();
        public List<Aviao>            avioes            = new ArrayList<>();
        public List<Voo>              voos              = new ArrayList<>();
        public List<Aeroporto>        aeroportos        = new ArrayList<>();
        public List<AeroportoDirecao> aeroportoDirecoes = new ArrayList<>();

        public String nomeArquivo       = null;
        public int    linhasEncontradas = 0;
        public int    linhasLidas       = 0;
        public int    linhasRejeitadas  = 0;
        public String statusLeitura     = "LIDO";
        public String detalheErro       = null;
    }

    public static S3Client criarClienteS3(Region regiao) {
        String accessKey = getEnvOrProp("AWS_ACCESS_KEY_ID", null);
        String secretKey = getEnvOrProp("AWS_SECRET_ACCESS_KEY", null);
        String sessionToken = getEnvOrProp("AWS_SESSION_TOKEN", null);

        if (accessKey != null && !accessKey.isEmpty() && secretKey != null && !secretKey.isEmpty()) {
            System.out.println("Autenticacao S3: utilizando credenciais explicitas informadas.");
            if (sessionToken != null && !sessionToken.isEmpty()) {
                return S3Client.builder()
                        .region(regiao)
                        .credentialsProvider(software.amazon.awssdk.auth.credentials.StaticCredentialsProvider.create(
                                software.amazon.awssdk.auth.credentials.AwsSessionCredentials.create(accessKey, secretKey, sessionToken)))
                        .build();
            } else {
                return S3Client.builder()
                        .region(regiao)
                        .credentialsProvider(software.amazon.awssdk.auth.credentials.StaticCredentialsProvider.create(
                                software.amazon.awssdk.auth.credentials.AwsBasicCredentials.create(accessKey, secretKey)))
                        .build();
            }
        }

        System.out.println("Autenticacao S3: utilizando IAM Role da instancia EC2 (Instance Profile)...");
        return S3Client.builder()
                .region(regiao)
                .build();
    }

    // ---------------------------------------------------------------
    // Lista de arquivos para importação
    // ---------------------------------------------------------------
    public List<String> obterListaDeArquivos() {
        List<String> arquivos = new ArrayList<>();
        String prefixo = getEnvOrProp("AWS_PREFIXO_ARQUIVOS", "anac_part_");
        String totalPartesStr = getEnvOrProp("AWS_TOTAL_PARTES", "23");

        if (totalPartesStr != null && !totalPartesStr.isEmpty()) {
            try {
                int total = Integer.parseInt(totalPartesStr);
                for (int i = 1; i <= total; i++) {
                    arquivos.add(String.format("%s%03d.xlsx", prefixo, i));
                }
                return arquivos;
            } catch (NumberFormatException ignored) {}
        }

        String unicoArquivo = getEnvOrProp("AWS_ARQUIVO_ANAC", "anac_part_001.xlsx");
        arquivos.add(unicoArquivo);
        return arquivos;
    }

    public ResultadoLeitura extrairDados() {
        String arquivo = getEnvOrProp("AWS_ARQUIVO_ANAC", "anac_part_001.xlsx");
        return extrairDadosDoArquivo(arquivo);
    }

    // ---------------------------------------------------------------
    // Baixa arquivo do S3 para disco e extrai dados
    // ---------------------------------------------------------------
    public ResultadoLeitura extrairDadosDoArquivo(String nomeArquivo) {
        String bucket = obterBucket();
        Region regiao = obterRegiao();

        System.out.println("Conectando ao S3...");
        System.out.printf("Bucket : %s%n", bucket);
        System.out.printf("Arquivo: %s%n", nomeArquivo);
        System.out.printf("Regiao : %s%n", regiao.id());

        java.io.File tempFile = null;
        try (S3Client s3 = criarClienteS3(regiao)) {
            GetObjectRequest pedido = GetObjectRequest.builder().bucket(bucket).key(nomeArquivo).build();

            tempFile = java.io.File.createTempFile("anac_", ".xlsx");
            tempFile.deleteOnExit();
            System.out.println("Baixando arquivo do S3 para disco temporario: " + tempFile.getAbsolutePath());
            try (InputStream stream = s3.getObject(pedido);
                 java.io.FileOutputStream fos = new java.io.FileOutputStream(tempFile)) {
                stream.transferTo(fos);
            }
            System.out.printf("Download concluido: %d bytes%n", tempFile.length());

            ResultadoLeitura resultado = extrairDeArquivo(tempFile);
            resultado.nomeArquivo = nomeArquivo;
            return resultado;

        } catch (Exception e) {
            throw new RuntimeException("Erro ao obter planilha do S3 (" + nomeArquivo + "): " + e.getMessage(), e);
        } finally {
            if (tempFile != null && tempFile.exists()) {
                tempFile.delete();
            }
        }
    }

    // ---------------------------------------------------------------
    // Leitura via StAX streaming (baixíssimo uso de memória)
    // Lê a sheet XML célula por célula sem carregar o documento inteiro.
    // ---------------------------------------------------------------
    public ResultadoLeitura extrairDeArquivo(java.io.File arquivo) {
        ResultadoLeitura resultado = new ResultadoLeitura();
        IOUtils.setByteArrayMaxOverride(1_000_000_000);

        ZipSecureFile.setMaxEntrySize(Long.MAX_VALUE);
        ZipSecureFile.setMaxTextSize(Long.MAX_VALUE);
        ZipSecureFile.setMinInflateRatio(0.0);

        try (OPCPackage pkg = OPCPackage.open(arquivo, PackageAccess.READ)) {
            System.out.println("Iniciando leitura do workbook (StAX streaming)...");

            XSSFReader xssfReader = new XSSFReader(pkg);
            SharedStrings sharedStrings = new ReadOnlySharedStringsTable(pkg);

            SheetIterator sheetIterator = (SheetIterator) xssfReader.getSheetsData();
            if (!sheetIterator.hasNext()) {
                throw new RuntimeException("Nenhuma sheet encontrada no arquivo.");
            }

            try (InputStream sheetStream = sheetIterator.next()) {
                String sheetName = sheetIterator.getSheetName();
                System.out.println("Lendo sheet: " + sheetName);

                XMLInputFactory xmlFactory = XMLInputFactory.newInstance();
                // Proteção contra XXE
                xmlFactory.setProperty(XMLInputFactory.IS_SUPPORTING_EXTERNAL_ENTITIES, false);
                xmlFactory.setProperty(XMLInputFactory.SUPPORT_DTD, false);
                XMLStreamReader xml = xmlFactory.createXMLStreamReader(sheetStream);

                // Mapa de coluna (índice) -> nome do cabeçalho
                String[] cabecalho = null;
                // Linha atual: mapa colIndex -> valor
                Map<Integer, String> currentRow = new HashMap<>();
                // Tipo de cada célula na linha atual
                Map<Integer, String> currentTypes = new HashMap<>();
                int currentRowNum = -1;
                boolean inRow = false;
                boolean inCell = false;
                boolean inV = false;
                int currentCol = -1;
                String currentType = null;
                StringBuilder currentVal = new StringBuilder();

                while (xml.hasNext()) {
                    int event = xml.next();

                    switch (event) {
                        case XMLStreamReader.START_ELEMENT:
                            String localName = xml.getLocalName();

                            if ("row".equals(localName)) {
                                inRow = true;
                                currentRow.clear();
                                currentTypes.clear();
                                String r = xml.getAttributeValue(null, "r");
                                currentRowNum = r != null ? Integer.parseInt(r) - 1 : -1;
                            } else if ("c".equals(localName) && inRow) {
                                inCell = true;
                                String r = xml.getAttributeValue(null, "r");
                                currentCol = refToColIndex(r);
                                currentType = xml.getAttributeValue(null, "t");
                                currentVal.setLength(0);
                            } else if ("v".equals(localName) && inCell) {
                                inV = true;
                            } else if ("t".equals(localName) && inCell) {
                                // inlineStr: <c t="inlineStr"><is><t>valor</t></is></c>
                                inV = true;
                            }
                            break;

                        case XMLStreamReader.CHARACTERS:
                            if (inV) {
                                currentVal.append(xml.getText());
                            }
                            break;

                        case XMLStreamReader.END_ELEMENT:
                            String endName = xml.getLocalName();

                            if ("v".equals(endName) || "t".equals(endName)) {
                                inV = false;
                            } else if ("c".equals(endName) && inCell) {
                                inCell = false;
                                String val = currentVal.toString();
                                // Resolve shared string se tipo "s"
                                if ("s".equals(currentType) && !val.isEmpty()) {
                                    try {
                                        int sstIdx = Integer.parseInt(val);
                                        val = sharedStrings.getItemAt(sstIdx).getString();
                                    } catch (Exception ignored) {
                                        val = "";
                                    }
                                }
                                if (currentCol >= 0 && val != null && !val.isEmpty()) {
                                    currentRow.put(currentCol, val);
                                    currentTypes.put(currentCol, currentType);
                                }
                            } else if ("row".equals(endName) && inRow) {
                                inRow = false;

                                // Processa a linha
                                if (currentRowNum == 0 || cabecalho == null) {
                                    // Linha de cabeçalho
                                    int maxCol = 0;
                                    for (Integer k : currentRow.keySet()) {
                                        if (k > maxCol) maxCol = k;
                                    }
                                    cabecalho = new String[maxCol + 1];
                                    for (Map.Entry<Integer, String> e : currentRow.entrySet()) {
                                        cabecalho[e.getKey()] = e.getValue() != null ? e.getValue().toLowerCase() : "";
                                    }
                                    System.out.println("Total de colunas indexadas: " + cabecalho.length);
                                } else {
                                    resultado.linhasEncontradas++;
                                    boolean linhaValida = processarLinha(currentRow, currentTypes, cabecalho, resultado);
                                    if (linhaValida) {
                                        resultado.linhasLidas++;
                                    } else {
                                        resultado.linhasRejeitadas++;
                                    }
                                }
                            }
                            break;
                    }
                }

                xml.close();
            }

            // Status
            if (resultado.linhasRejeitadas == 0) {
                resultado.statusLeitura = "LIDO";
            } else if (resultado.linhasLidas > 0) {
                resultado.statusLeitura = "PARCIALMENTE_LIDO";
            } else {
                resultado.statusLeitura = "ERRO_NA_LEITURA";
            }

            printarLinhas();
            System.out.println("Leitura do arquivo finalizada");
            System.out.println("Linhas encontradas : " + resultado.linhasEncontradas);
            System.out.println("Linhas lidas       : " + resultado.linhasLidas);
            System.out.println("Linhas rejeitadas  : " + resultado.linhasRejeitadas);
            System.out.println("Status             : " + resultado.statusLeitura);
            System.out.println("Companhias : " + resultado.companhias.size());
            System.out.println("Avioes     : " + resultado.avioes.size());
            System.out.println("Voos       : " + resultado.voos.size());
            System.out.println("Aeroportos : " + resultado.aeroportos.size());
            System.out.println("Direcoes   : " + resultado.aeroportoDirecoes.size());
            printarLinhas();

        } catch (Exception e) {
            resultado.statusLeitura = "ERRO_NA_LEITURA";
            resultado.detalheErro = e.getMessage();
            throw new RuntimeException("Erro ao ler a planilha: " + e.getMessage(), e);
        }

        return resultado;
    }

    // ---------------------------------------------------------------
    // Processa uma linha e extrai entidades
    // ---------------------------------------------------------------
    private boolean processarLinha(Map<Integer, String> row, Map<Integer, String> types,
                                    String[] cabecalho, ResultadoLeitura resultado) {
        boolean linhaValida = false;

        // --- Companhia ---
        Integer codEmpresa = getValInt(row, cabecalho, "id_empresa");
        String nmEmpresa = getValStr(row, cabecalho, "nm_empresa");
        String paisEmpresa = getValStr(row, cabecalho, "nm_pais");
        if (paisEmpresa == null || paisEmpresa.isEmpty()) {
            paisEmpresa = getValStr(row, cabecalho, "nm_pais_origem");
        }
        if (codEmpresa != null && nmEmpresa != null && !nmEmpresa.isEmpty()) {
            Companhia c = new Companhia();
            c.codCompanhia = codEmpresa;
            c.nomeCompanhia = nmEmpresa;
            c.paisCompanhia = (paisEmpresa != null && !paisEmpresa.isEmpty()) ? paisEmpresa : "BRASIL";
            resultado.companhias.add(c);
            linhaValida = true;
        }

        // --- Aviao ---
        String modelo = getValStr(row, cabecalho, "ds_modelo");
        Integer assentos = getValInt(row, cabecalho, "nr_assentos_ofertados");
        if (modelo != null && !modelo.isEmpty()) {
            Aviao a = new Aviao();
            a.modelo = modelo;
            a.numAssentos = assentos != null ? assentos : 0;
            resultado.avioes.add(a);
            linhaValida = true;
        }

        // --- Voo ---
        Integer nrVoo = getValInt(row, cabecalho, "nr_voo");
        Integer tipoVoo = getValInt(row, cabecalho, "cd_di");
        Integer passPagos = getValInt(row, cabecalho, "nr_passag_pagos");
        Integer passGratis = getValInt(row, cabecalho, "nr_passag_gratis");
        int qtdPass = (passPagos != null ? passPagos : 0) + (passGratis != null ? passGratis : 0);
        if (nrVoo != null) {
            Voo v = new Voo();
            v.numVoo = nrVoo;
            v.tipoVoo = tipoVoo != null ? tipoVoo : 0;
            v.qtdPassageiros = qtdPass;
            resultado.voos.add(v);
            linhaValida = true;
        }

        // --- Aeroporto Origem ---
        String nmAeroOrig = getValStr(row, cabecalho, "nm_aerodromo_origem");
        String icaoOrig = getValStr(row, cabecalho, "sg_icao_origem");
        if (nmAeroOrig != null && !nmAeroOrig.isEmpty()) {
            Aeroporto orig = new Aeroporto();
            orig.nomeAeroporto = nmAeroOrig;
            orig.municipio = getValStr(row, cabecalho, "nm_municipio_origem");
            orig.uf = getValStr(row, cabecalho, "sg_uf_origem");
            orig.regiao = getValStr(row, cabecalho, "nm_regiao_origem");
            orig.pais = getValStr(row, cabecalho, "nm_pais_origem");
            orig.icao = icaoOrig;
            resultado.aeroportos.add(orig);
            linhaValida = true;
        }

        // --- Aeroporto Destino ---
        String nmAeroDest = getValStr(row, cabecalho, "nm_aerodromo_destino");
        String icaoDest = getValStr(row, cabecalho, "sg_icao_destino");
        if (nmAeroDest != null && !nmAeroDest.isEmpty()) {
            Aeroporto dest = new Aeroporto();
            dest.nomeAeroporto = nmAeroDest;
            dest.municipio = getValStr(row, cabecalho, "nm_municipio_destino");
            dest.uf = getValStr(row, cabecalho, "sg_uf_destino");
            dest.regiao = getValStr(row, cabecalho, "nm_regiao_destino");
            dest.pais = getValStr(row, cabecalho, "nm_pais_destino");
            dest.icao = icaoDest;
            resultado.aeroportos.add(dest);
            linhaValida = true;
        }

        // --- AeroportoDirecao Partida ---
        LocalDate dtPart = getValDate(row, cabecalho, "dt_partida_real");
        LocalTime hrPart = getValTime(row, cabecalho, "hr_partida_real");
        if (dtPart != null && hrPart != null) {
            AeroportoDirecao p = new AeroportoDirecao();
            p.direcao = "Partida";
            p.dia = dtPart;
            p.hora = hrPart;
            resultado.aeroportoDirecoes.add(p);
        }

        // --- AeroportoDirecao Destino ---
        LocalDate dtCheg = getValDate(row, cabecalho, "dt_chegada_real");
        LocalTime hrCheg = getValTime(row, cabecalho, "hr_chegada_real");
        if (dtCheg != null && hrCheg != null) {
            AeroportoDirecao c = new AeroportoDirecao();
            c.direcao = "Destino";
            c.dia = dtCheg;
            c.hora = hrCheg;
            resultado.aeroportoDirecoes.add(c);
        }

        return linhaValida;
    }

    // ---------------------------------------------------------------
    // Converte referência "AB12" em índice de coluna (0-based)
    // ---------------------------------------------------------------
    private int refToColIndex(String ref) {
        if (ref == null || ref.isEmpty()) return 0;
        int col = 0;
        for (int i = 0; i < ref.length(); i++) {
            char c = ref.charAt(i);
            if (c >= 'A' && c <= 'Z') {
                col = col * 26 + (c - 'A' + 1);
            } else if (c >= 'a' && c <= 'z') {
                col = col * 26 + (c - 'a' + 1);
            } else {
                break;
            }
        }
        return col - 1;
    }

    // ---------------------------------------------------------------
    // Busca índice de coluna pelo nome
    // ---------------------------------------------------------------
    private int indiceColuna(String[] cabecalho, String nomeColuna) {
        String nomeBusca = nomeColuna.toLowerCase();
        for (int i = 0; i < cabecalho.length; i++) {
            if (nomeBusca.equals(cabecalho[i])) {
                return i;
            }
        }
        return -1;
    }

    // ---------------------------------------------------------------
    // Leitores de célula — operam sobre Map<Integer, String>
    // ---------------------------------------------------------------
    private String getValStr(Map<Integer, String> row, String[] cabecalho, String nomeColuna) {
        int idx = indiceColuna(cabecalho, nomeColuna);
        if (idx == -1) return null;
        return row.get(idx);
    }

    private Integer getValInt(Map<Integer, String> row, String[] cabecalho, String nomeColuna) {
        String val = getValStr(row, cabecalho, nomeColuna);
        if (val == null || val.isEmpty()) return null;
        try {
            return (int) Double.parseDouble(val);
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private LocalDate getValDate(Map<Integer, String> row, String[] cabecalho, String nomeColuna) {
        String val = getValStr(row, cabecalho, nomeColuna);
        if (val == null || val.isEmpty()) return null;
        try {
            // Serial date Excel epoch: 1899-12-30
            double d = Double.parseDouble(val);
            return LocalDate.of(1899, 12, 30).plusDays((long) d);
        } catch (NumberFormatException nfe) {
            try {
                if (val.contains("-")) {
                    return LocalDate.parse(val, FMT_DATA);
                } else if (val.contains("/")) {
                    return LocalDate.parse(val, FMT_DATA_BR);
                }
            } catch (Exception ignored) {}
        }
        return null;
    }

    private LocalTime getValTime(Map<Integer, String> row, String[] cabecalho, String nomeColuna) {
        String val = getValStr(row, cabecalho, nomeColuna);
        if (val == null || val.isEmpty()) return null;
        try {
            // Fração do dia (ex: 0.5 = 12:00:00)
            double d = Double.parseDouble(val);
            double fraction = d - (long) d;
            int seconds = (int) (fraction * 24 * 60 * 60);
            return LocalTime.ofSecondOfDay(seconds);
        } catch (NumberFormatException nfe) {
            try {
                return LocalTime.parse(val, FMT_HORA);
            } catch (Exception ignored) {}
        }
        return null;
    }

    private void printarLinhas() {
        System.out.println("-".repeat(40));
    }
}
