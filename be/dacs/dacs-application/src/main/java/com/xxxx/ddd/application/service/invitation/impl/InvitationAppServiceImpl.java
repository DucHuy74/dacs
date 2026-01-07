package com.xxxx.ddd.application.service.invitation.impl;

import com.xxxx.ddd.application.service.invitation.InvitationAppService;
import com.xxxx.ddd.application.service.notification.NotificationAppService;
import com.xxxx.ddd.common.exception.ErrorCode;
import com.xxxx.dddd.domain.exception.AppException;
import com.xxxx.dddd.domain.model.entity.Profile;
import com.xxxx.dddd.domain.model.entity.workspace.Workspace;
import com.xxxx.dddd.domain.model.entity.workspace.WorkspaceInvitation;
import com.xxxx.dddd.domain.model.entity.workspace.WorkspaceMember;
import com.xxxx.dddd.domain.model.entity.workspace.WorkspaceRole;
import com.xxxx.dddd.domain.model.enums.InvitationStatus;
import com.xxxx.dddd.domain.model.enums.NotificationType;
import com.xxxx.dddd.domain.model.enums.WorkspaceRoleType;
import com.xxxx.dddd.domain.repository.*;
import jakarta.transaction.Transactional;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;

@Service
@Slf4j
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class InvitationAppServiceImpl implements InvitationAppService {

    InvitationRepository invitationRepository;
    WorkspaceRepository workspaceRepository;
    WorkspaceMemberRepository workspaceMemberRepository;
    WorkspaceRoleRepository workspaceRoleRepository;
    ProfileRepository profileRepository;

    NotificationAppService notificationAppService;

    @Transactional
    public String accept(String token) {

        WorkspaceInvitation invitation = invitationRepository.findById(token)
                .orElseThrow(() -> new AppException(ErrorCode.INVALID_INVITE));

        if (invitation.getStatus() != InvitationStatus.PENDING)
            throw new AppException(ErrorCode.INVITE_USED);

        if (invitation.getExpiredAt().isBefore(Instant.now()))
            throw new AppException(ErrorCode.INVITE_EXPIRED);

        Profile profile = profileRepository
                .findByEmail(invitation.getEmail())
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_EXISTED));


        //Email trong invite phải trùng email user login
        if (!profile.getEmail().equalsIgnoreCase(invitation.getEmail())) {
            throw new AppException(ErrorCode.NO_PERMISSION);
        }

        Workspace workspace = workspaceRepository
                .findById(invitation.getWorkspaceId())
                .orElseThrow(() -> new AppException(ErrorCode.WORKSPACE_NOT_FOUND));

        if (workspaceMemberRepository
                .findByWorkspaceIdAndUserId(
                        workspace.getId(),
                        profile.getUserId())
                .isPresent()) {
            throw new AppException(ErrorCode.MEMBER_EXISTED);
        }

        WorkspaceRole memberRole = workspaceRoleRepository
                .findByWorkspaceAndRoleName(workspace, WorkspaceRoleType.MEMBER)
                .orElseGet(() -> workspaceRoleRepository.save(
                        WorkspaceRole.builder()
                                .workspace(workspace)
                                .roleName(WorkspaceRoleType.MEMBER)
                                .build()
                ));

        workspaceMemberRepository.save(
                WorkspaceMember.builder()
                        .workspace(workspace)
                        .profile(profile)
                        .workspaceRole(memberRole)
                        .build()
        );

        invitation.setStatus(InvitationStatus.ACCEPTED);
        invitationRepository.save(invitation);

        notificationAppService.notifyUser(
                invitation.getInviterId(),
                "Invitation accepted",
                profile.getEmail() + " accepted your invitation",
                NotificationType.INVITATION_ACCEPTED,
                workspace.getId()
        );

        return workspace.getId();
    }

    @Transactional
    public void deny(String token) {

        WorkspaceInvitation invitation = invitationRepository.findById(token)
                .orElseThrow(() -> new AppException(ErrorCode.INVALID_INVITE));

        if (invitation.getStatus() != InvitationStatus.PENDING)
            throw new AppException(ErrorCode.INVITE_USED);

        Profile profile = profileRepository
                .findByEmail(invitation.getEmail())
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_EXISTED));


        if (!profile.getEmail().equalsIgnoreCase(invitation.getEmail())) {
            throw new AppException(ErrorCode.NO_PERMISSION);
        }

        invitation.setStatus(InvitationStatus.REJECTED);
        invitationRepository.save(invitation);

        notificationAppService.notifyUser(
                invitation.getInviterId(),
                "Invitation denied",
                profile.getEmail() + " denied your invitation",
                NotificationType.INVITATION_DENIED,
                invitation.getWorkspaceId()
        );
    }
}
