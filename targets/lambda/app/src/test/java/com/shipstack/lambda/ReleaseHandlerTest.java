package com.shipstack.lambda;

import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;

class ReleaseHandlerTest {
    @Test
    void responseIdentifiesTheLambdaRelease() {
        ReleaseHandler handler = new ReleaseHandler(() -> "test-build");

        Map<String, Object> response = handler.handleRequest(Map.of(), null);

        assertEquals("shipstack", response.get("service"));
        assertEquals("lambda", response.get("target"));
        assertEquals("test-build", response.get("release"));
    }

    @Test
    void missingReleaseUsesAnExplicitFallback() {
        ReleaseHandler handler = new ReleaseHandler(() -> null);

        Map<String, Object> response = handler.handleRequest(Map.of(), null);

        assertEquals("unknown", response.get("release"));
    }
}
