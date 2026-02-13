package com.xxxx.ddd.infrastructure.graphql.messaging;

import com.xxxx.dddd.domain.event.UserStoryCreatedEvent;
import com.xxxx.dddd.domain.model.graph.AnalyzedStory;
import com.xxxx.dddd.domain.service.graph.UserStoryAnalyzer;
import lombok.RequiredArgsConstructor;
import org.springframework.data.neo4j.core.Neo4jClient;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class GraphProcessingService {

    private final UserStoryAnalyzer analyzer;
    private final Neo4jClient neo4jClient;

    public void process(UserStoryCreatedEvent event) {

        AnalyzedStory analyzed = analyzer.analyze(event.storyText());

        Map<String, Object> params = new HashMap<>();

        params.put("id", event.id());
        params.put("storyText", event.storyText());
        params.put("actor", analyzed.actor());
        params.put("action", analyzed.action());
        params.put("object", analyzed.object());
        params.put("backlogId", event.backlogId());
        params.put("workspaceId", event.workspaceId());
        params.put("sprintId", event.sprintId());

        neo4jClient.query("""
MERGE (ws:Workspace {id:$workspaceId})

MERGE (b:Backlog {id:$backlogId})
MERGE (ws)-[:HAS_BACKLOG]->(b)

MERGE (us:UserStory {id:$id})
SET us.storyText = $storyText

MERGE (b)-[:CONTAINS]->(us)

MERGE (actor:Actor {name:$actor})
MERGE (obj:Object {name:$object})

MERGE (us)-[:DESCRIBES]->(actor)
MERGE (us)-[:DESCRIBES]->(obj)

MERGE (actor)-[:ACTION {name:$action}]->(obj)

FOREACH (_ IN CASE WHEN $sprintId IS NULL THEN [] ELSE [1] END |
    MERGE (s:Sprint {id:$sprintId})
    MERGE (us)-[:IN_SPRINT]->(s)
)
""")
                .bindAll(params)
                .run();
    }
}
