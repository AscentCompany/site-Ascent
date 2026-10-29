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

    private static final DateTimeFormatter FMT_DATA    = DateTimeFormatter.ofPattern("yyyy-MM-dd");
    private static final DateTimeFormatter FMT_DATA_BR = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    private static final DateTimeFormatter FMT_HORA    = DateTimeFormatter.ofPattern("HH:mm:ss");

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

    public ResultadoLeitura extrairDeArquivo(java.io.File arquivo) {
        ResultadoLeitura resultado = new ResultadoLeitura();
        IOUtils.setByteArrayMaxOverride(1_000_000_000);

        ZipSecureFile.setMaxEntrySize(Long.MAX_VALUE);
        ZipSecureFile.setMaxTextSize(Long.MAX_VALUE);
        ZipSecureFile.setMinInflateRatio(0.0);

        try (OPCPackage pkg = OPCPackage.open(arquivo, PackageAccess.READ)) {

            XSSFReader    xssfReader    = new XSSFReader(pkg);
            SharedStrings sharedStrings = new ReadOnlySharedStringsTable(pkg);

            SheetIterator sheetIterator = (SheetIterator) xssfReader.getSheetsData();
            if (!sheetIterator.hasNext()) {
                throw new RuntimeException("Nenhuma sheet encontrada no arquivo.");
            }

            try (InputStream sheetStream = sheetIterator.next()) {

                XMLInputFactory xmlFactory = XMLInputFactory.newInstance();
                xmlFactory.setProperty(XMLInputFactory.IS_SUPPORTING_EXTERNAL_ENTITIES, false);
                xmlFactory.setProperty(XMLInputFactory.SUPPORT_DTD, false);
                XMLStreamReader xml = xmlFactory.createXMLStreamReader(sheetStream);

                String[] cabecalho = null;
                Map<Integer, String> currentRow   = new HashMap<>();
                Map<Integer, String> currentTypes = new HashMap<>();
                int     currentRowNum = -1;
                boolean inRow         = false;
                boolean inCell        = false;
                boolean inV           = false;
                int     currentCol    = -1;
                String  currentType   = null;
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
                                if (r != null) {
                                    currentRowNum = Integer.parseInt(r) - 1;
                                } else {
                                    currentRowNum = -1;
                                }
                            } else if ("c".equals(localName) && inRow) {
                                inCell = true;
                                String r = xml.getAttributeValue(null, "r");
                                currentCol  = refToColIndex(r);
                                currentType = xml.getAttributeValue(null, "t");
                                currentVal.setLength(0);
                            } else if ("v".equals(localName) && inCell) {
                                inV = true;
                            } else if ("t".equals(localName) && inCell) {
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

                                if (currentRowNum == 0 || cabecalho == null) {
                                    int maxCol = 0;
                                    for (Integer k : currentRow.keySet()) {
                                        if (k > maxCol) maxCol = k;
                                    }
                                    cabecalho = new String[maxCol + 1];
                                    for (Map.Entry<Integer, String> e : currentRow.entrySet()) {
                                        if (e.getValue() != null) {
                                            cabecalho[e.getKey()] = e.getValue().toLowerCase();
                                        } else {
                                            cabecalho[e.getKey()] = "";
                                        }
                                    }
                                } else {
                                    if (resultado.linhasLidas >= 5) {
                                        xml.close();
                                        break;
                                    }
                                    resultado.linhasEncontradas++;
                                    boolean linhaValida = processarLinha(currentRow, currentTypes, cabecalho, resultado);
                                    if (linhaValida) {
                                        resultado.linhasLidas++;
                                        System.out.printf("[%s] Linha %d lida%n",
                                            java.time.LocalTime.now().format(java.time.format.DateTimeFormatter.ofPattern("HH:mm:ss")),
                                            resultado.linhasLidas);
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

            if (resultado.linhasRejeitadas == 0) {
                resultado.statusLeitura = "LIDO";
            } else if (resultado.linhasLidas > 0) {
                resultado.statusLeitura = "PARCIALMENTE_LIDO";
            } else {
                resultado.statusLeitura = "ERRO_NA_LEITURA";
            }

        } catch (Exception e) {
            resultado.statusLeitura = "ERRO_NA_LEITURA";
            resultado.detalheErro   = e.getMessage();
            throw new RuntimeException("Erro ao ler a planilha: " + e.getMessage(), e);
        }

        return resultado;
    }

    private boolean processarLinha(Map<Integer, String> row, Map<Integer, String> types,
                                    String[] cabecalho, ResultadoLeitura resultado) {
        boolean linhaValida = false;

        Integer codEmpresa  = getValInt(row, cabecalho, "id_empresa");
        String  nmEmpresa   = getValStr(row, cabecalho, "nm_empresa");
        String  paisEmpresa = getValStr(row, cabecalho, "nm_pais");
        if (paisEmpresa == null || paisEmpresa.isEmpty()) {
            paisEmpresa = getValStr(row, cabecalho, "nm_pais_origem");
        }
        if (codEmpresa != null && nmEmpresa != null && !nmEmpresa.isEmpty()) {
            Companhia c = new Companhia();
            c.codCompanhia  = codEmpresa;
            c.nomeCompanhia = nmEmpresa;
            if (paisEmpresa != null && !paisEmpresa.isEmpty()) {
                c.paisCompanhia = paisEmpresa;
            } else {
                c.paisCompanhia = "BRASIL";
            }
            resultado.companhias.add(c);
            linhaValida = true;
        }

        String  modelo   = getValStr(row, cabecalho, "ds_modelo");
        Integer assentos = getValInt(row, cabecalho, "nr_assentos_ofertados");
        if (modelo != null && !modelo.isEmpty()) {
            Aviao a = new Aviao();
            a.modelo = modelo;
            if (assentos != null) {
                a.numAssentos = assentos;
            } else {
                a.numAssentos = 0;
            }
            resultado.avioes.add(a);
            linhaValida = true;
        }

        Integer nrVoo      = getValInt(row, cabecalho, "nr_voo");
        Integer tipoVoo    = getValInt(row, cabecalho, "cd_di");
        Integer passPagos  = getValInt(row, cabecalho, "nr_passag_pagos");
        Integer passGratis = getValInt(row, cabecalho, "nr_passag_gratis");
        int pagos;
        if (passPagos != null) {
            pagos = passPagos;
        } else {
            pagos = 0;
        }
        int gratis;
        if (passGratis != null) {
            gratis = passGratis;
        } else {
            gratis = 0;
        }
        int qtdPass = pagos + gratis;
        if (nrVoo != null) {
            Voo v = new Voo();
            v.numVoo = nrVoo;
            if (tipoVoo != null) {
                v.tipoVoo = tipoVoo;
            } else {
                v.tipoVoo = 0;
            }
            v.qtdPassageiros = qtdPass;
            resultado.voos.add(v);
            linhaValida = true;
        }

        String nmAeroOrig = getValStr(row, cabecalho, "nm_aerodromo_origem");
        String icaoOrig   = getValStr(row, cabecalho, "sg_icao_origem");
        if (nmAeroOrig != null && !nmAeroOrig.isEmpty()) {
            Aeroporto orig = new Aeroporto();
            orig.nomeAeroporto = nmAeroOrig;
            orig.municipio     = getValStr(row, cabecalho, "nm_municipio_origem");
            orig.uf            = getValStr(row, cabecalho, "sg_uf_origem");
            orig.regiao        = getValStr(row, cabecalho, "nm_regiao_origem");
            orig.pais          = getValStr(row, cabecalho, "nm_pais_origem");
            orig.icao          = icaoOrig;
            resultado.aeroportos.add(orig);
            linhaValida = true;
        }

        String nmAeroDest = getValStr(row, cabecalho, "nm_aerodromo_destino");
        String icaoDest   = getValStr(row, cabecalho, "sg_icao_destino");
        if (nmAeroDest != null && !nmAeroDest.isEmpty()) {
            Aeroporto dest = new Aeroporto();
            dest.nomeAeroporto = nmAeroDest;
            dest.municipio     = getValStr(row, cabecalho, "nm_municipio_destino");
            dest.uf            = getValStr(row, cabecalho, "sg_uf_destino");
            dest.regiao        = getValStr(row, cabecalho, "nm_regiao_destino");
            dest.pais          = getValStr(row, cabecalho, "nm_pais_destino");
            dest.icao          = icaoDest;
            resultado.aeroportos.add(dest);
            linhaValida = true;
        }

        LocalDate dtPart = getValDate(row, cabecalho, "dt_partida_real");
        LocalTime hrPart = getValTime(row, cabecalho, "hr_partida_real");
        if (dtPart != null && hrPart != null) {
            AeroportoDirecao p = new AeroportoDirecao();
            p.direcao = "Partida";
            p.dia     = dtPart;
            p.hora    = hrPart;
            resultado.aeroportoDirecoes.add(p);
        }

        LocalDate dtCheg = getValDate(row, cabecalho, "dt_chegada_real");
        LocalTime hrCheg = getValTime(row, cabecalho, "hr_chegada_real");
        if (dtCheg != null && hrCheg != null) {
            AeroportoDirecao c = new AeroportoDirecao();
            c.direcao = "Destino";
            c.dia     = dtCheg;
            c.hora    = hrCheg;
            resultado.aeroportoDirecoes.add(c);
        }

        return linhaValida;
    }

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

    private int indiceColuna(String[] cabecalho, String nomeColuna) {
        String nomeBusca = nomeColuna.toLowerCase();
        for (int i = 0; i < cabecalho.length; i++) {
            if (nomeBusca.equals(cabecalho[i])) {
                return i;
            }
        }
        return -1;
    }

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
            double d        = Double.parseDouble(val);
            double fraction = d - (long) d;
            int    seconds  = (int) (fraction * 24 * 60 * 60);
            return LocalTime.ofSecondOfDay(seconds);
        } catch (NumberFormatException nfe) {
            try {
                return LocalTime.parse(val, FMT_HORA);
            } catch (Exception ignored) {}
        }
        return null;
    }
}
