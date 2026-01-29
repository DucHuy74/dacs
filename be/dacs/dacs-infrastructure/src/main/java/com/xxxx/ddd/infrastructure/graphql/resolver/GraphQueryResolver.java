package com.xxxx.ddd.infrastructure.graphql.resolver;

import com.xxxx.ddd.application.model.dto.graph.GraphEdgeDTO;
import com.xxxx.ddd.application.model.dto.graph.GraphNodeDTO;
import com.xxxx.ddd.application.model.dto.graph.GraphResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.data.neo4j.core.Neo4jClient;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.stereotype.Controller;

import java.util.ArrayList;
import java.util.List;

@Controller
@RequiredArgsConstructor
public class GraphQueryResolver {

    private final Neo4jClient neo4jClient;

    @QueryMapping
    public GraphResponse sprintGraph(@Argument String sprintId) {

        List<GraphNodeDTO> nodes =
                new ArrayList<>(
                        neo4jClient.query("""
                    MATCH (us:UserStory)-[:IN_SPRINT]->(s:Sprint {id:$sprintId})
                    OPTIONAL MATCH (us)-[*0..2]-(n)
                    RETURN DISTINCT
                         coalesce(n.id, n.name) AS id,
                         labels(n)[0] AS label,
                         labels(n)[0] AS type
                """)
                                .bind(sprintId).to("sprintId")
                                .fetchAs(GraphNodeDTO.class)
                                .mappedBy((ts, rec) -> new GraphNodeDTO(
                                        rec.get("id").asString(),
                                        rec.get("label").asString(),
                                        rec.get("type").asString()
                                ))
                                .all()
                );




        List<GraphEdgeDTO> edges =
                new ArrayList<>(
                        neo4jClient.query("""
                    MATCH (us:UserStory)-[:IN_SPRINT]->(s:Sprint {id:$sprintId})
                    MATCH (us)-[r]-(n)
                    RETURN
                          coalesce(us.id, us.name) AS from,
                          coalesce(n.id, n.name) AS to,
                          type(r) AS type
                """)
                                .bind(sprintId).to("sprintId")
                                .fetchAs(GraphEdgeDTO.class)
                                .mappedBy((ts, rec) -> new GraphEdgeDTO(
                                        rec.get("from").asString(),
                                        rec.get("to").asString(),
                                        rec.get("type").asString()
                                ))
                                .all()
                );

        return new GraphResponse(nodes, edges);
    }

}
