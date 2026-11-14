var kpiModel = require("../models/kpiModel");

function calcularTaxaArredondada(registro) {
    if (!registro) {
        return 0;
    }

    if (registro.totalAssentos !== undefined) {
        let totalAssentos = Number(registro.totalAssentos);
        let totalPassageiros = Number(registro.totalPassageiros);

        if (isNaN(totalAssentos) || totalAssentos <= 0 || isNaN(totalPassageiros)) {
            return 0;
        }

        return Math.round((totalPassageiros / totalAssentos) * 100);
    }

    let taxa = Number(registro.taxaOcupacao);
    if (isNaN(taxa)) {
        return 0;
    }

    return Math.round(taxa);
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

module.exports = {
    buscarDadosKpiBenchmark
};
