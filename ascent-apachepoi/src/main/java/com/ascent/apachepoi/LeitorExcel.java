package com.ascent.apachepoi;

import org.apache.poi.openxml4j.opc.OPCPackage;
import org.apache.poi.openxml4j.opc.PackageAccess;
import org.apache.poi.openxml4j.util.ZipSecureFile;
import org.apache.poi.util.IOUtils;
import org.apache.poi.xssf.eventusermodel.ReadOnlySharedStringsTable;
import org.apache.poi.xssf.eventusermodel.XSSFReader;
import org.apache.poi.xssf.eventusermodel.XSSFReader.SheetIterator;
import org.apache.poi.xssf.model.SharedStrings;

import javax.xml.stream.XMLInputFactory;
import javax.xml.stream.XMLStreamReader;
import java.io.File;
import java.io.InputStream;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class LeitorExcel {

    private static final DateTimeFormatter FMT_DATA    = DateTimeFormatter.ofPattern("yyyy-MM-dd");
    private static final DateTimeFormatter FMT_DATA_BR = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    private static final DateTimeFormatter FMT_HORA    = DateTimeFormatter.ofPattern("HH:mm:ss");

    // <editor-fold desc="ResultadoLeitura">
    public static class ResultadoLeitura {

        private List<Companhia>        companhias        = new ArrayList<>();
        private List<Aviao>            avioes            = new ArrayList<>();
        private List<Voo>              voos              = new ArrayList<>();
        private List<Aeroporto>        aeroportos        = new ArrayList<>();
        private List<AeroportoDirecao> aeroportoDirecoes = new ArrayList<>();

        private String nomeArquivo       = null;
        private int    linhasEncontradas = 0;
        private int    linhasLidas       = 0;
        private int    linhasRejeitadas  = 0;
        private String statusLeitura     = "LIDO";
        private String detalheErro       = null;

        public List<Companhia> getCompanhias() { return companhias; }
        public List<Aviao> getAvioes() { return avioes; }
        public List<Voo> getVoos() { return voos; }
        public List<Aeroporto> getAeroportos() { return aeroportos; }
        public List<AeroportoDirecao> getAeroportoDirecoes() { return aeroportoDirecoes; }

        public String getNomeArquivo() { return nomeArquivo; }
        public void setNomeArquivo(String nomeArquivo) { this.nomeArquivo = nomeArquivo; }

        public int getLinhasEncontradas() { return linhasEncontradas; }
        public int getLinhasLidas() { return linhasLidas; }
        public int getLinhasRejeitadas() { return linhasRejeitadas; }
        public String getStatusLeitura() { return statusLeitura; }
        public String getDetalheErro() { return detalheErro; }

        @Override
        public String toString() {
            return String.format("ResultadoLeitura{arquivo='%s', lidas=%d, rejeitadas=%d, status='%s'}",
                    nomeArquivo, linhasLidas, linhasRejeitadas, statusLeitura);
        }
    }
    // </editor-fold>

    public ResultadoLeitura extrairDeArquivo(File arquivo) {
        ResultadoLeitura resultado = new ResultadoLeitura();
        resultado.setNomeArquivo(arquivo.getName());

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
                Map<Integer, String> linhaAtual  = new HashMap<>();
                Map<Integer, String> tiposAtual  = new HashMap<>();
                int     numLinha     = -1;
                boolean emLinha      = false;
                boolean emCelula     = false;
                boolean emValor      = false;
                int     colunaAtual  = -1;
                String  tipoAtual    = null;
                StringBuilder valorAtual = new StringBuilder();

                while (xml.hasNext()) {
                    int evento = xml.next();

                    switch (evento) {
                        case XMLStreamReader.START_ELEMENT -> {
                            String tag = xml.getLocalName();
                            if ("row".equals(tag)) {
                                emLinha = true;
                                linhaAtual.clear();
                                tiposAtual.clear();
                                String r = xml.getAttributeValue(null, "r");
                                numLinha = r != null ? Integer.parseInt(r) - 1 : -1;
                            } else if ("c".equals(tag) && emLinha) {
                                emCelula    = true;
                                colunaAtual = refParaColuna(xml.getAttributeValue(null, "r"));
                                tipoAtual   = xml.getAttributeValue(null, "t");
                                valorAtual.setLength(0);
                            } else if (("v".equals(tag) || "t".equals(tag)) && emCelula) {
                                emValor = true;
                            }
                        }
                        case XMLStreamReader.CHARACTERS -> {
                            if (emValor) valorAtual.append(xml.getText());
                        }
                        case XMLStreamReader.END_ELEMENT -> {
                            String tag = xml.getLocalName();
                            if ("v".equals(tag) || "t".equals(tag)) {
                                emValor = false;
                            } else if ("c".equals(tag) && emCelula) {
                                emCelula = false;
                                String val = valorAtual.toString();
                                if ("s".equals(tipoAtual) && !val.isEmpty()) {
                                    try {
                                        val = sharedStrings.getItemAt(Integer.parseInt(val)).getString();
                                    } catch (Exception e) {
                                        val = "";
                                    }
                                }
                                if (colunaAtual >= 0 && !val.isEmpty()) {
                                    linhaAtual.put(colunaAtual, val);
                                    tiposAtual.put(colunaAtual, tipoAtual);
                                }
                            } else if ("row".equals(tag) && emLinha) {
                                emLinha = false;
                                if (numLinha == 0 || cabecalho == null) {
                                    cabecalho = construirCabecalho(linhaAtual);
                                } else {
                                    resultado.linhasEncontradas++;
                                    boolean valida = processarLinha(linhaAtual, cabecalho, resultado);
                                    if (valida) {
                                        resultado.linhasLidas++;
                                    } else {
                                        resultado.linhasRejeitadas++;
                                    }
                                }
                            }
                        }
                    }
                }
                xml.close();
            }

            resultado.statusLeitura = resultado.linhasRejeitadas == 0        ? "LIDO"
                                    : resultado.linhasLidas       > 0         ? "PARCIALMENTE_LIDO"
                                                                               : "ERRO_NA_LEITURA";

        } catch (Exception e) {
            resultado.statusLeitura = "ERRO_NA_LEITURA";
            resultado.detalheErro   = e.getMessage();
            throw new RuntimeException("Erro ao ler o arquivo " + arquivo.getName() + ": " + e.getMessage(), e);
        }

        return resultado;
    }

    // Monta o array de cabeçalho a partir da linha 0
    private String[] construirCabecalho(Map<Integer, String> linha) {
        int maxCol = linha.keySet().stream().mapToInt(i -> i).max().orElse(0);
        String[] cabecalho = new String[maxCol + 1];
        for (Map.Entry<Integer, String> e : linha.entrySet()) {
            cabecalho[e.getKey()] = e.getValue() != null ? e.getValue().toLowerCase() : "";
        }
        return cabecalho;
    }

    // Processa uma linha de dados — retorna false se algum campo obrigatório for nulo/inválido
    private boolean processarLinha(Map<Integer, String> linha, String[] cabecalho, ResultadoLeitura resultado) {

        // Campos obrigatórios: numVoo + codEmpresa + nmAerodromo (origem ou destino)
        Integer codEmpresa = getInt(linha, cabecalho, "id_empresa");
        Integer nrVoo      = getInt(linha, cabecalho, "nr_voo");
        String  nmAeroOrig = getStr(linha, cabecalho, "nm_aerodromo_origem");

        if (codEmpresa == null || nrVoo == null || nmAeroOrig == null || nmAeroOrig.isBlank()) {
            return false; // linha inválida — pula
        }

        // --- Companhia ---
        Companhia companhia = new Companhia();
        companhia.setCodCompanhia(codEmpresa);
        companhia.setNomeCompanhia(getStr(linha, cabecalho, "nm_empresa"));
        companhia.setPaisCompanhia(getStrOuPadrao(linha, cabecalho, "nm_pais_origem", "BRASIL"));
        companhia.setRazaoSocial("");
        companhia.setCnpj("");
        resultado.getCompanhias().add(companhia);

        // --- Aviao ---
        String modelo = getStr(linha, cabecalho, "ds_modelo");
        if (modelo != null && !modelo.isBlank()) {
            Aviao aviao = new Aviao();
            aviao.setModelo(modelo);
            aviao.setNumAssentos(getIntOuPadrao(linha, cabecalho, "nr_assentos_ofertados", 0));
            resultado.getAvioes().add(aviao);
        }

        // --- Voo ---
        Voo voo = new Voo();
        voo.setNumVoo(nrVoo);
        voo.setTipoVoo(getIntOuPadrao(linha, cabecalho, "cd_di", 0));
        int pagos   = getIntOuPadrao(linha, cabecalho, "nr_passag_pagos",   0);
        int gratis  = getIntOuPadrao(linha, cabecalho, "nr_passag_gratis",  0);
        voo.setQtdPassageiros(pagos + gratis);
        resultado.getVoos().add(voo);

        // --- Aeroporto Origem ---
        Aeroporto origem = new Aeroporto();
        origem.setNomeAeroporto(nmAeroOrig);
        origem.setMunicipio(getStr(linha, cabecalho, "nm_municipio_origem"));
        origem.setUf(getStr(linha, cabecalho, "sg_uf_origem"));
        origem.setRegiao(getStr(linha, cabecalho, "nm_regiao_origem"));
        origem.setPais(getStrOuPadrao(linha, cabecalho, "nm_pais_origem", "BRASIL"));
        origem.setIcao(getStr(linha, cabecalho, "sg_icao_origem"));
        resultado.getAeroportos().add(origem);

        // --- Aeroporto Destino ---
        String nmAeroDest = getStr(linha, cabecalho, "nm_aerodromo_destino");
        if (nmAeroDest != null && !nmAeroDest.isBlank()) {
            Aeroporto destino = new Aeroporto();
            destino.setNomeAeroporto(nmAeroDest);
            destino.setMunicipio(getStr(linha, cabecalho, "nm_municipio_destino"));
            destino.setUf(getStr(linha, cabecalho, "sg_uf_destino"));
            destino.setRegiao(getStr(linha, cabecalho, "nm_regiao_destino"));
            destino.setPais(getStrOuPadrao(linha, cabecalho, "nm_pais_destino", "BRASIL"));
            destino.setIcao(getStr(linha, cabecalho, "sg_icao_destino"));
            resultado.getAeroportos().add(destino);
        }

        // --- AeroportoDirecao Partida ---
        LocalDate dtPart = getDate(linha, cabecalho, "dt_partida_real");
        LocalTime hrPart = getTime(linha, cabecalho, "hr_partida_real");
        if (dtPart != null && hrPart != null) {
            AeroportoDirecao partida = new AeroportoDirecao();
            partida.setDirecao("Partida");
            partida.setDia(dtPart);
            partida.setHora(hrPart);
            resultado.getAeroportoDirecoes().add(partida);
        }

        // --- AeroportoDirecao Chegada ---
        LocalDate dtCheg = getDate(linha, cabecalho, "dt_chegada_real");
        LocalTime hrCheg = getTime(linha, cabecalho, "hr_chegada_real");
        if (dtCheg != null && hrCheg != null) {
            AeroportoDirecao chegada = new AeroportoDirecao();
            chegada.setDirecao("Destino");
            chegada.setDia(dtCheg);
            chegada.setHora(hrCheg);
            resultado.getAeroportoDirecoes().add(chegada);
        }

        return true;
    }

    // <editor-fold desc="Helpers de leitura de célula">

    private int refParaColuna(String ref) {
        if (ref == null || ref.isEmpty()) return 0;
        int col = 0;
        for (char c : ref.toCharArray()) {
            if (c >= 'A' && c <= 'Z') col = col * 26 + (c - 'A' + 1);
            else if (c >= 'a' && c <= 'z') col = col * 26 + (c - 'a' + 1);
            else break;
        }
        return col - 1;
    }

    private int indiceColuna(String[] cabecalho, String nome) {
        String busca = nome.toLowerCase();
        for (int i = 0; i < cabecalho.length; i++) {
            if (busca.equals(cabecalho[i])) return i;
        }
        return -1;
    }

    private String getStr(Map<Integer, String> linha, String[] cabecalho, String nome) {
        int idx = indiceColuna(cabecalho, nome);
        return idx == -1 ? null : linha.get(idx);
    }

    private String getStrOuPadrao(Map<Integer, String> linha, String[] cabecalho, String nome, String padrao) {
        String val = getStr(linha, cabecalho, nome);
        return (val != null && !val.isBlank()) ? val : padrao;
    }

    private Integer getInt(Map<Integer, String> linha, String[] cabecalho, String nome) {
        String val = getStr(linha, cabecalho, nome);
        if (val == null || val.isBlank()) return null;
        try { return (int) Double.parseDouble(val); }
        catch (NumberFormatException e) { return null; }
    }

    private int getIntOuPadrao(Map<Integer, String> linha, String[] cabecalho, String nome, int padrao) {
        Integer val = getInt(linha, cabecalho, nome);
        return val != null ? val : padrao;
    }

    private LocalDate getDate(Map<Integer, String> linha, String[] cabecalho, String nome) {
        String val = getStr(linha, cabecalho, nome);
        if (val == null || val.isBlank()) return null;
        try {
            double d = Double.parseDouble(val);
            return LocalDate.of(1899, 12, 30).plusDays((long) d);
        } catch (NumberFormatException e) {
            try { return val.contains("-") ? LocalDate.parse(val, FMT_DATA) : LocalDate.parse(val, FMT_DATA_BR); }
            catch (Exception ex) { return null; }
        }
    }

    private LocalTime getTime(Map<Integer, String> linha, String[] cabecalho, String nome) {
        String val = getStr(linha, cabecalho, nome);
        if (val == null || val.isBlank()) return null;
        try {
            double d = Double.parseDouble(val);
            int segundos = (int) ((d - (long) d) * 24 * 60 * 60);
            return LocalTime.ofSecondOfDay(segundos);
        } catch (NumberFormatException e) {
            try { return LocalTime.parse(val, FMT_HORA); }
            catch (Exception ex) { return null; }
        }
    }

    // </editor-fold>

    public static String getEnvOrProp(String chave, String padrao) {
        String val = System.getProperty(chave);
        if (val != null && !val.trim().isEmpty()) return val.trim();
        val = System.getenv(chave);
        if (val != null && !val.trim().isEmpty()) return val.trim();
        return padrao;
    }
}
