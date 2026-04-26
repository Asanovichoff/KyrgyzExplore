package com.kyrgyzexplore.message;

import com.kyrgyzexplore.common.dto.ApiResponse;
import com.kyrgyzexplore.message.dto.MessageResponse;
import com.kyrgyzexplore.user.User;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/messages")
@RequiredArgsConstructor
public class MessageController {

    private final MessageService messageService;

    /** Fetch message history for a booking (traveler or host only). */
    @GetMapping("/{bookingId}")
    public ApiResponse<Page<MessageResponse>> getHistory(
            @PathVariable UUID bookingId,
            @AuthenticationPrincipal User currentUser,
            @PageableDefault(size = 50) Pageable pageable) {
        return ApiResponse.ok(messageService.getHistory(bookingId, currentUser.getId(), pageable));
    }

    /** Mark all messages in this conversation as read (from the caller's perspective). */
    @PostMapping("/{bookingId}/read")
    public ApiResponse<Integer> markAsRead(
            @PathVariable UUID bookingId,
            @AuthenticationPrincipal User currentUser) {
        int updated = messageService.markConversationAsRead(bookingId, currentUser.getId());
        return ApiResponse.ok(updated);
    }
}
