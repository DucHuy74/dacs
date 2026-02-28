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

/*
* sprintId = null, backlogId != null
* FOREACH (_ IN CASE WHEN $backlogId IS NULL THEN [] ELSE [1] END |
    MERGE (b:Backlog {id:$backlogId})
    MERGE (ws)-[:HAS_BACKLOG]->(b)
    MERGE (b)-[:CONTAINS]->(us)
)
* -> tạo graph ở backlog
*
* sprintId != null, backlogId = null
* FOREACH (_ IN CASE WHEN $sprintId IS NULL THEN [] ELSE [1] END |
    MATCH (oldB:Backlog)-[r:CONTAINS]->(us)
    DELETE r
)
* xóa relation cũ của user story đó trong backlog
*
* FOREACH (_ IN CASE WHEN $sprintId IS NULL THEN [] ELSE [1] END |
    MERGE (s:Sprint {id:$sprintId})
    MERGE (us)-[:IN_SPRINT]->(s)
)
* tạo relation mới với sprint
* */
        neo4jClient.query("""
                        MERGE (ws:Workspace {id:$workspaceId})
                        
                                                    MERGE (us:UserStory {id:$id})
                                                    SET us.storyText = $storyText
                        
                                                    // ===== BACKLOG =====
                                                    FOREACH (_ IN CASE WHEN $backlogId IS NOT NULL THEN [1] ELSE [] END |
                                                        MERGE (b:Backlog {id:$backlogId})
                                                        MERGE (ws)-[:HAS_BACKLOG]->(b)
                                                        MERGE (b)-[:CONTAINS]->(us)
                                                    )
                        
                                                    // ===== REMOVE OLD BACKLOG RELATION IF MOVED TO SPRINT =====
                                                    WITH us
                                                    OPTIONAL MATCH (oldB:Backlog)-[r:CONTAINS]->(us)
                                                    WHERE $sprintId IS NOT NULL
                                                    DELETE r
                        
                                                    // ===== SPRINT =====
                                                    FOREACH (_ IN CASE WHEN $sprintId IS NOT NULL THEN [1] ELSE [] END |
                                                        MERGE (s:Sprint {id:$sprintId})
                                                        MERGE (us)-[:IN_SPRINT]->(s)
                                                    )
                        
                                                    // ===== NLP =====
                                                    MERGE (actor:Actor {name:$actor})
                                                    MERGE (action:Action {name:$action})
                                                    MERGE (obj:Object {name:$object})
                        
                                                    MERGE (us)-[:HAS_ACTOR]->(actor)
                                                    MERGE (us)-[:PERFORMS]->(action)
                                                    MERGE (us)-[:TARGETS]->(obj)
""")
                .bindAll(params)
                .run();
    }
}
