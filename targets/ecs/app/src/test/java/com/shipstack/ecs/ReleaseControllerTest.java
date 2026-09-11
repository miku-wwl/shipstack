package com.shipstack.ecs;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(value = ReleaseController.class, properties = "APP_VERSION=test-build")
class ReleaseControllerTest {
    @Autowired
    private MockMvc mockMvc;

    @Test
    void versionEndpointExposesReleaseIdentity() throws Exception {
        mockMvc.perform(get("/api/v1/version"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.service").value("ecs-platform-demo"))
                .andExpect(jsonPath("$.version").value("test-build"));
    }
}
