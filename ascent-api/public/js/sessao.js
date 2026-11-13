// sessão
var URL_LOGIN = new URL("../login.html", document.currentScript.src).href;

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
