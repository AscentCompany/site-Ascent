var mysql = require("mysql2");

// CONEXÃO DO BANCO MYSQL SERVER
var mySqlConfig = {
    host: process.env.DB_HOST || "localhost",
    database: process.env.DB_DATABASE,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT || 3306
};

function executar(instrucao) {

    if (process.env.AMBIENTE_PROCESSO !== "producao" && process.env.AMBIENTE_PROCESSO !== "desenvolvimento") {
        console.log("\nO AMBIENTE (produção OU desenvolvimento) NÃO FOI DEFINIDO EM .env OU dev.env OU app.js\n");
        return Promise.reject("AMBIENTE NÃO CONFIGURADO EM .env");
    }

    return new Promise(function (resolve, reject) {
        var conexao = mysql.createConnection(mySqlConfig);

        conexao.connect(function (erroConexao) {
            if (erroConexao) {
                // Sem isso a Promise ficava pendurada e a API nunca respondia
                // quando o MySQL estava fora do ar (ECONNREFUSED / Connection refused).
                console.error(
                    "ERRO AO CONECTAR NO MYSQL (" + mySqlConfig.host + ":" + mySqlConfig.port + "):",
                    erroConexao.message
                );
                conexao.destroy();
                reject(erroConexao);
                return;
            }

            conexao.query(instrucao, function (erro, resultados) {
                conexao.end();
                if (erro) {
                    reject(erro);
                    return;
                }
                console.log(resultados);
                resolve(resultados);
            });
        });

        conexao.on('error', function (erro) {
            console.error("ERRO NO MySQL SERVER:", erro.message);
            reject(erro);
        });
    });
}

module.exports = {
    executar
};
