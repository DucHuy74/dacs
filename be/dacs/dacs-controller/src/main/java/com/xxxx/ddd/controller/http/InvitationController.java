package com.xxxx.ddd.controller.http;

import com.xxxx.ddd.application.service.invitation.InvitationAppService;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Slf4j
@RestController
@RequestMapping("/invitations")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class InvitationController {
    InvitationAppService invitationService;

    @GetMapping("/accept")
    public ResponseEntity<String> accept(@RequestParam String token) {
        invitationService.accept(token);
        return ResponseEntity.ok("Invitation accepted successfully");
    }

    @GetMapping("/deny")
    public ResponseEntity<String> deny(@RequestParam String token) {
        invitationService.deny(token);
        return ResponseEntity.ok("Invitation denied");
    }
}