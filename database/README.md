# Database Scripts

## 📋 Estrutura dos Arquivos

### Arquivos Principais

#### `ascent.sql` ✅ **[ARQUIVO OFICIAL]**
**Este é o arquivo que deve ser usado para criar o banco de dados do zero.**

Contém:
- Schema completo de todas as tabelas (aeroporto, voo, companhia, usuário, alertas, etc.)
- Dados iniciais (seed) com:
  - Companhia: Ascent Airlines (código 1001)
  - Cargos: Administrador, Gestor de Operações Aéreas, Analista de Planejamento de Rotas
  - Usuários de teste (camila, giovanna, gustavo, lucas, matheus, thamyres)
  - Permissões e funcionalidades do sistema

**Uso:**
```bash
mysql -u root -p < database/ascent.sql
```

---

#### `banco.sql` ⚠️ **[LEGADO - NÃO USAR]**
Schema antigo com estrutura diferente de alertas. Mantido apenas para referência histórica.

---

#### `seed.sql`
Dados iniciais incluídos no `ascent.sql`. Pode ser executado separadamente se necessário.

---

### Scripts Utilitários

#### `corrigir-schema-alertas.sql`
Script para corrigir o schema das tabelas de alerta **SEM PERDER** os dados de voos já importados.

Útil se você:
- Executou `banco.sql` por engano
- Precisa atualizar apenas as tabelas de alerta

**Uso:**
```bash
mysql -u ascent -p ascent < database/corrigir-schema-alertas.sql
```

---

## 🚀 Setup Completo do Banco de Dados

### Primeira vez configurando o projeto:

1. **Criar o banco e importar schema:**
```bash
mysql -u root -p < database/ascent.sql
```

2. **Criar usuário do banco (se necessário):**
```sql
CREATE USER 'ascent'@'localhost' IDENTIFIED BY 'sptech';
GRANT ALL PRIVILEGES ON ascent.* TO 'ascent'@'localhost';
FLUSH PRIVILEGES;
```

3. **Configurar variáveis de ambiente:**

Copie `.env.example` para `.env.dev` na pasta `ascent-api/`:
```env
DB_HOST=localhost
DB_USER=ascent
DB_PASSWORD=sptech
DB_NAME=ascent
DB_PORT=3306
```

4. **Importar dados ANAC (opcional):**

Se você tiver os arquivos Excel da ANAC:
```bash
cd ascent-apachepoi
# Configure o .env com as credenciais do banco
mvn clean package -DskipTests
java -cp target/ascent-apachepoi-1.0-SNAPSHOT-jar-with-dependencies.jar com.ascent.apachepoi.MainAppLocal
```

---

## 🔧 Troubleshooting

### Problema: "Unknown column 'faixaOcupacao'"
**Causa:** Você executou `banco.sql` em vez de `ascent.sql`

**Solução:**
```bash
mysql -u ascent -p ascent < database/corrigir-schema-alertas.sql
```

### Problema: Tabelas de alerta não existem
**Solução:** Execute o `ascent.sql` completo

### Problema: Código da companhia não funciona
**Causa:** Seed não foi executado

**Solução:** 
- Código da companhia: **1001**
- Ou execute: `mysql -u ascent -p ascent < database/seed.sql`

---

## 📊 Validação do Schema

Para validar se o schema está correto:

```sql
USE ascent;

-- Verificar estrutura da tabela regraAlerta
DESCRIBE regraAlerta;

-- Deve retornar as colunas:
-- idRegraAlerta, faixaOcupacao, severidade, janelaAnalise, 
-- janelaInicio, janelaFim, ativo, fkCompanhia, fkUsuarioCriador, dataCriacao
```

---

## 🎯 Schema Correto das Tabelas de Alerta

### regraAlerta
```sql
idRegraAlerta INT PRIMARY KEY AUTO_INCREMENT
faixaOcupacao DECIMAL(5,2) NOT NULL
severidade VARCHAR(10) NOT NULL
janelaAnalise VARCHAR(20) NOT NULL
janelaInicio DATE NULL
janelaFim DATE NULL
ativo TINYINT(1) NOT NULL
fkCompanhia INT NOT NULL
fkUsuarioCriador INT NOT NULL
dataCriacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
```

### alerta
```sql
idAlerta INT PRIMARY KEY AUTO_INCREMENT
origemIata VARCHAR(10) NOT NULL
destinoIata VARCHAR(10) NOT NULL
ocupacaoMedia DECIMAL(5,2) NOT NULL
severidade VARCHAR(10) NOT NULL
lida TINYINT(1) NOT NULL
fkRegraAlerta INT NOT NULL
fkCompanhia INT NOT NULL
dataCriacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
```

---

## 📝 Notas

- **Sempre use `ascent.sql`** como ponto de partida
- O schema de alertas está alinhado com o código backend em `ascent-api/src/models/alertaModel.js`
- Os dados de seed incluem usuários de teste com senha igual ao nome de usuário (ex: camila/camila)
- A companhia padrão é **Ascent Airlines** com código **1001**
