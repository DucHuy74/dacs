package com.xxxx.ddd.application.service.invitation;

public interface InvitationAppService {
    String accept(String token);

    void deny(String token);
}
