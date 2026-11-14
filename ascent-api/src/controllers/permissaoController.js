var permissaoModel = require("../models/permissaoModel");
var logModel = require("../models/logModel");

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
    let fkUsuarioAcao = req.body.fkUsuarioAcao;

    permissaoModel.cadastrarPermissao(nomePermissao)
        .then(() => {
            return permissaoModel.buscarUltimaPermissao();
        })
        .then(resultadoUltimo => {
            var idNovaPermissao = resultadoUltimo[0].idNovaPermissao;

            if (funcionalidades.length === 0) {
                logModel.registrarLog("GESTÃO DE PERMISSÃO", "CADASTRO", `Cadastrou a permissão ${nomePermissao} sem funcionalidades`, "permissoes.html", fkUsuarioAcao);
                res.json({ mensagem: "Permissão salva sem funcionalidades" });
                return;
            }

            let salvos = 0;
            for (let i = 0; i < funcionalidades.length; i++) {
                permissaoModel.cadastrarPermissaoFuncionalidade(idNovaPermissao, funcionalidades[i])
                    .then(() => {
                        salvos++;
                        if (salvos === funcionalidades.length) {
                            logModel.registrarLog("GESTÃO DE PERMISSÃO", "CADASTRO", `Cadastrou a permissão ${nomePermissao}`, "permissoes.html", fkUsuarioAcao);
                            res.json({ mensagem: "Permissão e funcionalidades cadastradas!" });
                        }
                    })
                    .catch(erro => {
                        console.log(erro);
                        logModel.registrarLog("GESTÃO DE PERMISSÃO", "CADASTRO_ERRO", `Falha ao vincular a funcionalidade ID ${funcionalidades[i]} na permissão ${nomePermissao}`, "permissoes.html", fkUsuarioAcao);
                    });
            }
        })
        .catch(erro => {
            logModel.registrarLog("GESTÃO DE PERMISSÃO", "CADASTRO_ERRO", `Falha ao cadastrar a permissão ${nomePermissao}`, "permissoes.html", fkUsuarioAcao);
            res.status(500).json(erro.sqlMessage);
        });
}

function buscarCargosVinculados(req, res) {
    var idPermissao = req.params.idPermissao;
    permissaoModel.buscarCargosDaPermissao(idPermissao)
        .then(resultado => res.json(resultado))
        .catch(erro => res.status(500).json(erro.sqlMessage));
}

function deletar(req, res) {
    var idPermissao = req.params.idPermissao;
    let fkUsuarioAcao = req.query.fkUsuarioAcao || req.body.fkUsuarioAcao;

    permissaoModel.contarPermissoes()
        .then(resultado => {
            let qtdPermissoes = resultado[0].qtd;

            if (qtdPermissoes <= 1) {
                permissaoModel.deletarPermissaoFuncionalidades(idPermissao)
                    .then(() => {
                        logModel.registrarLog("GESTÃO DE PERMISSÃO", "EXCLUSAO", `Removeu as funcionalidades da última permissão ID ${idPermissao} (a permissão foi mantida)`, "permissoes.html", fkUsuarioAcao);
                        res.json({ mensagem: "Como esta é a última permissão do sistema, ela não foi excluída, mas todas as suas funcionalidades foram removidas!" });
                    })
                    .catch(erro => {
                        logModel.registrarLog("GESTÃO DE PERMISSÃO", "EXCLUSAO_ERRO", `Falha ao remover as funcionalidades da permissão ID ${idPermissao}`, "permissoes.html", fkUsuarioAcao);
                        res.status(500).json(erro.sqlMessage);
                    });
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
                        logModel.registrarLog("GESTÃO DE PERMISSÃO", "EXCLUSAO", `Excluiu a permissão ID ${idPermissao}`, "permissoes.html", fkUsuarioAcao);
                        res.json({ mensagem: "Permissão excluída com sucesso!" });
                    })
                    .catch(erro => {
                        logModel.registrarLog("GESTÃO DE PERMISSÃO", "EXCLUSAO_ERRO", `Falha ao excluir a permissão ID ${idPermissao}`, "permissoes.html", fkUsuarioAcao);
                        res.status(500).json(erro.sqlMessage);
                    });
            }
        })
        .catch(erro => {
            logModel.registrarLog("GESTÃO DE PERMISSÃO", "EXCLUSAO_ERRO", `Falha ao excluir a permissão ID ${idPermissao}`, "permissoes.html", fkUsuarioAcao);
            res.status(500).json(erro.sqlMessage);
        });
}

function atualizar(req, res) {
    var idPermissao = req.params.idPermissao;
    var funcionalidades = req.body.funcionalidadesServer;
    let fkUsuarioAcao = req.body.fkUsuarioAcao;

    permissaoModel.deletarPermissaoFuncionalidades(idPermissao)
        .then(() => {

            if (funcionalidades.length === 0) {
                logModel.registrarLog("GESTÃO DE PERMISSÃO", "EDICAO", `Removeu todas as funcionalidades da permissão ID ${idPermissao}`, "permissoes.html", fkUsuarioAcao);
                res.json({ mensagem: "A permissão foi atualizada e não possui mais funcionalidades vinculadas." });
                return;
            }

            let salvos = 0;
            for (let i = 0; i < funcionalidades.length; i++) {
                permissaoModel.cadastrarPermissaoFuncionalidade(idPermissao, funcionalidades[i])
                    .then(() => {
                        salvos++;
                        if (salvos === funcionalidades.length) {
                            logModel.registrarLog("GESTÃO DE PERMISSÃO", "EDICAO", `Atualizou as funcionalidades da permissão ID ${idPermissao}`, "permissoes.html", fkUsuarioAcao);
                            res.json({ mensagem: "Permissão atualizada com sucesso!" });
                        }
                    })
                    .catch(erro => {
                        console.log(erro);
                        logModel.registrarLog("GESTÃO DE PERMISSÃO", "EDICAO_ERRO", `Falha ao vincular a funcionalidade ID ${funcionalidades[i]} na permissão ID ${idPermissao}`, "permissoes.html", fkUsuarioAcao);
                    });
            }
        })
        .catch(erro => {
            logModel.registrarLog("GESTÃO DE PERMISSÃO", "EDICAO_ERRO", `Falha ao atualizar as funcionalidades da permissão ID ${idPermissao}`, "permissoes.html", fkUsuarioAcao);
            res.status(500).json(erro.sqlMessage);
        });
}

module.exports = {
    listarPermissoes,
    listarFuncionalidades,
    cadastrar,
    deletar,
    buscarCargosVinculados,
    atualizar
}