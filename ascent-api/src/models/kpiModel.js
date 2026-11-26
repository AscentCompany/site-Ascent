var database = require("../../database/config");

// Ano anterior fechado: mesma referência usada nos gráficos da dashboard de operações
function obterAnoAnteriorFechado() {
    return new Date().getFullYear() - 1;
}

function obterIntervaloAno(ano) {
    return {
        inicio: `${ano}-01-01`,
        fim: `${ano + 1}-01-01`
    };
}

// Totais de passageiros/assentos da companhia no ano (partidas), sempre retornando a companhia
function montarSqlOcupacaoCompanhiaAno() {
    return `
        SELECT
            c.idCompanhia,
            c.nomeCompanhia,
            COALESCE(dados.totalPassageiros, 0) AS totalPassageiros,
            COALESCE(dados.totalAssentos, 0) AS totalAssentos,
            (dados.totalPassageiros / NULLIF(dados.totalAssentos, 0)) * 100 AS taxaOcupacao
        FROM companhia c
        LEFT JOIN (
            SELECT
                SUM(v.qtdPassageiros) AS totalPassageiros,
                SUM(av.numAssentos) AS totalAssentos
            FROM voo v
            STRAIGHT_JOIN aeroportoDirecao ad ON ad.fkVoo = v.idVoo AND ad.direcao = 'Partida'
            STRAIGHT_JOIN aviao av ON av.idAviao = v.fkAviao
            WHERE v.fkCompanhia = ?
              AND ad.dia >= ? AND ad.dia < ?
              AND v.qtdPassageiros IS NOT NULL
              AND av.numAssentos > 0
        ) dados ON 1 = 1
        WHERE c.idCompanhia = ?;
    `;
}

function obterBenchmarkOcupacao(idCompanhia) {
    let id = Number(idCompanhia);
    if (isNaN(id) || id <= 0) {
        id = 0;
    }

    let anoReferencia = obterAnoAnteriorFechado();
    let intervalo = obterIntervaloAno(anoReferencia);

    let sqlBenchmark = `
        SELECT
            c.idCompanhia,
            c.nomeCompanhia,
            voos.totalPassageiros,
            voos.totalAssentos,
            (voos.totalPassageiros / NULLIF(voos.totalAssentos, 0)) * 100 AS taxaOcupacao
        FROM (
            SELECT
                v.fkCompanhia,
                SUM(v.qtdPassageiros) AS totalPassageiros,
                SUM(av.numAssentos) AS totalAssentos
            FROM aeroportoDirecao ad
            STRAIGHT_JOIN voo v ON v.idVoo = ad.fkVoo
            STRAIGHT_JOIN aviao av ON av.idAviao = v.fkAviao
            WHERE ad.direcao = 'Partida'
              AND ad.dia >= ? AND ad.dia < ?
              AND v.qtdPassageiros IS NOT NULL
              AND av.numAssentos > 0
            GROUP BY v.fkCompanhia
        ) voos
        JOIN companhia c ON c.idCompanhia = voos.fkCompanhia
        ORDER BY taxaOcupacao DESC
        LIMIT 1;
    `;

    let sqlSuaCompanhia = montarSqlOcupacaoCompanhiaAno();

    let resposta = {
        anoReferencia: anoReferencia,
        benchmark: null,
        suaCompanhia: null
    };

    return database.executar(sqlBenchmark, [intervalo.inicio, intervalo.fim])
        .then(function (resultadoBenchmark) {
            if (resultadoBenchmark.length > 0) {
                resposta.benchmark = resultadoBenchmark[0];
            }

            return database.executar(sqlSuaCompanhia, [id, intervalo.inicio, intervalo.fim, id]);
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

    let anoReferencia = obterAnoAnteriorFechado();
    let intervalo = obterIntervaloAno(anoReferencia);

    let sqlMercado = `
        SELECT AVG(v.qtdPassageiros) AS mediaMercado
        FROM aeroportoDirecao ad
        STRAIGHT_JOIN voo v ON v.idVoo = ad.fkVoo
        WHERE ad.direcao = 'Partida'
          AND ad.dia >= ? AND ad.dia < ?
          AND v.qtdPassageiros IS NOT NULL;
    `;

    let sqlCompanhia = `
        SELECT AVG(v.qtdPassageiros) AS mediaCompanhia
        FROM voo v
        STRAIGHT_JOIN aeroportoDirecao ad ON ad.fkVoo = v.idVoo AND ad.direcao = 'Partida'
        WHERE v.fkCompanhia = ?
          AND ad.dia >= ? AND ad.dia < ?
          AND v.qtdPassageiros IS NOT NULL;
    `;

    let resposta = {
        anoReferencia: anoReferencia,
        mediaMercado: null,
        mediaCompanhia: null
    };

    return database.executar(sqlMercado, [intervalo.inicio, intervalo.fim])
        .then(function (resultadoMercado) {
            if (resultadoMercado.length > 0) {
                resposta.mediaMercado = resultadoMercado[0].mediaMercado;
            }

            return database.executar(sqlCompanhia, [id, intervalo.inicio, intervalo.fim]);
        })
        .then(function (resultadoCompanhia) {
            if (resultadoCompanhia.length > 0) {
                resposta.mediaCompanhia = resultadoCompanhia[0].mediaCompanhia;
            }

            return resposta;
        });
}

function montarSqlMesesPorAno(expressaoAno) {
    let filtroData;
    if (typeof expressaoAno === 'number' || !isNaN(Number(expressaoAno))) {
        let ano = Number(expressaoAno);
        filtroData = `ad.dia >= '${ano}-01-01' AND ad.dia < '${ano + 1}-01-01'`;
    } else if (expressaoAno === "YEAR(CURDATE())") {
        filtroData = `ad.dia >= MAKEDATE(YEAR(CURDATE()), 1)
            AND ad.dia < MAKEDATE(YEAR(CURDATE()) + 1, 1)`;
    } else {
        filtroData = `YEAR(ad.dia) = ${expressaoAno}`;
    }

    return `
        SELECT
            YEAR(ad.dia) AS ano,
            MONTH(ad.dia) AS mes,
            SUM(v.qtdPassageiros) AS totalPassageiros,
            SUM(av.numAssentos) AS totalAssentos,
            (SUM(v.qtdPassageiros) / NULLIF(SUM(av.numAssentos), 0)) * 100 AS taxaOcupacao
        FROM aeroportoDirecao ad
        JOIN voo v ON v.idVoo = ad.fkVoo
        JOIN aviao av ON av.idAviao = v.fkAviao
        WHERE ad.direcao = 'Partida'
          AND ${filtroData}
          AND ad.dia IS NOT NULL
          AND v.qtdPassageiros IS NOT NULL
          AND av.numAssentos > 0
        GROUP BY YEAR(ad.dia), MONTH(ad.dia)
        ORDER BY taxaOcupacao DESC;
    `;
}

function obterMesMaiorProcura() {
    let anoReferencia = obterAnoAnteriorFechado();

    let resposta = {
        anoAnalisado: anoReferencia,
        meses: [],
        mesAnoAnterior: null
    };

    return database.executar(montarSqlMesesPorAno(anoReferencia))
        .then(function (resultadoMeses) {
            resposta.meses = resultadoMeses;

            if (resultadoMeses.length === 0) {
                return [];
            }

            let anoAnalisado = Number(resultadoMeses[0].ano);
            let mesCampeao = Number(resultadoMeses[0].mes);

            if (isNaN(anoAnalisado) || isNaN(mesCampeao) || mesCampeao < 1 || mesCampeao > 12) {
                return [];
            }

            resposta.anoAnalisado = anoAnalisado;

            let anoAnterior = anoAnalisado - 1;
            let mesFormatado = String(mesCampeao).padStart(2, '0');
            let sqlMesAnoAnterior = `
                SELECT
                    YEAR(ad.dia) AS ano,
                    SUM(v.qtdPassageiros) AS totalPassageiros,
                    SUM(av.numAssentos) AS totalAssentos,
                    (SUM(v.qtdPassageiros) / NULLIF(SUM(av.numAssentos), 0)) * 100 AS taxaOcupacao
                FROM aeroportoDirecao ad
                JOIN voo v ON v.idVoo = ad.fkVoo
                JOIN aviao av ON av.idAviao = v.fkAviao
                WHERE ad.direcao = 'Partida'
                  AND ad.dia >= '${anoAnterior}-${mesFormatado}-01'
                  AND ad.dia < DATE_ADD('${anoAnterior}-${mesFormatado}-01', INTERVAL 1 MONTH)
                  AND ad.dia IS NOT NULL
                  AND v.qtdPassageiros IS NOT NULL
                  AND av.numAssentos > 0
                GROUP BY YEAR(ad.dia);
            `;

            return database.executar(sqlMesAnoAnterior);
        })
        .then(function (resultadoAnoAnterior) {
            if (resultadoAnoAnterior.length > 0) {
                resposta.mesAnoAnterior = resultadoAnoAnterior[0];
            }
            return resposta;
        });
}

function obterTaxaOcupacaoMedia(idCompanhia) {
    let id = Number(idCompanhia);
    if (isNaN(id) || id <= 0 || id % 1 !== 0) {
        id = 0;
    }

    let anoReferencia = obterAnoAnteriorFechado();
    let intervalo = obterIntervaloAno(anoReferencia);

    let sqlMercado = `
        SELECT
            (SUM(v.qtdPassageiros) / NULLIF(SUM(av.numAssentos), 0)) * 100 AS taxaOcupacaoMercado
        FROM aeroportoDirecao ad
        STRAIGHT_JOIN voo v ON v.idVoo = ad.fkVoo
        STRAIGHT_JOIN aviao av ON av.idAviao = v.fkAviao
        WHERE ad.direcao = 'Partida'
          AND ad.dia >= ? AND ad.dia < ?
          AND v.qtdPassageiros IS NOT NULL
          AND av.numAssentos > 0;
    `;

    let sqlCompanhia = montarSqlOcupacaoCompanhiaAno();

    let resposta = {
        anoReferencia: anoReferencia,
        taxaOcupacaoMercado: null,
        suaCompanhia: null
    };

    return database.executar(sqlMercado, [intervalo.inicio, intervalo.fim])
        .then(function (resultadoMercado) {
            if (resultadoMercado.length > 0) {
                resposta.taxaOcupacaoMercado = resultadoMercado[0].taxaOcupacaoMercado;
            }

            return database.executar(sqlCompanhia, [id, intervalo.inicio, intervalo.fim, id]);
        })
        .then(function (resultadoCompanhia) {
            if (resultadoCompanhia.length > 0) {
                let linha = resultadoCompanhia[0];
                linha.taxaOcupacaoCompanhia = linha.taxaOcupacao;
                resposta.suaCompanhia = linha;
            }

            return resposta;
        });
}

module.exports = {
    obterBenchmarkOcupacao,
    obterVolumeMedioPassageiros,
    obterMesMaiorProcura,
    obterTaxaOcupacaoMedia
};
