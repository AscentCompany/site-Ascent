var cargoModel = require("../models/cargoModel");
const logModel = require("../models/logModel");

function verificarPermissaoAdmin(req, res) {
    var idCompanhia = req.params.idCompanhia;
    cargoModel.verificarPermissaoAdmin(idCompanhia)
        .then(resultado => res.json(resultado))
        .catch(erro => res.status(500).json(erro.sqlMessage));
}

function listarCargos(req, res) {
    var idCompanhia = req.params.idCompanhia;
    cargoModel.listarCargos(idCompanhia)
        .then(resultado => res.json(resultado))
        .catch(erro => res.status(500).json(erro.sqlMessage));
}

function listarPermissoes(req, res) {
    cargoModel.listarPermissoes()
        .then(resultado => res.json(resultado))
        .catch(erro => res.status(500).json(erro.sqlMessage));
}

function cadastrar(req, res) {
    var nomeCargo = req.body.nomeCargoServer;
    var idCompanhia = req.body.idCompanhiaServer;
    var permissoes = req.body.permissoesServer || [];
    var fkUsuarioAcao = req.body.fkUsuarioAcao || null;

    cargoModel.cadastrarCargo(nomeCargo, idCompanhia)
        .then(() => {
            return cargoModel.buscarUltimoCargo(idCompanhia);
        })
        .then(resultadoUltimo => {
            var idNovoCargo = resultadoUltimo[0].idNovoCargo;

            // Regra de negocio: todo cargo exceto 'Padrao' recebe a permissao de Perfil ('Editar Usuario') por padrao
            var promessaPermissoes = Promise.resolve(permissoes);
            var isPadrao = String(nomeCargo || "").toLowerCase().indexOf("padra") !== -1;
            if (!isPadrao) {
                promessaPermissoes = cargoModel.listarPermissoes().then(lista => {
                    var permPerfil = lista.find(p => p.nome === "Editar Usuario");
                    if (permPerfil && !permissoes.some(id => Number(id) === Number(permPerfil.idPermissao))) {
                        return permissoes.concat([permPerfil.idPermissao]);
                    }
                    return permissoes;
                });
            }

            return promessaPermissoes.then(permissoesFinais => {
                if (permissoesFinais.length === 0) {
                    logModel.registrarLog("GESTÃO DE CARGO", "CADASTRO", `Cadastrou o cargo ${nomeCargo}`, "cargos.html", fkUsuarioAcao);
                    res.json({ mensagem: "Cargo salvo sem permissões" });
                    return;
                }

                var promessas = permissoesFinais.map(idPermissao => {
                    return cargoModel.cadastrarCargoPermissao(idNovoCargo, idPermissao);
                });

                return Promise.all(promessas)
                    .then(() => {
                        logModel.registrarLog("GESTÃO DE CARGO PERMISSÃO", "CADASTRO", `Cadastrou o cargo ${nomeCargo} com permissões ${permissoesFinais.join(", ")}`, "cargos.html", fkUsuarioAcao);
                        res.json({ mensagem: "Cargo e permissões cadastrados!" });
                    })
                    .catch(erro => {
                        console.error("Erro ao salvar permissão:", erro);
                        logModel.registrarLog("GESTÃO DE CARGO PERMISSÃO", "CADASTRO_ERRO", `Falha ao cadastrar permissões ao cargo ${nomeCargo}`, "cargos.html", fkUsuarioAcao);
                        res.status(500).json(erro.sqlMessage || "Erro ao vincular permissões.");
                    });
            });
        })
        .catch(erro => {
            console.error("Erro ao cadastrar cargo:", erro);
            logModel.registrarLog("GESTÃO DE CARGO", "CADASTRO_ERRO", `Falha ao cadastrar cargo ${nomeCargo}`, "cargos.html", fkUsuarioAcao);
            res.status(500).json(erro.sqlMessage || "Erro ao criar cargo.");
            let salvos = 0;
            for (let i = 0; i < permissoes.length; i++) {
                cargoModel.cadastrarCargoPermissao(idNovoCargo, permissoes[i])
                    .then(() => {
                        salvos++;
                        if (salvos === permissoes.length) {
                            logModel.registrarLog("GESTÃO DE CARGO PERMISSÃO", "CADASTRO", `Cadastrou o cargo ${nomeCargo} com permissões ${permissoes[i]}`, "cargos.html", fkUsuarioAcao);
                            res.json({ mensagem: "Cargo e permissões cadastrados!" });
                        }
                    })
                    .catch(erro => {
                        logModel.registrarLog("GESTÃO DE CARGO PERMISSÃO", "CADASTRO_ERRO", `Falha ao cadastrar a permissões ${permissoes[i]} ao cargo ${nomeCargo}`, "cargo.html", fkUsuarioAcao);
                        console.log("Erro ao salvar permissão:", erro);
                    });
            }
        })
        .catch(erro => {
            logModel.registrarLog("GESTÃO DE CARGO", "CADASTRO_ERRO", `Falha ao cadastrar cargo ${nomeCargo}`, "cargos.html", fkUsuarioAcao);
            res.status(500).json(erro.sqlMessage)
        });
}

function deletar(req, res) {
    var idCargo = req.params.idCargo;
    var nomeCargo = req.body.nomeCargo || idCargo;
    var fkUsuarioAcao = req.query.fkUsuarioAcao || req.body.fkUsuarioAcao || null;

    // primeiro deleta na associativa, depois o cargo
    cargoModel.deletarCargoPermissoes(idCargo)
        .then(() => {
            logModel.registrarLog("GESTÃO DE CARGO", "EXCLUSAO", `Excluiu as permissões do cargo ${nomeCargo} da Tabela CargoPermissão`, "cargos.html", fkUsuarioAcao);
            return cargoModel.deletarCargo(idCargo);
        })
        .then(resultado => {
            logModel.registrarLog("GESTÃO DE CARGO", "EXCLUSAO", `Excluiu o cargo ${nomeCargo}`, "cargos.html", fkUsuarioAcao);
            res.json(resultado);
        })
        .catch(erro => {
            console.error(erro);
            logModel.registrarLog("GESTÃO DE CARGO", "EXCLUSAO_ERRO", `Falha ao excluir o cargo ${nomeCargo}`, "cargos.html", fkUsuarioAcao);
            res.status(500).json(erro.sqlMessage || "Erro ao excluir cargo.");
            ("GESTÃO DE CARGO", "EXCLUSAO", `Excluiu o cargo ${nomeCargo} da Tabela CargoPermissão`, "cargos.html", fkUsuarioAcao);
            return cargoModel.deletarCargo(idCargo);
        })
        .then(resultado => {
            ("GESTÃO DE CARGO", "EXCLUSAO", `Excluiu o cargo ${nomeCargo}`, "cargos.html", fkUsuarioAcao);
            res.json(resultado);
        })
        .catch(erro => {
            console.log(erro);
            ("GESTÃO DE CARGO", "EXCLUSAO_ERRO", `Falha ao excluir o cargo ${nomeCargo}`, "cargos.html", fkUsuarioAcao);
            res.status(500).json(erro.sqlMessage);
        });
}

function atualizar(req, res) {
    var idCargo = req.params.idCargo;
    var permissoes = req.body.permissoesServer || [];
    var nomeCargo = req.body.nomeCargo || idCargo;
    var fkUsuarioAcao = req.body.fkUsuarioAcao || null;

    cargoModel.deletarCargoPermissoes(idCargo)
        .then(() => {
            if (permissoes.length === 0) {
                logModel.registrarLog("GESTÃO DE CARGO PERMISSÃO", "EDICAO", `Removeu as permissões do cargo ${nomeCargo}`, "cargos.html", fkUsuarioAcao);
                res.json({ mensagem: "Todas as permissões foram removidas." });
                return;
            }

            var promessas = permissoes.map(idPermissao => {
                return cargoModel.cadastrarCargoPermissao(idCargo, idPermissao);
            });

            return Promise.all(promessas)
                .then(() => {
                    logModel.registrarLog("GESTÃO DE CARGO PERMISSÃO", "EDICAO", `Atualizou as permissões do cargo ${nomeCargo}`, "cargos.html", fkUsuarioAcao);
                    res.json({ mensagem: "Permissões atualizadas!" });
                })
                .catch(erro => {
                    console.error("Erro ao atualizar permissões:", erro);
                    logModel.registrarLog("GESTÃO DE CARGO PERMISSÃO", "EDICAO_ERRO", `Falha ao atualizar as permissões do cargo ${nomeCargo}`, "cargos.html", fkUsuarioAcao);
                    res.status(500).json(erro.sqlMessage || "Erro ao atualizar permissões.");
                });
        })
        .catch(erro => {
            console.error(erro);
            logModel.registrarLog("GESTÃO DE CARGO PERMISSÃO", "EDICAO_ERRO", `Falha ao remover as permissões do cargo ${nomeCargo}`, "cargos.html", fkUsuarioAcao);
            res.status(500).json(erro.sqlMessage || "Erro ao processar permissões.");
            let salvos = 0;
            for (let i = 0; i < permissoes.length; i++) {
                cargoModel.cadastrarCargoPermissao(idCargo, permissoes[i])
                    .then(() => {
                        salvos++;
                        if (salvos === permissoes.length) {
                            logModel.registrarLog("GESTÃO DE CARGO PERMISSÃO", "EDICAO", `Atualizou as permissões do cargo ${nomeCargo}`, "cargos.html", fkUsuarioAcao);
                            res.json({ mensagem: "Permissões atualizadas!" });
                        }
                    })
                    .catch(erro => {
                        logModel.registrarLog("GESTÃO DE CARGO PERMISSÃO", "EDICAO_ERRO", `Falha ao atualizar as permissões do cargo ${nomeCargo}`, "cargos.html", fkUsuarioAcao);
                        console.log("Erro ao salvar permissão:", erro);
                    });
            }
        })
        .catch(erro => {
            logModel.registrarLog("GESTÃO DE CARGO PERMISSÃO", "EDICAO_ERRO", `Falha ao remover as permissões do cargo ${nomeCargo}`, "cargos.html", fkUsuarioAcao);
            res.status(500).json(erro.sqlMessage)
        });
}

module.exports = {
    verificarPermissaoAdmin,
    listarCargos,
    listarPermissoes,
    cadastrar,
    deletar,
    atualizar
};
