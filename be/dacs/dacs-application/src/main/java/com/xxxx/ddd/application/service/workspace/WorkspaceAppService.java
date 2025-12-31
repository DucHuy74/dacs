package com.xxxx.ddd.application.service.workspace;

import com.xxxx.ddd.application.model.dto.request.WorkspaceAddMemberRequest;
import com.xxxx.ddd.application.model.dto.request.WorkspaceCreateRequest;
import com.xxxx.ddd.application.model.dto.request.WorkspaceUpdateRequest;
import com.xxxx.ddd.application.model.dto.response.WorkspaceMemberResponse;
import com.xxxx.ddd.application.model.dto.response.WorkspaceResponse;

import java.util.List;

public interface WorkspaceAppService {
    WorkspaceResponse createWorkspace(WorkspaceCreateRequest request);

    WorkspaceResponse updateWorkspace(
            String workspaceId,
            WorkspaceUpdateRequest request
    );

    void inviteMemberToWorkspace(
            String workspaceId,
            WorkspaceAddMemberRequest request
    );

    List<WorkspaceResponse> getAllWorkspaces();

    List<WorkspaceMemberResponse> getMembers(String workspaceId);

    void deleteWorkspace(String workspaceId);
}
