package com.ascent;

import java.time.LocalDate;
import java.time.LocalTime;

public class AeroportoDirecao {
    public Integer fkAeroporto;
    public Integer fkVoo;
    public String direcao;   // "Partida" ou "Destino"
    public LocalDate dia;    // dt_partida_real ou dt_chegada_real
    public LocalTime hora;   // hr_partida_real ou hr_chegada_real
}
