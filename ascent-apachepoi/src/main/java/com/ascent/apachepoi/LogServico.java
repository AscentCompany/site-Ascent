package com.ascent.apachepoi;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

public class LogServico {

    private Integer idLogServico;
    private String categoria;
    private String servico;
    private String mensagem;
    private LocalDateTime dataHora;
    private String origemCadastro;
    private Integer fkUsuario;

    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    public LogServico() {}

    public LogServico(Integer idLogServico, String categoria, String servico, String mensagem, LocalDateTime dataHora, String origemCadastro, Integer fkUsuario) {
        this.idLogServico = idLogServico;
        this.categoria = categoria;
        this.servico = servico;
        this.mensagem = mensagem;
        this.dataHora = dataHora;
        this.origemCadastro = origemCadastro;
        this.fkUsuario = fkUsuario;
    }

    public Integer getIdLogServico() {
        return idLogServico;
    }

    public void setIdLogServico(Integer idLogServico) {
        this.idLogServico = idLogServico;
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

    public String formatarLog() {
        String dataHoraFormatada = (dataHora != null) ? dataHora.format(FORMATTER) : "SEM_DATA";
        return String.format("[%s] [%s] [%s] %s (ID: %s, Origem: %s)",
                dataHoraFormatada,
                categoria,
                servico,
                mensagem,
                idLogServico != null ? idLogServico : "N/A",
                origemCadastro != null ? origemCadastro : "N/A"
        );
    }

    @Override
    public String toString() {
        return formatarLog();
    }
}
