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

function obterAnoReferencia(idCompanhia) {
    let id = Number(idCompanhia);
    if (isNaN(id) || id <= 0) id = 0;

    let sqlCompanhia = `
        SELECT YEAR(MAX(ad.dia)) AS ultimoAno
        FROM aeroportoDirecao ad
        JOIN voo v ON v.idVoo = ad.fkVoo
        WHERE v.fkCompanhia = ?
        AND ad.dia IS NOT NULL;
    `;

    return database.executar(sqlCompanhia, [id])
        .then(function (res) {
            if (res.length > 0 && res[0].ultimoAno) {
                return Number(res[0].ultimoAno);
            }
            let sqlGlobal = `
                SELECT YEAR(MAX(dia)) AS ultimoAno
                FROM aeroportoDirecao
                WHERE dia IS NOT NULL;
            `;
            return database.executar(sqlGlobal);
        })
        .then(function (resGlobal) {
            if (typeof resGlobal === 'number') {
                return resGlobal;
            }
            if (resGlobal.length > 0 && resGlobal[0].ultimoAno) {
                return Number(resGlobal[0].ultimoAno);
            }
            return new Date().getFullYear() - 1;
        });
}

function montarRotaIncidenciaItem(rotaRow, totalVoos) {
    if (!rotaRow || totalVoos <= 0) {
        return {
            rota: null,
            quantidadeVoos: 0,
            totalVoos: totalVoos || 0,
            percentual: null
        };
    }

    let voosRota = Number(rotaRow.quantidadeVoos) || 0;
    let percentual = Number(((voosRota / totalVoos) * 100).toFixed(1));

    return {
        rota: `${rotaRow.nomeOrigem} - ${rotaRow.nomeDestino}`,
        quantidadeVoos: voosRota,
        totalVoos: totalVoos,
        percentual: percentual
    };
}

function obterRotaMaiorIncidencia(idCompanhia) {
    let id = Number(idCompanhia);
    if (isNaN(id) || id <= 0) id = 0;

    return obterAnoReferencia(id).then(function (anoRef) {
        let inicioAno = `${anoRef}-01-01`;
        let fimAno = `${anoRef + 1}-01-01`;

        let sqlTotalCompanhia = `
            SELECT COUNT(DISTINCT v.idVoo) AS totalVoos
            FROM voo v
            STRAIGHT_JOIN aeroportoDirecao ad ON ad.fkVoo = v.idVoo AND ad.direcao = 'Partida'
            WHERE v.fkCompanhia = ?
              AND ad.dia >= ? AND ad.dia < ?;
        `;

        let sqlRotaCompanhia = `
            SELECT
                top.idOrigem,
                top.idDestino,
                COALESCE(NULLIF(TRIM(origem.nomeAeroporto), ''), NULLIF(TRIM(origem.municipio), ''), CONCAT('Aeroporto ', origem.idAeroporto)) AS nomeOrigem,
                COALESCE(NULLIF(TRIM(destino.nomeAeroporto), ''), NULLIF(TRIM(destino.municipio), ''), CONCAT('Aeroporto ', destino.idAeroporto)) AS nomeDestino,
                top.quantidadeVoos,
                top.totalPassageiros
            FROM (
                SELECT
                    partida.fkAeroporto AS idOrigem,
                    chegada.fkAeroporto AS idDestino,
                    COUNT(DISTINCT v.idVoo) AS quantidadeVoos,
                    SUM(v.qtdPassageiros) AS totalPassageiros
                FROM voo v
                STRAIGHT_JOIN aeroportoDirecao partida ON partida.fkVoo = v.idVoo AND partida.direcao = 'Partida'
                STRAIGHT_JOIN aeroportoDirecao chegada ON chegada.fkVoo = v.idVoo AND chegada.direcao = 'Destino'
                WHERE v.fkCompanhia = ?
                  AND partida.dia >= ? AND partida.dia < ?
                GROUP BY partida.fkAeroporto, chegada.fkAeroporto
                ORDER BY quantidadeVoos DESC, totalPassageiros DESC
                LIMIT 1
            ) top
            JOIN aeroporto origem ON origem.idAeroporto = top.idOrigem
            JOIN aeroporto destino ON destino.idAeroporto = top.idDestino;
        `;

        let sqlTotalMercado = `
            SELECT COUNT(*) AS totalVoos
            FROM aeroportoDirecao ad
            WHERE ad.direcao = 'Partida'
              AND ad.dia >= ? AND ad.dia < ?;
        `;

        let sqlRotaMercado = `
            SELECT
                top.idOrigem,
                top.idDestino,
                COALESCE(NULLIF(TRIM(origem.nomeAeroporto), ''), NULLIF(TRIM(origem.municipio), ''), CONCAT('Aeroporto ', origem.idAeroporto)) AS nomeOrigem,
                COALESCE(NULLIF(TRIM(destino.nomeAeroporto), ''), NULLIF(TRIM(destino.municipio), ''), CONCAT('Aeroporto ', destino.idAeroporto)) AS nomeDestino,
                top.quantidadeVoos,
                top.totalPassageiros
            FROM (
                SELECT
                    partida.fkAeroporto AS idOrigem,
                    chegada.fkAeroporto AS idDestino,
                    COUNT(*) AS quantidadeVoos,
                    SUM(v.qtdPassageiros) AS totalPassageiros
                FROM aeroportoDirecao partida
                STRAIGHT_JOIN voo v ON v.idVoo = partida.fkVoo
                STRAIGHT_JOIN aeroportoDirecao chegada ON chegada.fkVoo = v.idVoo AND chegada.direcao = 'Destino'
                WHERE partida.direcao = 'Partida'
                  AND partida.dia >= ? AND partida.dia < ?
                GROUP BY partida.fkAeroporto, chegada.fkAeroporto
                ORDER BY quantidadeVoos DESC, totalPassageiros DESC
                LIMIT 1
            ) top
            JOIN aeroporto origem ON origem.idAeroporto = top.idOrigem
            JOIN aeroporto destino ON destino.idAeroporto = top.idDestino;
        `;

        return Promise.all([
            database.executar(sqlTotalCompanhia, [id, inicioAno, fimAno]),
            database.executar(sqlRotaCompanhia, [id, inicioAno, fimAno]),
            database.executar(sqlTotalMercado, [inicioAno, fimAno]),
            database.executar(sqlRotaMercado, [inicioAno, fimAno])
        ]).then(function (resultados) {
            let totalComp = resultados[0].length > 0 ? Number(resultados[0][0].totalVoos) || 0 : 0;
            let rotaCompRow = resultados[1].length > 0 ? resultados[1][0] : null;
            let totalMerc = resultados[2].length > 0 ? Number(resultados[2][0].totalVoos) || 0 : 0;
            let rotaMercRow = resultados[3].length > 0 ? resultados[3][0] : null;

            return {
                anoReferencia: anoRef,
                suaCompanhia: montarRotaIncidenciaItem(rotaCompRow, totalComp),
                mercado: montarRotaIncidenciaItem(rotaMercRow, totalMerc)
            };
        });
    });
}

function montarAeroportoMenorProcuraItem(row) {
    if (!row) {
        return {
            nomeAeroporto: null,
            totalPassageiros: null,
            totalAssentos: 0,
            quantidadeVoos: 0,
            taxaOcupacao: null
        };
    }

    let totalPass = Number(row.totalPassageiros) || 0;
    let totalAssentos = Number(row.totalAssentos) || 0;
    let taxaOcupacao = totalAssentos > 0
        ? Number(((totalPass / totalAssentos) * 100).toFixed(1))
        : null;

    return {
        nomeAeroporto: row.nomeAeroporto,
        totalPassageiros: totalPass,
        totalAssentos: totalAssentos,
        quantidadeVoos: Number(row.quantidadeVoos) || 0,
        taxaOcupacao: taxaOcupacao
    };
}

function obterAeroportoMenorProcura(idCompanhia) {
    let id = Number(idCompanhia);
    if (isNaN(id) || id <= 0) id = 0;

    return obterAnoReferencia(id).then(function (anoRef) {
        let inicioAno = `${anoRef}-01-01`;
        let fimAno = `${anoRef + 1}-01-01`;

        let sqlCompanhia = `
            SELECT
                top.idAeroporto,
                COALESCE(NULLIF(TRIM(a.nomeAeroporto), ''), NULLIF(TRIM(a.municipio), ''), CONCAT('Aeroporto ', a.idAeroporto)) AS nomeAeroporto,
                top.quantidadeVoos,
                top.totalPassageiros,
                top.totalAssentos
            FROM (
                SELECT
                    ad.fkAeroporto AS idAeroporto,
                    COUNT(*) AS quantidadeVoos,
                    SUM(v.qtdPassageiros) AS totalPassageiros,
                    SUM(av.numAssentos) AS totalAssentos
                FROM voo v
                STRAIGHT_JOIN aeroportoDirecao ad ON ad.fkVoo = v.idVoo AND ad.direcao = 'Partida'
                STRAIGHT_JOIN aviao av ON av.idAviao = v.fkAviao
                WHERE v.fkCompanhia = ?
                  AND ad.dia >= ? AND ad.dia < ?
                  AND v.qtdPassageiros IS NOT NULL
                  AND av.numAssentos > 0
                GROUP BY ad.fkAeroporto
                ORDER BY (SUM(v.qtdPassageiros) = 0) ASC, totalPassageiros ASC, quantidadeVoos ASC
                LIMIT 1
            ) top
            JOIN aeroporto a ON a.idAeroporto = top.idAeroporto;
        `;

        let sqlMercado = `
            SELECT
                top.idAeroporto,
                COALESCE(NULLIF(TRIM(a.nomeAeroporto), ''), NULLIF(TRIM(a.municipio), ''), CONCAT('Aeroporto ', a.idAeroporto)) AS nomeAeroporto,
                top.quantidadeVoos,
                top.totalPassageiros,
                top.totalAssentos
            FROM (
                SELECT
                    ad.fkAeroporto AS idAeroporto,
                    COUNT(*) AS quantidadeVoos,
                    SUM(v.qtdPassageiros) AS totalPassageiros,
                    SUM(av.numAssentos) AS totalAssentos
                FROM aeroportoDirecao ad
                STRAIGHT_JOIN voo v ON v.idVoo = ad.fkVoo
                STRAIGHT_JOIN aviao av ON av.idAviao = v.fkAviao
                WHERE ad.direcao = 'Partida'
                  AND ad.dia >= ? AND ad.dia < ?
                  AND v.qtdPassageiros IS NOT NULL
                  AND av.numAssentos > 0
                GROUP BY ad.fkAeroporto
                ORDER BY (SUM(v.qtdPassageiros) = 0) ASC, totalPassageiros ASC, quantidadeVoos ASC
                LIMIT 1
            ) top
            JOIN aeroporto a ON a.idAeroporto = top.idAeroporto;
        `;

        return Promise.all([
            database.executar(sqlCompanhia, [id, inicioAno, fimAno]),
            database.executar(sqlMercado, [inicioAno, fimAno])
        ]).then(function (resultados) {
            let compRow = resultados[0].length > 0 ? resultados[0][0] : null;
            let mercRow = resultados[1].length > 0 ? resultados[1][0] : null;

            return {
                anoReferencia: anoRef,
                suaCompanhia: montarAeroportoMenorProcuraItem(compRow),
                mercado: montarAeroportoMenorProcuraItem(mercRow)
            };
        });
    });
}

function montarHubCirculacaoItem(hubRow, totalVoos) {
    if (!hubRow || totalVoos <= 0) {
        return {
            nomeAeroporto: null,
            voosNoAeroporto: 0,
            totalVoos: totalVoos || 0,
            percentual: null
        };
    }

    let voosHub = Number(hubRow.voosNoAeroporto) || 0;
    let percentualBruto = (voosHub / totalVoos) * 100;
    let percentual = percentualBruto >= 10
        ? Math.round(percentualBruto)
        : Number(percentualBruto.toFixed(1));

    return {
        nomeAeroporto: hubRow.nomeAeroporto,
        voosNoAeroporto: voosHub,
        totalVoos: totalVoos,
        percentual: percentual
    };
}

function obterHubMaiorCirculacao(idCompanhia) {
    let id = Number(idCompanhia);
    if (isNaN(id) || id <= 0) id = 0;

    return obterAnoReferencia(id).then(function (anoRef) {
        let inicioAno = `${anoRef}-01-01`;
        let fimAno = `${anoRef + 1}-01-01`;

        let sqlTotalCompanhia = `
            SELECT COUNT(DISTINCT v.idVoo) AS totalVoos
            FROM voo v
            STRAIGHT_JOIN aeroportoDirecao ad ON ad.fkVoo = v.idVoo
            WHERE v.fkCompanhia = ?
              AND ad.dia >= ? AND ad.dia < ?;
        `;

        let sqlHubCompanhia = `
            SELECT
                top.idAeroporto,
                COALESCE(NULLIF(TRIM(a.nomeAeroporto), ''), NULLIF(TRIM(a.municipio), ''), CONCAT('Aeroporto ', a.idAeroporto)) AS nomeAeroporto,
                top.voosNoAeroporto
            FROM (
                SELECT
                    ad.fkAeroporto AS idAeroporto,
                    COUNT(DISTINCT v.idVoo) AS voosNoAeroporto
                FROM voo v
                STRAIGHT_JOIN aeroportoDirecao ad ON ad.fkVoo = v.idVoo
                WHERE v.fkCompanhia = ?
                  AND ad.dia >= ? AND ad.dia < ?
                GROUP BY ad.fkAeroporto
                ORDER BY voosNoAeroporto DESC
                LIMIT 1
            ) top
            JOIN aeroporto a ON a.idAeroporto = top.idAeroporto;
        `;

        let sqlTotalMercado = `
            SELECT COUNT(DISTINCT ad.fkVoo) AS totalVoos
            FROM aeroportoDirecao ad
            WHERE ad.dia >= ? AND ad.dia < ?;
        `;

        let sqlHubMercado = `
            SELECT
                top.idAeroporto,
                COALESCE(NULLIF(TRIM(a.nomeAeroporto), ''), NULLIF(TRIM(a.municipio), ''), CONCAT('Aeroporto ', a.idAeroporto)) AS nomeAeroporto,
                top.voosNoAeroporto
            FROM (
                SELECT
                    ad.fkAeroporto AS idAeroporto,
                    COUNT(*) AS voosNoAeroporto
                FROM aeroportoDirecao ad
                WHERE ad.dia >= ? AND ad.dia < ?
                GROUP BY ad.fkAeroporto
                ORDER BY voosNoAeroporto DESC
                LIMIT 1
            ) top
            JOIN aeroporto a ON a.idAeroporto = top.idAeroporto;
        `;

        return Promise.all([
            database.executar(sqlTotalCompanhia, [id, inicioAno, fimAno]),
            database.executar(sqlHubCompanhia, [id, inicioAno, fimAno]),
            database.executar(sqlTotalMercado, [inicioAno, fimAno]),
            database.executar(sqlHubMercado, [inicioAno, fimAno])
        ]).then(function (resultados) {
            let totalComp = resultados[0].length > 0 ? Number(resultados[0][0].totalVoos) || 0 : 0;
            let hubCompRow = resultados[1].length > 0 ? resultados[1][0] : null;
            let totalMerc = resultados[2].length > 0 ? Number(resultados[2][0].totalVoos) || 0 : 0;
            let hubMercRow = resultados[3].length > 0 ? resultados[3][0] : null;

            return {
                anoReferencia: anoRef,
                suaCompanhia: montarHubCirculacaoItem(hubCompRow, totalComp),
                mercado: montarHubCirculacaoItem(hubMercRow, totalMerc)
            };
        });
    });
}

function obterMesMaiorProcuraRotas(idCompanhia) {
    let id = Number(idCompanhia);
    if (isNaN(id) || id <= 0) id = 0;

    let nomesMeses = [
        "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
        "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
    ];

    return obterAnoReferencia(id).then(function (anoRef) {
        let anoAnterior = anoRef - 1;
        let inicioAno = `${anoRef}-01-01`;
        let fimAno = `${anoRef + 1}-01-01`;
        let inicioAnoAnt = `${anoAnterior}-01-01`;
        let fimAnoAnt = `${anoAnterior + 1}-01-01`;

        let sqlMeses = `
            SELECT
                MONTH(ad.dia) AS mes,
                COUNT(DISTINCT v.idVoo) AS quantidadeVoos,
                SUM(v.qtdPassageiros) AS totalPassageiros
            FROM voo v
            STRAIGHT_JOIN aeroportoDirecao ad ON ad.fkVoo = v.idVoo AND ad.direcao = 'Partida'
            WHERE v.fkCompanhia = ?
            AND ad.dia >= ? AND ad.dia < ?
            AND v.qtdPassageiros IS NOT NULL
            GROUP BY MONTH(ad.dia)
            ORDER BY totalPassageiros DESC, quantidadeVoos DESC;
        `;

        return database.executar(sqlMeses, [id, inicioAno, fimAno]).then(function (meses) {
            if (!meses || meses.length === 0) {
                return {
                    anoReferencia: anoRef,
                    mesNome: 'Sem dados',
                    shareGeral: 0,
                    vsAnoAnterior: null
                };
            }

            let mesCampeao = meses[0];
            let mesNum = Number(mesCampeao.mes);
            let mesNome = nomesMeses[mesNum - 1] || 'Sem dados';
            let passCampeao = Number(mesCampeao.totalPassageiros) || 0;

            let totalPassAno = meses.reduce(function (acum, m) {
                return acum + (Number(m.totalPassageiros) || 0);
            }, 0);

            let shareGeral = totalPassAno > 0 ? Number(((passCampeao / totalPassAno) * 100).toFixed(1)) : 0;

            let mesFormatado = String(mesNum).padStart(2, '0');
            let dataMesAnt = `${anoAnterior}-${mesFormatado}-01`;
            let sqlMesAnoAnterior = `
                SELECT
                    SUM(v.qtdPassageiros) AS totalPassageiros
                FROM voo v
                STRAIGHT_JOIN aeroportoDirecao ad ON ad.fkVoo = v.idVoo AND ad.direcao = 'Partida'
                WHERE v.fkCompanhia = ?
                AND ad.dia >= ?
                AND ad.dia < DATE_ADD(?, INTERVAL 1 MONTH)
                AND v.qtdPassageiros IS NOT NULL;
            `;

            let sqlTotalAnoAnterior = `
                SELECT
                    SUM(v.qtdPassageiros) AS totalPassageiros
                FROM voo v
                STRAIGHT_JOIN aeroportoDirecao ad ON ad.fkVoo = v.idVoo AND ad.direcao = 'Partida'
                WHERE v.fkCompanhia = ?
                AND ad.dia >= ? AND ad.dia < ?
                AND v.qtdPassageiros IS NOT NULL;
            `;

            return Promise.all([
                database.executar(sqlMesAnoAnterior, [id, dataMesAnt, dataMesAnt]),
                database.executar(sqlTotalAnoAnterior, [id, inicioAnoAnt, fimAnoAnt])
            ]).then(function (resAnt) {
                let passMesAnt = resAnt[0].length > 0 ? Number(resAnt[0][0].totalPassageiros) || 0 : 0;
                let totalAnoAnt = resAnt[1].length > 0 ? Number(resAnt[1][0].totalPassageiros) || 0 : 0;

                let vsAnoAnterior = null;
                if (totalAnoAnt > 0) {
                    let shareAnt = (passMesAnt / totalAnoAnt) * 100;
                    vsAnoAnterior = Number((shareGeral - shareAnt).toFixed(1));
                }

                return {
                    anoReferencia: anoRef,
                    mesNome: mesNome,
                    mesNumero: mesNum,
                    shareGeral: shareGeral,
                    vsAnoAnterior: vsAnoAnterior
                };
            });
        });
    });
}

module.exports = {
    obterBenchmarkOcupacao,
    obterVolumeMedioPassageiros,
    obterMesMaiorProcura,
    obterTaxaOcupacaoMedia,
    obterRotaMaiorIncidencia,
    obterAeroportoMenorProcura,
    obterHubMaiorCirculacao,
    obterMesMaiorProcuraRotas
};
