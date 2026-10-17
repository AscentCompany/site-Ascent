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

function buscarCargosVinculados(req, res) {
    var idPermissao = req.params.idPermissao;
    permissaoModel.buscarCargosDaPermissao(idPermissao)
        .then(resultado => res.json(resultado))
        .catch(erro => res.status(500).json(erro.sqlMessage));
}

function deletar(req, res) {
    var idPermissao = req.params.idPermissao;

    permissaoModel.contarPermissoes()
        .then(resultado => {
            let qtdPermissoes = resultado[0].qtd;

            if (qtdPermissoes <= 1) {
                permissaoModel.deletarPermissaoFuncionalidades(idPermissao)
                    .then(() => {
                        res.json({ mensagem: "Como esta é a última permissão do sistema, ela não foi excluída, mas todas as suas funcionalidades foram removidas!" });
                    })
                    .catch(erro => res.status(500).json(erro.sqlMessage));
            }
            else {
                permissaoModel.deletarCargoPermissoesPorPermissao(idPermissao)
                    .then(() => {
                        return permissaoModel.deletarPermissaoFuncionalidades(idPermissao);
                    })
                    .then(() => {
                        return permissaoModel.deletarPermissao(idPermissao);
                    })
                    .then(() => {
                        res.json({ mensagem: "Permissão excluída com sucesso!" });
                    })
                    .catch(erro => res.status(500).json(erro.sqlMessage));
            }
        })
        .catch(erro => res.status(500).json(erro.sqlMessage));
}

function atualizar(req, res) {
    var idPermissao = req.params.idPermissao;
    var funcionalidades = req.body.funcionalidadesServer;

    permissaoModel.deletarPermissaoFuncionalidades(idPermissao)
        .then(() => {

            if (funcionalidades.length === 0) {
                res.json({ mensagem: "A permissão foi atualizada e não possui mais funcionalidades vinculadas." });
                return;
            }

            let salvos = 0;
            for (let i = 0; i < funcionalidades.length; i++) {
                permissaoModel.cadastrarPermissaoFuncionalidade(idPermissao, funcionalidades[i])
                    .then(() => {
                        salvos++;
                        if (salvos === funcionalidades.length) {
                            res.json({ mensagem: "Permissão atualizada com sucesso!" });
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
    cadastrar,
    deletar,
    buscarCargosVinculados,
    atualizar
}