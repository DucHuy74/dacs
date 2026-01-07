package com.xxxx.ddd.application.service.userstory.impl;

import com.xxxx.ddd.application.mapper.UserStoryMapper;
import com.xxxx.ddd.application.model.dto.request.UserStoryCreateRequest;
import com.xxxx.ddd.application.model.dto.request.UserStoryStatusUpdateRequest;
import com.xxxx.ddd.application.model.dto.response.UserStoryResponse;
import com.xxxx.ddd.application.service.userstory.UserStoryAppService;
import com.xxxx.ddd.common.exception.ErrorCode;
import com.xxxx.dddd.domain.exception.AppException;
import com.xxxx.dddd.domain.model.entity.UserStory;
import com.xxxx.dddd.domain.model.entity.workspace.Workspace;
import com.xxxx.dddd.domain.model.enums.UserStoryStatus;
import com.xxxx.dddd.domain.repository.UserStoryRepository;
import com.xxxx.dddd.domain.repository.WorkspaceRepository;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Slf4j
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class UserStoryAppServiceImpl implements UserStoryAppService {
    UserStoryRepository userStoryRepository;
    WorkspaceRepository workspaceRepository;
    UserStoryMapper userStoryMapper;

    @Override
    public UserStoryResponse create(String workspaceId, UserStoryCreateRequest request) {

        Workspace workspace = workspaceRepository.findById(workspaceId)
                .orElseThrow(() -> new AppException(ErrorCode.WORKSPACE_NOT_FOUND));

        UserStory story = userStoryMapper.toEntity(request);
        story.setWorkspace(workspace);
        story.setStatus(UserStoryStatus.ToDo); // backlog
        story.setSprint(null);

        return userStoryMapper.toResponse(
                userStoryRepository.save(story)
        );
    }

    @Override
    @Transactional(readOnly = true)
    public List<UserStoryResponse> getBacklog(String workspaceId) {

        return userStoryMapper.toResponses(
                userStoryRepository.findByWorkspace_IdAndSprintIsNull(workspaceId)
        );
    }

    @Override
    @Transactional(readOnly = true)
    public List<UserStoryResponse> getBySprint(String sprintId) {

        return userStoryMapper.toResponses(
                userStoryRepository.findBySprint_Id(sprintId)
        );
    }

    @Override
    public UserStoryResponse updateStatus(
            String userStoryId,
            UserStoryStatusUpdateRequest request
    ) {

        UserStory story = userStoryRepository.findById(userStoryId)
                .orElseThrow(() -> new AppException(ErrorCode.USER_STORY_NOT_FOUND));

        story.setStatus(request.getStatus());

        return userStoryMapper.toResponse(story);
    }

    @Override
    public void delete(String userStoryId) {

        userStoryRepository.findById(userStoryId)
                .orElseThrow(() -> new AppException(ErrorCode.USER_STORY_NOT_FOUND));

        userStoryRepository.delete(userStoryId);
    }
}
