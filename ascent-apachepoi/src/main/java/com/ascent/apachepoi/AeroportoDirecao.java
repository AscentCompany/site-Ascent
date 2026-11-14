package com.ascent.apachepoi;

import java.time.LocalDate;
import java.time.LocalTime;

public class AeroportoDirecao {

    private Integer idAeroportoDirecao;
    private Integer fkAeroporto;
    private Integer fkVoo;
    private String direcao;
    private LocalDate dia;
    private LocalTime hora;

    public AeroportoDirecao() {
    }

    public AeroportoDirecao(Integer idAeroportoDirecao, Integer fkAeroporto, Integer fkVoo, String direcao, LocalDate dia, LocalTime hora) {
        this.idAeroportoDirecao = idAeroportoDirecao;
        this.fkAeroporto = fkAeroporto;
        this.fkVoo = fkVoo;
        this.direcao = direcao;
        this.dia = dia;
        this.hora = hora;
    }

    // <editor-fold desc="Getters e Setters">

    public Integer getIdAeroportoDirecao() {
        return idAeroportoDirecao;
    }

    public void setIdAeroportoDirecao(Integer idAeroportoDirecao) {
        this.idAeroportoDirecao = idAeroportoDirecao;
    }

    public Integer getFkAeroporto() {
        return fkAeroporto;
    }

    public void setFkAeroporto(Integer fkAeroporto) {
        this.fkAeroporto = fkAeroporto;
    }

    public Integer getFkVoo() {
        return fkVoo;
    }

    public void setFkVoo(Integer fkVoo) {
        this.fkVoo = fkVoo;
    }

    public String getDirecao() {
        return direcao;
    }

    public void setDirecao(String direcao) {
        this.direcao = direcao;
    }

    public LocalDate getDia() {
        return dia;
    }

    public void setDia(LocalDate dia) {
        this.dia = dia;
    }

    public LocalTime getHora() {
        return hora;
    }

    public void setHora(LocalTime hora) {
        this.hora = hora;
    }

    // </editor-fold>

    @Override
    public String toString() {
        return "AeroportoDirecao{" +
                "fkAeroporto=" + fkAeroporto +
                ", fkVoo=" + fkVoo +
                ", direcao='" + direcao + '\'' +
                ", dia=" + dia +
                ", hora=" + hora +
                '}';
    }
}
