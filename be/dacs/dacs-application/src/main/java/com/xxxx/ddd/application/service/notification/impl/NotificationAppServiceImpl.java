package com.xxxx.ddd.application.service.notification.impl;

import com.xxxx.ddd.application.model.dto.response.NotificationResponse;
import com.xxxx.ddd.application.port.async.RealtimeNotificationPort;
import com.xxxx.ddd.application.service.notification.NotificationAppService;
import com.xxxx.dddd.domain.model.entity.Notification;
import com.xxxx.dddd.domain.model.enums.NotificationType;
import com.xxxx.dddd.domain.repository.NotificationRepository;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;

@Service
@Slf4j
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class NotificationAppServiceImpl implements NotificationAppService {

    NotificationRepository notificationRepository;
    RealtimeNotificationPort realtimeNotificationPort;

    public void notifyUser(
            String userId,
            String title,
            String content,
            NotificationType type,
            String refId
    ) {
        Notification notification = notificationRepository.save(
                Notification.builder()
                        .userId(userId)
                        .title(title)
                        .content(content)
                        .type(type)
                        .referenceId(refId)
                        .read(false)
                        .createdAt(Instant.now())
                        .build()
        );

        // Nếu user online → gửi realtime
        if (realtimeNotificationPort.isOnline(userId)) {
            realtimeNotificationPort.send(userId, notification);
        }
    }

    public List<NotificationResponse> getUnread(String userId) {
        return notificationRepository
                .findByUserIdAndReadFalseOrderByCreatedAtDesc(userId)
                .stream()
                .map(n -> NotificationResponse.builder()
                        .id(n.getId())
                        .title(n.getTitle())
                        .content(n.getContent())
                        .type(n.getType())
                        .referenceId(n.getReferenceId())
                        .createdAt(n.getCreatedAt())
                        .read(n.isRead())
                        .build()
                )
                .toList();
    }


    public void markAsRead(String notificationId, String userId) {
        Notification noti = notificationRepository.findById(notificationId)
                .orElseThrow();

        if (!noti.getUserId().equals(userId)) {
            throw new RuntimeException("No permission");
        }

        noti.setRead(true);
        notificationRepository.save(noti);
    }
}
