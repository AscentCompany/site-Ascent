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
import java.util.Arrays;

public class LeitorExcel {

    private static final DateTimeFormatter FMT_DATA    = DateTimeFormatter.ofPattern("yyyy-MM-dd");
    private static final DateTimeFormatter FMT_DATA_BR = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    private static final DateTimeFormatter FMT_HORA    = DateTimeFormatter.ofPattern("HH:mm:ss");

    /**
     * Recebe cada linha válida assim que ela é lida da planilha.
     * Isso permite inserir no banco em lote sem guardar o arquivo inteiro na memória.
     */
    public abstract static class ConsumidorLinha {
        public abstract void consumir(LinhaVoo linha);
    }

    // Índices das colunas calculados uma única vez a partir do cabeçalho.
    private static final class Colunas {
        int codEmpresa;
        int nrVoo;
        int nmEmpresa;
        int nmPaisOrigem;
        int dsModelo;
        int nrAssentos;
        int cdDi;
        int nrPassagPagos;
        int nrPassagGratis;
        int nmAeroOrigem;
        int nmMunicipioOrigem;
        int sgUfOrigem;
        int nmRegiaoOrigem;
        int sgIcaoOrigem;
        int nmAeroDestino;
        int nmMunicipioDestino;
        int sgUfDestino;
        int nmRegiaoDestino;
        int nmPaisDestino;
        int sgIcaoDestino;
        int dtPartida;
        int hrPartida;
        int dtChegada;
        int hrChegada;
    }

    // <editor-fold desc="ResultadoLeitura">
    public static class ResultadoLeitura {

        private String nomeArquivo       = null;
        private int    linhasEncontradas = 0;
        private int    linhasLidas       = 0;
        private int    linhasRejeitadas  = 0;
        private String statusLeitura     = "LIDO";
        private String detalheErro       = null;

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

    /**
     * Lê o arquivo em streaming e entrega cada linha válida ao consumidor.
     * A validação de campos obrigatórios e de datas/horas nulas é mantida:
     * linhas inválidas são contadas como rejeitadas e não são consumidas.
     */
    public ResultadoLeitura ler(File arquivo, ConsumidorLinha consumidor) {
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

                Colunas colunas      = null;
                String[] linhaAtual  = new String[64];
                int     maiorColuna  = -1;
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
                                emLinha     = true;
                                maiorColuna = -1;
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
                                    if (colunaAtual >= linhaAtual.length) {
                                        linhaAtual = Arrays.copyOf(linhaAtual, colunaAtual + 16);
                                    }
                                    linhaAtual[colunaAtual] = val;
                                    if (colunaAtual > maiorColuna) maiorColuna = colunaAtual;
                                }
                            } else if ("row".equals(tag) && emLinha) {
                                emLinha = false;
                                if (colunas == null) {
                                    // A primeira linha do arquivo é o cabeçalho.
                                    colunas = construirColunas(linhaAtual, maiorColuna);
                                } else {
                                    resultado.linhasEncontradas++;
                                    LinhaVoo linha = processarLinha(linhaAtual, colunas);
                                    if (linha != null) {
                                        resultado.linhasLidas++;
                                        consumidor.consumir(linha);
                                    } else {
                                        resultado.linhasRejeitadas++;
                                    }
                                }
                                // Limpa apenas o trecho usado nesta linha para reutilizar o array.
                                if (maiorColuna >= 0) {
                                    Arrays.fill(linhaAtual, 0, maiorColuna + 1, null);
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

    // Monta os índices das colunas a partir do cabeçalho (executado uma vez por arquivo)
    private Colunas construirColunas(String[] linha, int maiorColuna) {
        String[] cabecalho = new String[maiorColuna + 1];
        for (int i = 0; i <= maiorColuna; i++) {
            cabecalho[i] = linha[i] != null ? linha[i].trim().toLowerCase() : "";
        }

        Colunas c = new Colunas();
        c.codEmpresa        = indiceColuna(cabecalho, "id_empresa");
        c.nrVoo             = indiceColuna(cabecalho, "nr_voo");
        c.nmEmpresa         = indiceColuna(cabecalho, "nm_empresa");
        c.nmPaisOrigem      = indiceColuna(cabecalho, "nm_pais_origem");
        c.dsModelo          = indiceColuna(cabecalho, "ds_modelo");
        c.nrAssentos        = indiceColuna(cabecalho, "nr_assentos_ofertados");
        c.cdDi              = indiceColuna(cabecalho, "cd_di");
        c.nrPassagPagos     = indiceColuna(cabecalho, "nr_passag_pagos");
        c.nrPassagGratis    = indiceColuna(cabecalho, "nr_passag_gratis");
        c.nmAeroOrigem      = indiceColuna(cabecalho, "nm_aerodromo_origem");
        c.nmMunicipioOrigem = indiceColuna(cabecalho, "nm_municipio_origem");
        c.sgUfOrigem        = indiceColuna(cabecalho, "sg_uf_origem");
        c.nmRegiaoOrigem    = indiceColuna(cabecalho, "nm_regiao_origem");
        c.sgIcaoOrigem      = indiceColuna(cabecalho, "sg_icao_origem");
        c.nmAeroDestino     = indiceColuna(cabecalho, "nm_aerodromo_destino");
        c.nmMunicipioDestino= indiceColuna(cabecalho, "nm_municipio_destino");
        c.sgUfDestino       = indiceColuna(cabecalho, "sg_uf_destino");
        c.nmRegiaoDestino   = indiceColuna(cabecalho, "nm_regiao_destino");
        c.nmPaisDestino     = indiceColuna(cabecalho, "nm_pais_destino");
        c.sgIcaoDestino     = indiceColuna(cabecalho, "sg_icao_destino");
        c.dtPartida         = indiceColuna(cabecalho, "dt_partida_real");
        c.hrPartida         = indiceColuna(cabecalho, "hr_partida_real");
        c.dtChegada         = indiceColuna(cabecalho, "dt_chegada_real");
        c.hrChegada         = indiceColuna(cabecalho, "hr_chegada_real");
        return c;
    }

    private LinhaVoo processarLinha(String[] linha, Colunas c) {

        Integer codEmpresa = getInt(linha, c.codEmpresa);
        Integer nrVoo      = getInt(linha, c.nrVoo);
        String  nmAeroOrig = getStr(linha, c.nmAeroOrigem);

        if (codEmpresa == null || nrVoo == null || nmAeroOrig == null || nmAeroOrig.isBlank()) {
            return null;
        }

        Companhia companhia = new Companhia();
        companhia.setCodCompanhia(codEmpresa);
        companhia.setNomeCompanhia(getStr(linha, c.nmEmpresa));
        companhia.setPaisCompanhia(getStrOuPadrao(linha, c.nmPaisOrigem, "BRASIL"));
        companhia.setRazaoSocial("");
        companhia.setCnpj("");

        Aviao aviao = null;
        String modelo = getStr(linha, c.dsModelo);
        if (modelo != null && !modelo.isBlank()) {
            aviao = new Aviao();
            aviao.setModelo(modelo);
            aviao.setNumAssentos(getIntOuPadrao(linha, c.nrAssentos, 0));
        }

        Voo voo = new Voo();
        voo.setNumVoo(nrVoo);
        voo.setTipoVoo(getIntOuPadrao(linha, c.cdDi, 0));
        int pagos  = getIntOuPadrao(linha, c.nrPassagPagos,  0);
        int gratis = getIntOuPadrao(linha, c.nrPassagGratis, 0);
        voo.setQtdPassageiros(pagos + gratis);

        Aeroporto origem = new Aeroporto();
        origem.setNomeAeroporto(nmAeroOrig);
        origem.setMunicipio(getStr(linha, c.nmMunicipioOrigem));
        origem.setUf(getStr(linha, c.sgUfOrigem));
        origem.setRegiao(getStr(linha, c.nmRegiaoOrigem));
        origem.setPais(getStrOuPadrao(linha, c.nmPaisOrigem, "BRASIL"));
        origem.setIcao(getStr(linha, c.sgIcaoOrigem));

        // --- Aeroporto Destino ---
        Aeroporto destino = null;
        String nmAeroDest = getStr(linha, c.nmAeroDestino);
        if (nmAeroDest != null && !nmAeroDest.isBlank()) {
            destino = new Aeroporto();
            destino.setNomeAeroporto(nmAeroDest);
            destino.setMunicipio(getStr(linha, c.nmMunicipioDestino));
            destino.setUf(getStr(linha, c.sgUfDestino));
            destino.setRegiao(getStr(linha, c.nmRegiaoDestino));
            destino.setPais(getStrOuPadrao(linha, c.nmPaisDestino, "BRASIL"));
            destino.setIcao(getStr(linha, c.sgIcaoDestino));
        }

        // --- AeroportoDirecao Partida ---
        AeroportoDirecao partida = null;
        LocalDate dtPart = getDate(linha, c.dtPartida);
        LocalTime hrPart = getTime(linha, c.hrPartida);
        if (dtPart != null && hrPart != null) {
            partida = new AeroportoDirecao();
            partida.setDirecao("Partida");
            partida.setDia(dtPart);
            partida.setHora(hrPart);
        }

        // --- AeroportoDirecao Chegada ---
        AeroportoDirecao chegada = null;
        LocalDate dtCheg = getDate(linha, c.dtChegada);
        LocalTime hrCheg = getTime(linha, c.hrChegada);
        if (dtCheg != null && hrCheg != null) {
            chegada = new AeroportoDirecao();
            chegada.setDirecao("Destino");
            chegada.setDia(dtCheg);
            chegada.setHora(hrCheg);
        }

        return new LinhaVoo(companhia, aviao, voo, origem, destino, partida, chegada);
    }

    // <editor-fold desc="Helpers de leitura de célula">

    private int refParaColuna(String ref) {
        if (ref == null || ref.isEmpty()) return 0;
        int col = 0;
        for (int i = 0; i < ref.length(); i++) {
            char c = ref.charAt(i);
            if (c >= 'A' && c <= 'Z') col = col * 26 + (c - 'A' + 1);
            else if (c >= 'a' && c <= 'z') col = col * 26 + (c - 'a' + 1);
            else break;
        }
        return col - 1;
    }

    private int indiceColuna(String[] cabecalho, String nome) {
        for (int i = 0; i < cabecalho.length; i++) {
            if (nome.equals(cabecalho[i])) return i;
        }
        return -1;
    }

    private String getStr(String[] linha, int idx) {
        if (idx < 0 || idx >= linha.length) return null;
        return linha[idx];
    }

    private String getStrOuPadrao(String[] linha, int idx, String padrao) {
        String val = getStr(linha, idx);
        return (val != null && !val.isBlank()) ? val : padrao;
    }

    private Integer getInt(String[] linha, int idx) {
        String val = getStr(linha, idx);
        if (val == null || val.isBlank()) return null;
        try { return (int) Double.parseDouble(val); }
        catch (NumberFormatException e) { return null; }
    }

    private int getIntOuPadrao(String[] linha, int idx, int padrao) {
        Integer val = getInt(linha, idx);
        return val != null ? val : padrao;
    }

    private LocalDate getDate(String[] linha, int idx) {
        String val = getStr(linha, idx);
        if (val == null || val.isBlank()) return null;
        try {
            double d = Double.parseDouble(val);
            return LocalDate.of(1899, 12, 30).plusDays((long) d);
        } catch (NumberFormatException e) {
            try { return val.contains("-") ? LocalDate.parse(val, FMT_DATA) : LocalDate.parse(val, FMT_DATA_BR); }
            catch (Exception ex) { return null; }
        }
    }

    private LocalTime getTime(String[] linha, int idx) {
        String val = getStr(linha, idx);
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
