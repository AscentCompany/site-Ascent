var graficosModel = require("../models/graficosModel");

function buscarInformativoRotas(req, res) {
    let idCompanhia = Number(req.params.idCompanhia);

    if (!Number.isInteger(idCompanhia) || idCompanhia <= 0) {
        return res.status(400).json({
            sucesso: false,
            mensagem: "ID da companhia inválido ou não informado."
        });
    }

    let anoReferencia = new Date().getFullYear() - 1;

    graficosModel.obterInformativoRotas(idCompanhia, anoReferencia)
        .then(function (resultado) {
            let rotas = resultado.map(function (registro) {
                let totalPassageiros = Number(registro.totalPassageiros);
                let totalAssentos = Number(registro.totalAssentos);

                return {
                    rota: registro.rota,
                    quantidadeVoos: Number(registro.quantidadeVoos),
                    taxaOcupacao: (totalPassageiros / totalAssentos) * 100,
                    totalPassageiros: totalPassageiros,
                    totalAssentos: totalAssentos
                };
            });

            let totalPassageiros = rotas.reduce(function (total, rota) {
                return total + rota.totalPassageiros;
            }, 0);
            let totalAssentos = rotas.reduce(function (total, rota) {
                return total + rota.totalAssentos;
            }, 0);
            let taxaOcupacaoMedia = totalAssentos > 0
                ? (totalPassageiros / totalAssentos) * 100
                : null;

            let maiorOcupacao = rotas.slice().sort(function (a, b) {
                return b.taxaOcupacao - a.taxaOcupacao || a.rota.localeCompare(b.rota);
            });
            let menorOcupacao = rotas.slice().sort(function (a, b) {
                return a.taxaOcupacao - b.taxaOcupacao || a.rota.localeCompare(b.rota);
            });

            res.json({
                sucesso: true,
                dados: {
                    anoReferencia: anoReferencia,
                    rotasMaiorOcupacao: maiorOcupacao.slice(0, 5),
                    rotasMenorOcupacao: menorOcupacao.slice(0, 5),
                    taxaOcupacaoMedia: taxaOcupacaoMedia,
                    totalRotasSubutilizadas: taxaOcupacaoMedia === null
                        ? 0
                        : rotas.filter(function (rota) {
                            return rota.taxaOcupacao < taxaOcupacaoMedia;
                        }).length,
                    totalRotasGargaloDemanda: rotas.filter(function (rota) {
                        return rota.taxaOcupacao <= 50;
                    }).length
                }
            });
        })
        .catch(function (erro) {
            console.error("Erro ao buscar informativo de rotas:", erro);
            res.status(500).json({
                sucesso: false,
                mensagem: "Erro ao buscar o informativo de rotas.",
                erro: erro.sqlMessage || erro.message || erro
            });
        });
}

function buscarGraficosOperacoes(req, res) {
    let idCompanhia = Number(req.params.idCompanhia);

    if (!Number.isInteger(idCompanhia) || idCompanhia <= 0) {
        return res.status(400).json({
            sucesso: false,
            mensagem: "ID da companhia inválido ou não informado."
        });
    }

    let anoReferencia = new Date().getFullYear() - 1;

    Promise.all([
        graficosModel.obterPontosCapacidadeOcupacao(idCompanhia, anoReferencia),
        graficosModel.obterMediasMensaisProcura(idCompanhia, anoReferencia)
    ])
        .then(function (resultados) {
            let pontosMercado = [];
            let pontosCompanhia = [];

            resultados[0].forEach(function (registro) {
                let ponto = {
                    x: Number(registro.capacidade),
                    y: Number(registro.passageiros)
                };
                let voosMercado = Number(registro.voosMercado);
                let voosCompanhia = Number(registro.voosCompanhia);

                if (voosMercado > 0) {
                    pontosMercado.push({
                        x: ponto.x,
                        y: ponto.y,
                        quantidadeVoos: voosMercado
                    });
                }

                if (voosCompanhia > 0) {
                    pontosCompanhia.push({
                        x: ponto.x,
                        y: ponto.y,
                        quantidadeVoos: voosCompanhia
                    });
                }
            });

            let mediaPassageirosPorMes = new Array(12).fill(null);
            let mediaAssentosPorMes = new Array(12).fill(null);
            let voosPorMes = new Array(12).fill(0);

            resultados[1].forEach(function (registro) {
                let indiceMes = Number(registro.mes) - 1;
                if (indiceMes < 0 || indiceMes >= 12) {
                    return;
                }

                mediaPassageirosPorMes[indiceMes] = Number(registro.mediaPassageiros);
                mediaAssentosPorMes[indiceMes] = Number(registro.mediaAssentos);
                voosPorMes[indiceMes] = Number(registro.quantidadeVoos);
            });

            res.json({
                sucesso: true,
                dados: {
                    anoReferencia: anoReferencia,
                    dispersaoCapacidade: {
                        companhia: pontosCompanhia,
                        mercado: pontosMercado
                    },
                    procuraMensal: {
                        mediaPassageiros: mediaPassageirosPorMes,
                        mediaAssentos: mediaAssentosPorMes,
                        quantidadeVoos: voosPorMes
                    }
                }
            });
        })
        .catch(function (erro) {
            console.error("Erro ao buscar gráficos de operações:", erro);
            res.status(500).json({
                sucesso: false,
                mensagem: "Erro ao buscar os gráficos de operações.",
                erro: erro.sqlMessage || erro.message || erro
            });
        });
}

function buscarGraficosRotas(req, res) {
    let idCompanhia = Number(req.params.idCompanhia);

    if (!Number.isInteger(idCompanhia) || idCompanhia <= 0) {
        return res.status(400).json({
            sucesso: false,
            mensagem: "ID da companhia inválido ou não informado."
        });
    }

    let anoReferencia = new Date().getFullYear() - 1;

    Promise.all([
        graficosModel.obterDemandaMensalPorTipo(idCompanhia, anoReferencia),
        graficosModel.obterDemandaHorarioPorTipo(idCompanhia, anoReferencia),
        graficosModel.obterDemandaPorRota(idCompanhia, anoReferencia)
    ])
        .then(function (resultados) {
            let comerciaisMes = new Array(12).fill(0);
            let turisticosMes = new Array(12).fill(0);

            resultados[0].forEach(function (registro) {
                let indiceMes = Number(registro.mes) - 1;
                if (indiceMes < 0 || indiceMes >= 12) {
                    return;
                }
                comerciaisMes[indiceMes] = Number(registro.passageirosComerciais) || 0;
                turisticosMes[indiceMes] = Number(registro.passageirosTuristicos) || 0;
            });

            let comerciaisHorario = new Array(6).fill(0);
            let turisticosHorario = new Array(6).fill(0);

            resultados[1].forEach(function (registro) {
                let faixa = Number(registro.faixaHorario);
                if (faixa < 0 || faixa >= 6) {
                    return;
                }
                comerciaisHorario[faixa] = Number(registro.passageirosComerciais) || 0;
                turisticosHorario[faixa] = Number(registro.passageirosTuristicos) || 0;
            });

            let rotas = resultados[2].map(function (registro) {
                return {
                    rota: registro.rotaIcao,
                    nomeCompletoRota: registro.nomeCompletoRota,
                    quantidadeVoos: Number(registro.quantidadeVoos) || 0,
                    totalPassageiros: Number(registro.totalPassageiros) || 0
                };
            });

            res.json({
                sucesso: true,
                dados: {
                    anoReferencia: anoReferencia,
                    demandaMensal: {
                        comerciais: comerciaisMes,
                        turisticos: turisticosMes
                    },
                    demandaHorario: {
                        comerciais: comerciaisHorario,
                        turisticos: turisticosHorario
                    },
                    demandaPorRota: rotas
                }
            });
        })
        .catch(function (erro) {
            console.error("Erro ao buscar gráficos de rotas:", erro);
            res.status(500).json({
                sucesso: false,
                mensagem: "Erro ao buscar os gráficos de rotas.",
                erro: erro.sqlMessage || erro.message || erro
            });
        });
}

module.exports = {
    buscarInformativoRotas,
    buscarGraficosOperacoes,
    buscarGraficosRotas
};
