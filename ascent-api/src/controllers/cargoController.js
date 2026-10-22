var cargoModel = require("../models/cargoModel");

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
    var permissoes = req.body.permissoesServer;

    cargoModel.cadastrarCargo(nomeCargo, idCompanhia)
        .then(() => {
            return cargoModel.buscarUltimoCargo(idCompanhia);
        })
        .then(resultadoUltimo => {
            var idNovoCargo = resultadoUltimo[0].idNovoCargo;

            if (permissoes.length === 0) {
                res.json({ mensagem: "Cargo salvo sem permissões" });
                return;
            }

            let salvos = 0;
            for (let i = 0; i < permissoes.length; i++) {
                cargoModel.cadastrarCargoPermissao(idNovoCargo, permissoes[i])
                    .then(() => {
                        salvos++;
                        if (salvos === permissoes.length) {
                            res.json({ mensagem: "Cargo e permissões cadastrados!" });
                        }
                    })
                    .catch(erro => {
                        console.log("Erro ao salvar permissão:", erro);
                    });
            }
        })
        .catch(erro => res.status(500).json(erro.sqlMessage));
}

function deletar(req, res) {
    var idCargo = req.params.idCargo;

    // primeiro deleta na associativa, depois o cargo
    cargoModel.deletarCargoPermissoes(idCargo)
        .then(() => {
            return cargoModel.deletarCargo(idCargo);
        })
        .then(resultado => {
            res.json(resultado);
        })
        .catch(erro => {
            console.log(erro);
            res.status(500).json(erro.sqlMessage);
        });
}

module.exports = {
    verificarPermissaoAdmin,
    listarCargos,
    listarPermissoes,
    cadastrar,
    deletar

}