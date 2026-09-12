package com.shipstack.lambda;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.function.Supplier;

/**
 * Minimal Java Lambda handler used to prove which release is running.
 */
public final class ReleaseHandler implements RequestHandler<Map<String, Object>, Map<String, Object>> {
    private final Supplier<String> releaseSupplier;

    public ReleaseHandler() {
        this(() -> System.getenv("APP_VERSION"));
    }

    ReleaseHandler(Supplier<String> releaseSupplier) {
        this.releaseSupplier = releaseSupplier;
    }

    @Override
    public Map<String, Object> handleRequest(Map<String, Object> input, Context context) {
        String release = releaseSupplier.get();
        if (release == null || release.isBlank()) {
            release = "unknown";
        }

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("service", "shipstack");
        response.put("target", "lambda");
        response.put("release", release);
        return response;
    }
}
