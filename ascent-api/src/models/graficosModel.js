var database = require("../../database/config");

function obterInformativoRotas(idCompanhia, anoReferencia) {
    let id = Number(idCompanhia);
    if (!Number.isInteger(id) || id <= 0) {
        return Promise.reject(new Error("ID da companhia inválido ou não informado."));
    }

    let ano = Number(anoReferencia);
    if (!Number.isInteger(ano) || ano <= 0) {
        return Promise.reject(new Error("Ano de referência inválido ou não informado."));
    }

    let sql = `
        SELECT
            CONCAT(
                COALESCE(NULLIF(TRIM(origem.nomeAeroporto), ''), NULLIF(TRIM(origem.municipio), ''), CONCAT('Aeroporto ', origem.idAeroporto)),
                ' - ',
                COALESCE(NULLIF(TRIM(destino.nomeAeroporto), ''), NULLIF(TRIM(destino.municipio), ''), CONCAT('Aeroporto ', destino.idAeroporto))
            ) AS rota,
            COUNT(DISTINCT v.idVoo) AS quantidadeVoos,
            SUM(v.qtdPassageiros) AS totalPassageiros,
            SUM(av.numAssentos) AS totalAssentos
        FROM voo v
        STRAIGHT_JOIN aeroportoDirecao partida
            ON partida.fkVoo = v.idVoo AND partida.direcao = 'Partida'
        STRAIGHT_JOIN aeroportoDirecao chegada
            ON chegada.fkVoo = v.idVoo AND chegada.direcao = 'Destino'
        STRAIGHT_JOIN aviao av ON av.idAviao = v.fkAviao
        STRAIGHT_JOIN aeroporto origem ON origem.idAeroporto = partida.fkAeroporto
        STRAIGHT_JOIN aeroporto destino ON destino.idAeroporto = chegada.fkAeroporto
        WHERE v.fkCompanhia = ?
          AND v.qtdPassageiros IS NOT NULL
          AND av.numAssentos > 0
          AND partida.dia >= ?
          AND partida.dia < ?
        GROUP BY partida.fkAeroporto, chegada.fkAeroporto,
                 origem.nomeAeroporto, destino.nomeAeroporto,
                 origem.municipio, destino.municipio;
    `;

    return database.executar(sql, [
        id,
        ano + "-01-01",
        (ano + 1) + "-01-01"
    ], { logResultados: false });
}

function obterPontosCapacidadeOcupacao(idCompanhia, anoReferencia) {
    let id = Number(idCompanhia);
    let ano = Number(anoReferencia);
    if (!Number.isInteger(id) || id <= 0 || !Number.isInteger(ano) || ano <= 0) {
        return Promise.reject(new Error("Companhia ou ano de referência inválido."));
    }

    let sql = `
        SELECT
            av.numAssentos AS capacidade,
            v.qtdPassageiros AS passageiros,
            COUNT(*) AS voosMercado,
            SUM(v.fkCompanhia = ?) AS voosCompanhia
        FROM aeroportoDirecao partida
        STRAIGHT_JOIN voo v ON v.idVoo = partida.fkVoo
        STRAIGHT_JOIN aviao av ON av.idAviao = v.fkAviao
        WHERE partida.direcao = 'Partida'
          AND partida.dia >= ?
          AND partida.dia < ?
          AND v.qtdPassageiros IS NOT NULL
          AND av.numAssentos > 0
        GROUP BY av.numAssentos, v.qtdPassageiros;
    `;

    return database.executar(sql, [
        id,
        ano + "-01-01",
        (ano + 1) + "-01-01"
    ], { logResultados: false });
}

function obterMediasMensaisProcura(idCompanhia, anoReferencia) {
    let id = Number(idCompanhia);
    let ano = Number(anoReferencia);
    if (!Number.isInteger(id) || id <= 0 || !Number.isInteger(ano) || ano <= 0) {
        return Promise.reject(new Error("Companhia ou ano de referência inválido."));
    }

    let sql = `
        SELECT
            MONTH(partida.dia) AS mes,
            AVG(v.qtdPassageiros) AS mediaPassageiros,
            AVG(av.numAssentos) AS mediaAssentos,
            COUNT(*) AS quantidadeVoos
        FROM voo v
        STRAIGHT_JOIN aeroportoDirecao partida
            ON partida.fkVoo = v.idVoo AND partida.direcao = 'Partida'
        STRAIGHT_JOIN aviao av ON av.idAviao = v.fkAviao
        WHERE v.fkCompanhia = ?
          AND partida.dia >= ?
          AND partida.dia < ?
          AND v.qtdPassageiros IS NOT NULL
          AND av.numAssentos > 0
        GROUP BY MONTH(partida.dia)
        ORDER BY mes;
    `;

    return database.executar(sql, [
        id,
        ano + "-01-01",
        (ano + 1) + "-01-01"
    ], { logResultados: false });
}

module.exports = {
    obterInformativoRotas,
    obterPontosCapacidadeOcupacao,
    obterMediasMensaisProcura
};
