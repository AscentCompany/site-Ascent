import java.time.LocalDate;
import java.time.LocalTime;

public class Voo {
    public Integer idVoo;
    public LocalDate dataPartida;
    public LocalTime horaPartida;
    public Double combustivelGasto;
    public Integer numAssentos;
    public Integer numPassageiros;
    public String nomeCompanhia; // depois vai virar o ID (fk) mas para fazer sentido agora ficou como nome
}
