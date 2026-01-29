package com.xxxx.dddd.domain.service.graph;

import com.xxxx.dddd.domain.model.graph.AnalyzedStory;
import org.springframework.stereotype.Component;

@Component
public class UserStoryAnalyzer {
    public AnalyzedStory analyze(String storyText) {
        String lower = storyText.toLowerCase();

        String actor = detectActor(lower);
        String action = detectAction(lower);
        String object = detectObject(lower, action);

        return new AnalyzedStory(actor, action, object);
    }

    private String detectActor(String text) {
        if (text.contains("as a user")) return "user";
        if (text.contains("as an admin")) return "admin";
        return "unknown";
    }

    private String detectAction(String text) {
        if (text.contains("login") || text.contains("log in")) return "LOGIN";
        if (text.contains("register") || text.contains("sign up")) return "REGISTER";
        if (text.contains("create")) return "CREATE";
        if (text.contains("edit") || text.contains("update")) return "UPDATE";
        if (text.contains("delete") || text.contains("remove")) return "DELETE";
        if (text.contains("search") || text.contains("find")) return "SEARCH";
        return "UNKNOWN";
    }

    private String detectObject(String text, String action) {
        if (text.contains("system")) return "system";
        if (text.contains("note")) return "note";
        if (text.contains("task")) return "task";
        if (text.contains("profile")) return "profile";

        if ("LOGIN".equals(action) || "REGISTER".equals(action)) {
            return "system";
        }
        return "unknown";
    }
}
