# Análise Crítica: Schema do Banco vs Código

## 🎯 Objetivo

Este documento identifica possíveis incompatibilidades entre o schema do banco de dados e o código que podem estar causando a falha na geração de alertas.

---

## ⚠️ PROBLEMA CRÍTICO IDENTIFICADO

### **Campo `direcao` na tabela `aeroportoDirecao`**

**Localização do problema:**
- Arquivo: `ascent-apachepoi/src/main/java/com/ascent/apachepoi/LeitorExcel.java`
- Linhas: 249 e 258

**Código atual (INCORRETO):**
```java
// Linha 249
partida.setDirecao("Partida");

// Linha 258
chegada.setDirecao("Destino");
```

**Query de alertas espera (em `alertaModel.js`, linha ~160):**
```javascript
JOIN aeroportoDirecao ad  ON ad.fkVoo = v.idVoo AND ad.direcao = 'ORIGEM'
JOIN aeroportoDirecao ad3 ON ad3.fkVoo = v.idVoo AND ad3.direcao = 'DESTINO'
```

### **Impacto:**

- ❌ A query NÃO encontra nenhuma rota porque os JOINs falham
- ❌ Mesmo que haja voos com ocupação baixa, nenhum alerta é gerado
- ❌ O sistema parece estar "funcionando" mas retorna 0 rotas sempre

### **Solução:**

**Opção A: Corrigir o código Java (RECOMENDADO)**

Editar `LeitorExcel.java`:

```java
// Linha 249 - ANTES
partida.setDirecao("Partida");
// DEPOIS
partida.setDirecao("ORIGEM");

// Linha 258 - ANTES
chegada.setDirecao("Destino");
// DEPOIS
chegada.setDirecao("DESTINO");
```

Depois:
1. Recompilar: `mvn clean package`
2. Limpar dados existentes (se já importou):
   ```sql
   TRUNCATE TABLE aeroportoDirecao;
   TRUNCATE TABLE voo;
   DELETE FROM logLeitura WHERE statusLeitura = 'EM_ANDAMENTO';
   ```
3. Reimportar o arquivo

**Opção B: Corrigir a query SQL (ALTERNATIVA)**

Editar `ascent-api/src/models/alertaModel.js` (linha ~160):

```javascript
// ANTES
JOIN aeroportoDirecao ad  ON ad.fkVoo = v.idVoo AND ad.direcao = 'ORIGEM'
JOIN aeroportoDirecao ad3 ON ad3.fkVoo = v.idVoo AND ad3.direcao = 'DESTINO'

// DEPOIS
JOIN aeroportoDirecao ad  ON ad.fkVoo = v.idVoo AND ad.direcao = 'Partida'
JOIN aeroportoDirecao ad3 ON ad3.fkVoo = v.idVoo AND ad3.direcao = 'Destino'
```

⚠️ **Desvantagem:** Isso só corrige o processamento de alertas. Se outras partes do sistema também usam 'ORIGEM'/'DESTINO', vai quebrar.

**Recomendação:** Use a **Opção A** (corrigir o Java) para manter consistência.

---

## 🔍 Mapeamento Completo de Campos

### Tabela: `voo`

| Campo Banco | Tipo Banco | Campo Código | Arquivo | Linha | Status |
|-------------|------------|--------------|---------|-------|--------|
| idVoo | INT AUTO_INCREMENT | idVoo | Voo.java | 7 | ✅ OK |
| numVoo | INT NULL | numVoo | LeitorExcel.java | 212 | ✅ OK |
| tipoVoo | INT NULL | tipoVoo | LeitorExcel.java | 220 | ✅ OK |
| qtdPassageiros | INT NULL | qtdPassageiros | LeitorExcel.java | 221-222 | ✅ OK |
| fkCompanhia | INT NOT NULL | (via ImportadorDados) | ImportadorDados.java | 185 | ✅ OK |
| fkAviao | INT NULL | (via ImportadorDados) | ImportadorDados.java | 186 | ✅ OK |

**Notas:**
- `qtdPassageiros` = `nrPassagPagos` + `nrPassagGratis` ✅
- Validação: linha válida requer `numVoo NOT NULL` ✅

### Tabela: `aeroportoDirecao`

| Campo Banco | Tipo Banco | Campo Código | Arquivo | Linha | Status |
|-------------|------------|--------------|---------|-------|--------|
| fkAeroporto | INT NOT NULL | fkAeroporto | ImportadorDados.java | 199 | ✅ OK |
| fkVoo | INT NOT NULL | (gerado após insert) | ImportadorDados.java | 199 | ✅ OK |
| **direcao** | VARCHAR(50) | direcao | LeitorExcel.java | 249, 258 | ❌ **INCOMPATÍVEL** |
| dia | DATE NOT NULL | dia | LeitorExcel.java | 243 | ✅ OK |
| hora | TIME NOT NULL | hora | LeitorExcel.java | 244 | ✅ OK |

**Problema identificado:**
- Código grava: `'Partida'` e `'Destino'`
- Query espera: `'ORIGEM'` e `'DESTINO'`

### Tabela: `aeroporto`

| Campo Banco | Tipo Banco | Campo Código | Arquivo | Linha | Status |
|-------------|------------|--------------|---------|-------|--------|
| idAeroporto | INT AUTO_INCREMENT | idAeroporto | Aeroporto.java | - | ✅ OK |
| nomeAeroporto | VARCHAR(255) | nomeAeroporto | LeitorExcel.java | 226 | ✅ OK |
| municipio | VARCHAR(255) | municipio | LeitorExcel.java | 227 | ✅ OK |
| uf | VARCHAR(50) | uf | LeitorExcel.java | 228 | ✅ OK |
| regiao | VARCHAR(100) | regiao | LeitorExcel.java | 229 | ✅ OK |
| pais | VARCHAR(100) | pais | LeitorExcel.java | 230 | ✅ OK |
| icao | VARCHAR(10) | icao | LeitorExcel.java | 231 | ⚠️ Não usado na query |

**Notas:**
- Campo `uf` é usado como "IATA" na query de alertas
- Na verdade deveria ser ICAO, mas dados da ANAC usam UF

### Tabela: `aviao`

| Campo Banco | Tipo Banco | Campo Código | Arquivo | Linha | Status |
|-------------|------------|--------------|---------|-------|--------|
| idAviao | INT AUTO_INCREMENT | idAviao | Aviao.java | - | ✅ OK |
| numAssentos | INT NULL | numAssentos | LeitorExcel.java | 217 | ✅ OK |
| modelo | VARCHAR(255) | modelo | LeitorExcel.java | 216 | ✅ OK |

**Notas:**
- `numAssentos` é essencial para cálculo de ocupação
- Validação: se modelo vazio, usa avião padrão com 0 assentos

### Tabela: `companhia`

| Campo Banco | Tipo Banco | Campo Código | Arquivo | Linha | Status |
|-------------|------------|--------------|---------|-------|--------|
| idCompanhia | INT AUTO_INCREMENT | - | - | - | ✅ OK |
| codCompanhia | INT NULL | codCompanhia | LeitorExcel.java | 210 | ✅ OK |
| nomeCompanhia | VARCHAR(255) | nomeCompanhia | LeitorExcel.java | 211 | ✅ OK |
| paisCompanhia | VARCHAR(100) | paisCompanhia | LeitorExcel.java | 212 | ✅ OK |
| razaoSocial | VARCHAR(255) | razaoSocial | LeitorExcel.java | 213 | ✅ OK (vazio) |
| cnpj | VARCHAR(20) | cnpj | LeitorExcel.java | 214 | ✅ OK (vazio) |

**Notas:**
- `codCompanhia` vem da coluna `id_empresa` do Excel
- Se `codCompanhia` é NULL, usa companhia padrão com código -1

### Tabela: `regraAlerta`

| Campo Banco | Tipo Banco | Campo JS | Arquivo | Status |
|-------------|------------|----------|---------|--------|
| idRegraAlerta | INT AUTO_INCREMENT | idRegra | alertaModel.js | ✅ OK |
| faixaOcupacao | DECIMAL(5,2) | faixaOcupacao | alertaModel.js | ✅ OK |
| severidade | VARCHAR(10) | severidade | alertaModel.js | ✅ OK |
| janelaAnalise | VARCHAR(20) | janelaAnalise | alertaModel.js | ✅ OK |
| janelaInicio | DATE NULL | janelaInicio | alertaModel.js | ✅ OK |
| janelaFim | DATE NULL | janelaFim | alertaModel.js | ✅ OK |
| ativo | TINYINT(1) | ativo | alertaModel.js | ✅ OK |
| fkCompanhia | INT NOT NULL | idCompanhia | alertaModel.js | ✅ OK |
| fkUsuarioCriador | INT NOT NULL | idUsuario | alertaModel.js | ✅ OK |
| dataCriacao | DATETIME | (auto) | - | ✅ OK |

**Valores válidos:**
- `severidade`: `'critico'` ou `'atencao'`
- `janelaAnalise`: `'1_ano'`, `'3_anos'`, `'5_anos'`, `'10_anos'`, `'todo_historico'`, `'personalizado'`

### Tabela: `alerta`

| Campo Banco | Tipo Banco | Campo JS | Arquivo | Status |
|-------------|------------|----------|---------|--------|
| idAlerta | INT AUTO_INCREMENT | - | alertaModel.js | ✅ OK |
| origemIata | VARCHAR(10) | origemIata | alertaModel.js | ✅ OK |
| destinoIata | VARCHAR(10) | destinoIata | alertaModel.js | ✅ OK |
| ocupacaoMedia | DECIMAL(5,2) | ocupacaoMedia | alertaModel.js | ✅ OK |
| severidade | VARCHAR(10) | (cópia da regra) | alertaModel.js | ✅ OK |
| lida | TINYINT(1) | lida | alertaModel.js | ✅ OK |
| fkRegraAlerta | INT NOT NULL | idRegra | alertaModel.js | ✅ OK |
| fkCompanhia | INT NOT NULL | idCompanhia | alertaModel.js | ✅ OK |
| dataCriacao | DATETIME | (auto) | - | ✅ OK |

---

## 🔎 Query de Processamento de Alertas - Análise Detalhada

**Localização:** `ascent-api/src/models/alertaModel.js` → função `processarRegra()` (linha ~153)

### Query SQL:

```sql
SELECT 
    ao.uf AS origemIata, 
    ad2.uf AS destinoIata,
    ROUND(100.0 * SUM(v.qtdPassageiros) / NULLIF(SUM(av.numAssentos), 0), 2) AS ocupacaoMedia
FROM voo v
JOIN aeroportoDirecao ad  ON ad.fkVoo = v.idVoo AND ad.direcao = 'ORIGEM'  -- ⚠️ PROBLEMA AQUI
JOIN aeroportoDirecao ad3 ON ad3.fkVoo = v.idVoo AND ad3.direcao = 'DESTINO'  -- ⚠️ PROBLEMA AQUI
JOIN aeroporto ao  ON ao.idAeroporto = ad.fkAeroporto
JOIN aeroporto ad2 ON ad2.idAeroporto = ad3.fkAeroporto
JOIN aviao av ON av.idAviao = v.fkAviao
WHERE v.fkCompanhia = ${idCompanhia} ${filtroData}
  AND v.qtdPassageiros IS NOT NULL 
  AND av.numAssentos > 0
GROUP BY ao.uf, ad2.uf
HAVING ocupacaoMedia < ${r.faixaOcupacao}
ORDER BY ocupacaoMedia ASC;
```

### Dependências:

| Tabela | Alias | Campo Join | Campo Esperado | Status |
|--------|-------|------------|----------------|--------|
| voo | v | fkCompanhia, idVoo | - | ✅ OK |
| aeroportoDirecao | ad | fkVoo, **direcao='ORIGEM'** | fkVoo, **direcao='Partida'** | ❌ **INCOMPATÍVEL** |
| aeroportoDirecao | ad3 | fkVoo, **direcao='DESTINO'** | fkVoo, **direcao='Destino'** | ❌ **INCOMPATÍVEL** |
| aeroporto | ao | idAeroporto | - | ✅ OK |
| aeroporto | ad2 | idAeroporto | - | ✅ OK |
| aviao | av | idAviao, numAssentos | - | ✅ OK |

### Filtros Temporais:

```javascript
if (r.janelaAnalise === "1_ano") 
    filtroData = "AND ad.dia >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)";
else if (r.janelaAnalise === "3_anos") 
    filtroData = "AND ad.dia >= DATE_SUB(CURDATE(), INTERVAL 3 YEAR)";
// ... etc
else if (r.janelaAnalise === "personalizado" && r.janelaInicio && r.janelaFim)
    filtroData = `AND ad.dia BETWEEN '${r.janelaInicio}' AND '${r.janelaFim}'`;
```

✅ Lógica correta

### Cálculo de Ocupação:

```sql
ROUND(100.0 * SUM(v.qtdPassageiros) / NULLIF(SUM(av.numAssentos), 0), 2)
```

✅ Lógica correta:
- Soma todos os passageiros de todos os voos da rota
- Soma todos os assentos oferecidos
- Calcula percentual
- `NULLIF(..., 0)` evita divisão por zero

---

## 🧪 Como Validar

### 1. Verificar valores atuais no banco:

```sql
SELECT DISTINCT direcao FROM aeroportoDirecao;
```

**Resultado esperado se há dados:**
- Se aparecer `'Partida'` e `'Destino'` → ❌ Confirma o problema
- Se aparecer `'ORIGEM'` e `'DESTINO'` → ✅ Está correto

### 2. Testar a query manualmente:

```sql
-- Teste 1: Com valores ERRADOS (não deve retornar nada)
SELECT COUNT(*) FROM voo v
JOIN aeroportoDirecao ad ON ad.fkVoo = v.idVoo AND ad.direcao = 'ORIGEM';

-- Teste 2: Com valores CORRETOS (deve retornar registros)
SELECT COUNT(*) FROM voo v
JOIN aeroportoDirecao ad ON ad.fkVoo = v.idVoo AND ad.direcao = 'Partida';
```

### 3. Query de diagnóstico completa:

```sql
-- Ver quantidade de voos por tipo de direção
SELECT 
    ad.direcao,
    COUNT(*) as total
FROM aeroportoDirecao ad
GROUP BY ad.direcao;

-- Testar query de alertas com valores corretos
SELECT 
    ao.uf AS origemIata, 
    ad2.uf AS destinoIata,
    ROUND(100.0 * SUM(v.qtdPassageiros) / NULLIF(SUM(av.numAssentos), 0), 2) AS ocupacaoMedia
FROM voo v
JOIN aeroportoDirecao ad  ON ad.fkVoo = v.idVoo AND ad.direcao = 'Partida'  -- Ajustado
JOIN aeroportoDirecao ad3 ON ad3.fkVoo = v.idVoo AND ad3.direcao = 'Destino'  -- Ajustado
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

## 📋 Checklist de Correção

Após identificar o problema:

- [ ] Corrigir `LeitorExcel.java` (linhas 249 e 258)
- [ ] Recompilar: `mvn clean package`
- [ ] Limpar dados antigos no banco (se já importou)
- [ ] Reimportar arquivo de teste
- [ ] Executar query de validação manual
- [ ] Criar regra de alerta
- [ ] Verificar geração de alertas
- [ ] Validar na interface

---

## 🎯 Conclusão

**Problema raiz identificado:**
- Incompatibilidade de valores no campo `direcao` entre código Java e query SQL
- Código grava `'Partida'/'Destino'`, query busca `'ORIGEM'/'DESTINO'`
- Resultado: JOINs falham, nenhuma rota é encontrada, zero alertas gerados

**Solução:**
1. Corrigir `LeitorExcel.java` para gravar valores corretos
2. Reimportar dados
3. Sistema funcionará corretamente

**Tempo estimado de correção:** 15-30 minutos (incluindo recompilação e reimportação)
