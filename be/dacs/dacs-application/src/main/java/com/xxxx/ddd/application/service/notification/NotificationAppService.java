package com.xxxx.ddd.application.service.notification;

import com.xxxx.ddd.application.model.dto.response.NotificationResponse;
import com.xxxx.dddd.domain.model.enums.NotificationType;

import java.util.List;

public interface NotificationAppService {
    void notifyUser(
            String userId,
            String title,
            String content,
            NotificationType type,
            String refId
    );

    List<NotificationResponse> getUnread(String userId);
    void markAsRead(String notificationId, String userId);
}
