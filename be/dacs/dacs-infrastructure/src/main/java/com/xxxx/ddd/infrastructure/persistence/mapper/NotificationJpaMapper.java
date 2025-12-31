package com.xxxx.ddd.infrastructure.persistence.mapper;

import com.xxxx.dddd.domain.model.entity.Notification;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface NotificationJpaMapper extends JpaRepository<Notification, String> {
    List<Notification> findByUserIdAndReadFalseOrderByCreatedAtDesc(String userId);
}
