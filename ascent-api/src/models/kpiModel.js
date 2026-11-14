var database = require("../../database/config");

function obterBenchmarkOcupacao(idCompanhia) {
    let id = Number(idCompanhia);
    if (isNaN(id) || id <= 0) {
        id = 0;
    }

    let sqlBenchmark = `
        SELECT
            c.idCompanhia,
            c.nomeCompanhia,
            SUM(v.qtdPassageiros) AS totalPassageiros,
            SUM(av.numAssentos) AS totalAssentos,
            (SUM(v.qtdPassageiros) / NULLIF(SUM(av.numAssentos), 0)) * 100 AS taxaOcupacao
        FROM voo v
        JOIN companhia c ON c.idCompanhia = v.fkCompanhia
        JOIN aviao av ON av.idAviao = v.fkAviao
        WHERE v.qtdPassageiros IS NOT NULL AND av.numAssentos > 0
        GROUP BY c.idCompanhia, c.nomeCompanhia
        ORDER BY taxaOcupacao DESC
        LIMIT 1;
    `;

    let sqlSuaCompanhia = `
        SELECT
            c.idCompanhia,
            c.nomeCompanhia,
            SUM(CASE WHEN v.qtdPassageiros IS NOT NULL AND av.numAssentos > 0 THEN v.qtdPassageiros ELSE 0 END) AS totalPassageiros,
            SUM(CASE WHEN v.qtdPassageiros IS NOT NULL AND av.numAssentos > 0 THEN av.numAssentos ELSE 0 END) AS totalAssentos,
            (
                SUM(CASE WHEN v.qtdPassageiros IS NOT NULL AND av.numAssentos > 0 THEN v.qtdPassageiros END) /
                NULLIF(SUM(CASE WHEN v.qtdPassageiros IS NOT NULL AND av.numAssentos > 0 THEN av.numAssentos END), 0)
            ) * 100 AS taxaOcupacao
        FROM companhia c
        LEFT JOIN voo v ON v.fkCompanhia = c.idCompanhia
        LEFT JOIN aviao av ON av.idAviao = v.fkAviao
        WHERE c.idCompanhia = ${id}
        GROUP BY c.idCompanhia, c.nomeCompanhia;
    `;

    let resposta = {
        benchmark: null,
        suaCompanhia: null
    };

    return database.executar(sqlBenchmark)
        .then(function (resultadoBenchmark) {
            if (resultadoBenchmark.length > 0) {
                resposta.benchmark = resultadoBenchmark[0];
            }

            return database.executar(sqlSuaCompanhia);
        })
        .then(function (resultadoSuaCompanhia) {
            if (resultadoSuaCompanhia.length > 0) {
                resposta.suaCompanhia = resultadoSuaCompanhia[0];
            }

            return resposta;
        });
}

function obterVolumeMedioPassageiros(idCompanhia) {
    let id = Number(idCompanhia);
    if (isNaN(id) || id <= 0 || id % 1 !== 0) {
        id = 0;
    }

    let sqlMercado = `
        SELECT AVG(qtdPassageiros) AS mediaMercado
        FROM voo
        WHERE qtdPassageiros IS NOT NULL;
    `;

    let sqlCompanhia = `
        SELECT AVG(qtdPassageiros) AS mediaCompanhia
        FROM voo
        WHERE fkCompanhia = ${id}
          AND qtdPassageiros IS NOT NULL;
    `;

    let resposta = {
        mediaMercado: null,
        mediaCompanhia: null
    };

    return database.executar(sqlMercado)
        .then(function (resultadoMercado) {
            if (resultadoMercado.length > 0) {
                resposta.mediaMercado = resultadoMercado[0].mediaMercado;
            }

            return database.executar(sqlCompanhia);
        })
        .then(function (resultadoCompanhia) {
            if (resultadoCompanhia.length > 0) {
                resposta.mediaCompanhia = resultadoCompanhia[0].mediaCompanhia;
            }

            return resposta;
        });
}

module.exports = {
    obterBenchmarkOcupacao,
    obterVolumeMedioPassageiros
};
