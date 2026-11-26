-- Criar usuário específico para a aplicação Ascent
-- Execute este script no MySQL Workbench com suas credenciais atuais

-- Remover usuário se já existir (para garantir limpeza)
DROP USER IF EXISTS 'ascent'@'localhost';

-- Criar novo usuário
CREATE USER 'ascent'@'localhost' IDENTIFIED BY 'sptech';

-- Conceder todas as permissões no banco ascent
GRANT ALL PRIVILEGES ON ascent.* TO 'ascent'@'localhost';

-- Aplicar as mudanças
FLUSH PRIVILEGES;

-- Verificar se foi criado
SELECT user, host FROM mysql.user WHERE user = 'ascent';

SELECT '✓ Usuário ascent criado com sucesso!' as resultado;
