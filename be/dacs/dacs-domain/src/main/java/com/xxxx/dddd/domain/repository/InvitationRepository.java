package com.xxxx.dddd.domain.repository;

import com.xxxx.dddd.domain.model.entity.Notification;
import com.xxxx.dddd.domain.model.entity.workspace.WorkspaceInvitation;
import com.xxxx.dddd.domain.model.enums.InvitationStatus;

import java.util.Optional;

public interface InvitationRepository {
    boolean existsByWorkspaceIdAndEmailAndStatus(
            String workspaceId,
            String email,
            InvitationStatus status
    );

    WorkspaceInvitation save(WorkspaceInvitation invitation);

    Optional<WorkspaceInvitation> findById(String id);
}
