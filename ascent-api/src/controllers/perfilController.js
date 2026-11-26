var perfilModel = require("../models/perfilModel");

function buscar(req, res) {
    var idUsuario = req.params.idUsuario;

    if (!idUsuario || isNaN(idUsuario)) {
        return res.status(400).json({ mensagem: "ID de usuário inválido." });
    }

    perfilModel.buscarPorId(idUsuario)
        .then(function (resultado) {
            if (resultado.length === 0) {
                return res.status(404).json({ mensagem: "Usuário não encontrado." });
            }
            res.status(200).json(resultado[0]);
        })
        .catch(function (erro) {
            console.log("Erro ao buscar perfil:", erro.sqlMessage || erro);
            res.status(500).json({ mensagem: "Erro ao buscar dados do perfil." });
        });
}

function alterarSenha(req, res) {
    var idUsuario = req.body.idUsuario;
    var senhaAtual = req.body.senhaAtual;
    var novaSenha = req.body.novaSenha;
    var confirmaSenha = req.body.confirmaSenha;

    if (!idUsuario || !senhaAtual || !novaSenha || !confirmaSenha) {
        return res.status(400).json({ mensagem: "Preencha todos os campos de senha." });
    }
    if (novaSenha !== confirmaSenha) {
        return res.status(400).json({ mensagem: "A nova senha e a confirmação não coincidem." });
    }
    if (novaSenha === senhaAtual) {
        return res.status(400).json({ mensagem: "A nova senha deve ser diferente da atual." });
    }
    if (novaSenha.length < 6) {
        return res.status(400).json({ mensagem: "A nova senha deve ter pelo menos 6 caracteres." });
    }

    perfilModel.validarSenhaAtual(idUsuario, senhaAtual)
        .then(function (resultado) {
            if (resultado.length === 0) {
                res.status(401).json({ mensagem: "A senha atual está incorreta." });
                return null;
            }
            return perfilModel.atualizarSenha(idUsuario, novaSenha).then(function () {
                res.status(200).json({ mensagem: "Senha alterada com sucesso!" });
            });
        })
        .catch(function (erro) {
            console.log("Erro ao alterar senha:", erro.sqlMessage || erro);
            res.status(500).json({ mensagem: "Erro ao alterar a senha." });
        });
}

module.exports = {
    buscar,
    alterarSenha
};
