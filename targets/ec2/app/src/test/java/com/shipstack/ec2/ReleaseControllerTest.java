package com.shipstack.ec2;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(ReleaseController.class)
class ReleaseControllerTest {
    @Autowired
    private MockMvc mockMvc;

    @Test
    void healthEndpointReportsHealthy() throws Exception {
        mockMvc.perform(get("/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UP"));
    }

    @Test
    void releaseEndpointExposesEc2ReleaseIdentity() throws Exception {
        mockMvc.perform(get("/release"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.service").value("shipstack"))
                .andExpect(jsonPath("$.target").value("ec2"))
                .andExpect(jsonPath("$.release").value("dev"));
    }
}
