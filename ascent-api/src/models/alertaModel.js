let database = require("../../database/config");


function listarRegras(idCompanhia) {
    return database.executar(`
        SELECT idRegraAlerta, faixaOcupacao, severidade,
               janelaAnalise, janelaInicio, janelaFim, ativo, dataCriacao
        FROM regraAlerta
        WHERE fkCompanhia = ${idCompanhia}
        ORDER BY dataCriacao DESC;
    `);
}


function checarDuplicata(faixaOcupacao, janelaAnalise, janelaInicio, janelaFim, idCompanhia, excluirId) {
    let filtroId = excluirId ? `AND idRegraAlerta != ${excluirId}` : "";
    let filtroInicio = janelaInicio ? `janelaInicio = '${janelaInicio}'` : 'janelaInicio IS NULL';
    let filtroFim = janelaFim ? `janelaFim = '${janelaFim}'` : 'janelaFim IS NULL';

    return database.executar(`
        SELECT idRegraAlerta FROM regraAlerta
        WHERE faixaOcupacao = ${faixaOcupacao}
          AND janelaAnalise = '${janelaAnalise}'
          AND fkCompanhia = ${idCompanhia}
          AND ${filtroInicio} AND ${filtroFim}
          ${filtroId}
        LIMIT 1;
    `);
}

function criarRegra(faixaOcupacao, severidade, janelaAnalise, janelaInicio, janelaFim, ativo, idCompanhia, idUsuario) {
    return checarDuplicata(faixaOcupacao, janelaAnalise, janelaInicio, janelaFim, idCompanhia, null)
        .then(function (dup) {

            if (dup.length > 0) return Promise.reject({ duplicata: true, mensagem: "Já existe uma regra com essa configuração." });

            let ini = janelaInicio ? `'${janelaInicio}'` : 'NULL';
            let fim = janelaFim ? `'${janelaFim}'` : 'NULL';

            return database.executar(`
                INSERT INTO regraAlerta (faixaOcupacao, severidade, janelaAnalise, janelaInicio, janelaFim, ativo, fkCompanhia, fkUsuarioCriador)
                VALUES (${faixaOcupacao}, '${severidade}', '${janelaAnalise}', ${ini}, ${fim}, ${ativo ? 1 : 0}, ${idCompanhia}, ${idUsuario});
            `);
        });
}


function editarRegra(idRegra, faixaOcupacao, severidade, janelaAnalise, janelaInicio, janelaFim, ativo, idCompanhia) {
    return checarDuplicata(faixaOcupacao, janelaAnalise, janelaInicio, janelaFim, idCompanhia, idRegra)
        .then(function (dup) {
            if (dup.length > 0) return Promise.reject({ duplicata: true, mensagem: "Já existe uma regra com essa configuração." });

            let ini = janelaInicio ? `'${janelaInicio}'` : 'NULL';
            let fim = janelaFim ? `'${janelaFim}'` : 'NULL';

            return database.executar(`
                UPDATE regraAlerta SET
                    faixaOcupacao = ${faixaOcupacao}, severidade = '${severidade}',
                    janelaAnalise = '${janelaAnalise}', janelaInicio = ${ini}, janelaFim = ${fim},
                    ativo = ${ativo ? 1 : 0}
                WHERE idRegraAlerta = ${idRegra} AND fkCompanhia = ${idCompanhia};
            `);
        });
}

function excluirRegra(idRegra, idCompanhia) {
    return database.executar(`DELETE FROM regraAlerta WHERE idRegraAlerta = ${idRegra} AND fkCompanhia = ${idCompanhia};`);
}


function processarRegra(idRegra, idCompanhia) {
    return database.executar(`SELECT * FROM regraAlerta WHERE idRegraAlerta = ${idRegra} AND fkCompanhia = ${idCompanhia} LIMIT 1;`)
        .then(function (rows) {

            if (!rows.length || !rows[0].ativo) return;

            let r = rows[0];
            let filtroData = "";

            if (r.janelaAnalise === "1_ano") filtroData = "AND ad.dia >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)";
            else if (r.janelaAnalise === "3_anos") filtroData = "AND ad.dia >= DATE_SUB(CURDATE(), INTERVAL 3 YEAR)";
            else if (r.janelaAnalise === "5_anos") filtroData = "AND ad.dia >= DATE_SUB(CURDATE(), INTERVAL 5 YEAR)";
            else if (r.janelaAnalise === "10_anos") filtroData = "AND ad.dia >= DATE_SUB(CURDATE(), INTERVAL 10 YEAR)";
            else if (r.janelaAnalise === "personalizado" && r.janelaInicio && r.janelaFim)
                filtroData = `AND ad.dia BETWEEN '${r.janelaInicio}' AND '${r.janelaFim}'`;

            return database.executar(`
                SELECT ao.uf AS origemIata, ad2.uf AS destinoIata,
                       ROUND(100.0 * SUM(v.qtdPassageiros) / NULLIF(SUM(av.numAssentos), 0), 2) AS ocupacaoMedia
                FROM voo v
                JOIN aeroportoDirecao ad  ON ad.fkVoo = v.idVoo AND ad.direcao = 'ORIGEM'
                JOIN aeroportoDirecao ad3 ON ad3.fkVoo = v.idVoo AND ad3.direcao = 'DESTINO'
                JOIN aeroporto ao  ON ao.idAeroporto = ad.fkAeroporto
                JOIN aeroporto ad2 ON ad2.idAeroporto = ad3.fkAeroporto
                JOIN aviao av ON av.idAviao = v.fkAviao
                WHERE v.fkCompanhia = ${idCompanhia} ${filtroData}
                  AND v.qtdPassageiros IS NOT NULL AND av.numAssentos > 0
                GROUP BY ao.uf, ad2.uf
                HAVING ocupacaoMedia < ${r.faixaOcupacao}
                ORDER BY ocupacaoMedia ASC;
            `).then(function (rotas) {

                return database.executar(`DELETE FROM alerta WHERE fkRegraAlerta = ${idRegra};`)
                    .then(function () {
                        if (!rotas.length) return;

                        let values = rotas.map(function (rt) {
                            return `('${rt.origemIata}', '${rt.destinoIata}', ${rt.ocupacaoMedia}, '${r.severidade}', 0, ${idRegra}, ${idCompanhia})`;
                        }).join(", ");

                        return database.executar(`INSERT INTO alerta (origemIata, destinoIata, ocupacaoMedia, severidade, lida, fkRegraAlerta, fkCompanhia) VALUES ${values};`);
                    });
            });
        });
}


function listarAlertas(idCompanhia, apenasNaoLidas) {
    let filtro = apenasNaoLidas ? "AND a.lida = 0" : "";

    return database.executar(`
        SELECT a.idAlerta, a.origemIata, a.destinoIata,
               CONCAT(a.origemIata, ' → ', a.destinoIata) AS rota,
               a.ocupacaoMedia, a.severidade, a.lida, a.dataCriacao,
               r.faixaOcupacao, r.janelaAnalise, r.janelaInicio, r.janelaFim
        FROM alerta a
        JOIN regraAlerta r ON r.idRegraAlerta = a.fkRegraAlerta
        WHERE a.fkCompanhia = ${idCompanhia} ${filtro}
        ORDER BY a.ocupacaoMedia ASC;
    `);
}

function contarNaoLidas(idCompanhia) {
    return database.executar(`SELECT COUNT(*) AS total FROM alerta WHERE fkCompanhia = ${idCompanhia} AND lida = 0;`);
}

function marcarLida(idAlerta, idCompanhia) {
    return database.executar(`UPDATE alerta SET lida = 1 WHERE idAlerta = ${idAlerta} AND fkCompanhia = ${idCompanhia};`);
}

function marcarTodasLidas(idCompanhia) {
    return database.executar(`UPDATE alerta SET lida = 1 WHERE fkCompanhia = ${idCompanhia};`);
}


function detalheAlerta(idAlerta, idCompanhia) {
    return database.executar(`
        SELECT a.idAlerta, a.origemIata, a.destinoIata,
               CONCAT(a.origemIata, ' → ', a.destinoIata) AS rota,
               a.ocupacaoMedia, a.severidade, a.lida,
               r.faixaOcupacao, r.janelaAnalise, r.janelaInicio, r.janelaFim
        FROM alerta a
        JOIN regraAlerta r ON r.idRegraAlerta = a.fkRegraAlerta
        WHERE a.idAlerta = ${idAlerta} AND a.fkCompanhia = ${idCompanhia} LIMIT 1;
    `).then(function (rows) {

        if (!rows.length) return Promise.reject("Alerta não encontrado.");

        let al = rows[0];

        return database.executar(`
            SELECT YEAR(ad.dia) AS ano,
                   ROUND(100.0 * SUM(v.qtdPassageiros) / NULLIF(SUM(av.numAssentos), 0), 2) AS ocupacaoMedia
            FROM voo v
            JOIN aeroportoDirecao ad  ON ad.fkVoo = v.idVoo AND ad.direcao = 'ORIGEM'
            JOIN aeroportoDirecao ad3 ON ad3.fkVoo = v.idVoo AND ad3.direcao = 'DESTINO'
            JOIN aeroporto ao  ON ao.idAeroporto = ad.fkAeroporto
            JOIN aeroporto ad2 ON ad2.idAeroporto = ad3.fkAeroporto
            JOIN aviao av ON av.idAviao = v.fkAviao
            WHERE v.fkCompanhia = ${idCompanhia}
              AND ao.uf = '${al.origemIata}' AND ad2.uf = '${al.destinoIata}'
              AND v.qtdPassageiros IS NOT NULL AND av.numAssentos > 0
            GROUP BY YEAR(ad.dia) ORDER BY ano DESC LIMIT 10;
        `).then(function (historico) {
            return { alerta: al, historico: historico };
        });
    });
}

module.exports = {
    listarRegras,
    criarRegra,
    editarRegra,
    excluirRegra,
    processarRegra,
    listarAlertas,
    contarNaoLidas,
    marcarLida,
    marcarTodasLidas,
    detalheAlerta
};
