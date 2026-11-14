package com.ascent.apachepoi;

public class Voo {

    private Integer idVoo;
    private Integer numVoo;
    private Integer tipoVoo;
    private Integer qtdPassageiros;
    private Integer fkCompanhia;
    private Integer fkAviao;

    public Voo() {
    }

    public Voo(Integer idVoo, Integer numVoo, Integer tipoVoo, Integer qtdPassageiros, Integer fkCompanhia, Integer fkAviao) {
        this.idVoo = idVoo;
        this.numVoo = numVoo;
        this.tipoVoo = tipoVoo;
        this.qtdPassageiros = qtdPassageiros;
        this.fkCompanhia = fkCompanhia;
        this.fkAviao = fkAviao;
    }

    // <editor-fold desc="Getters e Setters">

    public Integer getIdVoo() {
        return idVoo;
    }

    public void setIdVoo(Integer idVoo) {
        this.idVoo = idVoo;
    }

    public Integer getNumVoo() {
        return numVoo;
    }

    public void setNumVoo(Integer numVoo) {
        this.numVoo = numVoo;
    }

    public Integer getTipoVoo() {
        return tipoVoo;
    }

    public void setTipoVoo(Integer tipoVoo) {
        this.tipoVoo = tipoVoo;
    }

    public Integer getQtdPassageiros() {
        return qtdPassageiros;
    }

    public void setQtdPassageiros(Integer qtdPassageiros) {
        this.qtdPassageiros = qtdPassageiros;
    }

    public Integer getFkCompanhia() {
        return fkCompanhia;
    }

    public void setFkCompanhia(Integer fkCompanhia) {
        this.fkCompanhia = fkCompanhia;
    }

    public Integer getFkAviao() {
        return fkAviao;
    }

    public void setFkAviao(Integer fkAviao) {
        this.fkAviao = fkAviao;
    }

    // </editor-fold>

    @Override
    public String toString() {
        return "Voo{" +
                "idVoo=" + idVoo +
                ", numVoo=" + numVoo +
                ", qtdPassageiros=" + qtdPassageiros +
                '}';
    }
}
