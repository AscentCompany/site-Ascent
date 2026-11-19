package com.ascent.apachepoi;

/**
 * Uma linha válida da planilha já convertida nas entidades que serão persistidas.
 * O LeitorExcel entrega uma LinhaVoo por vez para o importador, sem acumular
 * milhões de objetos em memória.
 */
public class LinhaVoo {

    private final Companhia companhia;
    private final Aviao aviao;
    private final Voo voo;
    private final Aeroporto aeroportoOrigem;
    private final Aeroporto aeroportoDestino;
    private final AeroportoDirecao partida;
    private final AeroportoDirecao chegada;

    public LinhaVoo(Companhia companhia, Aviao aviao, Voo voo,
                    Aeroporto aeroportoOrigem, Aeroporto aeroportoDestino,
                    AeroportoDirecao partida, AeroportoDirecao chegada) {
        this.companhia = companhia;
        this.aviao = aviao;
        this.voo = voo;
        this.aeroportoOrigem = aeroportoOrigem;
        this.aeroportoDestino = aeroportoDestino;
        this.partida = partida;
        this.chegada = chegada;
    }

    public Companhia getCompanhia() { return companhia; }
    public Aviao getAviao() { return aviao; }
    public Voo getVoo() { return voo; }
    public Aeroporto getAeroportoOrigem() { return aeroportoOrigem; }
    public Aeroporto getAeroportoDestino() { return aeroportoDestino; }
    public AeroportoDirecao getPartida() { return partida; }
    public AeroportoDirecao getChegada() { return chegada; }
}
