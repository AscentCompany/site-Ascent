package com.ascent.apachepoi;

public class Aeroporto {

    private Integer idAeroporto;
    private String nomeAeroporto;
    private String municipio;
    private String uf;
    private String regiao;
    private String pais;
    private String icao;

    public Aeroporto() {
    }

    public Aeroporto(Integer idAeroporto, String nomeAeroporto, String municipio, String uf, String regiao, String pais, String icao) {
        this.idAeroporto = idAeroporto;
        this.nomeAeroporto = nomeAeroporto;
        this.municipio = municipio;
        this.uf = uf;
        this.regiao = regiao;
        this.pais = pais;
        this.icao = icao;
    }

    // <editor-fold desc="Getters e Setters">

    public Integer getIdAeroporto() {
        return idAeroporto;
    }

    public void setIdAeroporto(Integer idAeroporto) {
        this.idAeroporto = idAeroporto;
    }

    public String getNomeAeroporto() {
        return nomeAeroporto;
    }

    public void setNomeAeroporto(String nomeAeroporto) {
        this.nomeAeroporto = nomeAeroporto;
    }

    public String getMunicipio() {
        return municipio;
    }

    public void setMunicipio(String municipio) {
        this.municipio = municipio;
    }

    public String getUf() {
        return uf;
    }

    public void setUf(String uf) {
        this.uf = uf;
    }

    public String getRegiao() {
        return regiao;
    }

    public void setRegiao(String regiao) {
        this.regiao = regiao;
    }

    public String getPais() {
        return pais;
    }

    public void setPais(String pais) {
        this.pais = pais;
    }

    public String getIcao() {
        return icao;
    }

    public void setIcao(String icao) {
        this.icao = icao;
    }

    // </editor-fold>

    @Override
    public String toString() {
        return "Aeroporto{" +
                "idAeroporto=" + idAeroporto +
                ", nomeAeroporto='" + nomeAeroporto + '\'' +
                ", municipio='" + municipio + '\'' +
                ", uf='" + uf + '\'' +
                '}';
    }
}
