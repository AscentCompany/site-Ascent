let alertaModel = require("../models/alertaModel");

function listarRegras(req, res) {
    alertaModel.listarRegras(req.params.idCompanhia)
        .then(r => res.json(r))
        .catch(e => res.status(500).json(e.sqlMessage || e));
}


function criarRegra(req, res) {
    let { faixaOcupacao, severidade, janelaAnalise, janelaInicio, janelaFim, ativo, idCompanhia, idUsuario } = req.body;

    if (!faixaOcupacao || !severidade || !janelaAnalise || !idCompanhia || !idUsuario)
        return res.status(400).json({ mensagem: "Campos obrigatórios ausentes." });

    alertaModel.criarRegra(faixaOcupacao, severidade, janelaAnalise, janelaInicio || null, janelaFim || null, ativo, idCompanhia, idUsuario)
        .then(function (resultado) {
            if (ativo) return alertaModel.processarRegra(resultado.insertId, idCompanhia);
        })
        .then(() => res.status(201).json({ mensagem: "Regra criada." }))
        .catch(function (e) {
            if (e.duplicata) return res.status(409).json({ mensagem: e.mensagem });
            res.status(500).json(e.sqlMessage || e);
        });
}

function editarRegra(req, res) {
    let { faixaOcupacao, severidade, janelaAnalise, janelaInicio, janelaFim, ativo, idCompanhia } = req.body;

    if (!faixaOcupacao || !severidade || !janelaAnalise || !idCompanhia)
        return res.status(400).json({ mensagem: "Campos obrigatórios ausentes." });

    alertaModel.editarRegra(req.params.idRegra, faixaOcupacao, severidade, janelaAnalise, janelaInicio || null, janelaFim || null, ativo, idCompanhia)
        .then(function () {
            if (ativo) return alertaModel.processarRegra(req.params.idRegra, idCompanhia);
        })
        .then(() => res.json({ mensagem: "Regra atualizada." }))
        .catch(function (e) {
            if (e.duplicata) return res.status(409).json({ mensagem: e.mensagem });
            res.status(500).json(e.sqlMessage || e);
        });
}


function excluirRegra(req, res) {
    alertaModel.excluirRegra(req.params.idRegra, req.params.idCompanhia)
        .then(() => res.json({ mensagem: "Regra excluída." }))
        .catch(e => res.status(500).json(e.sqlMessage || e));
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
