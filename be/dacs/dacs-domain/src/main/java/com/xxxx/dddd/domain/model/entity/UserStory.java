package com.xxxx.dddd.domain.model.entity;

import com.xxxx.dddd.domain.model.enums.UserStoryStatus;
import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "user_story")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class UserStory {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "us_id")
    String id;

    @Column(name = "us_story_text", length = 255, nullable = false)
    String storyText;

    @Enumerated(EnumType.STRING)
    @Column(name = "us_status", nullable = false)
    UserStoryStatus status;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "spr_id")
    Sprint sprint;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "blg_id")
    Backlog backlog;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    LocalDateTime updatedAt;
}
