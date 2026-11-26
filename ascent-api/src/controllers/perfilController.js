var perfilModel = require("../models/perfilModel");
var logModel = require("../models/logModel");

// Registra o log sem nunca quebrar a resposta caso o INSERT falhe.
// Importante: jamais colocar senhas na mensagem do log.
function registrar(servico, mensagem, idUsuario) {
    var id = idUsuario && !isNaN(idUsuario) ? idUsuario : null;
    logModel.registrarLog("GESTÃO DE USUÁRIO", servico, mensagem, "perfil.html", id)
        .catch(function (e) {
            console.log("Falha ao registrar log:", e.sqlMessage || e);
        });
}

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
            registrar("PERFIL_BUSCA_ERRO", `Falha ao carregar o perfil do usuário ID ${idUsuario}`, idUsuario);
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
                registrar("ALTERACAO_SENHA_FALHA", `Tentativa de troca de senha com senha atual incorreta (usuário ID ${idUsuario})`, idUsuario);
                res.status(401).json({ mensagem: "A senha atual está incorreta." });
                return null;
            }
            return perfilModel.atualizarSenha(idUsuario, novaSenha).then(function () {
                registrar("ALTERACAO_SENHA", `Usuário ID ${idUsuario} alterou a própria senha`, idUsuario);
                res.status(200).json({ mensagem: "Senha alterada com sucesso!" });
            });
        })
        .catch(function (erro) {
            registrar("ALTERACAO_SENHA_ERRO", `Erro ao alterar a senha do usuário ID ${idUsuario}`, idUsuario);
            console.log("Erro ao alterar senha:", erro.sqlMessage || erro);
            res.status(500).json({ mensagem: "Erro ao alterar a senha." });
        });
}

function atualizarPerfil(req, res) {
    var idUsuario = req.body.idUsuario;
    var nome = req.body.nome ? String(req.body.nome).trim() : null;
    var senhaAtual = req.body.senhaAtual;
    var novaSenha = req.body.novaSenha;
    var confirmaSenha = req.body.confirmaSenha;

    if (!idUsuario || isNaN(idUsuario)) {
        return res.status(400).json({ mensagem: "ID de usuário inválido." });
    }

    if (!nome) {
        return res.status(400).json({ mensagem: "O nome completo não pode ficar em branco." });
    }

    if (nome.length > 45) {
        return res.status(400).json({ mensagem: "O nome completo deve ter no máximo 45 caracteres." });
    }

    var vaiAlterarSenha = Boolean(senhaAtual || novaSenha || confirmaSenha);

    if (vaiAlterarSenha) {
        if (!senhaAtual || !novaSenha || !confirmaSenha) {
            return res.status(400).json({ mensagem: "Para alterar a senha, preencha a senha atual, a nova senha e a confirmação." });
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
                    registrar("ALTERACAO_SENHA_FALHA", `Tentativa de atualizar perfil com senha atual incorreta (usuário ID ${idUsuario})`, idUsuario);
                    res.status(401).json({ mensagem: "A senha atual está incorreta." });
                    return null;
                }
                return perfilModel.atualizarNome(idUsuario, nome)
                    .then(function () {
                        return perfilModel.atualizarSenha(idUsuario, novaSenha);
                    })
                    .then(function () {
                        registrar("EDICAO_PERFIL", `Usuário ID ${idUsuario} atualizou o nome para "${nome}" e alterou a senha`, idUsuario);
                        res.status(200).json({ mensagem: "Perfil e senha atualizados com sucesso!", nome: nome });
                    });
            })
            .catch(function (erro) {
                registrar("EDICAO_PERFIL_ERRO", `Erro ao atualizar perfil e senha do usuário ID ${idUsuario}`, idUsuario);
                console.log("Erro ao atualizar perfil:", erro.sqlMessage || erro);
                res.status(500).json({ mensagem: "Erro ao atualizar dados do perfil." });
            });
    } else {
        perfilModel.atualizarNome(idUsuario, nome)
            .then(function () {
                registrar("EDICAO_PERFIL", `Usuário ID ${idUsuario} atualizou o nome para "${nome}"`, idUsuario);
                res.status(200).json({ mensagem: "Nome atualizado com sucesso!", nome: nome });
            })
            .catch(function (erro) {
                registrar("EDICAO_PERFIL_ERRO", `Erro ao atualizar o nome do usuário ID ${idUsuario}`, idUsuario);
                console.log("Erro ao atualizar nome:", erro.sqlMessage || erro);
                res.status(500).json({ mensagem: "Erro ao atualizar o nome." });
            });
    }
}

module.exports = {
    buscar,
    alterarSenha,
    atualizarPerfil
};