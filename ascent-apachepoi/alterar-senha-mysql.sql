-- Alterar senha do usuário root para 'sptech'
ALTER USER 'root'@'localhost' IDENTIFIED BY 'sptech';
FLUSH PRIVILEGES;
SELECT 'Senha do root alterada com sucesso!' as resultado;
