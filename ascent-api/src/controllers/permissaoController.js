var permissaoModel = require("../models/permissaoModel");

function listarPermissoes(req, res) {
    permissaoModel.listarPermissoes()
        .then(resultado => res.json(resultado))
        .catch(erro => res.status(500).json(erro.sqlMessage));
}

function listarFuncionalidades(req, res) {
    permissaoModel.listarFuncionalidades()
        .then(resultado => res.json(resultado))
        .catch(erro => res.status(500).json(erro.sqlMessage));
}

function cadastrar(req, res) {
    var nomePermissao = req.body.nomePermissaoServer;
    var funcionalidades = req.body.funcionalidadesServer;

    permissaoModel.cadastrarPermissao(nomePermissao)
        .then(() => {
            return permissaoModel.buscarUltimaPermissao();
        })
        .then(resultadoUltimo => {
            var idNovaPermissao = resultadoUltimo[0].idNovaPermissao;

            if (funcionalidades.length === 0) {
                res.json({ mensagem: "Permissão salva sem funcionalidades" });
                return;
            }

            let salvos = 0;
            for (let i = 0; i < funcionalidades.length; i++) {
                permissaoModel.cadastrarPermissaoFuncionalidade(idNovaPermissao, funcionalidades[i])
                    .then(() => {
                        salvos++;
                        if (salvos === funcionalidades.length) {
                            res.json({ mensagem: "Permissão e funcionalidades cadastradas!" });
                        }
                    })
                    .catch(erro => console.log(erro));
            }
        })
        .catch(erro => res.status(500).json(erro.sqlMessage));
}

module.exports = {
    listarPermissoes,
    listarFuncionalidades,
    cadastrar
}