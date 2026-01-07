package com.xxxx.dddd.domain.repository;

import com.xxxx.dddd.domain.model.entity.workspace.WorkspaceMember;

import java.util.List;
import java.util.Optional;


public interface WorkspaceMemberRepository {
    Optional<WorkspaceMember> findByWorkspaceIdAndUserId(
            String workspaceId,
            String userId
    );

    List<WorkspaceMember> findAllByUserId(String userId);

    List<WorkspaceMember> findAllByWorkspaceId(String workspaceId);

    WorkspaceMember save(WorkspaceMember workspaceMember);
}
