var kpiModel = require("../models/kpiModel");

function calcularTaxaExata(registro) {
    if (!registro) {
        return 0;
    }

    if (registro.totalAssentos !== undefined) {
        let totalAssentos = Number(registro.totalAssentos);
        let totalPassageiros = Number(registro.totalPassageiros);

        if (isNaN(totalAssentos) || totalAssentos <= 0 || isNaN(totalPassageiros)) {
            return 0;
        }

        return (totalPassageiros / totalAssentos) * 100;
    }

    let taxa = Number(registro.taxaOcupacao);
    if (isNaN(taxa)) {
        return 0;
    }

    return taxa;
}

function calcularTaxaArredondada(registro) {
    return Math.round(calcularTaxaExata(registro));
}

function buscarDadosKpiBenchmark(req, res) {
    let idCompanhia = Number(req.params.idCompanhia);

    if (!Number.isInteger(idCompanhia) || idCompanhia <= 0) {
        return res.status(400).json({
            sucesso: false,
            mensagem: "ID da companhia inválido ou não informado."
        });
    }

    kpiModel.obterBenchmarkOcupacao(idCompanhia)
        .then(function (resultado) {
            let benchmarkRow = resultado.benchmark;
            let suaCompanhiaRow = resultado.suaCompanhia;

            let nomeBenchmark = benchmarkRow && benchmarkRow.nomeCompanhia
                ? benchmarkRow.nomeCompanhia
                : "Sem dados";

            let nomeSuaCompanhia = suaCompanhiaRow && suaCompanhiaRow.nomeCompanhia
                ? suaCompanhiaRow.nomeCompanhia
                : "Sua companhia";

            let taxaBenchmark = calcularTaxaArredondada(benchmarkRow);
            let taxaSuaCompanhia = calcularTaxaArredondada(suaCompanhiaRow);

            res.json({
                sucesso: true,
                dados: {
                    anoReferencia: resultado.anoReferencia,
                    suaCompanhia: {
                        nome: nomeSuaCompanhia,
                        taxaOcupacao: taxaSuaCompanhia
                    },
                    benchmark: {
                        nome: nomeBenchmark,
                        taxaOcupacao: taxaBenchmark
                    }
                }
            });
        })
        .catch(function (erro) {
            console.error("Erro ao buscar benchmark de ocupação:", erro);
            res.status(500).json({
                sucesso: false,
                mensagem: "Erro ao buscar dados da KPI de benchmark.",
                erro: erro.sqlMessage || erro.message || erro
            });
        });
}

function arredondarMedia(valor) {
    if (valor === null || valor === undefined) {
        return 0;
    }

    let numero = Number(valor);
    if (isNaN(numero)) {
        return 0;
    }

    return Math.round(numero);
}

function buscarDadosKpiVolumeMedio(req, res) {
    let idCompanhia = Number(req.params.idCompanhia);

    if (isNaN(idCompanhia) || idCompanhia <= 0 ) {
        return res.status(400).json({
            sucesso: false,
            mensagem: "ID da companhia inválido ou não informado."
        });
    }

    kpiModel.obterVolumeMedioPassageiros(idCompanhia)
        .then(function (resultado) {
            let mediaMercado = arredondarMedia(resultado.mediaMercado);
            let mediaCompanhia = arredondarMedia(resultado.mediaCompanhia);

            res.json({
                sucesso: true,
                dados: {
                    anoReferencia: resultado.anoReferencia,
                    mediaMercado: mediaMercado,
                    mediaCompanhia: mediaCompanhia
                }
            });
        })
        .catch(function (erro) {
            console.error("Erro ao buscar volume médio de passageiros:", erro);
            res.status(500).json({
                sucesso: false,
                mensagem: "Erro ao buscar dados da KPI de volume médio.",
                erro: erro.sqlMessage || erro.message || erro
            });
        });
}

function buscarDadosKpiMesMaiorProcura(req, res) {
    let nomesMeses = [
        "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
        "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
    ];

    kpiModel.obterMesMaiorProcura()
        .then(function (resultado) {
            let anoAnalisado = resultado.anoAnalisado || null;
            let meses = resultado.meses || [];
            let mesAnoAnterior = resultado.mesAnoAnterior || null;

            if (meses.length === 0) {
                return res.json({
                    sucesso: true,
                    dados: {
                        anoAnalisado: anoAnalisado,
                        mesNome: "Sem dados",
                        taxaOcupacao: 0,
                        vsMedia: null,
                        vsAnoAnterior: null
                    }
                });
            }

            let mesCampeaoRow = meses[0];
            let mesNumero = Number(mesCampeaoRow.mes);
            let mesNome = nomesMeses[mesNumero - 1] || "Sem dados";
            let taxaMesCampeao = calcularTaxaExata(mesCampeaoRow);

            let somaPassageiros = 0;
            let somaAssentos = 0;
            for (let i = 0; i < meses.length; i++) {
                somaPassageiros += Number(meses[i].totalPassageiros) || 0;
                somaAssentos += Number(meses[i].totalAssentos) || 0;
            }

            let vsMedia = null;
            if (somaAssentos > 0) {
                let taxaMediaGeral = (somaPassageiros / somaAssentos) * 100;
                vsMedia = Number((taxaMesCampeao - taxaMediaGeral).toFixed(1));
            }

            let vsAnoAnterior = null;
            if (mesAnoAnterior) {
                let temAssentos = Number(mesAnoAnterior.totalAssentos) > 0;
                let temTaxa = mesAnoAnterior.totalAssentos === undefined
                    && mesAnoAnterior.taxaOcupacao !== null
                    && mesAnoAnterior.taxaOcupacao !== undefined
                    && !isNaN(Number(mesAnoAnterior.taxaOcupacao));

                if (temAssentos || temTaxa) {
                    let taxaAnoAnterior = calcularTaxaExata(mesAnoAnterior);
                    vsAnoAnterior = Number((taxaMesCampeao - taxaAnoAnterior).toFixed(1));
                }
            }

            res.json({
                sucesso: true,
                dados: {
                    anoAnalisado: anoAnalisado,
                    mesNome: mesNome,
                    taxaOcupacao: Math.round(taxaMesCampeao),
                    vsMedia: vsMedia,
                    vsAnoAnterior: vsAnoAnterior
                }
            });
        })
        .catch(function (erro) {
            console.error("Erro ao buscar mês com maior procura:", erro);
            res.status(500).json({
                sucesso: false,
                mensagem: "Erro ao buscar dados da KPI de mês com maior procura.",
                erro: erro.sqlMessage || erro.message || erro
            });
        });
}

function buscarDadosKpiOcupacaoMedia(req, res) {
    let idCompanhia = Number(req.params.idCompanhia);

    if (isNaN(idCompanhia) || idCompanhia <= 0) {
        return res.status(400).json({
            sucesso: false,
            mensagem: "ID da companhia inválido ou não informado."
        });
    }

    kpiModel.obterTaxaOcupacaoMedia(idCompanhia)
        .then(function (resultado) {
            let suaCompanhiaRow = resultado.suaCompanhia;
            let nomeSuaCompanhia = suaCompanhiaRow && suaCompanhiaRow.nomeCompanhia
                ? suaCompanhiaRow.nomeCompanhia
                : "Sua companhia";

            let taxaMercado = resultado.taxaOcupacaoMercado !== null && resultado.taxaOcupacaoMercado !== undefined
                ? Math.round(Number(resultado.taxaOcupacaoMercado))
                : 0;

            let taxaCompanhia = suaCompanhiaRow && suaCompanhiaRow.taxaOcupacaoCompanhia !== null && suaCompanhiaRow.taxaOcupacaoCompanhia !== undefined
                ? Math.round(Number(suaCompanhiaRow.taxaOcupacaoCompanhia))
                : 0;

            res.json({
                sucesso: true,
                dados: {
                    anoReferencia: resultado.anoReferencia,
                    suaCompanhia: {
                        nome: nomeSuaCompanhia,
                        taxaOcupacao: taxaCompanhia
                    },
                    mercado: {
                        nome: "Todas as companhias",
                        taxaOcupacao: taxaMercado
                    }
                }
            });
        })
        .catch(function (erro) {
            console.error("Erro ao buscar taxa de ocupação média:", erro);
            res.status(500).json({
                sucesso: false,
                mensagem: "Erro ao buscar dados da KPI de ocupação média.",
                erro: erro.sqlMessage || erro.message || erro
            });
        });
}

module.exports = {
    buscarDadosKpiBenchmark,
    buscarDadosKpiVolumeMedio,
    buscarDadosKpiMesMaiorProcura,
    buscarDadosKpiOcupacaoMedia
};
