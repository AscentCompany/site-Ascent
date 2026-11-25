package com.ascent.apachepoi;

import java.time.LocalDateTime;

public class LogLeitura extends LogServico {

    private String nomeArquivo;
    private StatusLeitura statusLeitura;
    private String statusLeitura;
    private Integer linhasEncontradas;
    private Integer linhasLidas;
    private Integer linhasRejeitadas;
    private String detalheErro;
    private Long idInicialVoo;

    public LogLeitura() {}

    public LogLeitura(Integer idLogServico, String categoria, String servico, String mensagem, LocalDateTime dataHora, String origemCadastro, Integer fkUsuario,
                      String nomeArquivo, StatusLeitura statusLeitura, Integer linhasEncontradas, Integer linhasLidas, Integer linhasRejeitadas, String detalheErro, Long idInicialVoo) {
                      String nomeArquivo, String statusLeitura, Integer linhasEncontradas, Integer linhasLidas, Integer linhasRejeitadas, String detalheErro, Long idInicialVoo) {
        super(idLogServico, categoria, servico, mensagem, dataHora, origemCadastro, fkUsuario);
        this.nomeArquivo = nomeArquivo;
        this.statusLeitura = statusLeitura;
        this.linhasEncontradas = linhasEncontradas;
        this.linhasLidas = linhasLidas;
        this.linhasRejeitadas = linhasRejeitadas;
        this.detalheErro = detalheErro;
        this.idInicialVoo = idInicialVoo;
    }

    public String getNomeArquivo() {
        return nomeArquivo;
    }

    public void setNomeArquivo(String nomeArquivo) {
        this.nomeArquivo = nomeArquivo;
    }

    public StatusLeitura getStatusLeitura() {
        return statusLeitura;
    }

    public void setStatusLeitura(StatusLeitura statusLeitura) {
    public String getStatusLeitura() {
        return statusLeitura;
    }

    public void setStatusLeitura(String statusLeitura) {
        this.statusLeitura = statusLeitura;
    }

    public Integer getLinhasEncontradas() {
        return linhasEncontradas;
    }

    public void setLinhasEncontradas(Integer linhasEncontradas) {
        this.linhasEncontradas = linhasEncontradas;
    }

    public Integer getLinhasLidas() {
        return linhasLidas;
    }

    public void setLinhasLidas(Integer linhasLidas) {
        this.linhasLidas = linhasLidas;
    }

    public Integer getLinhasRejeitadas() {
        return linhasRejeitadas;
    }

    public void setLinhasRejeitadas(Integer linhasRejeitadas) {
        this.linhasRejeitadas = linhasRejeitadas;
    }

    public String getDetalheErro() {
        return detalheErro;
    }

    public void setDetalheErro(String detalheErro) {
        this.detalheErro = detalheErro;
    }

    public Long getIdInicialVoo() {
        return idInicialVoo;
    }

    public void setIdInicialVoo(Long idInicialVoo) {
        this.idInicialVoo = idInicialVoo;
    }

    @Override
    public String formatarLog() {
        String texto = super.formatarLog();
        texto = texto + " | Arquivo: " + nomeArquivo + ", Status: " + statusLeitura;
        if (linhasEncontradas != null) {
            texto = texto + ", Encontradas: " + linhasEncontradas + ", Lidas: " + linhasLidas + ", Rejeitadas: " + linhasRejeitadas;
        }
        if (detalheErro != null) {
            texto = texto + ", Erro: " + detalheErro;
        }
        return texto;
    }
}

