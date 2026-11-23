let alertaModel = require("../models/alertaModel");
let logModel = require("../models/logModel");

function listarRegras(req, res) {
    alertaModel.listarRegras(req.params.idCompanhia)
        .then(r => res.json(r))
        .catch(e => res.status(500).json(e.sqlMessage || e));
}


function criarRegra(req, res) {
    let { faixaOcupacao, severidade, janelaAnalise, janelaInicio, janelaFim, ativo, idCompanhia, idUsuario } = req.body;

    if (!faixaOcupacao || !severidade || !janelaAnalise || !idCompanhia || !idUsuario)
        return res.status(400).json({ mensagem: "Campos obrigatórios ausentes." });

    let idRegraInserida;

    alertaModel.criarRegra(faixaOcupacao, severidade, janelaAnalise, janelaInicio || null, janelaFim || null, ativo, idCompanhia, idUsuario)
        .then(function (resultado) {
            idRegraInserida = resultado.insertId;
            if (ativo) return alertaModel.processarRegra(idRegraInserida, idCompanhia);
        })
        .then(function () {
            logModel.registrarLog(
                "GESTÃO DE ALERTAS",
                "CRIACAO_REGRA",
                `Regra criada: faixa ${faixaOcupacao}%, severidade ${severidade}`,
                "alertas.html",
                idUsuario
            );
            res.status(201).json({ mensagem: "Regra criada." });
        })
        .catch(function (e) {
            if (e.duplicata) return res.status(409).json({ mensagem: e.mensagem });
            logModel.registrarLog(
                "GESTÃO DE ALERTAS",
                "CRIACAO_REGRA_ERRO",
                `Falha ao criar regra: faixa ${faixaOcupacao}%, severidade ${severidade}`,
                "alertas.html",
                idUsuario
            );
            res.status(500).json(e.sqlMessage || e);
        });
}

function editarRegra(req, res) {
    let { faixaOcupacao, severidade, janelaAnalise, janelaInicio, janelaFim, ativo, idCompanhia, fkUsuarioAcao } = req.body;

    if (!faixaOcupacao || !severidade || !janelaAnalise || !idCompanhia)
        return res.status(400).json({ mensagem: "Campos obrigatórios ausentes." });

    let idRegra = req.params.idRegra;

    alertaModel.editarRegra(idRegra, faixaOcupacao, severidade, janelaAnalise, janelaInicio || null, janelaFim || null, ativo, idCompanhia)
        .then(function () {
            if (ativo) return alertaModel.processarRegra(idRegra, idCompanhia);
        })
        .then(function () {
            logModel.registrarLog(
                "GESTÃO DE ALERTAS",
                "EDICAO_REGRA",
                `Regra ID ${idRegra} atualizada: faixa ${faixaOcupacao}%, severidade ${severidade}`,
                "alertas.html",
                fkUsuarioAcao || null
            );
            res.json({ mensagem: "Regra atualizada." });
        })
        .catch(function (e) {
            if (e.duplicata) return res.status(409).json({ mensagem: e.mensagem });
            logModel.registrarLog(
                "GESTÃO DE ALERTAS",
                "EDICAO_REGRA_ERRO",
                `Falha ao atualizar regra ID ${idRegra}`,
                "alertas.html",
                fkUsuarioAcao || null
            );
            res.status(500).json(e.sqlMessage || e);
        });
}


function excluirRegra(req, res) {
    let idRegra = req.params.idRegra;
    let idCompanhia = req.params.idCompanhia;
    let fkUsuarioAcao = req.body.fkUsuarioAcao || null;

    alertaModel.excluirRegra(idRegra, idCompanhia)
        .then(function () {
            logModel.registrarLog(
                "GESTÃO DE ALERTAS",
                "EXCLUSAO_REGRA",
                `Regra ID ${idRegra} excluída`,
                "alertas.html",
                fkUsuarioAcao
            );
            res.json({ mensagem: "Regra excluída." });
        })
        .catch(function (e) {
            logModel.registrarLog(
                "GESTÃO DE ALERTAS",
                "EXCLUSAO_REGRA_ERRO",
                `Falha ao excluir regra ID ${idRegra}`,
                "alertas.html",
                fkUsuarioAcao
            );
            res.status(500).json(e.sqlMessage || e);
        });
}

function listarAlertas(req, res) {
    alertaModel.listarAlertas(req.params.idCompanhia, req.query.naoLidas === "true")
        .then(r => res.json(r))
        .catch(e => res.status(500).json(e.sqlMessage || e));
}

function contarNaoLidas(req, res) {
    alertaModel.contarNaoLidas(req.params.idCompanhia)
        .then(r => res.json({ total: r[0].total }))
        .catch(e => res.status(500).json(e.sqlMessage || e));
}


function marcarLida(req, res) {
    alertaModel.marcarLida(req.params.idAlerta, req.params.idCompanhia)
        .then(() => res.json({ mensagem: "Lido." }))
        .catch(e => res.status(500).json(e.sqlMessage || e));
}

function marcarTodasLidas(req, res) {
    alertaModel.marcarTodasLidas(req.params.idCompanhia)
        .then(() => res.json({ mensagem: "Todos lidos." }))
        .catch(e => res.status(500).json(e.sqlMessage || e));
}

function detalheAlerta(req, res) {
    alertaModel.detalheAlerta(req.params.idAlerta, req.params.idCompanhia)
        .then(r => res.json(r))
        .catch(e => res.status(500).json(e.sqlMessage || e));
}


module.exports = {
    listarRegras,
    criarRegra,
    editarRegra,
    excluirRegra,
    listarAlertas,
    contarNaoLidas,
    marcarLida,
    marcarTodasLidas,
    detalheAlerta
};
