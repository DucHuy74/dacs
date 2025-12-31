package com.xxxx.ddd.infrastructure.persistence.mapper;

import com.xxxx.dddd.domain.model.entity.workspace.WorkspaceMember;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface WorkspaceMemberJpaMapper extends JpaRepository<WorkspaceMember, String> {
    Optional<WorkspaceMember>
    findByWorkspace_IdAndProfile_ProfileId(String workspaceId, String profileId);


    List<WorkspaceMember> findAllByProfile_ProfileId(String userId);

    List<WorkspaceMember> findAllByWorkspace_Id(String workspaceId);
}
