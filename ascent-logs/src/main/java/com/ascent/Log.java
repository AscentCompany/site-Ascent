package com.ascent;

import java.time.LocalDateTime;

public class Log {

    private Integer logId;
    private String categoria;
    private String servico;
    private String mensagem;
    private LocalDateTime dataHora;
    private String origemCadastro;

    public Log() {}

    public Log(Integer logId, String categoria, String servico, String mensagem, LocalDateTime dataHora, String origemCadastro) {
        this.logId = logId;
        this.categoria = categoria;
        this.servico = servico;
        this.mensagem = mensagem;
        this.dataHora = dataHora;
        this.origemCadastro = origemCadastro;
    }

    public Log(String categoria, String servico, String mensagem, LocalDateTime dataHora, String origemCadastro) {
        this.categoria = categoria;
        this.servico = servico;
        this.mensagem = mensagem;
        this.dataHora = dataHora;
        this.origemCadastro = origemCadastro;
    }

    public Integer getLogId() {
        return logId;
    }

    public void setLogId(Integer logId) {
        this.logId = logId;
    }

    public String getCategoria() {
        return categoria;
    }

    public void setCategoria(String categoria) {
        this.categoria = categoria;
    }

    public String getServico() {
        return servico;
    }

    public void setServico(String servico) {
        this.servico = servico;
    }

    public String getMensagem() {
        return mensagem;
    }

    public void setMensagem(String mensagem) {
        this.mensagem = mensagem;
    }

    public LocalDateTime getDataHora() {
        return dataHora;
    }

    public void setDataHora(LocalDateTime dataHora) {
        this.dataHora = dataHora;
    }

    public String getOrigemCadastro() {
        return origemCadastro;
    }

    public void setOrigemCadastro(String origemCadastro) {
        this.origemCadastro = origemCadastro;
    }

    @Override
    public String toString() {
        return "Log{" +
                "logId=" + logId +
                ", categoria='" + categoria + '\'' +
                ", servico='" + servico + '\'' +
                ", mensagem='" + mensagem + '\'' +
                ", dataHora=" + dataHora +
                ", origemCadastro='" + origemCadastro + '\'' +
                '}';
    }


}
