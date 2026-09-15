package com.shipstack.batch;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 最小的一次性 Batch Job。它把当前发布身份写到标准输出，供流水线从
 * CloudWatch Logs 读取并校验实际运行的 Job。
 */
public final class BatchApplication {
    private BatchApplication() {
    }

    public static void main(String[] args) {
        System.out.println(toJson(releaseResponse(System.getenv("APP_VERSION"))));
    }

    static Map<String, String> releaseResponse(String release) {
        Map<String, String> response = new LinkedHashMap<>();
        response.put("service", "shipstack");
        response.put("target", "batch");
        response.put("release", release == null || release.isBlank() ? "unknown" : release);
        return response;
    }

    private static String toJson(Map<String, String> response) {
        return "{\"service\":\"" + escape(response.get("service"))
                + "\",\"target\":\"" + escape(response.get("target"))
                + "\",\"release\":\"" + escape(response.get("release")) + "\"}";
    }

    private static String escape(String value) {
        return value.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
