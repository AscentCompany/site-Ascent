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
  -- Regionais brasileiros da lista
  WHEN UPPER(nomeAeroporto) LIKE '%AUGUSTO SEVERO%' THEN 'SBNT'
  WHEN UPPER(nomeAeroporto) LIKE '%RENATO MOREIRA%' OR UPPER(municipio) = 'IMPERATRIZ' THEN 'SBIZ'
  WHEN UPPER(nomeAeroporto) LIKE '%ALCOLUMBRE%' OR UPPER(uf) = 'AP' AND UPPER(municipio) LIKE 'MACAP%' THEN 'SBMQ'
  WHEN UPPER(nomeAeroporto) LIKE '%ATLAS BRASIL%' THEN 'SBBV'
  WHEN UPPER(nomeAeroporto) LIKE '%LAURO CARNEIRO%' OR UPPER(municipio) = 'JOINVILLE' THEN 'SBJV'
  WHEN UPPER(nomeAeroporto) LIKE '%ERIBERTO MANOEL%' THEN 'SBSR'
  WHEN UPPER(nomeAeroporto) LIKE '%LYSIAS RODRIGUES%' OR UPPER(municipio) = 'PALMAS' THEN 'SBPJ'
  WHEN UPPER(nomeAeroporto) LIKE '%MARIO PEREIRA LOPES%' OR UPPER(nomeAeroporto) = 'SAO CARLOS' THEN 'SDSC'
  WHEN UPPER(nomeAeroporto) LIKE '%NELSON RODRIGUES%' OR UPPER(nomeAeroporto) = 'CALDAS NOVAS' THEN 'SBCN'
  WHEN UPPER(nomeAeroporto) LIKE '%JORGE AMADO%' THEN 'SBIL'
  WHEN UPPER(nomeAeroporto) LIKE '%JORGE TEIXEIRA%' THEN 'SBPV'
  WHEN UPPER(nomeAeroporto) LIKE '%CORREA DA ROCHA%' OR UPPER(municipio) LIKE 'MARAB%' THEN 'SBMA'
  WHEN UPPER(nomeAeroporto) LIKE '%WILSON FONSECA%' THEN 'SBSN'
  WHEN UPPER(nomeAeroporto) LIKE '%USIMINAS%' THEN 'SBIP'
  WHEN UPPER(nomeAeroporto) LIKE '%ALTINO MACHADO%' OR UPPER(nomeAeroporto) LIKE 'GOVERNADOR VALADARES%' THEN 'SBGV'
  WHEN UPPER(nomeAeroporto) LIKE '%FRANCISCO DE ASSIS%' THEN 'SBJF'
  WHEN UPPER(nomeAeroporto) LIKE 'MACA%' AND UPPER(uf) = 'RJ' THEN 'SBME'
  WHEN UPPER(nomeAeroporto) LIKE '%URBANO ERNESTO STUMPF%' THEN 'SBSJ'
  WHEN UPPER(nomeAeroporto) LIKE '%BRIGADEIRO CAMAR%' THEN 'SBVH'
  WHEN UPPER(municipio) LIKE 'JI-PARAN%' THEN 'SBJI'
  WHEN UPPER(nomeAeroporto) LIKE '%SUASSUNA%' THEN 'SBKG'
  WHEN UPPER(municipio) LIKE 'TEF%' AND UPPER(uf) = 'AM' THEN 'SBTF'
  WHEN UPPER(nomeAeroporto) LIKE '%BATISTA FIGUEIREDO%' THEN 'SWSI'
  WHEN UPPER(nomeAeroporto) LIKE 'RONDON%' AND UPPER(uf) = 'MT' THEN 'SWRD'
  WHEN UPPER(nomeAeroporto) LIKE '%SILVIO NAME%' OR UPPER(nomeAeroporto) LIKE 'MARING%' THEN 'SBMG'
  WHEN UPPER(nomeAeroporto) LIKE '%MARIO RIBEIRO%' THEN 'SBMK'
  WHEN UPPER(nomeAeroporto) = 'PELOTAS' THEN 'SBPK'
  WHEN UPPER(municipio) LIKE 'ARAGUA%' AND UPPER(uf) = 'TO' THEN 'SWGN'
  WHEN UPPER(nomeAeroporto) = 'TROMBETAS' THEN 'SBTB'
  WHEN UPPER(nomeAeroporto) LIKE '%SERAFIN ENOSS%' THEN 'SBCH'
  WHEN UPPER(nomeAeroporto) LIKE '%FERNANDO DE NORONHA%' THEN 'SBFN'
  WHEN UPPER(nomeAeroporto) LIKE '%DARIO GUARITA%' THEN 'SBAU'
  WHEN UPPER(nomeAeroporto) = 'ALTAMIRA' THEN 'SBHT'
  WHEN UPPER(nomeAeroporto) LIKE '%ORLANDO BEZERRA%' OR UPPER(nomeAeroporto) = 'CARIRI' THEN 'SBJU'
  WHEN UPPER(nomeAeroporto) = 'ITAITUBA' THEN 'SBIH'
  WHEN UPPER(nomeAeroporto) LIKE '%JULIO BELEM%' THEN 'SWPI'
  WHEN UPPER(nomeAeroporto) = 'TABATINGA' THEN 'SBTT'
  WHEN UPPER(nomeAeroporto) LIKE '%GABRIEL DA CACHOEIRA%' THEN 'SBUA'
  WHEN UPPER(nomeAeroporto) LIKE '%OSVALDO MARQUES DIAS%' THEN 'SBAT'
  WHEN UPPER(nomeAeroporto) LIKE '%LEITE DE CASTRO%' THEN 'SWLC'
  WHEN UPPER(nomeAeroporto) LIKE '%ALMEIDA FRANCO%' THEN 'SBUR'
  WHEN UPPER(nomeAeroporto) LIKE 'CORUMB%' THEN 'SBCR'
  WHEN UPPER(nomeAeroporto) = 'BONITO' AND UPPER(uf) = 'MS' THEN 'SBDB'
  WHEN UPPER(nomeAeroporto) LIKE '%HORACIO DE MATTOS%' OR UPPER(nomeAeroporto) = 'CHAPADA DIAMANTINA' THEN 'SBLE'
  WHEN UPPER(nomeAeroporto) LIKE 'TUCURU%' THEN 'SBTU'
  WHEN UPPER(nomeAeroporto) LIKE '%NILO COELHO%' THEN 'SBPL'
  WHEN UPPER(nomeAeroporto) = 'CABO FRIO' THEN 'SBCB'
  WHEN UPPER(nomeAeroporto) LIKE '%ZONA DA MATA%' THEN 'SBZM'
  WHEN UPPER(nomeAeroporto) LIKE 'CARAJ%' THEN 'SBCJ'
  WHEN UPPER(nomeAeroporto) = 'URUCU' THEN 'SBUY'
  WHEN UPPER(nomeAeroporto) LIKE '%MILENKOVICH%' THEN 'SBML'
  WHEN UPPER(nomeAeroporto) = 'PRESIDENTE PRUDENTE' THEN 'SBDN'
  WHEN UPPER(nomeAeroporto) = 'DOURADOS' OR UPPER(nomeAeroporto) LIKE '%MATOS PEREIRA%' THEN 'SBDO'
  WHEN UPPER(nomeAeroporto) LIKE '%DIOMICIO FREITAS%' THEN 'SBCM'
  WHEN UPPER(nomeAeroporto) LIKE '%ADALBERTO MENDES%' THEN 'SBCA'
  WHEN UPPER(nomeAeroporto) LIKE '%BAURU/AREALVA%' OR UPPER(nomeAeroporto) LIKE '%BAURU-AREALVA%' OR UPPER(nomeAeroporto) LIKE '%MOUSSA NAKHL%' THEN 'SBAE'
  WHEN UPPER(nomeAeroporto) LIKE '%HUGO CANTERGIANI%' THEN 'SBCX'
  WHEN UPPER(nomeAeroporto) LIKE '%PLACIDO DE CASTRO%' THEN 'SBRB'
  WHEN UPPER(nomeAeroporto) = 'CRUZEIRO DO SUL' THEN 'SBCZ'
  WHEN UPPER(nomeAeroporto) LIKE '%LAURO KURTZ%' THEN 'SBPF'
  WHEN UPPER(nomeAeroporto) LIKE 'SANTO %NGELO' THEN 'SBNM'
  WHEN UPPER(nomeAeroporto) LIKE '%RUBEM BERTA%' THEN 'SBUG'
  WHEN UPPER(nomeAeroporto) LIKE '%DIX-SEPT%' THEN 'SBMS'
  WHEN UPPER(nomeAeroporto) LIKE 'JERICOACORA%' THEN 'SBJE'
  WHEN UPPER(nomeAeroporto) = 'REGIONAL SUL' AND UPPER(uf) = 'SC' THEN 'SBJA'
  WHEN UPPER(nomeAeroporto) LIKE '%TRES LAGOAS%' THEN 'SBTG'
  WHEN UPPER(nomeAeroporto) LIKE '%AMILTON BERALDO%' OR UPPER(nomeAeroporto) = 'PONTA GROSSA' THEN 'SBPG'
  WHEN UPPER(nomeAeroporto) = 'TEIXEIRA DE FREITAS' THEN 'SNTF'
  WHEN UPPER(nomeAeroporto) LIKE '%PLANALTO SERRANO%' OR UPPER(nomeAeroporto) = 'CORREIA PINTO' THEN 'SNCP'
  WHEN UPPER(nomeAeroporto) LIKE '%PARNA%' AND UPPER(uf) = 'PI' THEN 'SBPB'
  WHEN UPPER(nomeAeroporto) LIKE '%DURVAL CARNEIRO%' THEN 'SBFE'
  WHEN UPPER(nomeAeroporto) LIKE '%SORRISO ADOLINO%' THEN 'SBSO'
  WHEN UPPER(nomeAeroporto) LIKE '%MOREIRA SALLES%' THEN 'SBPC'
  WHEN UPPER(nomeAeroporto) = 'SOROCABA' THEN 'SDCO'
  WHEN UPPER(nomeAeroporto) LIKE '%BARTOLOMEU DE GUSM%' AND UPPER(uf) = 'SP' THEN 'SBAQ'
  WHEN UPPER(nomeAeroporto) = 'BAURU' THEN 'SBBU'
  WHEN UPPER(nomeAeroporto) LIKE '%UMBERTO MODIANO%' THEN 'SBBZ'
  WHEN UPPER(nomeAeroporto) LIKE '%LOUREIRO CARDOSO%' THEN 'SBPO'
  WHEN UPPER(nomeAeroporto) LIKE '%Thomas de Faria%' THEN 'SBGU'
  WHEN UPPER(nomeAeroporto) LIKE '%SERRA DA CAPIVARA%' THEN 'SWKQ'
  WHEN UPPER(nomeAeroporto) LIKE 'PONTA POR%' THEN 'SBPP'
  WHEN UPPER(nomeAeroporto) LIKE '%ARACATI%' THEN 'SBAC'
  WHEN UPPER(nomeAeroporto) LIKE '%GUSTAVO KRAEMER%' THEN 'SBBG'
  WHEN UPPER(nomeAeroporto) LIKE '%CATARINA AEROPORTO%' THEN 'SBJH'
  -- Internacionais comerciais da lista
  WHEN UPPER(nomeAeroporto) LIKE '%JORGE NEWBERY%' THEN 'SABE'
  WHEN UPPER(nomeAeroporto) LIKE '%EZEIZA%' OR UPPER(nomeAeroporto) LIKE '%PISTARINI%' THEN 'SAEZ'
  WHEN UPPER(nomeAeroporto) LIKE '%CARRASCO%' THEN 'SUMU'
  WHEN UPPER(nomeAeroporto) LIKE '%ARTURO MERINO%' THEN 'SCEL'
  WHEN UPPER(nomeAeroporto) LIKE '%JORGE CHAVEZ%' OR UPPER(nomeAeroporto) LIKE '%JORGE CH%' AND UPPER(municipio) LIKE '%LIMA%' THEN 'SPJC'
  WHEN UPPER(nomeAeroporto) LIKE '%EL DORADO%' THEN 'SKBO'
  WHEN UPPER(nomeAeroporto) LIKE '%MARISCAL SUCRE%' OR UPPER(nomeAeroporto) = 'QUITO ' THEN 'SEQM'
  WHEN UPPER(nomeAeroporto) LIKE '%MARIA CORDOVA%' THEN 'SKRG'
  WHEN UPPER(nomeAeroporto) LIKE '%SIMON BOLIVAR%' OR UPPER(nomeAeroporto) LIKE '%MAIQUETIA%' THEN 'SVMI'
  WHEN UPPER(nomeAeroporto) LIKE '%VIRU VIRU%' THEN 'SLVR'
  WHEN UPPER(nomeAeroporto) LIKE '%SILVIO PETTIROSSI%' THEN 'SGAS'
  WHEN UPPER(nomeAeroporto) LIKE '%TOCUMEN%' THEN 'MPTO'
  WHEN UPPER(nomeAeroporto) LIKE '%BENITO JUAREZ%' THEN 'MMMX'
  WHEN UPPER(nomeAeroporto) LIKE '%CANCUN%' THEN 'MMUN'
  WHEN UPPER(nomeAeroporto) LIKE '%JOHN F. KENNEDY%' THEN 'KJFK'
  WHEN UPPER(nomeAeroporto) LIKE '%ORLANDO INTERNATIONAL%' THEN 'KMCO'
  WHEN UPPER(nomeAeroporto) LIKE '%MIAMI INTERNATIONAL%' THEN 'KMIA'
  WHEN UPPER(nomeAeroporto) LIKE '%FORT LAUDERDALE%' THEN 'KFLL'
  WHEN UPPER(nomeAeroporto) LIKE '%HARTSFIELD JACKSON%' THEN 'KATL'
  WHEN UPPER(nomeAeroporto) LIKE '%GEORGE BUSH%' THEN 'KIAH'
  WHEN UPPER(nomeAeroporto) LIKE '%DALLAS-FORT WORTH%' THEN 'KDFW'
  WHEN UPPER(nomeAeroporto) LIKE '%HARE INTERNATIONAL%' THEN 'KORD'
  WHEN UPPER(nomeAeroporto) LIKE '%LOS ANGELES%' THEN 'KLAX'
  WHEN UPPER(nomeAeroporto) LIKE '%NEWARK LIBERTY%' THEN 'KEWR'
  WHEN UPPER(nomeAeroporto) LIKE '%WASHINGTON DULLES%' THEN 'KIAD'
  WHEN UPPER(nomeAeroporto) LIKE '%LOGAN INTERNATIONAL%' THEN 'KBOS'
  WHEN UPPER(nomeAeroporto) LIKE '%SAN FRANCISCO%' THEN 'KSFO'
  WHEN UPPER(nomeAeroporto) LIKE '%TORONTO PEARSON%' THEN 'CYYZ'
  WHEN UPPER(nomeAeroporto) LIKE '%TRUDEAU%' THEN 'CYUL'
  WHEN UPPER(nomeAeroporto) = 'LISBOA' THEN 'LPPT'
  WHEN UPPER(nomeAeroporto) = 'PORTO' THEN 'LPPR'
  WHEN UPPER(nomeAeroporto) LIKE '%BARAJAS%' THEN 'LEMD'
  WHEN UPPER(nomeAeroporto) LIKE '%BARCELONA-EL PRAT%' THEN 'LEBL'
  WHEN UPPER(nomeAeroporto) LIKE '%CHARLES DE GAULLE%' THEN 'LFPG'
  WHEN UPPER(nomeAeroporto) LIKE '%PARIS ORLY%' THEN 'LFPO'
  WHEN UPPER(nomeAeroporto) LIKE '%HEATHROW%' THEN 'EGLL'
  WHEN UPPER(nomeAeroporto) LIKE '%GATWICK%' THEN 'EGKK'
  WHEN UPPER(nomeAeroporto) LIKE '%FRANKFURT INTERNATIONAL%' THEN 'EDDF'
  WHEN UPPER(nomeAeroporto) LIKE '%MUNICH INTERNATIONAL%' THEN 'EDDM'
  WHEN UPPER(nomeAeroporto) LIKE '%SCHIPHOL%' THEN 'EHAM'
  WHEN UPPER(nomeAeroporto) LIKE '%FIUMICINO%' THEN 'LIRF'
  WHEN UPPER(nomeAeroporto) LIKE '%MALPENSA%' THEN 'LIMC'
  WHEN UPPER(nomeAeroporto) LIKE '%ZURICH%' OR UPPER(nomeAeroporto) LIKE '%KLOTEN AIRPORT%' THEN 'LSZH'
  WHEN UPPER(nomeAeroporto) LIKE '%ISTANBUL AIRPORT%' THEN 'LTFM'
  WHEN UPPER(nomeAeroporto) = 'DUBAI' THEN 'OMDB'
  WHEN UPPER(nomeAeroporto) LIKE '%HAMAD INTERNATIONAL%' OR UPPER(nomeAeroporto) LIKE '%DOHA INTERNATIONAL%' THEN 'OTHH'
  WHEN UPPER(nomeAeroporto) LIKE '%OR TAMBO%' THEN 'FAOR'
  WHEN UPPER(nomeAeroporto) LIKE '%QUATRO DE FEVEREIRO%' THEN 'FNLU'
  WHEN UPPER(nomeAeroporto) LIKE '%AMILCAR CABRAL%' THEN 'GVAC'
  WHEN UPPER(nomeAeroporto) LIKE '%PUNTA CANA%' THEN 'MDPC'
  WHEN UPPER(nomeAeroporto) LIKE '%DE LAS AMERICAS%' THEN 'MDSD'
  WHEN UPPER(nomeAeroporto) LIKE '%TARAVELLA%' THEN 'SACO'
  WHEN UPPER(nomeAeroporto) LIKE '%ROSARIO%' THEN 'SAAR'
  WHEN UPPER(nomeAeroporto) LIKE '%BARILOCHE%' THEN 'SAZS'
  WHEN UPPER(nomeAeroporto) LIKE '%PLUMERILLO%' THEN 'SAME'
  WHEN UPPER(nomeAeroporto) LIKE '%EL ALTO%' THEN 'SLLP'
  WHEN UPPER(nomeAeroporto) LIKE '%GUAYAQUIL%' OR UPPER(nomeAeroporto) LIKE '%OLMEDO%' THEN 'SEGU'
  WHEN UPPER(nomeAeroporto) LIKE '%CARTAGENA%' OR UPPER(nomeAeroporto) LIKE '%RAFAEL NU%' THEN 'SKCG'
  WHEN UPPER(nomeAeroporto) LIKE '%BOLE INTERNATIONAL%' THEN 'HAAB'
WHEN UPPER(TRIM(nomeAeroporto)) = 'TOULOUSE - BLAGNAC AIRPORT' AND UPPER(TRIM(municipio)) = 'TOULOUSE' THEN 'LFBO'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'HOTEL TRANSAMERICA(AERODROMO PRIVADO)' AND uf = 'BA' THEN 'SBTC'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CARAUARI' AND uf = 'AM' THEN 'SWCA'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'ROMEU ZEMA' AND uf = 'MG' THEN 'SBAX'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'COARI' AND uf = 'AM' THEN 'SWKO'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'BARCELOS' AND uf = 'AM' THEN 'SWBC'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SENADORA EUNICE MICHILES' AND uf = 'AM' THEN 'SDCG'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'FONTE BOA' AND uf = 'AM' THEN 'SWOB'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CACOAL' AND uf = 'RO' THEN 'SSKW'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'BARREIRAS' AND uf = 'BA' THEN 'SNBR'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'PATOS DE MINAS' AND uf = 'MG' THEN 'SNPD'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'BARTOLOMEU LISANDRO' AND uf = 'RJ' THEN 'SBCP'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'EIRUNEPE' AND uf = 'AM' THEN 'SWEI'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SANTA IZABEL DO RIO NEGRO' AND uf = 'AM' THEN 'SWTP'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'FRANCISCO CORREA DA CRUZ' AND uf = 'AM' THEN 'SWHT'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'LABREA' AND uf = 'AM' THEN 'SWLB'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'ARTURO MICHELENA INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'VALENCIA, CARABOBO' THEN 'SVVA'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'AEROPORTO INTERNACIONAL LA AURORA' AND UPPER(TRIM(municipio)) = 'GUATEMALA/LA AURORA' THEN 'MGGT'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'GUARANI INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'CIUDAD DEL ESTE' THEN 'SGES'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'QUEEN BEATRIX INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'ORANJESTAD, ARUBA' THEN 'TNCA'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'LUIS MUNOZ MARIN INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'SAN JUAN' THEN 'TJSJ'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CAPE TOWN INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'CAPE TOWN' THEN 'FACT'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'LONDON STANSTED AIRPORT' AND UPPER(TRIM(municipio)) = 'LONDON, ENGLAND' THEN 'EGSS'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CHARLOTTE/DOUGLAS INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'CHARLOTTE, NORTH CAROLINA' THEN 'KCLT'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'BEIJING CAPITAL INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'BEIJING' THEN 'ZBAA'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'KOTOKA INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'ACCRA' THEN 'DGAA'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'VNUKOVO AIRPORT' AND UPPER(TRIM(municipio)) = 'MOSCOW' THEN 'UUWW'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'OTTAWA MACDONALD-CARTIER INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'OTTAWA, ONTARIO' THEN 'CYOW'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'HAVANA' AND UPPER(TRIM(municipio)) = 'HAVANA' THEN 'MUHA'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'JORGE WILSTERMANN INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'COCHABAMBA' THEN 'SLCB'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'LUXEMBOURG FINDEL AIRPORT' AND UPPER(TRIM(municipio)) = 'LUXEMBOURG CITY' THEN 'ELLX'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MAASTRICHT AACHEN AIRPORT' AND UPPER(TRIM(municipio)) = 'BEEK' THEN 'EHBK'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'RAFAEL HERNANDEZ AIRPORT' AND UPPER(TRIM(municipio)) = 'AQUADILLA BORINQUEN' THEN 'TJBQ'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'COTOPAXI INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'LATACUNGA' THEN 'SELT'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'ALFONSO BONILLA ARAGON INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'CALI' THEN 'SKCL'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'DETROIT METROPOLITAN WAYNE COUNTY AIRPORT' AND UPPER(TRIM(municipio)) = 'ROMULUS, MICHIGAN (NEAR DETROIT)' THEN 'KDTW'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'HATO INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'WILLEMSTAD' THEN 'TNCC'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'INCHEON INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'INCHEON (NEAR SEOUL)' THEN 'RKSI'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'TED STEVENS ANCHORAGE INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'ANCHORAGE, ALASKA' THEN 'PANC'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'DIEGO ARACENA INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'IQUIQUE' THEN 'SCDA'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'GUADALAJARA/INTL' AND UPPER(TRIM(municipio)) = 'GUADALAJARA/INTL' THEN 'MMGL'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MERIDA' AND UPPER(TRIM(municipio)) = 'MERIDA' THEN 'MMMD'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'TENERIFE SOUTH AIRPORT' AND UPPER(TRIM(municipio)) = 'TENERIFE' THEN 'GCTS'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'FRANKFURT-HAHN AIRPORT' AND UPPER(TRIM(municipio)) = 'RHINELAND-PALATINATE' THEN 'EDFH'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'BRUSSELS AIRPORT' AND UPPER(TRIM(municipio)) = 'BRUSSELS/ZAVENTEM' THEN 'EBBR'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'LISMORE AIRPORT' AND UPPER(TRIM(municipio)) = 'LISMORE, NEW SOUTH WALES' THEN 'YLIS'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'STOCKHOLM-ARLANDA AIRPORT' AND UPPER(TRIM(municipio)) = 'STOCKHOLM' THEN 'ESSA'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'HARARE INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'HARARE' THEN 'FVRG'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'LIEGE AIRPORT' AND UPPER(TRIM(municipio)) = 'LIEGE' THEN 'EBLG'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'ATATURK INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'ISTANBUL' THEN 'LTBA'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CHALONS VATRY AIRPORT' AND UPPER(TRIM(municipio)) = 'CHALONS-EN-CHAMPAGNE' THEN 'LFOK'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'LVIV INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'LVIV' THEN 'UKLL'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'BRESCIA AIRPORT GABRIELE D ANNUNZIO' AND UPPER(TRIM(municipio)) = 'MONTICHIARI' THEN 'LIPO'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'PIARCO INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'PORT OF SPAIN, TRINIDAD' THEN 'TTPP'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'ERNESTO CORTISSOZ INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'BARRANQUILLA' THEN 'SKBQ'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'GRAN CANARIA AIRPORT' AND UPPER(TRIM(municipio)) = 'LAS PALMAS' THEN 'GCLP'
        WHEN UPPER(TRIM(nomeAeroporto)) LIKE '%JOHAN ADOLF PENGEL%' AND UPPER(TRIM(municipio)) = 'ZANDERIJ' THEN 'SMJP'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'GRANTLEY ADAMS INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'BRIDGETOWN' THEN 'TBPB'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'TORRES' AND uf = 'RS' THEN 'SBTR'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SANTA ROSA' AND uf = 'RS' THEN 'SSZR'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'REGIONAL DE RIO GRANDE' AND uf = 'RS' THEN 'SJRG'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'VALENCA' AND uf = 'BA' THEN 'SNVB'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SHANNON AIRPORT' AND UPPER(TRIM(municipio)) = 'SHANNON, COUNTY CLARE' THEN 'EINN'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'REDENCAO' AND uf = 'PA' THEN 'SNDC'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'OURILANDIA DO NORTE' AND uf = 'PA' THEN 'SDOW'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MONTE DOURADO' AND uf = 'PA' THEN 'SBMD'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CONFRESA(AERODROMO PRIVADO)' AND uf = 'MT' THEN 'SJHG'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'VILA RICA' AND uf = 'MT' THEN 'SWVC'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SAO FELIX DO ARAGUAIA' AND uf = 'MT' THEN 'SWFX'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'GURUPI' AND uf = 'TO' THEN 'SWGI'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'ARAGARCAS' AND uf = 'GO' THEN 'SJVO'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'PORANGATU' AND uf = 'GO' THEN 'SWWA'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MOZARLANDIA' AND uf = 'GO' THEN 'SDOV'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MORRO DE SAO PAULO' AND uf = 'BA' THEN 'SDGX'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'HAMBURG FINKENWERDER AIRPORT' AND UPPER(TRIM(municipio)) = 'HAMBURG' THEN 'EDHI'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MAJOR BRIGADEIRO TROMPOWSKY' AND uf = 'MG' THEN 'SBVG'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SAO JOAO DEL REI' AND uf = 'MG' THEN 'SNJR'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SAN JOSE/JUAN SANTAMARIA' AND UPPER(TRIM(municipio)) = 'SAN JOSE/JUAN SANTAMARIA' THEN 'MROC'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'AEROPORTO INTERNACIONAL TOUSSAINT LOUVERTURE' AND UPPER(TRIM(municipio)) = 'PORT-DE-PAIX' THEN 'MTPP'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'NUEVA HESPERIDES INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'SALTO, SALTO' THEN 'SUSO'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'EAST MIDLANDS AIRPORT' AND UPPER(TRIM(municipio)) = 'EAST MIDLANDS, ENGLAND' THEN 'EGNX'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'LOME-TOKOIN AIRPORT' AND UPPER(TRIM(municipio)) = 'LOME' THEN 'DXXX'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'AUSTIN BERGSTROM INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'AUSTIN, TEXAS' THEN 'KAUS'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'RIGAINTERNATIONALAIRPORT' AND UPPER(TRIM(municipio)) = 'RIGA' THEN 'EVRA'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MONTERREY' AND UPPER(TRIM(municipio)) = 'MONTERREY' THEN 'MMMY'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'LEIPZIG/HALLE AIRPORT' AND UPPER(TRIM(municipio)) = 'LEIPZIG/HALLE' THEN 'EDDP'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'BENGALURU INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'BENGALURU' THEN 'VOBL'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'GLASGOW PRESTWICK INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'GLASGOW, SCOTLAND' THEN 'EGPF'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'AEROPORTO INTERNACIONAL LYNDEN PINDLING' AND UPPER(TRIM(municipio)) = 'NASSAU/INTL NEW PROVIDENCE' THEN 'MYNN'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'BEN GURION INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'LOD/TEL AVIV' THEN 'LLBG'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'HUNTSVILLE INTERNATIONAL AIRPORT (CARL T. JONES FIELD)' AND UPPER(TRIM(municipio)) = 'HUNTSVILLE, ALABAMA' THEN 'KHSV'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'DOVER AIR FORCE BASE' AND UPPER(TRIM(municipio)) = 'DOVER, DELAWARE' THEN 'KDOV'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'GENERAL JUAN N. ALVAREZ INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'ACAPULCO/GEN.JUAN ALVAREZ' THEN 'MMAA'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'ORLANDO DE CARVALHO' AND uf = 'PR' THEN 'SSUM'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'PAULO ABDALA' AND uf = 'PR' THEN 'SSFB'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CARLOS ALBERTO DA COSTA NEVES' AND uf = 'SC' THEN 'SBCD'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SANTA TEREZINHA' AND uf = 'SC' THEN 'SSJA'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'OLAVO CECCO RIGON' AND uf = 'SC' THEN 'SSCK'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'GUANAMBI' AND uf = 'BA' THEN 'SNGI'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'BOM JESUS DA LAPA' AND uf = 'BA' THEN 'SBLP'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'ORIXIMINA' AND uf = 'PA' THEN 'SNOX'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'BARRA DO VENTO' AND uf = 'RR' THEN 'SJQK'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CHEDDI JAGAN INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'GEORGETOWN' THEN 'SYCJ'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'LEAO DE OURO' AND uf = 'RR' THEN 'SJLM'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'ERECHIM' AND uf = 'RS' THEN 'SSER'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CONCEICAO DO ARAGUAIA' AND uf = 'PA' THEN 'SBAA'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SAO FELIX DO XINGU' AND uf = 'PA' THEN 'SNFX'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MINACU' AND uf = 'GO' THEN 'SBMC'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'PALMEIRAS DE GOIAS' AND uf = 'GO' THEN 'SWGP'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'INDIANAPOLIS INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'INDIANAPOLIS, INDIANA' THEN 'KIND'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'DIAMANTINA' AND uf = 'MG' THEN 'SNDT'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MARICA' AND uf = 'RJ' THEN 'SDMC'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'AEROPORTO ESTADUAL DE JUNDIAI' AND uf = 'SP' THEN 'SBJD'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MANAGUA' AND UPPER(TRIM(municipio)) = 'MANAGUA' THEN 'MNMG'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'JACKSONVILLE INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'JACKSONVILLE, FLORIDA' THEN 'KJAX'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'AEROCLUBE DE ELDORADO DO SUL' AND uf = 'RS' THEN 'SIXE'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CACERES' AND uf = 'MT' THEN 'SWKC'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'LUIS DAL CANALLE FILHO' AND uf = 'PR' THEN 'SBTD'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CHICAGO ROCKFORD INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'CHICAGO' THEN 'KRFD'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CHARLESTON INTERNATIONAL AIRPORT (CHARLESTON AIR FORCE BASE)' AND UPPER(TRIM(municipio)) = 'CHARLESTON, SOUTH CAROLINA' THEN 'KCHS'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'AL MAKTOUM INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'JEBEL ALI' THEN 'OMDW'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'BLAISE DIAGNE INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'DAKAR' THEN 'GOBD'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MCCARRAN INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'LAS VEGAS, NEVADA' THEN 'KLAS'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MALTA INTERNATIONAL AIRPORT (LUQA AIRPORT)' AND UPPER(TRIM(municipio)) = 'LUQA' THEN 'LMML'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CALGARY INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'CALGARY, ALBERTA' THEN 'CYYC'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CERRO MORENO INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'ANTOFAGASTA' THEN 'SCFA'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'AEROPORTO INTERNACIONAL MOHAMMED V' AND UPPER(TRIM(municipio)) = 'CASABLANCA' THEN 'GMMN'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'PAULO AFONSO' AND uf = 'BA' THEN 'SBUF'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'BILLUND AIRPORT' AND UPPER(TRIM(municipio)) = 'BILLUND' THEN 'EKBI'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'EMBRAER-UNIDADE GAVIAO PEIXOTO' AND uf = 'SP' THEN 'SBGP'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'BARRA DO GARCAS' AND uf = 'MT' THEN 'SBBW'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'VICOSA' AND uf = 'MG' THEN 'SNVC'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'AEROPORTO ELIAS BREDER' AND uf = 'MG' THEN 'SNJM'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'PATROCINIO' AND uf = 'MG' THEN 'SNPJ'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'JUSCELINO KUBITSCHECK' AND uf = 'MG' THEN 'SNTO'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'GUAXUPE' AND uf = 'MG' THEN 'SNGX'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'PARACATU' AND uf = 'MG' THEN 'SNZR'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CAXAMBU' AND uf = 'MG' THEN 'SNXB'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'ARACUAI' AND uf = 'MG' THEN 'SNUI'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CIRILO QUEIROZ' AND uf = 'MG' THEN 'SNAR'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'POUSO ALEGRE' AND uf = 'MG' THEN 'SNZA'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MUNICIPAL JOSE FIGUEIREDO' AND uf = 'MG' THEN 'SNOS'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SEBASTIAO GOMES DE SOUZA' AND uf = 'MG' THEN 'SNUH'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'RALEIGH-DURHAM INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'RALEIGH, NORTH CAROLINA' THEN 'KRDU'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'BRIGADEIRO CABRAL' AND uf = 'MG' THEN 'SNDV'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'AEROCLUBE DA BAHIA' AND uf = 'BA' THEN 'SNVR'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SAO JOSE' AND uf = 'PA' THEN 'SNSH'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'BREVES' AND uf = 'PA' THEN 'SNVS'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MONTE ALEGRE' AND uf = 'PA' THEN 'SNMA'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'PORTO DE MOZ' AND uf = 'PA' THEN 'SNMZ'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'RIO GRANDE' AND uf = 'RS' THEN 'SJRG'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'WALTER BUNDCHEN' AND uf = 'RS' THEN 'SSHZ'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CHAFEI AMSEI' AND uf = 'SP' THEN 'SBBT'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'OIAPOQUE' AND uf = 'AP' THEN 'SBOI'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'TENENTE LUND PRESETTO' AND uf = 'SP' THEN 'SIMK'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MUCURI' AND uf = 'BA' THEN 'SNMU'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CARAVELAS' AND uf = 'BA' THEN 'SBCV'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'BORBA' AND uf = 'AM' THEN 'SWBR'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MANICORE' AND uf = 'AM' THEN 'SBMY'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MAUES' AND uf = 'AM' THEN 'SWMW'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'ITACOATIARA' AND uf = 'AM' THEN 'SBIC'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'BARREIRINHA' AND uf = 'AM' THEN 'SWBI'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'DEL CARIBE INTERNATIONAL AIRPORT (GEN. SANTIAGO MARINO AIRPORT)' AND UPPER(TRIM(municipio)) = 'PORLAMAR, ISLA MARGARITA' THEN 'SVMG'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'NOVO PROGRESSO' AND uf = 'PA' THEN 'SJNP'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'GUARANTA' AND uf = 'MT' THEN 'SSNM'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'AEROPORTO MUNICIPAL BOM FUTURO' AND uf = 'MT' THEN 'SILC'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'ARIPUANA' AND uf = 'MT' THEN 'SSOU'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'JUINA' AND uf = 'MT' THEN 'SWJN'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'JUARA SUL' AND uf = 'MT' THEN 'SIZX'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'AEROCLUBE' AND uf = 'RS' THEN 'SSBG'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CORONEL FAP FRANCISCO SECADA VIGNETTA AIRPORT' AND UPPER(TRIM(municipio)) = 'IQUITOS, LORETO REGION' THEN 'SPQT'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'NARITA INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'NARITA, CHIBA' THEN 'RJAA'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'OLAYA HERRERA AIRPORT' AND UPPER(TRIM(municipio)) = 'MEDELLIN' THEN 'SKMD'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'OSCAR LARANJEIRAS' AND uf = 'PE' THEN 'SNRU'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'PRAINHA' AND uf = 'AM' THEN 'SWYN'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'BARREIRINHAS' AND uf = 'MA' THEN 'SSRS'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SANTA MAGALHAES' AND uf = 'PE' THEN 'SNHS'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'GARANHUNS' AND uf = 'PE' THEN 'SNGN'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'GUAIRA' AND uf = 'PR' THEN 'SSGY'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'AERODROMO MUNICIPAL DE LINHARES' AND uf = 'ES' THEN 'SNLN'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SALINOPOLIS' AND uf = 'PA' THEN 'SNSM'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'ARARIPINA' AND uf = 'PE' THEN 'SNAB'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'PEDRO VIEIRA MOREIRA' AND uf = 'PB' THEN 'SJZA'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CHAFEI AMSEI (SBBT*)' AND uf = 'SP' THEN 'SBBT'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'ANGRA DOS REIS' AND uf = 'RJ' THEN 'SDAG'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'WALFRIDO SAMITO DE ALMEIDA' AND uf = 'CE' THEN 'SWBE'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'IGUATU' AND uf = 'CE' THEN 'SNIG'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'DOUTOR LUCIO LIMA' AND uf = 'CE' THEN 'SNWS'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SALINAS' AND uf = 'MG' THEN 'SNSS'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'TELEMACO BORBA (SBTL*)' AND uf = 'PR' THEN 'SBTL'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'AERODROMO DE PARAGOMINAS' AND uf = 'PA' THEN 'SNEB'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'JOSE CLETO' AND uf = 'PR' THEN 'SSUV'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'JACAREACANGA' AND uf = 'PA' THEN 'SBEK'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'TUCSON INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'TUCSON, ARIZONA' THEN 'KTUS'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'KINGSTON/NORMAN MANLEY INTL' AND UPPER(TRIM(municipio)) = 'KINGSTON/NORMAN MANLEY INTL' THEN 'MKJP'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MARTINIQUE AIME CESAIRE INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'LE LAMENTIN, FORT-DE-FRANCE' THEN 'TFFF'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'LAJES AIR BASE INT.' AND UPPER(TRIM(municipio)) = 'TERCEIRA ISLAND/PRAIA DA VITORIA/ANGRA DO HEROISMO AREA' THEN 'LPLA'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MARTIN MIGUEL DE GUEMES INTERNATIONAL AIRPORT (EL AYBAL AIRPORT)' AND UPPER(TRIM(municipio)) = 'SALTA, SALTA PROVINCE' THEN 'SASA'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SOUTHERN CALIFORNIA LOGISTICS AIRPORT' AND UPPER(TRIM(municipio)) = 'VICTORVILLE, CALIFORNIA' THEN 'KVCV'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'FORT WORTH ALLIANCE AIRPORT' AND UPPER(TRIM(municipio)) = 'FORT WORTH, TEXAS' THEN 'KAFW'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'TAMPA INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'TAMPA, FLORIDA' THEN 'KTPA'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SOFIA INTERNATIONAL AIRPORT (VRAZHDEBNA)' AND UPPER(TRIM(municipio)) = 'SOFIA' THEN 'LBSF'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'PHOENIX SKY HARBOR INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'PHOENIX, ARIZONA' THEN 'KPHX'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MARCH AIR RESERVE BASE' AND UPPER(TRIM(municipio)) = 'RIVERSIDE, CALIFORNIA' THEN 'KRIV'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'LUSAKA INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'LUSAKA' THEN 'FLLC'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CAPITAN FAP RENAN ELIAS OLIVERA AIRPORT' AND UPPER(TRIM(municipio)) = 'PISCO, ICA REGION' THEN 'SPSO'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'ALEXANDRIA INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'ALEXANDRIA, LOUISIANA' THEN 'HEAX'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'RESISTENCIA INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'RESISTENCIA, CHACO PROVINCE' THEN 'SARE'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'LORENZO' AND uf = 'BA' THEN 'SNCL'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'AEROPORTO FABIO PERINI' AND uf = 'BA' THEN 'SDLO'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'BARRA GRANDE' AND uf = 'BA' THEN 'SIRI'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SEATTLE-TACOMA INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'SEATTLE, WASHINGTON' THEN 'KSEA'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CAPITAO JOAO BUSSE' AND uf = 'PR' THEN 'SSAP'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'GASTAO DE MESQUITA FILHO' AND uf = 'PR' THEN 'SSCT'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'ARAPONGAS' AND uf = 'PR' THEN 'SSOG'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'VACARIA NOVO' AND uf = 'RS' THEN 'SNEE'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CINCINNATI/NORTHERN KENTUCKY INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'HEBRON, KENTUCKY' THEN 'KCVG'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'VALLEY INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'HARLINGEN, TEXAS' THEN 'KHRL'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'PHOENIX-MESA GATEWAY AIRPORT' AND UPPER(TRIM(municipio)) = 'MESA, ARIZONA' THEN 'KIWA'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'RICKENBACKER INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'COLUMBUS, OHIO' THEN 'KLCK'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'NAVAL STATION NORFOLK' AND UPPER(TRIM(municipio)) = 'NORFOLK, VIRGINIA' THEN 'KORF'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'PEREGRINO FILHO' AND uf = 'PB' THEN 'SNTS'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'HONG KONG INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'CHEK LAP KOK' THEN 'VHHH'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CANELA' AND uf = 'RS' THEN 'SSCN'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SANTA CRUZ DO SUL' AND uf = 'RS' THEN 'SSSC'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'GERALDO GUIAS DE AQUINO' AND uf = 'PR' THEN 'SSKM'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'ALMEIRIM' AND uf = 'PA' THEN 'SNYA'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'OBIDOS' AND uf = 'PA' THEN 'SNTI'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'YUMA INTERNATIONAL AIRPORT/MARINE CORPS AIR STATION YUMA' AND UPPER(TRIM(municipio)) = 'YUMA, ARIZONA' THEN 'KNYL'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'TRAVIS AIR FORCE BASE' AND UPPER(TRIM(municipio)) = 'FAIRFIELD, CALIFORNIA' THEN 'KSUU'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'ENTEBBE INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'ENTEBBE (NEAR KAMPALA)' THEN 'HUEN'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CONAKRY/GBESSIA' AND UPPER(TRIM(municipio)) = 'CONAKRY/GBESSIA' THEN 'GUCY'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'USHUAIA - MALVINAS ARGENTINAS INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'USHUAIA, TIERRA DEL FUEGO PROVINCE' THEN 'SAWH'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'TARAUACA' AND uf = 'AC' THEN 'SBTK'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'NOVO CAMPO' AND uf = 'AM' THEN 'SWNK'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'FEIJO' AND uf = 'AC' THEN 'SNOU'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'BACABAL' AND uf = 'MA' THEN 'SNBI'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SAO MATEUS' AND uf = 'ES' THEN 'SNMX'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'ANGELO PONZONI' AND uf = 'SC' THEN 'SSVI'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'DINARD PLEURTUIT SAINT-MALO AIRPORT' AND UPPER(TRIM(municipio)) = 'DINARD' THEN 'LFRD'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'TURIN INTERNATIONAL AIRPORT (TORINO CASELLE AIRPORT)' AND UPPER(TRIM(municipio)) = 'TURIN (TORINO)' THEN 'LIMF'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'TOLUCA' AND UPPER(TRIM(municipio)) = 'TOLUCA' THEN 'MMTO'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'PORTO NACIONAL' AND uf = 'TO' THEN 'SBPN'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SOURE' AND uf = 'PA' THEN 'SNSW'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MONTPELLIER-MEDITERRANEE AIRPORT' AND UPPER(TRIM(municipio)) = 'MONTPELLIER' THEN 'LFMT'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'ABBOTSFORD INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'ABBOTSFORD, BRITISH COLUMBIA' THEN 'CYXX'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'ESTANCIA REBOG' AND uf = 'MT' THEN 'SJQP'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'DIAMANTINO' AND uf = 'MT' THEN 'SWDM'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'ANTONIO MACEO AIRPORT' AND UPPER(TRIM(municipio)) = 'SANTIAGO DE CUBA, SANTIAGO DE CUBA' THEN 'MUCU'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'DIORI HAMANI INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'NIAMEY' THEN 'DRRN'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'ZARAGOZA AIRPORT' AND UPPER(TRIM(municipio)) = 'ZARAGOZA' THEN 'LEZG'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CADJEHOUN AIRPORT (COTONOU AIRPORT)' AND UPPER(TRIM(municipio)) = 'COTONOU' THEN 'DBBB'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'AIRBORNE AIRPARK' AND UPPER(TRIM(municipio)) = 'WILMINGTON, OHIO' THEN 'KILN'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'HONIARA INTERNATIONAL AIRPORT (HENDERSON FIELD)' AND UPPER(TRIM(municipio)) = 'HONIARA, GUADALCANAL' THEN 'AGGH'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'HONOLULU INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'HONOLULU' THEN 'PHNL'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'AMAPA' AND uf = 'AP' THEN 'SBAM'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'PARATI' AND uf = 'RJ' THEN 'SDTK'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SAUCE VIEJO AIRPORT' AND UPPER(TRIM(municipio)) = 'SANTA FE, SANTA FE PROVINCE' THEN 'SAAV'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CHATEAUROUX-DEOLS AIRPORT' AND UPPER(TRIM(municipio)) = 'CHATEAUROUX, DEOLS' THEN 'LFLX'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MATECANA INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'PEREIRA' THEN 'SKPE'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'TARBES - LOURDES PYRENEES AIRPORT' AND UPPER(TRIM(municipio)) = 'TARBES' THEN 'LFBT'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MUSCAT INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'MUSCAT' THEN 'OOMS'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'HEWANORRA INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'VIEUX-FORT, SAINT LUCIA' THEN 'TLPL'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SUVARNABHUMI AIRPORT (NEW BANGKOK INTERNATIONAL AIRPORT)' AND UPPER(TRIM(municipio)) = 'SAMUT PRAKAN (NEAR BANGKOK)' THEN 'VTBS'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CAICO' AND uf = 'RN' THEN 'SNKK'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'PROGRESSO' AND uf = 'PA' THEN 'SJNP'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MATUPA' AND uf = 'MT' THEN 'SSNM'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'JUARA' AND uf = 'MT' THEN 'SIZX'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'JURUENA' AND uf = 'MT' THEN 'SWJF'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'TIRIOS' AND uf = 'PA' THEN 'SNTI'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'IPIRANGA' AND uf = 'AM' THEN 'SWII'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'JAPURA - VILA BITTENCOURT' AND uf = 'AM' THEN 'SWJP'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'NOVO ARIPUANA' AND uf = 'AM' THEN 'SWNA'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'TOLEDO' AND uf = 'PR' THEN 'SBTD'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MARCELO PIRES HALZHAUSEN' AND uf = 'SP' THEN 'SNAX'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'DOMINGOS PIGNATARI' AND uf = 'SP' THEN 'SDVG'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'PRINCESS JULIANA INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'PHILIPSBURG' THEN 'TNCM'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SOUSA' AND uf = 'PB' THEN 'SNQD'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'COMANDANTE PASCHOAL PATROCINIO FILHO' AND uf = 'MG' THEN 'SNFE'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'GENERAL JOSE ANTONIO ANZOATEGUI INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'BARCELONA, ANZOATEGUI' THEN 'SVBC'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SAARBRUCKEN AIRPORT' AND UPPER(TRIM(municipio)) = 'SAARBRUCKEN' THEN 'EDDR'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'LOUIS ARMSTRONG INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'NEW ORLEANS, LOUISIANA' THEN 'KMSY'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'ORLANDO SANFORD INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'SANFORD, FLORIDA' THEN 'KSFB'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'EXETER INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'EXETER, ENGLAND' THEN 'EGTE'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'DALLAS LOVE FIELD' AND UPPER(TRIM(municipio)) = 'DALLAS, TEXAS, ESTADOS UNIDOS DA AMERICA' THEN 'KDAL'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'GUAJARA-MIRIM' AND uf = 'RO' THEN 'SBGM'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'COSTA MARQUES' AND uf = 'RO' THEN 'SWCQ'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'PITINGA' AND uf = 'AM' THEN 'SJVP'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'ANDREWS AIR FORCE BASE' AND UPPER(TRIM(municipio)) = 'CAMP SPRINGS, MARYLAND' THEN 'KADW'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'TANCREDO DE ALMEIDA NEVES' AND uf = 'SP' THEN 'SDBK'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CAIRO INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'CAIRO' THEN 'HECA'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'BARRA DO CORDA' AND uf = 'MA' THEN 'SNBC'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MONROVIA' AND UPPER(TRIM(municipio)) = 'MONROVIA' THEN 'GLRB'
        WHEN UPPER(TRIM(nomeAeroporto)) LIKE '%LEON M%BA INTERNATIONAL%' AND UPPER(TRIM(municipio)) = 'LIBREVILLE' THEN 'FOOL'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'LANSERIA AIRPORT' AND UPPER(TRIM(municipio)) = 'LANSERIA' THEN 'FALA'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'AEROPORTO INTERNACIONAL NOUAKCHOTT-OUMTOUNSY' AND UPPER(TRIM(municipio)) = 'NOUAKCHOTT, MAURITANIA' THEN 'GQNO'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'TUNIS - CARTHAGE INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'TUNIS' THEN 'DTTA'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'HAMILTON/JOHN C. MUNRO INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'HAMILTON, ONTARIO' THEN 'NZHN'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'TIANJIN BINHAI INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'TIANJIN' THEN 'ZBTJ'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'ARARAS' AND uf = 'SP' THEN 'SDAA'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CHACALLUTA INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'ARICA' THEN 'SCAR'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'IJUI' AND uf = 'RS' THEN 'SSIJ'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'PRESIDENTE PERON INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'NEUQUEN, NEUQUEN PROVINCE' THEN 'SAZN'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'LA CHINITA INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'MARACAIBO, ZULIA' THEN 'SVMC'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'VITORIA AIRPORT' AND UPPER(TRIM(municipio)) = 'ALAVA' THEN 'LEVT'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SABIHA GOKCEN INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'ISTANBUL' THEN 'LTFJ'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'LISZT FERENC INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'BUDAPEST' THEN 'LHBP'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SNOHOMISH COUNTY AIRPORT (PAINE FIELD)' AND UPPER(TRIM(municipio)) = 'EVERETT, WASHINGTON' THEN 'KPAE'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'RESENDE' AND uf = 'RJ' THEN 'SDRS'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'TAPACHULA INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'TAPACHULA, CHIAPAS' THEN 'MMTP'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MALAGA-COSTA DEL SOL AIRPORT' AND UPPER(TRIM(municipio)) = 'MALAGA' THEN 'LEMG'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SAO TOME INTERNATIONAL AIRPORT (SALAZAR AIRPORT)' AND UPPER(TRIM(municipio)) = 'SAO TOME' THEN 'FPST'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'TERRAVISTA' AND uf = 'BA' THEN 'SBTV'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MUNDICO COELHO' AND uf = 'PA' THEN 'SNMD'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'ESTRELA DALVA' AND uf = 'MS' THEN 'SIEV'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'AEROPORTO INTERNACIONAL DR. ANTONIO AGOSTINHO NETO' AND UPPER(TRIM(municipio)) = 'LUANDA' THEN 'FNBJ'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'LA FLORIDA AIRPORT' AND UPPER(TRIM(municipio)) = 'LA SERENA' THEN 'SCSE'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CARRIEL SUR INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'CONCEPCION' THEN 'SCIE'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'EUROAIRPORT BASEL-MULHOUSE-FREIBURG' AND UPPER(TRIM(municipio)) = 'MULHOUSE, FRANCE/BASEL, SWITZERLAND' THEN 'LFSB'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SUBTENIENTE FAP ALEJANDRO VELASCO ASTETE INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'CUSCO, CUSCO REGION' THEN 'SPZO'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SOEKARNO HATTA INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'CENGKARENG, BANTEN (NEAR JAKARTA)]' THEN 'WIII'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'PHILADELPHIA INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'PHILADELPHIA, PENNSYLVANIA' THEN 'KPHL'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'PORT BOUET AIRPORT (FELIX HOUPHOUET BOIGNY INTERNATIONAL AIRPORT)' AND UPPER(TRIM(municipio)) = 'ABIDJAN' THEN 'DIAP'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'GREENVILLE-SPARTANBURG INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'GREER, SOUTH CAROLINA' THEN 'KGSP'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'ONTARIO INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'ONTARIO, CALIFORNIA' THEN 'KONT'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'WINDHOEK HOSEA KUTAKO INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'WINDHOEK' THEN 'FYWH'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'COLUMBIA METROPOLITAN AIRPORT' AND UPPER(TRIM(municipio)) = 'WEST COLUMBIA, SOUTH CAROLINA (NEAR COLUMBIA)' THEN 'KCAE'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'ATLANTIC CITY INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'ATLANTIC CITY, NEW JERSEY' THEN 'KACY'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'TERUEL AIRPORT' AND UPPER(TRIM(municipio)) = 'TERUEL' THEN 'LETL'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'LAREDO INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'LAREDO, TEXAS' THEN 'KLRD'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MOBILE DOWNTOWN AIRPORT' AND UPPER(TRIM(municipio)) = 'MOBILE, ALABAMA' THEN 'KBFM'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'RUBEN BERTA' AND uf = 'PR' THEN 'SSCR'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'LAKE CHARLES REGIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'LAKE CHARLES, LOUISIANA' THEN 'KLCH'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SANTA CLARA' AND UPPER(TRIM(municipio)) = 'SANTA CLARA' THEN 'MUSC'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'FAZENDA COLIBRI' AND uf = 'MS' THEN 'SWJQ'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'ANAPOLIS' AND uf = 'GO' THEN 'SWNS'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'EL LOA AIRPORT' AND UPPER(TRIM(municipio)) = 'CALAMA' THEN 'SCCF'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SURUCUCU' AND uf = 'RR' THEN 'SWUQ'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'FAZENDA PIRATININGA' AND uf = 'GO' THEN 'SWDE'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'NASHVILLE INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'NASHVILLE, TENNESSEE' THEN 'KBNA'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'AEROPORTO DE MOCAMBINHO' AND uf = 'MG' THEN 'SNMK'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SAO JOAQUIM' AND uf = 'AM' THEN 'SWSQ'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'DOMINGOS REGO' AND uf = 'MA' THEN 'SNDR'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'FAZENDA SOYA' AND uf = 'BA' THEN 'SNDQ'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'JOMO KENYATTA INTERNATIONAL AIRPORT (FORMERLY NAIROBI INTERNATIONAL AIRPORT)' AND UPPER(TRIM(municipio)) = 'NAIROBI' THEN 'HKJK'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'LOUISVILLE INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'LOUISVILLE, KENTUCKY' THEN 'KSDF'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'LEEWARD POINT FIELD (US NAVAL STATION GUANTANAMO BAY)' AND UPPER(TRIM(municipio)) = 'GUANTANAMO BAY, GUANTANAMO' THEN 'MUGM'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'QUAD CITY INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'MOLINE, ILLINOIS' THEN 'KMLI'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'EDINBURGH AIRPORT' AND UPPER(TRIM(municipio)) = 'EDINBURGH, SCOTLAND' THEN 'EGPH'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'COLOGNE BONN AIRPORT' AND UPPER(TRIM(municipio)) = 'COLOGNE/BONN' THEN 'EDDK'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'PALONEGRO AIRPORT' AND UPPER(TRIM(municipio)) = 'LEBRIJA (NEAR BUCARAMANGA)' THEN 'SKBG'
        WHEN UPPER(TRIM(nomeAeroporto)) LIKE 'RHODES INTERNATIONAL AIRPORT%' AND UPPER(TRIM(municipio)) LIKE 'RHODES%' THEN 'LGRP'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SIR SEEWOOSAGUR RAMGOOLAM INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'PLAINE MAGNIEN' THEN 'FIMP'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'TAIWAN TAOYUAN INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'TAOYUAN CITY' THEN 'RCTP'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'DOTHAN REGIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'DOTHAN, ALABAMA' THEN 'KDHN'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'BORDEAUX MERIGNAC AIRPORT' AND UPPER(TRIM(municipio)) = 'BORDEAUX' THEN 'LFBD'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'HELIO WASUM' AND uf = 'SC' THEN 'SSOE'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'PARIS LE BOURGET AIRPORT' AND UPPER(TRIM(municipio)) = 'PARIS' THEN 'LFPB'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'LONDON LUTON AIRPORT' AND UPPER(TRIM(municipio)) = 'LONDON, ENGLAND' THEN 'EGGW'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'NOVOSIBIRSK TOLMACHEVO AIRPORT' AND UPPER(TRIM(municipio)) = 'NOVOSIBIRSK' THEN 'UNNT'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'EL TEPUAL INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'PUERTO MONTT' THEN 'SCTE'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'BASE AEREA DE ANAPOLIS' AND uf = 'GO' THEN 'SWNS'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MALLAM AMINU KANO INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'KANO, KANO STATE' THEN 'DNKN'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'LARANJAL DO JARI' AND uf = 'AP' THEN 'SINQ'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'JEQUIE' AND uf = 'BA' THEN 'SNJK'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MAYOR BUENAVENTURA VIVAS AIRPORT' AND UPPER(TRIM(municipio)) = 'SANTO DOMINGO' THEN 'SVSO'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'TULSA INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'TULSA, OKLAHOMA' THEN 'KTUL'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'RODRIGUEZ BALLON INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'AREQUIPA, AREQUIPA REGION' THEN 'SPQU'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'GRAND BAHAMA INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'FREEPORT' THEN 'MYGF'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'RZESZOW-JASIONKA AIRPORT' AND UPPER(TRIM(municipio)) = 'RZESZOW' THEN 'EPRZ'
        WHEN UPPER(TRIM(nomeAeroporto)) LIKE '%KEFLAVIK INTERNATIONAL%' AND UPPER(TRIM(municipio)) = 'KEFLAVIK' THEN 'BIKF'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CASTELLON AIRPORT' AND UPPER(TRIM(municipio)) = 'CASTELLON' THEN 'LECH'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'DUSSELDORF-MONCHENGLADBACH AIRPORT' AND UPPER(TRIM(municipio)) = 'MONCHENGLADBACH' THEN 'EDLN'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'HOTEL TRANSAMERICA' AND uf = 'BA' THEN 'SBTC'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'PALMA DE MALLORCA AIRPORT' AND UPPER(TRIM(municipio)) = 'ISLAS BALEARES' THEN 'LEPA'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MADRID-TORREJON AIRPORT' AND UPPER(TRIM(municipio)) = 'MADRID' THEN 'LETO'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'LAGOA SANTA' AND uf = 'MG' THEN 'SBLS'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'DUSSELDORF INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'DUSSELDORF' THEN 'EDDL'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'FAZENDA SOCOCO' AND uf = 'PA' THEN 'SNYV'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'AGROPALMA' AND uf = 'PA' THEN 'SNTP'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'FAZENDA SANTO AMBROSIO' AND uf = 'PA' THEN 'SISO'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'BALSAS' AND uf = 'MA' THEN 'SNBS'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'PRIMAVERA' AND uf = 'MT' THEN 'SNXL'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'WALNUT RIDGE REGIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'WALNUT RIDGE, ARKANSAS' THEN 'KARG'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'ELOY ALFARO INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'MANTA' THEN 'SEMT'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'EL PASO INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'EL PASO, TEXAS' THEN 'KELP'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'INCA MANCO CAPAC INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'PUNO/JULIACA, PUNO REGION' THEN 'SPJL'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'TANGARA DA SERRA' AND uf = 'MT' THEN 'SWTS'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SHEREMETYEVO INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'MOSCOW' THEN 'UUEE'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'HEYDAR ALIYEV INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'BAKU' THEN 'UBBB'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'BARROW/WALNEY ISLAND AIRFIELD' AND UPPER(TRIM(municipio)) = 'BARROW-IN-FURNESS, ENGLAND' THEN 'EGNL'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SYDNEY AIRPORT' AND UPPER(TRIM(municipio)) = 'MASCOT, NEW SOUTH WALES' THEN 'YSSY'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'TASHKENT AIRPORT' AND UPPER(TRIM(municipio)) = 'TASHKENT' THEN 'UZTT'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'GRIFFISS AIRPORT' AND UPPER(TRIM(municipio)) = 'ROME, NEW YORK' THEN 'KRME'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'BALTIMORE-WASHINGTON INTERNATIONAL THURGOOD MARSHALL AIRPORT' AND UPPER(TRIM(municipio)) = 'BALTIMORE, MARYLAND & WASHINGTON, DC' THEN 'KBWI'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SAN BERNARDINO INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'SAN BERNARDINO, CALIFORNIA' THEN 'KSBD'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'GREENWOOD-LEFLORE AIRPORT' AND UPPER(TRIM(municipio)) = 'GREENWOOD, MISSISSIPPI' THEN 'KGWO'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'SELETAR AIRPORT' AND UPPER(TRIM(municipio)) = 'SELETAR' THEN 'WSSL'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'BRADLEY INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'WINDSOR LOCKS, CONNECTICUT (NEAR HARTFORD)' THEN 'KBDL'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'EASTLEIGH AIRPORT' AND UPPER(TRIM(municipio)) = 'NAIROBI' THEN 'HKRE'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'REGIONAL ORLANDO VILLAS BOAS' AND uf = 'MT' THEN 'SWXM'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'GENOA CRISTOFORO COLOMBO AIRPORT (SESTRI AIRPORT)' AND UPPER(TRIM(municipio)) = 'GENOA (GENOVA)' THEN 'LIMJ'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CAMILO DAZA INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'CUCUTA' THEN 'SKCC'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'BEGUMPET AIRPORT' AND UPPER(TRIM(municipio)) = 'HYDERABAD' THEN 'VOHY'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'ESTADUAL ARTHUR SIQUEIRA' AND uf = 'SP' THEN 'SBBP'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'MONTREAL-MIRABEL INTERNATIONAL AIRPORT' AND UPPER(TRIM(municipio)) = 'MONTREAL, QUEBEC' THEN 'CYMX'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'CACADOR' AND uf = 'SC' THEN 'SBCD'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'BEBEDOURO' AND uf = 'SP' THEN 'SDBB'
        WHEN UPPER(TRIM(nomeAeroporto)) = 'NAPLES INTERNATIONAL AIRPORT (CAPODICHINO AIRPORT)' AND UPPER(TRIM(municipio)) = 'NAPLES' THEN 'LIRN'
  ELSE icao
END
WHERE idAeroporto > 0
  AND (icao IS NULL OR icao = '');
