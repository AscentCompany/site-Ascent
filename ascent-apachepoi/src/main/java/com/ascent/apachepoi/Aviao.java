package com.ascent.apachepoi;

public class Aviao {

    private Integer idAviao;
    private Integer numAssentos;
    private String modelo;

    public Aviao() {
    }

    public Aviao(Integer idAviao, Integer numAssentos, String modelo) {
        this.idAviao = idAviao;
        this.numAssentos = numAssentos;
        this.modelo = modelo;
    }

    // <editor-fold desc="Getters e Setters">

    public Integer getIdAviao() {
        return idAviao;
    }

    public void setIdAviao(Integer idAviao) {
        this.idAviao = idAviao;
    }

    public Integer getNumAssentos() {
        return numAssentos;
    }

    public void setNumAssentos(Integer numAssentos) {
        this.numAssentos = numAssentos;
    }

    public String getModelo() {
        return modelo;
    }

    public void setModelo(String modelo) {
        this.modelo = modelo;
    }

    // </editor-fold>

    @Override
    public String toString() {
        return "Aviao{" +
                "idAviao=" + idAviao +
                ", modelo='" + modelo + '\'' +
                ", numAssentos=" + numAssentos +
                '}';
    }
}
