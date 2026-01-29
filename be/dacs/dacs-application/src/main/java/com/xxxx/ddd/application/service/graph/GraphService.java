package com.xxxx.ddd.application.service.graph;

import com.xxxx.ddd.application.model.dto.graph.GraphResponse;

public interface GraphService {
    GraphResponse getSprintGraph(String sprintId);
}