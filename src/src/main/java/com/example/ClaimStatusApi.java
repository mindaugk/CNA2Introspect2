package com.example;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.JsonNode;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.core.ResponseBytes;
import software.amazon.awssdk.core.SdkBytes;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.bedrockruntime.BedrockRuntimeClient;
import software.amazon.awssdk.services.bedrockruntime.model.InvokeModelRequest;
import software.amazon.awssdk.services.bedrockruntime.model.InvokeModelResponse;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.services.dynamodb.model.AttributeValue;
import software.amazon.awssdk.services.dynamodb.model.GetItemRequest;
import software.amazon.awssdk.services.dynamodb.model.GetItemResponse;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.S3Exception;

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

public class ClaimStatusApi {
    private static final ObjectMapper MAPPER = new ObjectMapper();
    private static final String CLAIMS_TABLE = Optional.ofNullable(System.getenv("CLAIMS_TABLE"))
            .filter(v -> !v.isBlank())
            .orElse("claims");
    private static final String NOTES_BUCKET = Optional.ofNullable(System.getenv("NOTES_BUCKET"))
        .filter(v -> !v.isBlank())
        .orElse("claim-notes");
    private static final String NOTES_KEY_TEMPLATE = Optional.ofNullable(System.getenv("NOTES_KEY_TEMPLATE"))
        .filter(v -> !v.isBlank())
        .orElse("claims/%s/note-01.txt");
    private static final String BEDROCK_MODEL_ID = Optional.ofNullable(System.getenv("BEDROCK_MODEL_ID"))
        .filter(v -> !v.isBlank())
        .orElse("anthropic.claude-3-sonnet-20240229-v1:0");
    private static final Region AWS_REGION = Region.of(Optional.ofNullable(System.getenv("AWS_REGION"))
            .filter(v -> !v.isBlank())
            .orElse("us-east-1"));

    public static void main(String[] args) throws IOException {
        HttpServer server = HttpServer.create(new InetSocketAddress(8080), 0);
        server.createContext("/claims", new ClaimsHandler());
        server.setExecutor(null);
        server.start();
        System.out.println("Listening on :8080");
    }

    static class ClaimsHandler implements HttpHandler {
        private final DynamoDbClient dynamoDb = DynamoDbClient.builder()
                .region(AWS_REGION)
                .build();
        private final S3Client s3 = S3Client.builder()
                .region(AWS_REGION)
                .build();
        private final BedrockRuntimeClient bedrock = BedrockRuntimeClient.builder()
                .region(AWS_REGION)
                .build();

        @Override
        public void handle(HttpExchange exchange) throws IOException {
            long start = System.currentTimeMillis();
            String method = exchange.getRequestMethod();
            String path = exchange.getRequestURI().getPath();

            String[] parts = path.split("/");
            if (parts.length == 3 && !parts[2].isBlank() && "GET".equalsIgnoreCase(method)) {
                handleGetClaim(exchange, parts[2], start);
                return;
            }

            if (parts.length == 4 && "summarize".equalsIgnoreCase(parts[3]) && !parts[2].isBlank()) {
                if (!"POST".equalsIgnoreCase(method)) {
                    sendJson(exchange, 405, Map.of("message", "Method not allowed"));
                    logRequest(exchange, 405, start, null);
                    return;
                }
                handleSummarize(exchange, parts[2], start);
                return;
            }

            sendJson(exchange, 400, Map.of("message", "Invalid path. Use /claims/{id} or /claims/{id}/summarize"));
            logRequest(exchange, 400, start, null);
        }

        private void handleGetClaim(HttpExchange exchange, String claimId, long start) throws IOException {
            try {
                Map<String, AttributeValue> key = Map.of("id", AttributeValue.builder().s(claimId).build());
                GetItemRequest request = GetItemRequest.builder()
                        .tableName(CLAIMS_TABLE)
                        .key(key)
                        .build();
                GetItemResponse response = dynamoDb.getItem(request);

                if (response.item() == null || response.item().isEmpty()) {
                    sendJson(exchange, 404, Map.of("message", "Claim not found", "id", claimId));
                    logRequest(exchange, 404, start, null);
                    return;
                }

                Map<String, Object> payload = convertItem(response.item());
                sendJson(exchange, 200, payload);
                logRequest(exchange, 200, start, null);
            } catch (Exception ex) {
                sendJson(exchange, 500, Map.of("message", "Server error", "detail", ex.getMessage()));
                logRequest(exchange, 500, start, ex);
            }
        }

        private void handleSummarize(HttpExchange exchange, String claimId, long start) throws IOException {
            String s3Key = String.format(NOTES_KEY_TEMPLATE, claimId);
            try {
                ResponseBytes<?> objBytes = s3.getObjectAsBytes(GetObjectRequest.builder()
                        .bucket(NOTES_BUCKET)
                        .key(s3Key)
                        .build());
                String content = objBytes.asString(StandardCharsets.UTF_8);
                Map<String, Object> note = MAPPER.readValue(
                        content,
                        new com.fasterxml.jackson.core.type.TypeReference<Map<String, Object>>() {}
                );

                String text = Optional.ofNullable(note.get("text")).map(Object::toString).orElse("");
                String prompt = buildPrompt(claimId, text);
                Map<String, String> summaries = invokeBedrock(prompt);

                note.put("overall-summary", summaries.getOrDefault("overall-summary", ""));
                note.put("customer-facing-summary", summaries.getOrDefault("customer-facing-summary", ""));
                note.put("adjuster-facing-summary", summaries.getOrDefault("adjuster-facing-summary", ""));
                note.put("recommended-next-step", summaries.getOrDefault("recommended-next-step", ""));

                String updated = MAPPER.writeValueAsString(note);
                s3.putObject(PutObjectRequest.builder()
                                .bucket(NOTES_BUCKET)
                                .key(s3Key)
                                .contentType("application/json")
                                .build(),
                        RequestBody.fromString(updated, StandardCharsets.UTF_8));

                sendJson(exchange, 200, note);
                logRequest(exchange, 200, start, null);
            } catch (S3Exception ex) {
                if (ex.statusCode() == 404) {
                    sendJson(exchange, 404, Map.of("message", "Note not found", "id", claimId, "key", s3Key));
                    logRequest(exchange, 404, start, ex);
                    return;
                }
                sendJson(exchange, 500, Map.of("message", "S3 error", "detail", ex.getMessage()));
                logRequest(exchange, 500, start, ex);
            } catch (Exception ex) {
                sendJson(exchange, 500, Map.of("message", "Server error", "detail", ex.getMessage()));
                logRequest(exchange, 500, start, ex);
            }
        }

        private Map<String, String> invokeBedrock(String prompt) throws IOException {
            String payload = MAPPER.writeValueAsString(Map.of(
                    "anthropic_version", "bedrock-2023-05-31",
                    "max_tokens", 512,
                    "temperature", 0.2,
                    "messages", List.of(Map.of(
                            "role", "user",
                            "content", List.of(Map.of("type", "text", "text", prompt))
                    ))
            ));

            InvokeModelRequest request = InvokeModelRequest.builder()
                    .modelId(BEDROCK_MODEL_ID)
                    .contentType("application/json")
                    .accept("application/json")
                    .body(SdkBytes.fromString(payload, StandardCharsets.UTF_8))
                    .build();

            InvokeModelResponse response = bedrock.invokeModel(request);
            String responseBody = response.body().asString(StandardCharsets.UTF_8);

            JsonNode root = MAPPER.readTree(responseBody);
            JsonNode content = root.path("content");
            if (!content.isArray() || content.isEmpty()) {
                throw new IOException("Unexpected Bedrock response: missing content");
            }

            String text = content.get(0).path("text").asText();
            if (text == null || text.isBlank()) {
                throw new IOException("Unexpected Bedrock response: empty text");
            }

            JsonNode summaryNode = MAPPER.readTree(text);
            Map<String, String> result = new HashMap<>();
            result.put("overall-summary", summaryNode.path("overall-summary").asText(""));
            result.put("customer-facing-summary", summaryNode.path("customer-facing-summary").asText(""));
            result.put("adjuster-facing-summary", summaryNode.path("adjuster-facing-summary").asText(""));
            result.put("recommended-next-step", summaryNode.path("recommended-next-step").asText(""));
            return result;
        }

        private String buildPrompt(String claimId, String noteText) {
            String requestId = UUID.randomUUID().toString();
            return "You are an insurance claims assistant. "
                    + "Generate concise summaries from the note below. "
                    + "Return ONLY valid JSON with keys: overall-summary, customer-facing-summary, "
                    + "adjuster-facing-summary, recommended-next-step. "
                    + "No additional text. "
                    + "RequestId=" + requestId + "\n\n"
                    + "ClaimId: " + claimId + "\n"
                    + "Note: " + noteText;
        }
    }

    private static void sendJson(HttpExchange exchange, int status, Map<String, ?> payload) throws IOException {
        byte[] bytes = MAPPER.writeValueAsBytes(payload);
        exchange.getResponseHeaders().add("Content-Type", "application/json");
        exchange.sendResponseHeaders(status, bytes.length);
        try (OutputStream os = exchange.getResponseBody()) {
            os.write(bytes);
        }
    }

    private static void logRequest(HttpExchange exchange, int status, long start, Exception ex) {
        long durationMs = System.currentTimeMillis() - start;
        String method = exchange.getRequestMethod();
        String path = exchange.getRequestURI().getPath();
        String query = exchange.getRequestURI().getQuery();
        String fullPath = (query == null || query.isBlank()) ? path : path + "?" + query;
        if (ex == null) {
            System.out.printf("%s %s -> %d (%dms)%n", method, fullPath, status, durationMs);
        } else {
            System.out.printf("%s %s -> %d (%dms) error=%s%n", method, fullPath, status, durationMs, ex.getMessage());
        }
    }

    private static Map<String, Object> convertItem(Map<String, AttributeValue> item) {
        Map<String, Object> result = new HashMap<>();
        for (Map.Entry<String, AttributeValue> entry : item.entrySet()) {
            result.put(entry.getKey(), convertValue(entry.getValue()));
        }
        return result;
    }

    private static Object convertValue(AttributeValue value) {
        if (value.s() != null) {
            return value.s();
        }
        if (value.n() != null) {
            try {
                if (value.n().contains(".")) {
                    return Double.parseDouble(value.n());
                }
                return Long.parseLong(value.n());
            } catch (NumberFormatException ex) {
                return value.n();
            }
        }
        if (value.bool() != null) {
            return value.bool();
        }
        if (value.m() != null && !value.m().isEmpty()) {
            return convertItem(value.m());
        }
        if (value.l() != null) {
            List<Object> list = value.l().stream().map(ClaimStatusApi::convertValue).toList();
            return list;
        }
        if (value.ss() != null && !value.ss().isEmpty()) {
            return value.ss();
        }
        if (value.ns() != null && !value.ns().isEmpty()) {
            return value.ns();
        }
        return null;
    }
}
