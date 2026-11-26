// sessão
var URL_LOGIN = new URL("../login.html", document.currentScript.src).href;
var funcionalidadesCargoCache = {};

function validarSessao() {
    var email = sessionStorage.EMAIL_USUARIO;
    var nome = sessionStorage.NOME_USUARIO;

    var b_usuario = document.getElementById("b_usuario") || document.getElementById("nome-usuario");

    if (email != null && nome != null) {
        if (b_usuario) {
            b_usuario.innerHTML = nome;
        } else if (document.readyState === "loading") {
            document.addEventListener("DOMContentLoaded", function () {
                var usuario = document.getElementById("b_usuario") || document.getElementById("nome-usuario");
                if (usuario) {
                    usuario.innerHTML = nome;
                }
            }, { once: true });
        }
    } else {
        window.location = URL_LOGIN;
    }
}

function obterChaveCacheFuncionalidades() {
    var idCargo = Number(sessionStorage.CARGO_USUARIO);
    var idCompanhia = Number(sessionStorage.COMPANHIA_USUARIO);
    if (!idCargo || !idCompanhia) {
        return null;
    }
    return `${idCompanhia}:${idCargo}`;
}

function obterFuncionalidadesCargoCache() {
    var chaveCache = obterChaveCacheFuncionalidades();
    if (!chaveCache) {
        return [];
    }

    try {
        var bruto = sessionStorage.getItem("FUNCIONALIDADES_CARGO");
        if (!bruto) {
            return null;
        }
        var dados = JSON.parse(bruto);
        if (dados && dados.chave === chaveCache && Array.isArray(dados.funcionalidades)) {
            return dados.funcionalidades;
        }
    } catch (erro) {
        console.warn("Cache de funcionalidades inválido:", erro);
    }
    return null;
}

function salvarFuncionalidadesCargoCache(funcionalidades) {
    var chaveCache = obterChaveCacheFuncionalidades();
    if (!chaveCache || !Array.isArray(funcionalidades)) {
        return;
    }

    try {
        sessionStorage.setItem("FUNCIONALIDADES_CARGO", JSON.stringify({
            chave: chaveCache,
            funcionalidades: funcionalidades
        }));
    } catch (erro) {
        console.warn("Não foi possível salvar cache de funcionalidades:", erro);
    }
}

function limparCacheFuncionalidadesCargo() {
    funcionalidadesCargoCache = {};
    sessionStorage.removeItem("FUNCIONALIDADES_CARGO");
}

function carregarFuncionalidadesCargo() {
    var idCargo = Number(sessionStorage.CARGO_USUARIO);
    var idCompanhia = Number(sessionStorage.COMPANHIA_USUARIO);

    if (!idCargo || !idCompanhia) {
        return Promise.resolve([]);
    }

    var cacheSessao = obterFuncionalidadesCargoCache();
    if (cacheSessao !== null) {
        return Promise.resolve(cacheSessao);
    }

    var chaveCache = `${idCompanhia}:${idCargo}`;
    if (funcionalidadesCargoCache[chaveCache]) {
        return funcionalidadesCargoCache[chaveCache];
    }

    var requisicoes = [
        fetch(`/cargos/listar/${idCompanhia}`),
        fetch("/permissoes/listar")
    ];

    funcionalidadesCargoCache[chaveCache] = Promise.all(requisicoes)
        .then(function (respostas) {
            if (respostas.some(function (resposta) { return !resposta.ok; })) {
                throw new Error("Não foi possível consultar as funcionalidades do cargo.");
            }
            return Promise.all(respostas.map(function (resposta) { return resposta.json(); }));
        })
        .then(function (resultados) {
            var cargos = resultados[0];
            var permissoes = resultados[1];
            if (!Array.isArray(cargos) || !Array.isArray(permissoes)) {
                throw new Error("A resposta de funcionalidades do cargo é inválida.");
            }

            var idsPermissoesCargo = new Set(cargos.filter(function (cargo) {
                return Number(cargo.idCargo) === idCargo
                    && cargo.idCargoPermissao !== null
                    && Number(cargo.idCargoPermissao) === idCargo;
            }).map(function (cargo) {
                return Number(cargo.idPermissao);
            }));

            var funcionalidades = permissoes.filter(function (permissao) {
                return idsPermissoesCargo.has(Number(permissao.idPermissao))
                    && permissao.idpermissaoFuncionalidade !== null
                    && Number(permissao.idpermissaoFuncionalidade) === Number(permissao.idPermissao);
            }).map(function (permissao) {
                return permissao.funcionalidade;
            });
            var listaFuncionalidades = Array.from(new Set(funcionalidades));
            salvarFuncionalidadesCargoCache(listaFuncionalidades);
            return listaFuncionalidades;
        })
        .catch(function (erro) {
            delete funcionalidadesCargoCache[chaveCache];
            throw erro;
        });

    return funcionalidadesCargoCache[chaveCache];
}

function usuarioTemFuncionalidade(nomeFuncionalidade) {
    return carregarFuncionalidadesCargo().then(function (funcionalidades) {
        return funcionalidades.indexOf(nomeFuncionalidade) !== -1;
    });
}

function exigirFuncionalidadePagina(nomeFuncionalidade, urlFallback) {
    return usuarioTemFuncionalidade(nomeFuncionalidade)
        .then(function (podeAcessar) {
            if (!podeAcessar) {
                alert("Você não tem permissão para acessar esta página.");
                window.location.href = urlFallback;
                return false;
            }
            return true;
        })
        .catch(function (erro) {
            console.error("Erro ao verificar permissão da página:", erro);
            alert("Não foi possível verificar suas permissões. Tente novamente.");
            window.location.href = urlFallback;
            return false;
        });
}

function limparSessao() {
    sessionStorage.clear();
    window.location = URL_LOGIN;
}

// carregamento (loading)
function aguardar() {
    var divAguardar = document.getElementById("div_aguardar");
    divAguardar.style.display = "flex";
}

function finalizarAguardar(texto) {
    var divAguardar = document.getElementById("div_aguardar");
    divAguardar.style.display = "none";

    var divErrosLogin = document.getElementById("div_erros_login");
    if (texto) {
        divErrosLogin.style.display = "flex";
        divErrosLogin.innerHTML = texto;
    }
}
