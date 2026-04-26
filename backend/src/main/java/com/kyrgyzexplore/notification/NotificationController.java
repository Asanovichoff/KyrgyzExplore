package com.kyrgyzexplore.notification;

import com.kyrgyzexplore.common.dto.ApiResponse;
import com.kyrgyzexplore.notification.dto.NotificationResponse;
import com.kyrgyzexplore.user.User;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    @GetMapping("/my")
    public ApiResponse<Page<NotificationResponse>> getMyNotifications(
            @AuthenticationPrincipal User currentUser,
            @PageableDefault(size = 20) Pageable pageable) {
        return ApiResponse.ok(notificationService.getMyNotifications(currentUser.getId(), pageable));
    }

    @GetMapping("/my/unread-count")
    public ApiResponse<Integer> getUnreadCount(@AuthenticationPrincipal User currentUser) {
        return ApiResponse.ok(notificationService.getUnreadCount(currentUser.getId()));
    }

    @PostMapping("/{id}/read")
    public ApiResponse<Void> markOneAsRead(
            @PathVariable UUID id,
            @AuthenticationPrincipal User currentUser) {
        notificationService.markOneAsRead(id, currentUser.getId());
        return ApiResponse.ok(null);
    }

    @PostMapping("/read-all")
    public ApiResponse<Integer> markAllAsRead(@AuthenticationPrincipal User currentUser) {
        int updated = notificationService.markAllAsRead(currentUser.getId());
        return ApiResponse.ok(updated);
    }
}
