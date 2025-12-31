package com.xxxx.dddd.domain.repository;

import com.xxxx.dddd.domain.model.entity.Notification;
import com.xxxx.dddd.domain.model.entity.workspace.Workspace;

import java.util.List;
import java.util.Optional;

public interface NotificationRepository {
    List<Notification> findByUserIdAndReadFalseOrderByCreatedAtDesc(String userId);
    Notification save(Notification notification);

    Optional<Notification> findById(String notificationId);
}
