package com.shipstack.batch;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class BatchApplicationTest {
    @Test
    void returnsTheExpectedReleaseIdentity() {
        var response = BatchApplication.releaseResponse("build-123");

        assertEquals("shipstack", response.get("service"));
        assertEquals("batch", response.get("target"));
        assertEquals("build-123", response.get("release"));
    }

    @Test
    void usesUnknownWhenReleaseIsMissing() {
        assertEquals("unknown", BatchApplication.releaseResponse(null).get("release"));
    }
}
