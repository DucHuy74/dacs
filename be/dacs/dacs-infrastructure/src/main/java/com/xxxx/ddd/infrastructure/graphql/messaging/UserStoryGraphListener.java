package com.xxxx.ddd.infrastructure.graphql.messaging;

import com.xxxx.dddd.domain.event.UserStoryCreatedEvent;
import com.xxxx.dddd.domain.model.graph.AnalyzedStory;
import com.xxxx.dddd.domain.service.graph.UserStoryAnalyzer;
import lombok.RequiredArgsConstructor;
import org.springframework.data.neo4j.core.Neo4jClient;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

import java.util.HashMap;
import java.util.Map;

@Component
@RequiredArgsConstructor
public class UserStoryGraphListener {

    private final UserStoryAnalyzer analyzer;
    private final Neo4jClient neo4jClient;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void handle(UserStoryCreatedEvent event) {

        AnalyzedStory analyzed = analyzer.analyze(event.storyText());

        Map<String, Object> params = new HashMap<>();
        params.put("id", event.id());
        params.put("storyText", event.storyText());
        params.put("actor", analyzed.actor());
        params.put("action", analyzed.action());
        params.put("object", analyzed.object());
        params.put("sprintId", event.sprintId());

        neo4jClient.query("""
    MERGE (us:UserStory {id:$id})
    SET us.storyText = $storyText

    MERGE (actor:Actor {name:$actor})
    MERGE (obj:Object {name:$object})

    MERGE (us)-[:DESCRIBES]->(actor)
    MERGE (us)-[:DESCRIBES]->(obj)

    CREATE (actor)-[:ACTION {
        name:$action,
        storyId:$id
    }]->(obj)

    FOREACH (_ IN CASE WHEN $sprintId IS NULL THEN [1] ELSE [] END |
        MERGE (b:Backlog {id:"DEFAULT"})
        MERGE (us)-[:IN_BACKLOG]->(b)
    )

    FOREACH (_ IN CASE WHEN $sprintId IS NULL THEN [] ELSE [1] END |
        MERGE (s:Sprint {id:$sprintId})
        MERGE (us)-[:IN_SPRINT]->(s)
    )
""")
                .bindAll(params)
                .run();

    }
}
