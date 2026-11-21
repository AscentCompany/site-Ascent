// Bom dia - teste 2
var usuarioModel = require("../models/usuarioModel");
var logModel = require("../models/logModel");

function autenticar(req, res) {
    var email = req.body.emailServer;
    var senha = req.body.senhaServer;

    if (email == undefined) {
        res.status(400).send("Seu email está undefined!");
    } else if (senha == undefined) {
        res.status(400).send("Sua senha está indefinida!");
    } else {

        usuarioModel.autenticar(email, senha)
            .then(
                function (resultadoAutenticar) {
                    console.log(`\nResultados encontrados: ${resultadoAutenticar.length}`);
                    console.log(`Resultados: ${JSON.stringify(resultadoAutenticar)}`);

                    if (resultadoAutenticar.length == 1) {
                        console.log(resultadoAutenticar);

                        var usuarioLogado = resultadoAutenticar[0];
                        logModel.registrarLog("AUTENTICAÇÃO", "LOGIN", `Usuário ${usuarioLogado.email} realizou login com sucesso`, "login.html", usuarioLogado.idUsuario);

                        usuarioModel.verificarPermissaoAdmin(usuarioLogado.fkCompanhia)
                            .then(adminRes => {
                                var idCargoAdmin = adminRes && adminRes.length > 0 ? adminRes[0].adminCargo : null;
                                res.json({
                                    idUsuario: usuarioLogado.idUsuario,
                                    email: usuarioLogado.email,
                                    nome: usuarioLogado.nome,
                                    senha: usuarioLogado.senha,
                                    idCompanhia: usuarioLogado.fkCompanhia,
                                    idCargo: usuarioLogado.fkCargo,
                                    adminCargo: idCargoAdmin
                                });
                            })
                            .catch(() => {
                                res.json({
                                    idUsuario: usuarioLogado.idUsuario,
                                    email: usuarioLogado.email,
                                    nome: usuarioLogado.nome,
                                    senha: usuarioLogado.senha,
                                    idCompanhia: usuarioLogado.fkCompanhia,
                                    idCargo: usuarioLogado.fkCargo
                                });
                            });


                    } else if (resultadoAutenticar.length == 0) {
                        logModel.registrarLog("AUTENTICAÇÃO", "LOGIN_FALHA", `Tentativa de login inválida para o e-mail: ${email}`, "login.html", null);
                        res.status(403).send("Email e/ou senha inválido(s)");
                    } else {
                        res.status(403).send("Mais de um usuário com o mesmo login e senha!");
                    }
                }
            ).catch(
                function (erro) {
                    logModel.registrarLog("AUTENTICAÇÃO", "LOGIN_ERRO", `Erro ao autenticar usuário ${email}`, "login.html", null);
                    console.log(erro);
                    console.log("\nHouve um erro ao realizar o login! Erro: ", erro.sqlMessage);
                    res.status(500).json(erro.sqlMessage);
                }
            );
    }

}

function cadastrar(req, res) {
    var nome = req.body.nomeServer;
    var email = req.body.emailServer;
    var senha = req.body.senhaServer;
    var idCompanhia = req.body.idCompanhiaServer;

    if (nome == undefined) {
        res.status(400).send("Seu nome está undefined!");
    } else if (email == undefined) {
        res.status(400).send("Seu email está undefined!");
    } else if (senha == undefined) {
        res.status(400).send("Sua senha está undefined!");
    } else if (idCompanhia == undefined) {
        res.status(400).send("Sua companhia está undefined!");
    } else {
        // O frontend envia o codCompanhia (código de negócio).
        // Resolvemos para o idCompanhia (PK) antes de qualquer operação.
        var cargoModel = require("../models/cargoModel");
        var permissaoModel = require("../models/permissaoModel");

        usuarioModel.buscarIdPorCodigo(idCompanhia)
            .then(resultado => {
                if (!resultado || resultado.length === 0) {
                    return res.status(404).send("Companhia não encontrada. Verifique o código informado.");
                }
                var idCompanhiaReal = resultado[0].idCompanhia;

                return cargoModel.listarCargos(idCompanhiaReal)
                    .then(cargosResultado => {
                        if (cargosResultado.length === 0) {
                            // Primeiro cadastro da companhia: provisiona a estrutura de cargos padrão
                            // 1. Cria o cargo Administrador
                            return cargoModel.cadastrarCargo("Administrador", idCompanhiaReal)
                                .then(() => cargoModel.buscarUltimoCargo(idCompanhiaReal))
                                .then(ultCargo => {
                                    var idCargoAdmin = ultCargo[0].idNovoCargo;

                                    // 2. Vincula todas as permissões ao Administrador
                                    return permissaoModel.listarPermissoes()
                                        .then(permissoes => {
                                            var promises = permissoes.map(p =>
                                                cargoModel.cadastrarCargoPermissao(idCargoAdmin, p.idPermissao || p)
                                            );
                                            return Promise.all(promises);
                                        })
                                        // 3. Cria os demais cargos operacionais padrão da companhia
                                        .then(() => cargoModel.cadastrarCargo("Gestor de Operações Aéreas", idCompanhiaReal))
                                        .then(() => cargoModel.cadastrarCargo("Analista de Planejamento de Rotas", idCompanhiaReal))
                                        // 4. Cadastra o 1º usuário com o cargo Administrador
                                        .then(() => usuarioModel.cadastrar(nome, email, senha, idCompanhiaReal, idCargoAdmin));
                                });
                        }

                        // Próximos usuários da companhia: cadastra com o cargo padrão (Analista de Planejamento de Rotas)
                        return usuarioModel.cadastrar(nome, email, senha, idCompanhiaReal);
                    });
            })
            .then(function (resultado) {
                var novoIdUsuario = resultado.insertId || null;
                logModel.registrarLog(
                    "GESTÃO DE USUÁRIO",
                    "CADASTRO",
                    `Novo usuário ${nome} (${email}) cadastrado na companhia ${idCompanhia}`,
                    "cadastro.html",
                    novoIdUsuario
                );
                res.json(resultado);
            })
            .catch(function (erro) {
                logModel.registrarLog(
                    "GESTÃO DE USUÁRIO",
                    "CADASTRO_ERRO",
                    `Falha ao cadastrar usuário ${email}`,
                    "cadastro.html",
                    null
                );
                console.log(erro);
                console.log("\nHouve um erro ao realizar o cadastro! Erro: ", erro.sqlMessage || erro);
                res.status(500).json(erro.sqlMessage || "Erro interno");
            });
    }
}


// funcoes da tela de gerencia
function verificarPermissaoAdmin(req, res) {
    var idCompanhia = req.params.idCompanhia;
    usuarioModel.verificarPermissaoAdmin(idCompanhia)
        .then(resultado => res.json(resultado))
        .catch(erro => res.status(500).json(erro.sqlMessage));
}

function listarCargos(req, res) {
    var idCompanhia = req.params.idCompanhia;
    usuarioModel.listarCargos(idCompanhia)
        .then(resultado => res.json(resultado))
        .catch(erro => res.status(500).json(erro.sqlMessage));
}

function listarUsuariosCompanhia(req, res) {
    var idCompanhia = req.params.idCompanhia;
    usuarioModel.listarUsuariosCompanhia(idCompanhia)
        .then(resultado => res.json(resultado))
        .catch(erro => res.status(500).json(erro.sqlMessage));
}

function cadastrarFuncionario(req, res) {
    var nome = req.body.nomeServer;
    var email = req.body.emailServer;
    var senha = req.body.senhaServer;
    var idCompanhia = req.body.idCompanhiaServer;
    var idCargo = req.body.idCargoServer;
    var fkUsuarioAcao = req.body.fkUsuarioAcao;

    if (nome == undefined || email == undefined || senha == undefined || idCompanhia == undefined || idCargo == undefined) {
        res.status(400).send("Valores indefinidos!");
    } else {
        usuarioModel.cadastrarFuncionario(nome, email, senha, idCompanhia, idCargo)
            .then(resultado => {
                logModel.registrarLog("GESTÃO DE USUÁRIO", "CADASTRO", `Cadastrou o funcionário ${nome}`, "usuarios.html", fkUsuarioAcao);
                res.json(resultado);
            })
            .catch(erro => {
                logModel.registrarLog("GESTÃO DE USUÁRIO", "CADASTRO_ERRO", `Falha ao cadastrar o funcionário ${nome}`, "usuarios.html", fkUsuarioAcao);
                res.status(500).json(erro.sqlMessage);
            });
    }
}

function editarUsuario(req, res) {
    var idUsuario = req.params.idUsuario;
    var email = req.body.email;
    var fkCargo = req.body.fkCargo;
    var fkUsuarioAcao = req.body.fkUsuarioAcao;

    usuarioModel.editarUsuario(idUsuario, email, fkCargo)
        .then(resultado => {
            logModel.registrarLog("GESTÃO DE USUÁRIO", "EDICAO", `Atualizou os dados do funcionário ID ${idUsuario}`, "usuarios.html", fkUsuarioAcao);
            res.json(resultado);
        })
        .catch(erro => {
            logModel.registrarLog("GESTÃO DE USUÁRIO", "EDICAO_ERRO", `Falha ao salvar alterações do funcionário ID ${idUsuario}`, "usuarios.html", fkUsuarioAcao);
            res.status(500).json(erro.sqlMessage);
        });
}

function deletarUsuario(req, res) {
    var idUsuario = req.params.idUsuario;
    var fkUsuarioAcao = req.query.fkUsuarioAcao || req.body.fkUsuarioAcao;

    usuarioModel.deletarUsuario(idUsuario)
        .then(resultado => {
            logModel.registrarLog("GESTÃO DE USUÁRIO", "EXCLUSAO", `Excluiu o funcionário ID ${idUsuario}`, "usuarios.html", fkUsuarioAcao);
            res.json(resultado);
        })
        .catch(erro => {
            logModel.registrarLog("GESTÃO DE USUÁRIO", "EXCLUSAO_ERRO", `Falha ao excluir o funcionário ID ${idUsuario}`, "usuarios.html", fkUsuarioAcao);
            res.status(500).json(erro.sqlMessage);
        });
}

module.exports = {
    autenticar,
    cadastrar,
    verificarPermissaoAdmin,
    listarCargos,
    listarUsuariosCompanhia,
    cadastrarFuncionario,
    editarUsuario,
    deletarUsuario
}