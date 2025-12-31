package com.xxxx.ddd.controller.http;

import com.xxxx.ddd.application.model.dto.response.NotificationResponse;
import com.xxxx.ddd.application.service.notification.NotificationAppService;
import com.xxxx.ddd.application.service.notification.impl.NotificationAppServiceImpl;
import com.xxxx.ddd.common.dto.ApiResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationAppService notificationService;

    @GetMapping("/unread")
    public ApiResponse<List<NotificationResponse>> getUnread() {

        String userId = SecurityContextHolder
                .getContext()
                .getAuthentication()
                .getName();

        return ApiResponse.<List<NotificationResponse>>builder()
                .result(notificationService.getUnread(userId))
                .build();
    }

    @PatchMapping("/{id}/read")
    public ApiResponse<Void> markAsRead(@PathVariable String id) {

        String userId = SecurityContextHolder
                .getContext()
                .getAuthentication()
                .getName();

        notificationService.markAsRead(id, userId);

        return ApiResponse.<Void>builder()
                .message("Marked as read")
                .build();
    }
}
