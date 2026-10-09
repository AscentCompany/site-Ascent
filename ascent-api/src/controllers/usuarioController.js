var usuarioModel = require("../models/usuarioModel");

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
                    console.log(`Resultados: ${JSON.stringify(resultadoAutenticar)}`); // transforma JSON em String

                    if (resultadoAutenticar.length == 1) {
                        console.log(resultadoAutenticar);

                        res.json({
                            idUsuario: resultadoAutenticar[0].idUsuario,
                            email: resultadoAutenticar[0].email,
                            nome: resultadoAutenticar[0].nome,
                            senha: resultadoAutenticar[0].senha,
                            idCompanhia: resultadoAutenticar[0].fkCompanhia,
                            idCargo: resultadoAutenticar[0].fkCargo
                        });


                    } else if (resultadoAutenticar.length == 0) {
                        res.status(403).send("Email e/ou senha inválido(s)");
                    } else {
                        res.status(403).send("Mais de um usuário com o mesmo login e senha!");
                    }
                }
            ).catch(
                function (erro) {
                    console.log(erro);
                    console.log("\nHouve um erro ao realizar o login! Erro: ", erro.sqlMessage);
                    res.status(500).json(erro.sqlMessage);
                }
            );
    }

}

function cadastrar(req, res) {
    // Crie uma variável que vá recuperar os valores do arquivo cadastro.html
    var nome = req.body.nomeServer;
    var email = req.body.emailServer;
    var senha = req.body.senhaServer;
    var idCompanhia = req.body.idCompanhiaServer;

    // Faça as validações dos valores
    if (nome == undefined) {
        res.status(400).send("Seu nome está undefined!");
    } else if (email == undefined) {
        res.status(400).send("Seu email está undefined!");
    } else if (senha == undefined) {
        res.status(400).send("Sua senha está undefined!");
    } else if (idCompanhia == undefined) {
        res.status(400).send("Sua companhia está undefined!");
    }else {

        // Passe os valores como parâmetro e vá para o arquivo usuarioModel.js
        usuarioModel.cadastrar(nome, email, senha, idCompanhia)
            .then(
                function (resultado) {
                    res.json(resultado);
                }
            ).catch(
                function (erro) {
                    console.log(erro);
                    console.log(
                        "\nHouve um erro ao realizar o cadastro! Erro: ",
                        erro.sqlMessage
                    );
                    res.status(500).json(erro.sqlMessage);
                }
            );
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

    if (nome == undefined || email == undefined || senha == undefined || idCompanhia == undefined || idCargo == undefined) {
        res.status(400).send("Valores indefinidos!");
    } else {
        usuarioModel.cadastrarFuncionario(nome, email, senha, idCompanhia, idCargo)
            .then(resultado => res.json(resultado))
            .catch(erro => res.status(500).json(erro.sqlMessage));
    }
}

function editarUsuario(req, res) {
    var idUsuario = req.params.idUsuario;
    var email = req.body.email;
    var fkCargo = req.body.fkCargo;

    usuarioModel.editarUsuario(idUsuario, email, fkCargo)
        .then(resultado => res.json(resultado))
        .catch(erro => res.status(500).json(erro.sqlMessage));
}

function deletarUsuario(req, res) {
    var idUsuario = req.params.idUsuario;
    usuarioModel.deletarUsuario(idUsuario)
        .then(resultado => res.json(resultado))
        .catch(erro => res.status(500).json(erro.sqlMessage));
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