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
            SUM(voos.totalPassageiros) AS totalPassageiros,
            SUM(voos.quantidadeVoos * av.numAssentos) AS totalAssentos,
            (
                SUM(voos.totalPassageiros) /
                NULLIF(SUM(voos.quantidadeVoos * av.numAssentos), 0)
            ) * 100 AS taxaOcupacao
        FROM (
            SELECT
                fkCompanhia,
                fkAviao,
                SUM(qtdPassageiros) AS totalPassageiros,
                COUNT(*) AS quantidadeVoos
            FROM voo FORCE INDEX (idx_voo_cia_passag_aviao)
            WHERE qtdPassageiros IS NOT NULL
            GROUP BY fkCompanhia, fkAviao
        ) voos
        STRAIGHT_JOIN aviao av
            ON av.idAviao = voos.fkAviao AND av.numAssentos > 0
        STRAIGHT_JOIN companhia c
            ON c.idCompanhia = voos.fkCompanhia
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
    let resposta = {
        anoAnalisado: null,
        meses: [],
        mesAnoAnterior: null
    };

    return database.executar(montarSqlMesesPorAno("YEAR(CURDATE())"))
        .then(function (resultadoMesesAtual) {
            if (resultadoMesesAtual.length > 0) {
                return resultadoMesesAtual;
            }

            let sqlUltimoAno = `
                SELECT YEAR(MAX(dia)) AS ultimoAno
                FROM aeroportoDirecao
                WHERE direcao = 'Partida'
                  AND dia <= CURDATE();
            `;

            return database.executar(sqlUltimoAno)
                .then(function (resultadoAno) {
                    if (resultadoAno.length === 0 || !resultadoAno[0].ultimoAno) {
                        return [];
                    }

                    let ultimoAno = Number(resultadoAno[0].ultimoAno);
                    if (isNaN(ultimoAno) || ultimoAno <= 0) {
                        return [];
                    }

                    return database.executar(montarSqlMesesPorAno(ultimoAno));
                });
        })
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

    let sqlMercado = `
        SELECT
            (
                SUM(CASE WHEN v.qtdPassageiros IS NOT NULL AND av.numAssentos > 0 THEN v.qtdPassageiros ELSE 0 END) /
                NULLIF(SUM(CASE WHEN v.qtdPassageiros IS NOT NULL AND av.numAssentos > 0 THEN av.numAssentos ELSE 0 END), 0)
            ) * 100 AS taxaOcupacaoMercado
        FROM voo v
        JOIN aviao av ON av.idAviao = v.fkAviao;
    `;

    let sqlCompanhia = `
        SELECT
            c.idCompanhia,
            c.nomeCompanhia,
            (
                SUM(CASE WHEN v.qtdPassageiros IS NOT NULL AND av.numAssentos > 0 THEN v.qtdPassageiros ELSE 0 END) /
                NULLIF(SUM(CASE WHEN v.qtdPassageiros IS NOT NULL AND av.numAssentos > 0 THEN av.numAssentos ELSE 0 END), 0)
            ) * 100 AS taxaOcupacaoCompanhia
        FROM companhia c
        LEFT JOIN voo v ON v.fkCompanhia = c.idCompanhia
        LEFT JOIN aviao av ON av.idAviao = v.fkAviao
        WHERE c.idCompanhia = ${id}
        GROUP BY c.idCompanhia, c.nomeCompanhia;
    `;

    let resposta = {
        taxaOcupacaoMercado: null,
        suaCompanhia: null
    };

    return database.executar(sqlMercado)
        .then(function (resultadoMercado) {
            if (resultadoMercado.length > 0) {
                resposta.taxaOcupacaoMercado = resultadoMercado[0].taxaOcupacaoMercado;
            }

            return database.executar(sqlCompanhia);
        })
        .then(function (resultadoCompanhia) {
            if (resultadoCompanhia.length > 0) {
                resposta.suaCompanhia = resultadoCompanhia[0];
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
