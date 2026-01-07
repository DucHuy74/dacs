package com.xxxx.ddd.application.service.workspace.impl;

import com.xxxx.ddd.application.mapper.WorkspaceMapper;
import com.xxxx.ddd.application.model.dto.request.WorkspaceAddMemberRequest;
import com.xxxx.ddd.application.model.dto.request.WorkspaceCreateRequest;
import com.xxxx.ddd.application.model.dto.request.WorkspaceUpdateRequest;
import com.xxxx.ddd.application.model.dto.response.WorkspaceMemberResponse;
import com.xxxx.ddd.application.model.dto.response.WorkspaceResponse;
import com.xxxx.ddd.application.port.async.InvitationAsyncPort;
import com.xxxx.ddd.application.service.profile.ProfileAppService;
import com.xxxx.ddd.application.service.workspace.WorkspaceAppService;
import com.xxxx.ddd.common.exception.ErrorCode;
import com.xxxx.dddd.domain.exception.AppException;
import com.xxxx.dddd.domain.model.entity.Backlog;
import com.xxxx.dddd.domain.model.entity.Profile;
import com.xxxx.dddd.domain.model.entity.workspace.Workspace;
import com.xxxx.dddd.domain.model.entity.workspace.WorkspaceInvitation;
import com.xxxx.dddd.domain.model.entity.workspace.WorkspaceMember;
import com.xxxx.dddd.domain.model.entity.workspace.WorkspaceRole;
import com.xxxx.dddd.domain.model.enums.InvitationStatus;
import com.xxxx.dddd.domain.model.enums.WorkspaceRoleType;
import com.xxxx.dddd.domain.repository.*;
import jakarta.transaction.Transactional;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Service
@Slf4j
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class WorkspaceAppServiceImpl implements WorkspaceAppService {
    WorkspaceRepository workspaceRepository;
    WorkspaceRoleRepository workspaceRoleRepository;
    WorkspaceMemberRepository workspaceMemberRepository;
    InvitationRepository invitationRepository;
    ProfileRepository profileRepository;
    WorkspaceMapper workspaceMapper;

    InvitationAsyncPort invitationAsyncPort;
    ProfileAppService profileAppService;

    @Transactional
    public WorkspaceResponse createWorkspace(WorkspaceCreateRequest request) {

        Profile profile = profileAppService.getOrCreateCurrentProfile();

        Workspace workspace = Workspace.builder()
                .name(request.getName())
                .type(request.getType())
                .access(request.getAccess())
                .build();

        Backlog backlog = Backlog.builder()
                .name("Backlog")
                .workspace(workspace)
                .build();

        workspace.setBacklog(backlog);
        workspaceRepository.saveAndFlush(workspace);

        WorkspaceRole adminRole = workspaceRoleRepository.save(
                WorkspaceRole.builder()
                        .workspace(workspace)
                        .roleName(WorkspaceRoleType.ADMIN)
                        .build()
        );

        workspaceMemberRepository.save(
                WorkspaceMember.builder()
                        .workspace(workspace)
                        .profile(profile)
                        .workspaceRole(adminRole)
                        .build()
        );

        return workspaceMapper.toWorkspaceResponse(workspace);
    }

    @Transactional
    public WorkspaceResponse updateWorkspace(
            String workspaceId,
            WorkspaceUpdateRequest request) {

        Profile profile = profileAppService.getOrCreateCurrentProfile();

        Workspace workspace = workspaceRepository.findById(workspaceId)
                .orElseThrow(() -> new AppException(ErrorCode.WORKSPACE_NOT_FOUND));

        WorkspaceMember member =
                workspaceMemberRepository
                        .findByWorkspaceIdAndUserId(
                                workspaceId,
                                profile.getUserId()
                        )
                        .orElseThrow(() -> new AppException(ErrorCode.NO_PERMISSION));

        if (member.getWorkspaceRole().getRoleName() != WorkspaceRoleType.ADMIN) {
            throw new AppException(ErrorCode.NO_PERMISSION);
        }

        workspaceMapper.updateWorkspace(workspace, request);

        return workspaceMapper.toWorkspaceResponse(workspace);
    }


    @Transactional
    public void inviteMemberToWorkspace(
            String workspaceId,
            WorkspaceAddMemberRequest request) {

        Profile inviter = profileAppService.getOrCreateCurrentProfile();

        WorkspaceMember admin =
                workspaceMemberRepository
                        .findByWorkspaceIdAndUserId(
                                workspaceId,
                                inviter.getUserId()
                        )
                        .orElseThrow(() -> new AppException(ErrorCode.NO_PERMISSION));

        if (admin.getWorkspaceRole().getRoleName() != WorkspaceRoleType.ADMIN) {
            throw new AppException(ErrorCode.NO_PERMISSION);
        }

        if (invitationRepository.existsByWorkspaceIdAndEmailAndStatus(
                workspaceId,
                request.getEmail(),
                InvitationStatus.PENDING)) {
            throw new AppException(ErrorCode.INVITATION_ALREADY_SENT);
        }

        WorkspaceInvitation invitation = invitationRepository.save(
                WorkspaceInvitation.builder()
                        .workspaceId(workspaceId)
                        .email(request.getEmail())
                        .inviterId(inviter.getUserId())
                        .status(InvitationStatus.PENDING)
                        .expiredAt(Instant.now().plus(3, ChronoUnit.DAYS))
                        .build()
        );

        TransactionSynchronizationManager.registerSynchronization(
                new TransactionSynchronization() {
                    @Override
                    public void afterCommit() {
                        invitationAsyncPort.sendInviteEmail(
                                request.getEmail(),
                                admin.getWorkspace().getName(),
                                inviter.getFirstName() + " " + inviter.getLastName(),
                                invitation.getId()
                        );
                    }
                }
        );
    }


    public List<WorkspaceResponse> getAllWorkspaces() {

        Profile profile = profileAppService.getOrCreateCurrentProfile();

        return workspaceMemberRepository
                .findAllByUserId(profile.getProfileId())
                .stream()
                .map(member -> {
                    Workspace workspace = member.getWorkspace();
                    WorkspaceResponse res =
                            workspaceMapper.toWorkspaceResponse(workspace);

                    res.setRoles(
                            List.of(member.getWorkspaceRole().getRoleName().name())
                    );

                    res.setOwnerId(
                            workspace.getMembers().stream()
                                    .filter(m ->
                                            m.getWorkspaceRole().getRoleName()
                                                    == WorkspaceRoleType.ADMIN
                                    )
                                    .map(m -> m.getProfile().getUserId())
                                    .findFirst()
                                    .orElse(null)
                    );

                    return res;
                })
                .toList();
    }


    @Transactional
    public void deleteWorkspace(String workspaceId) {

        Profile profile = profileAppService.getOrCreateCurrentProfile();

        WorkspaceMember admin =
                workspaceMemberRepository
                        .findByWorkspaceIdAndUserId(
                                workspaceId,
                                profile.getUserId()
                        )
                        .orElseThrow(() -> new AppException(ErrorCode.NO_PERMISSION));

        if (admin.getWorkspaceRole().getRoleName() != WorkspaceRoleType.ADMIN) {
            throw new AppException(ErrorCode.NO_PERMISSION);
        }

        workspaceRepository.delete(admin.getWorkspace());
    }


    public List<WorkspaceMemberResponse> getMembers(String workspaceId) {

        Profile profile = profileAppService.getOrCreateCurrentProfile();

        workspaceMemberRepository
                .findByWorkspaceIdAndUserId(
                        workspaceId,
                        profile.getUserId()
                )
                .orElseThrow(() -> new AppException(ErrorCode.NO_PERMISSION));

        return workspaceMemberRepository
                .findAllByWorkspaceId(workspaceId)
                .stream()
                .map(m -> WorkspaceMemberResponse.builder()
                        .userId(m.getProfile().getUserId())
                        .email(m.getProfile().getEmail())
                        .role(m.getWorkspaceRole().getRoleName())
                        .build())
                .toList();
    }

}
