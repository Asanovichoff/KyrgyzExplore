package com.kyrgyzexplore.message.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class SendMessageRequest {

    @NotBlank(message = "Message content must not be blank")
    @Size(max = 2000, message = "Message must not exceed 2000 characters")
    private String content;
}
