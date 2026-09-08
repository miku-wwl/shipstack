package com.shipstack.ecs;

import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1")
public class ReleaseController {
    private final String version;

    public ReleaseController(@Value("${APP_VERSION:dev}") String version) {
        this.version = version;
    }

    @GetMapping("/hello")
    public Map<String, String> hello() {
        return Map.of("message", "hello from shipstack ecs", "target", "ecs");
    }

    @GetMapping("/version")
    public Map<String, String> version() {
        return Map.of("service", "ecs-platform-demo", "version", version);
    }
}
