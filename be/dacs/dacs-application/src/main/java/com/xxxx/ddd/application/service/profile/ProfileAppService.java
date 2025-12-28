package com.xxxx.ddd.application.service.profile;

import com.xxxx.ddd.application.model.dto.request.RegistrationRequest;
import com.xxxx.ddd.application.model.dto.response.ProfileResponse;

import java.util.List;

public interface ProfileAppService {
    List<ProfileResponse> getAllProfiles();

    ProfileResponse getMyProfile();

    ProfileResponse register(RegistrationRequest request);
}
