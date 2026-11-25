# 🚀 Comandos Rápidos - Diagnóstico de Alertas

## 📋 Pré-requisitos

Antes de começar, confirme:
- [ ] MySQL rodando localmente ou em Docker
- [ ] Java 17+ instalado (`java -version`)
- [ ] Maven instalado (`mvn -version`)
- [ ] Arquivo `anac_part_023.xlsx` em `C:\Users\Pichau\Downloads\output\`
- [ ] Arquivo `.env` configurado na raiz do projeto

---

## 1️⃣ Executar Diagnóstico SQL

### Conectar no MySQL (escolha uma opção):

**Opção A: MySQL local**
```powershell
# Ajuste usuário e senha conforme seu .env
mysql -u root -p ascent
```

**Opção B: MySQL em Docker**
```powershell
docker exec -it ascent-mysql mysql -u admin -p ascent
```

**Opção C: MySQL Workbench**
- Abrir MySQL Workbench
- Conectar no banco `ascent`
- Abrir arquivo `diagnostico-alertas.sql`
- Executar

### Executar script de diagnóstico:

```sql
source C:/Users/Pichau/Downloads/site-Ascent/diagnostico-alertas.sql
```

Ou copiar e colar o conteúdo do arquivo.

### Queries rápidas para diagnóstico:

```sql
-- Ver total de voos
SELECT COUNT(*) FROM voo;

-- Ver voos por companhia
SELECT fkCompanhia, COUNT(*) as total FROM voo GROUP BY fkCompanhia;

-- Ver valores do campo direcao
SELECT DISTINCT direcao FROM aeroportoDirecao;

-- Ver regras criadas
SELECT * FROM regraAlerta WHERE fkCompanhia IN (1,2);

-- Ver alertas gerados
SELECT * FROM alerta WHERE fkCompanhia IN (1,2) ORDER BY dataCriacao DESC;
```

---

## 2️⃣ Compilar e Importar Dados

### Navegar para o diretório do importador:

```powershell
cd C:\Users\Pichau\Downloads\site-Ascent\ascent-apachepoi
```

### Compilar o projeto:

```powershell
mvn clean package -DskipTests
```

**Tempo estimado:** 2-5 minutos

### Executar importação local:

```powershell
java -cp target/ascent-apachepoi-1.0.jar com.ascent.apachepoi.MainAppLocal
```

**Tempo estimado:** 5-20 minutos (depende do hardware)

### Monitorar progresso:

A aplicação exibe logs em tempo real:
```
[14:23:45] Leitura concluída:
[14:23:45]   • Linhas encontradas: 1,000,000
[14:23:45]   • Linhas válidas (lidas): 985,432
[14:23:45]   • Voos inseridos: 985,432
```

---

## 3️⃣ Validar Importação

### Conectar no MySQL novamente e verificar:

```sql
-- Total de voos importados
SELECT COUNT(*) as total_voos FROM voo;

-- Distribuição por companhia
SELECT 
    c.idCompanhia,
    c.nomeCompanhia,
    COUNT(v.idVoo) as total_voos
FROM companhia c
LEFT JOIN voo v ON v.fkCompanhia = c.idCompanhia
GROUP BY c.idCompanhia, c.nomeCompanhia
ORDER BY total_voos DESC;

-- Verificar dados de ocupação (essencial para alertas)
SELECT 
    COUNT(*) as voos_total,
    COUNT(CASE WHEN qtdPassageiros IS NOT NULL THEN 1 END) as voos_com_passageiros,
    COUNT(CASE WHEN qtdPassageiros > 0 THEN 1 END) as voos_com_passageiros_positivos
FROM voo;

-- Amostra de 10 voos
SELECT 
    v.idVoo,
    v.numVoo,
    v.qtdPassageiros,
    av.numAssentos,
    ROUND(100.0 * v.qtdPassageiros / NULLIF(av.numAssentos, 0), 2) AS ocupacao_pct,
    c.nomeCompanhia
FROM voo v
LEFT JOIN companhia c ON c.idCompanhia = v.fkCompanhia
LEFT JOIN aviao av ON av.idAviao = v.fkAviao
LIMIT 10;
```

---

## 4️⃣ Testar Query de Alertas Manualmente

### Query de teste (ocupação < 90%):

```sql
SELECT 
    ao.uf AS origemIata, 
    ad2.uf AS destinoIata,
    ROUND(100.0 * SUM(v.qtdPassageiros) / NULLIF(SUM(av.numAssentos), 0), 2) AS ocupacaoMedia,
    COUNT(v.idVoo) AS total_voos
FROM voo v
JOIN aeroportoDirecao ad  ON ad.fkVoo = v.idVoo AND ad.direcao = 'ORIGEM'
JOIN aeroportoDirecao ad3 ON ad3.fkVoo = v.idVoo AND ad3.direcao = 'DESTINO'
JOIN aeroporto ao  ON ao.idAeroporto = ad.fkAeroporto
JOIN aeroporto ad2 ON ad2.idAeroporto = ad3.fkAeroporto
JOIN aviao av ON av.idAviao = v.fkAviao
WHERE v.fkCompanhia = 1
  AND v.qtdPassageiros IS NOT NULL 
  AND av.numAssentos > 0
GROUP BY ao.uf, ad2.uf
HAVING ocupacaoMedia < 90
ORDER BY ocupacaoMedia ASC
LIMIT 10;
```

**Se retornar 0 linhas:** Problema no campo `direcao` → Vá para seção 5

**Se retornar rotas:** ✅ Dados OK → Vá para seção 6

### Query alternativa (se campo direcao está como 'Partida'/'Destino'):

```sql
SELECT 
    ao.uf AS origemIata, 
    ad2.uf AS destinoIata,
    ROUND(100.0 * SUM(v.qtdPassageiros) / NULLIF(SUM(av.numAssentos), 0), 2) AS ocupacaoMedia,
    COUNT(v.idVoo) AS total_voos
FROM voo v
JOIN aeroportoDirecao ad  ON ad.fkVoo = v.idVoo AND ad.direcao = 'Partida'
JOIN aeroportoDirecao ad3 ON ad3.fkVoo = v.idVoo AND ad3.direcao = 'Destino'
JOIN aeroporto ao  ON ao.idAeroporto = ad.fkAeroporto
JOIN aeroporto ad2 ON ad2.idAeroporto = ad3.fkAeroporto
JOIN aviao av ON av.idAviao = v.fkAviao
WHERE v.fkCompanhia = 1
  AND v.qtdPassageiros IS NOT NULL 
  AND av.numAssentos > 0
GROUP BY ao.uf, ad2.uf
HAVING ocupacaoMedia < 90
ORDER BY ocupacaoMedia ASC
LIMIT 10;
```

---

## 5️⃣ Corrigir Problema do Campo `direcao` (Se Necessário)

### Verificar qual valor está gravado:

```sql
SELECT DISTINCT direcao FROM aeroportoDirecao;
```

**Se aparecer 'Partida' e 'Destino':** Precisa corrigir o código

### Editar arquivo LeitorExcel.java:

**Arquivo:** `ascent-apachepoi\src\main\java\com\ascent\apachepoi\LeitorExcel.java`

**Linha 249 - ANTES:**
```java
partida.setDirecao("Partida");
```

**Linha 249 - DEPOIS:**
```java
partida.setDirecao("ORIGEM");
```

**Linha 258 - ANTES:**
```java
chegada.setDirecao("Destino");
```

**Linha 258 - DEPOIS:**
```java
chegada.setDirecao("DESTINO");
```

### Recompilar:

```powershell
cd C:\Users\Pichau\Downloads\site-Ascent\ascent-apachepoi
mvn clean package -DskipTests
```

### Limpar dados antigos:

```sql
TRUNCATE TABLE aeroportoDirecao;
TRUNCATE TABLE voo;
DELETE FROM logLeitura WHERE statusLeitura = 'EM_ANDAMENTO';
```

### Reimportar:

```powershell
java -cp target/ascent-apachepoi-1.0.jar com.ascent.apachepoi.MainAppLocal
```

---

## 6️⃣ Adicionar Logs no Backend (Opcional)

### Editar alertaModel.js:

**Arquivo:** `ascent-api\src\models\alertaModel.js`

**Na função `processarRegra()` (linha ~153), adicionar após `return database.executar(...)` da busca da regra:**

```javascript
.then(function (rows) {
    console.log("====================================");
    console.log("PROCESSANDO REGRA DE ALERTA");
    console.log("idRegra:", idRegra);
    console.log("idCompanhia:", idCompanhia);
    console.log("Regra encontrada:", rows);
    console.log("====================================");
    
    if (!rows.length || !rows[0].ativo) {
        console.log("Regra não encontrada ou inativa. Abortando.");
        return;
    }
    
    // ... código existente ...
```

**E após executar a query de busca de rotas (linha ~175):**

```javascript
.then(function (rotas) {
    console.log("====================================");
    console.log("ROTAS ENCONTRADAS:", rotas.length);
    if (rotas.length > 0) {
        console.log("Primeiras 5 rotas:", rotas.slice(0, 5));
    }
    console.log("====================================");
    
    // ... código existente ...
```

### Reiniciar o servidor Node.js:

```powershell
cd C:\Users\Pichau\Downloads\site-Ascent\ascent-api

# Parar servidor se estiver rodando (Ctrl+C)

# Iniciar novamente
npm start
```

---

## 7️⃣ Testar Criação de Regra via Interface

### Acessar interface:

```
http://localhost:3333/dashboard/configurarAlertas.html
```

### Criar regra de teste:

1. Clicar em "Criar Regra"
2. Configurar:
   - **Faixa de ocupação:** `90`
   - **Severidade:** Atenção (🟡)
   - **Janela:** Todo o histórico
   - **Status:** Ativa ✅
3. Clicar em "Salvar Regra"

### Verificar logs no console do Node.js:

Deve aparecer:
```
====================================
PROCESSANDO REGRA DE ALERTA
idRegra: 1
idCompanhia: 1
====================================
...
====================================
ROTAS ENCONTRADAS: 15
====================================
```

### Verificar no banco:

```sql
-- Ver alertas gerados
SELECT * FROM alerta WHERE fkCompanhia = 1 ORDER BY dataCriacao DESC;

-- Detalhes dos alertas
SELECT 
    a.origemIata,
    a.destinoIata,
    a.ocupacaoMedia,
    a.severidade,
    a.lida,
    r.faixaOcupacao
FROM alerta a
JOIN regraAlerta r ON r.idRegraAlerta = a.fkRegraAlerta
WHERE a.fkCompanhia = 1;
```

---

## 8️⃣ Verificar na Central de Alertas

### Acessar interface:

```
http://localhost:3333/dashboard/centralAlertas.html
```

### O que deve aparecer:

- Badge com quantidade de alertas não lidos
- Lista de alertas com:
  - 🟡 Severidade
  - Rota (origem → destino)
  - Ocupação média (%)
- Ao clicar em um alerta:
  - Modal com detalhes
  - Histórico de ocupação por ano (gráfico de barras)

---

## 9️⃣ Limpeza (Se Necessário)

### Remover todos os dados importados:

```sql
-- ⚠️ CUIDADO: Isso apaga TODOS os voos e dados relacionados
TRUNCATE TABLE aeroportoDirecao;
TRUNCATE TABLE voo;
TRUNCATE TABLE alerta;
TRUNCATE TABLE regraAlerta;
DELETE FROM logLeitura;

-- Manter companhias/aviões/aeroportos para próxima importação
-- Ou remover tudo:
-- TRUNCATE TABLE companhia;
-- TRUNCATE TABLE aviao;
-- TRUNCATE TABLE aeroporto;
```

### Resetar auto_increment (se quiser IDs começando do 1):

```sql
ALTER TABLE voo AUTO_INCREMENT = 1;
ALTER TABLE aeroportoDirecao AUTO_INCREMENT = 1;
ALTER TABLE alerta AUTO_INCREMENT = 1;
ALTER TABLE regraAlerta AUTO_INCREMENT = 1;
```

---

## 🔧 Troubleshooting

### Erro: "Connection refused"

**Problema:** Não consegue conectar no MySQL

**Soluções:**
```powershell
# Verificar se MySQL está rodando
docker ps --filter "name=mysql"

# Se não estiver, iniciar
docker start ascent-mysql

# Ou subir via docker-compose
cd C:\Users\Pichau\Downloads\site-Ascent
docker compose up -d mysql
```

### Erro: "Table doesn't exist"

**Problema:** Schema não foi criado

**Solução:**
```powershell
# Executar scripts de criação
mysql -u root -p ascent < database/ascent.sql
mysql -u root -p ascent < database/seed.sql
```

### Erro: "OutOfMemoryError" durante importação

**Problema:** Memória insuficiente

**Solução:**
```powershell
# Aumentar heap do Java
java -Xmx2G -cp target/ascent-apachepoi-1.0.jar com.ascent.apachepoi.MainAppLocal
```

### Importação muito lenta

**Problema:** Performance baixa

**Dicas:**
- Desabilitar antivírus temporariamente
- Fechar outras aplicações
- Verificar espaço em disco
- Aguardar pacientemente (pode demorar 10-20 min)

### Query retorna 0 rotas mas há voos no banco

**Problema:** Campo `direcao` incompatível

**Verificar:**
```sql
SELECT DISTINCT direcao FROM aeroportoDirecao;
```

**Se aparecer 'Partida'/'Destino':** Seguir seção 5 deste guia

---

## 📞 Suporte Adicional

Consulte os documentos completos:
- `INSTRUCOES-DIAGNOSTICO.md` - Guia detalhado passo a passo
- `ANALISE-SCHEMA-vs-CODIGO.md` - Análise de incompatibilidades
- `diagnostico-alertas.sql` - Script SQL completo
