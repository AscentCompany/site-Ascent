// Cache em memória para rotas analíticas do Express
const cache = new Map();

/**
 * Middleware para cachear respostas de rotas GET
 * @param {number} minutos - Tempo de vida do cache em minutos (padrão: 10 min)
 */
function cacheMiddleware(minutos = 10) {
    const ttlMs = minutos * 60 * 1000;

    return function (req, res, next) {
        if (req.method !== "GET") {
            return next();
        }

        const chave = req.originalUrl || req.url;
        const registro = cache.get(chave);

        if (registro && Date.now() < registro.expiraEm) {
            return res.json(registro.dados);
        }

        const jsonOriginal = res.json.bind(res);
        res.json = function (dados) {
            if (res.statusCode >= 200 && res.statusCode < 300) {
                cache.set(chave, {
                    dados: dados,
                    expiraEm: Date.now() + ttlMs
                });
            }
            return jsonOriginal(dados);
        };

        next();
    };
}

module.exports = cacheMiddleware;
