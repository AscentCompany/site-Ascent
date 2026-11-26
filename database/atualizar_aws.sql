-- =============================================================
-- atualizar_aws.sql - Atualizacao segura e idempotente do banco
-- Compativel com MySQL 8.0 na AWS (Linux / Docker)
-- Pode rodar com o sistema no ar, sem derrubar nada.
-- =============================================================
USE ascent;
SET NAMES utf8mb4;

-- 1. Garante coluna idInicialVoo em logsServico
SET @col_exists := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'logsServico'
    AND COLUMN_NAME = 'idInicialVoo'
);
SET @sql_add_col := IF(
  @col_exists = 0,
  'ALTER TABLE logsServico ADD COLUMN idInicialVoo BIGINT NULL DEFAULT NULL;',
  'SELECT 1;'
);
PREPARE stmt_col FROM @sql_add_col;
EXECUTE stmt_col;
DEALLOCATE PREPARE stmt_col;

-- 1b. Garante coluna icao em aeroporto
SET @col_icao_exists := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'aeroporto'
    AND COLUMN_NAME = 'icao'
);
SET @sql_add_icao := IF(
  @col_icao_exists = 0,
  'ALTER TABLE aeroporto ADD COLUMN icao VARCHAR(10) NULL DEFAULT NULL;',
  'SELECT 1;'
);
PREPARE stmt_icao FROM @sql_add_icao;
EXECUTE stmt_icao;
DEALLOCATE PREPARE stmt_icao;

-- 2. Permissoes padrao do sistema
INSERT INTO permissao (nomePermissao)
SELECT 'Acessar Dashboard Rotas' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Acessar Dashboard Rotas');

INSERT INTO permissao (nomePermissao)
SELECT 'Acessar Dashboard Operacoes' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Acessar Dashboard Operacoes');

INSERT INTO permissao (nomePermissao)
SELECT 'Gerenciar Alertas Operacionais' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Gerenciar Alertas Operacionais');

INSERT INTO permissao (nomePermissao)
SELECT 'Gerenciar Organizacao' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Gerenciar Organizacao');

INSERT INTO permissao (nomePermissao)
SELECT 'Adicionar Usuario' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Adicionar Usuario');

INSERT INTO permissao (nomePermissao)
SELECT 'Editar Usuario' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Editar Usuario');

INSERT INTO permissao (nomePermissao)
SELECT 'Excluir Usuario' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Excluir Usuario');

INSERT INTO permissao (nomePermissao)
SELECT 'Gerenciar Cargos' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Gerenciar Cargos');

INSERT INTO permissao (nomePermissao)
SELECT 'Acessar Central Recomendacoes' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM permissao WHERE nomePermissao = 'Acessar Central Recomendacoes');

-- 3. Funcionalidades associadas as telas do front-end
INSERT INTO funcionalidade (nomeFuncionalidade)
SELECT 'Visualizar Dashboard Rotas' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM funcionalidade WHERE nomeFuncionalidade = 'Visualizar Dashboard Rotas');

INSERT INTO funcionalidade (nomeFuncionalidade)
SELECT 'Visualizar Dashboard Operacoes' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM funcionalidade WHERE nomeFuncionalidade = 'Visualizar Dashboard Operacoes');

INSERT INTO funcionalidade (nomeFuncionalidade)
SELECT 'Configurar Regras Alertas' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM funcionalidade WHERE nomeFuncionalidade = 'Configurar Regras Alertas');

INSERT INTO funcionalidade (nomeFuncionalidade)
SELECT 'Gerenciar Funcionarios e Cargos' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM funcionalidade WHERE nomeFuncionalidade = 'Gerenciar Funcionarios e Cargos');

INSERT INTO funcionalidade (nomeFuncionalidade)
SELECT 'Editar Informacoes Usuario' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM funcionalidade WHERE nomeFuncionalidade = 'Editar Informacoes Usuario');

INSERT INTO funcionalidade (nomeFuncionalidade)
SELECT 'Visualizar Central Recomendacoes' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM funcionalidade WHERE nomeFuncionalidade = 'Visualizar Central Recomendacoes');

INSERT INTO funcionalidade (nomeFuncionalidade)
SELECT 'Acessar Dashboard' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM funcionalidade WHERE nomeFuncionalidade = 'Acessar Dashboard');

INSERT INTO funcionalidade (nomeFuncionalidade)
SELECT 'Exportar Relatorios' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM funcionalidade WHERE nomeFuncionalidade = 'Exportar Relatorios');

INSERT INTO funcionalidade (nomeFuncionalidade)
SELECT 'Visualizar Graficos de Ocupacao' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM funcionalidade WHERE nomeFuncionalidade = 'Visualizar Graficos de Ocupacao');

INSERT INTO funcionalidade (nomeFuncionalidade)
SELECT 'Configuracoes Avancadas' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM funcionalidade WHERE nomeFuncionalidade = 'Configuracoes Avancadas');

-- 4. Vinculo entre Funcionalidades e Permissoes (funcPermissao)
INSERT INTO funcPermissao (fkFuncionalidade, fkPermissao)
SELECT f.idFuncionalidade, p.idPermissao
FROM funcionalidade f
JOIN permissao p ON p.nomePermissao = 'Acessar Dashboard Rotas'
LEFT JOIN funcPermissao fp ON fp.fkFuncionalidade = f.idFuncionalidade AND fp.fkPermissao = p.idPermissao
WHERE f.nomeFuncionalidade = 'Visualizar Dashboard Rotas'
  AND fp.fkFuncionalidade IS NULL;

INSERT INTO funcPermissao (fkFuncionalidade, fkPermissao)
SELECT f.idFuncionalidade, p.idPermissao
FROM funcionalidade f
JOIN permissao p ON p.nomePermissao = 'Acessar Dashboard Operacoes'
LEFT JOIN funcPermissao fp ON fp.fkFuncionalidade = f.idFuncionalidade AND fp.fkPermissao = p.idPermissao
WHERE f.nomeFuncionalidade = 'Visualizar Dashboard Operacoes'
  AND fp.fkFuncionalidade IS NULL;

INSERT INTO funcPermissao (fkFuncionalidade, fkPermissao)
SELECT f.idFuncionalidade, p.idPermissao
FROM funcionalidade f
JOIN permissao p ON p.nomePermissao = 'Gerenciar Alertas Operacionais'
LEFT JOIN funcPermissao fp ON fp.fkFuncionalidade = f.idFuncionalidade AND fp.fkPermissao = p.idPermissao
WHERE f.nomeFuncionalidade = 'Configurar Regras Alertas'
  AND fp.fkFuncionalidade IS NULL;

INSERT INTO funcPermissao (fkFuncionalidade, fkPermissao)
SELECT f.idFuncionalidade, p.idPermissao
FROM funcionalidade f
JOIN permissao p ON p.nomePermissao = 'Gerenciar Organizacao'
LEFT JOIN funcPermissao fp ON fp.fkFuncionalidade = f.idFuncionalidade AND fp.fkPermissao = p.idPermissao
WHERE f.nomeFuncionalidade = 'Gerenciar Funcionarios e Cargos'
  AND fp.fkFuncionalidade IS NULL;

INSERT INTO funcPermissao (fkFuncionalidade, fkPermissao)
SELECT f.idFuncionalidade, p.idPermissao
FROM funcionalidade f
JOIN permissao p ON p.nomePermissao = 'Editar Usuario'
LEFT JOIN funcPermissao fp ON fp.fkFuncionalidade = f.idFuncionalidade AND fp.fkPermissao = p.idPermissao
WHERE f.nomeFuncionalidade = 'Editar Informacoes Usuario'
  AND fp.fkFuncionalidade IS NULL;

INSERT INTO funcPermissao (fkFuncionalidade, fkPermissao)
SELECT f.idFuncionalidade, p.idPermissao
FROM funcionalidade f
JOIN permissao p ON p.nomePermissao = 'Acessar Central Recomendacoes'
LEFT JOIN funcPermissao fp ON fp.fkFuncionalidade = f.idFuncionalidade AND fp.fkPermissao = p.idPermissao
WHERE f.nomeFuncionalidade = 'Visualizar Central Recomendacoes'
  AND fp.fkFuncionalidade IS NULL;

-- 5. Garante que toda companhia tenha um cargo 'Administrador'
INSERT INTO cargo (cargo, fkCompanhia)
SELECT 'Administrador', co.idCompanhia
FROM companhia co
WHERE NOT EXISTS (
  SELECT 1 FROM cargo c WHERE c.fkCompanhia = co.idCompanhia AND c.cargo = 'Administrador'
);

-- 6. Vincula TODAS as permissoes a TODOS os cargos 'Administrador'
INSERT INTO cargoPermissao (fkCargo, fkPermissao)
SELECT c.idCargo, p.idPermissao
FROM cargo c
CROSS JOIN permissao p
LEFT JOIN cargoPermissao cp ON cp.fkCargo = c.idCargo AND cp.fkPermissao = p.idPermissao
WHERE c.cargo = 'Administrador'
  AND cp.fkCargo IS NULL;

-- Garante a permissao 'Editar Usuario' (funcionalidade de Perfil) para todos os cargos exceto 'Padrao'
INSERT INTO cargoPermissao (fkCargo, fkPermissao)
SELECT c.idCargo, p.idPermissao
FROM cargo c
JOIN permissao p ON p.nomePermissao = 'Editar Usuario'
LEFT JOIN cargoPermissao cp ON cp.fkCargo = c.idCargo AND cp.fkPermissao = p.idPermissao
WHERE c.cargo NOT LIKE 'Padra%'
  AND cp.fkCargo IS NULL;

-- Permissoes operacionais padrao para Gestor de Operacoes Aereas
INSERT INTO cargoPermissao (fkCargo, fkPermissao)
SELECT c.idCargo, p.idPermissao
FROM cargo c
JOIN permissao p ON p.nomePermissao IN ('Acessar Dashboard Operacoes', 'Gerenciar Alertas Operacionais')
LEFT JOIN cargoPermissao cp ON cp.fkCargo = c.idCargo AND cp.fkPermissao = p.idPermissao
WHERE c.cargo = 'Gestor de Operacoes Aereas'
  AND cp.fkCargo IS NULL;

-- Permissoes analiticas padrao para Analista de Planejamento de Rotas
INSERT INTO cargoPermissao (fkCargo, fkPermissao)
SELECT c.idCargo, p.idPermissao
FROM cargo c
JOIN permissao p ON p.nomePermissao IN ('Acessar Dashboard Rotas', 'Acessar Central Recomendacoes')
LEFT JOIN cargoPermissao cp ON cp.fkCargo = c.idCargo AND cp.fkPermissao = p.idPermissao
WHERE c.cargo = 'Analista de Planejamento de Rotas'
  AND cp.fkCargo IS NULL;

-- 7. Se alguma companhia nao tem nenhum usuario com cargo Administrador,
--    promove o primeiro usuario cadastrado para Administrador
UPDATE usuario u
JOIN (
  SELECT u2.fkCompanhia, MIN(u2.idUsuario) AS primeiroId
  FROM usuario u2
  GROUP BY u2.fkCompanhia
) primeiro ON primeiro.primeiroId = u.idUsuario
JOIN cargo c_admin ON c_admin.fkCompanhia = u.fkCompanhia AND c_admin.cargo = 'Administrador'
LEFT JOIN (
  SELECT DISTINCT u3.fkCompanhia
  FROM usuario u3
  JOIN cargo c3 ON c3.idCargo = u3.fkCargo
  WHERE c3.cargo = 'Administrador'
) ja_tem ON ja_tem.fkCompanhia = u.fkCompanhia
SET u.fkCargo = c_admin.idCargo
WHERE ja_tem.fkCompanhia IS NULL;

-- 8. Preenche ICAO nos aeroportos ja cadastrados (sem precisar reimportar)
UPDATE aeroporto
SET icao = CASE
  WHEN UPPER(nomeAeroporto) LIKE '%GUARULHOS%' OR UPPER(nomeAeroporto) LIKE '%FRANCO MONTORO%' THEN 'SBGR'
  WHEN UPPER(nomeAeroporto) LIKE '%GALEAO%' OR UPPER(nomeAeroporto) LIKE '%ANTONIO CARLOS JOBIM%' THEN 'SBGL'
  WHEN UPPER(nomeAeroporto) LIKE '%CONGONHAS%' THEN 'SBSP'
  WHEN UPPER(nomeAeroporto) LIKE '%VIRACOPOS%' THEN 'SBKP'
  WHEN UPPER(nomeAeroporto) LIKE '%JUSCELINO KUBITSCHEK%' OR UPPER(municipio) LIKE 'BRASILIA%' THEN 'SBBR'
  WHEN UPPER(nomeAeroporto) LIKE '%CONFINS%' OR UPPER(nomeAeroporto) LIKE '%TANCREDO NEVES%' THEN 'SBCF'
  WHEN UPPER(nomeAeroporto) LIKE '%SANTOS DUMONT%' THEN 'SBRJ'
  WHEN UPPER(nomeAeroporto) LIKE '%SALVADOR%' OR UPPER(nomeAeroporto) LIKE '%LUIS EDUARDO MAGALHAES%' THEN 'SBSV'
  WHEN UPPER(nomeAeroporto) LIKE '%GUARARAPES%' OR UPPER(municipio) LIKE 'RECIFE%' THEN 'SBRF'
  WHEN UPPER(nomeAeroporto) LIKE '%PINTO MARTINS%' OR UPPER(municipio) LIKE 'FORTALEZA%' THEN 'SBFZ'
  WHEN UPPER(nomeAeroporto) LIKE '%SALGADO FILHO%' OR UPPER(municipio) LIKE 'PORTO ALEGRE%' THEN 'SBPA'
  WHEN UPPER(nomeAeroporto) LIKE '%AFONSO PENA%' THEN 'SBCT'
  WHEN UPPER(nomeAeroporto) LIKE '%HERCILIO LUZ%' OR UPPER(municipio) LIKE 'FLORIANOPOLIS%' THEN 'SBFL'
  WHEN UPPER(nomeAeroporto) LIKE '%EURICO DE AGUIAR SALLES%' OR UPPER(municipio) LIKE 'VITORIA%' THEN 'SBVT'
  WHEN UPPER(nomeAeroporto) LIKE '%EDUARDO GOMES%' OR UPPER(municipio) LIKE 'MANAUS%' THEN 'SBEG'
  WHEN UPPER(nomeAeroporto) LIKE '%VAL DE CANS%' OR UPPER(municipio) LIKE 'BELEM%' THEN 'SBBE'
  WHEN UPPER(nomeAeroporto) LIKE '%SANTA GENOVEVA%' OR UPPER(municipio) LIKE 'GOIANIA%' THEN 'SBGO'
  WHEN UPPER(nomeAeroporto) LIKE '%MARECHAL RONDON%' OR UPPER(municipio) LIKE 'CUIABA%' THEN 'SBCY'
  WHEN UPPER(nomeAeroporto) LIKE '%ALUIZIO ALVES%' OR UPPER(nomeAeroporto) LIKE '%SAO GONCALO DO AMARANTE%' THEN 'SBSG'
  WHEN UPPER(nomeAeroporto) LIKE '%ZUMBI DOS PALMARES%' OR UPPER(municipio) LIKE 'MACEIO%' THEN 'SBMO'
  WHEN UPPER(nomeAeroporto) LIKE '%CATARATAS%' OR UPPER(municipio) LIKE 'FOZ DO IGUACU%' THEN 'SBFI'
  WHEN UPPER(nomeAeroporto) LIKE '%VICTOR KONDER%' OR UPPER(municipio) LIKE 'NAVEGANTES%' THEN 'SBNF'
  WHEN UPPER(nomeAeroporto) LIKE '%PORTO SEGURO%' THEN 'SBPS'
  WHEN UPPER(nomeAeroporto) LIKE '%CUNHA MACHADO%' OR UPPER(municipio) LIKE 'SAO LUIS%' THEN 'SBSL'
  WHEN UPPER(nomeAeroporto) LIKE '%CASTRO PINTO%' OR UPPER(municipio) LIKE 'JOAO PESSOA%' THEN 'SBJP'
  WHEN UPPER(nomeAeroporto) LIKE '%PETRONIO PORTELLA%' OR UPPER(municipio) LIKE 'TERESINA%' THEN 'SBTE'
  WHEN UPPER(nomeAeroporto) LIKE '%SANTA MARIA%' AND UPPER(uf) = 'SE' THEN 'SBAR'
  WHEN UPPER(municipio) LIKE 'CAMPO GRANDE%' AND UPPER(uf) = 'MS' THEN 'SBCG'
  WHEN UPPER(nomeAeroporto) LIKE '%JOSE RICHA%' OR UPPER(municipio) LIKE 'LONDRINA%' THEN 'SBLO'
  WHEN UPPER(nomeAeroporto) LIKE '%LEITE LOPES%' OR UPPER(municipio) LIKE 'RIBEIRAO PRETO%' THEN 'SBRP'
  WHEN UPPER(nomeAeroporto) LIKE '%CESAR BOMBONATO%' OR UPPER(municipio) LIKE 'UBERLANDIA%' THEN 'SBUL'
  WHEN UPPER(nomeAeroporto) LIKE '%PAMPULHA%' THEN 'SBBH'
  WHEN UPPER(nomeAeroporto) LIKE '%BACACHERI%' THEN 'SBBI'
  WHEN UPPER(nomeAeroporto) LIKE '%CAMPO DE MARTE%' THEN 'SBMT'
  WHEN UPPER(nomeAeroporto) LIKE '%JACAREPAGUA%' THEN 'SBJR'
  ELSE icao
END
WHERE idAeroporto > 0
  AND (icao IS NULL OR icao = '');
