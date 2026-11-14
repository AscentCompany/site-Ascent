package com.ascent.apachepoi;

public class Companhia {

    private Integer codCompanhia;
    private String nomeCompanhia;
    private String paisCompanhia;
    private String razaoSocial;
    private String cnpj;

    public Companhia() {
    }

    public Companhia(Integer codCompanhia, String nomeCompanhia, String paisCompanhia, String razaoSocial, String cnpj) {
        this.codCompanhia = codCompanhia;
        this.nomeCompanhia = nomeCompanhia;
        this.paisCompanhia = paisCompanhia;
        this.razaoSocial = razaoSocial;
        this.cnpj = cnpj;
    }

    // <editor-fold desc="Getters e Setters">

    public Integer getCodCompanhia() {
        return codCompanhia;
    }

    public void setCodCompanhia(Integer codCompanhia) {
        this.codCompanhia = codCompanhia;
    }

    public String getNomeCompanhia() {
        return nomeCompanhia;
    }

    public void setNomeCompanhia(String nomeCompanhia) {
        this.nomeCompanhia = nomeCompanhia;
    }

    public String getPaisCompanhia() {
        return paisCompanhia;
    }

    public void setPaisCompanhia(String paisCompanhia) {
        this.paisCompanhia = paisCompanhia;
    }

    public String getRazaoSocial() {
        return razaoSocial;
    }

    public void setRazaoSocial(String razaoSocial) {
        this.razaoSocial = razaoSocial;
    }

    public String getCnpj() {
        return cnpj;
    }

    public void setCnpj(String cnpj) {
        this.cnpj = cnpj;
    }

    // </editor-fold>

    @Override
    public String toString() {
        return "Companhia{" +
                "codCompanhia=" + codCompanhia +
                ", nomeCompanhia='" + nomeCompanhia + '\'' +
                ", paisCompanhia='" + paisCompanhia + '\'' +
                '}';
    }
}
