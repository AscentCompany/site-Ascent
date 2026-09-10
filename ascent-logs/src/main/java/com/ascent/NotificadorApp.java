package com.ascent;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;

import javax.mail.*;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.Properties;

public class NotificadorApp {

    private static final String SLACK_WEBHOOK_URL = System.getenv("SLACK_WEBHOOK_URL");
    private static final String SLACK_WEBHOOK_CADASTRO_URL = System.getenv("SLACK_WEBHOOK_CADASTRO_URL");
    private static final String EMAIL_REMETENTE = System.getenv("EMAIL_REMETENTE");
    private static final String SENHA_APP = System.getenv("SENHA_APP");

    public static void main(String[] args) throws Exception {

        if (SLACK_WEBHOOK_URL == null || SLACK_WEBHOOK_CADASTRO_URL == null || EMAIL_REMETENTE == null || SENHA_APP == null) {
            System.err.println("ERRO FATAL: Variáveis de ambiente não configuradas!");
            System.err.println("Certifique-se de definir: SLACK_WEBHOOK_URL_GERAL, SLACK_WEBHOOK_URL_CADASTRO, EMAIL_REMETENTE, SENHA_APP");
            System.exit(1);
        }

        HttpServer server = HttpServer.create(new InetSocketAddress(8080), 0);

        server.createContext("/api/notificar", new NotificacaoGeralHandler());

        server.createContext("/enviar-alerta-slack", new AlertaCadastroHandler());

        server.setExecutor(null);
        server.start();
        System.out.println("Central de Notificações rodando na porta 8080!");
    }

    static class NotificacaoGeralHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            configurarHeadersCORS(exchange);

            if ("OPTIONS".equals(exchange.getRequestMethod())) {
                exchange.sendResponseHeaders(204, -1);
                return;
            }

            if ("POST".equals(exchange.getRequestMethod())) {
                try {
                    InputStreamReader isr = new InputStreamReader(exchange.getRequestBody(), "utf-8");
                    JsonObject dados = new Gson().fromJson(isr, JsonObject.class);

                    String mensagem = dados.get("mensagem").getAsString();
                    boolean enviarSlack = dados.has("enviarSlack") && dados.get("enviarSlack").getAsBoolean();
                    boolean enviarEmail = dados.has("enviarEmail") && dados.get("enviarEmail").getAsBoolean();

                    if (enviarSlack) {
                        enviarParaSlack(SLACK_WEBHOOK_URL ,mensagem);
                    }

                    if (enviarEmail && dados.has("emailDestinatario")) {
                        String emailDestino = dados.get("emailDestinatario").getAsString();
                        enviarParaEmail(emailDestino, mensagem);
                    }

                    System.out.println("--- [ROTA 1] NOVO PEDIDO GENÉRICO ---");
                    System.out.println("Mensagem: " + mensagem + " | Slack: " + enviarSlack + " | E-mail: " + enviarEmail);

                    enviarResposta(exchange, 200, "{\"status\": \"sucesso\"}");

                } catch (Exception e) {
                    e.printStackTrace();
                    enviarResposta(exchange, 500, "{\"erro\": \"Erro interno no servidor\"}");
                }
            } else {
                exchange.sendResponseHeaders(405, -1);
            }
        }
    }

    static class AlertaCadastroHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            configurarHeadersCORS(exchange);

            if ("OPTIONS".equals(exchange.getRequestMethod())) {
                exchange.sendResponseHeaders(204, -1);
                return;
            }

            if ("POST".equals(exchange.getRequestMethod())) {
                try {
                    InputStreamReader isr = new InputStreamReader(exchange.getRequestBody(), "utf-8");
                    JsonObject dados = new Gson().fromJson(isr, JsonObject.class);

                    String nome = dados.has("nomeServer") ? dados.get("nomeServer").getAsString() : "Indisponível";
                    String email = dados.has("emailServer") ? dados.get("emailServer").getAsString() : "Indisponível";

                    System.out.println("--- [ROTA 2] ALERTA DE CADASTRO ---");
                    System.out.println("Enviando pro Slack -> " + nome + " (" + email + ")");

                    String textoMensagem = "Novo Usuario Cadastrado: " + nome + ", " + email;
                    enviarParaSlack(SLACK_WEBHOOK_CADASTRO_URL ,textoMensagem);

                    enviarResposta(exchange, 200, "{\"status\": \"ok\"}");

                } catch (Exception e) {
                    e.printStackTrace();
                    enviarResposta(exchange, 500, "{\"erro\": \"Erro interno no servidor\"}");
                }
            } else {
                exchange.sendResponseHeaders(405, -1);
            }
        }
    }

    private static void enviarParaSlack(String urlWebhook, String mensagem) throws Exception {
        JsonObject payload = new JsonObject();
        payload.addProperty("text", mensagem);

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(urlWebhook))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(payload.toString()))
                .build();

        HttpClient.newHttpClient().send(request, HttpResponse.BodyHandlers.ofString());
        System.out.println("Notificação disparada para o Slack!");
    }

    private static void enviarParaEmail(String destinatario, String mensagemTexto) throws Exception {
        Properties props = new Properties();
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.starttls.enable", "true");
        props.put("mail.smtp.host", "smtp.gmail.com");
        props.put("mail.smtp.port", "587");

        Session session = Session.getInstance(props, new Authenticator() {
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(EMAIL_REMETENTE, SENHA_APP);
            }
        });

        Message message = new MimeMessage(session);
        message.setFrom(new InternetAddress(EMAIL_REMETENTE));
        message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(destinatario));
        message.setSubject("Nova Notificação (Central de Alertas)");
        message.setText(mensagemTexto);

        Transport.send(message);
        System.out.println("✅ E-mail enviado com sucesso para " + destinatario);
    }

    private static void configurarHeadersCORS(HttpExchange exchange) {
        exchange.getResponseHeaders().add("Access-Control-Allow-Origin", "*");
        exchange.getResponseHeaders().add("Access-Control-Allow-Methods", "POST, OPTIONS");
        exchange.getResponseHeaders().add("Access-Control-Allow-Headers", "Content-Type");
    }

    private static void enviarResposta(HttpExchange exchange, int statusCode, String resposta) throws IOException {
        byte[] bytes = resposta.getBytes("UTF-8");
        exchange.sendResponseHeaders(statusCode, bytes.length);
        OutputStream os = exchange.getResponseBody();
        os.write(bytes);
        os.close();
    }
}