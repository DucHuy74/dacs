package com.xxxx.ddd.infrastructure.persistence.mapper;

import com.xxxx.dddd.domain.model.entity.workspace.WorkspaceInvitation;
import com.xxxx.dddd.domain.model.enums.InvitationStatus;
import org.springframework.data.jpa.repository.JpaRepository;

public interface InvitationJpaMapper extends JpaRepository<WorkspaceInvitation, String> {
    boolean existsByWorkspaceIdAndEmailAndStatus(
            String workspaceId,
            String email,
            InvitationStatus status
    );
}
