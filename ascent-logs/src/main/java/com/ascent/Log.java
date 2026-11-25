package com.ascent;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

public class Log {

    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private Integer logId;
    private String categoria;
    private String servico;
    private String mensagem;
    private LocalDateTime dataHora;
    private String origemCadastro;
    private Integer fkUsuario;

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

    public Integer getFkUsuario() {
        return fkUsuario;
    }

    public void setFkUsuario(Integer fkUsuario) {
        this.fkUsuario = fkUsuario;
    }

    @Override
    public String toString() {
        String dataHoraFormatada = dataHora != null ? dataHora.format(FORMATTER) : "SEM_DATA";
        return String.format("[%s] [%s] [%s] %s (LogID: %s, AutorID: %s, Origem: %s)",
                dataHoraFormatada,
                categoria != null ? categoria : "N/A",
                servico != null ? servico : "N/A",
                mensagem != null ? mensagem : "N/A",
                logId != null ? logId : "N/A",
                fkUsuario != null ? fkUsuario : "SISTEMA",
                origemCadastro != null ? origemCadastro : "N/A");
    }


}
