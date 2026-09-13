package com.shipstack.eks;

import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ReleaseController {
    private final String release;

    public ReleaseController(@Value("${APP_VERSION:dev}") String release) {
        this.release = release;
    }

    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of("status", "UP");
    }

    @GetMapping("/release")
    public Map<String, String> release() {
        return Map.of(
                "service", "shipstack",
                "target", "eks",
                "release", release);
    }
}
