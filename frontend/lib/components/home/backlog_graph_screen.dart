// lib/components/home/backlog_graph_screen.dart
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/backlog/graph_model.dart';
import '../../viewmodels/backlog/graph_view_model.dart';

// =============================================================================
// THEME CONSTANTS
// =============================================================================
const kBgColor = Color(0xFF0D1117);
const kSubjectFill = Color(0xFF161B22);
const kSubjectBorder = Color(0xFF58A6FF);
const kVerbFill = Color(0xFF1A1040);
const kVerbBorder = Color(0xFF7C3AED);
const kVerbGlow = Color(0xFF7C3AED);
const kObjectFill = Color(0xFF0D1117);
const kObjectBorder = Color(0xFF22D3EE);
const kLineColor = Color(0x556E7FBF);
const kHighlightLine = Color(0xFF818CF8);
const kTextPrimary = Color(0xFFE6EDF3);
const kTextSecondary = Color(0xFF8B949E);

const kDoneColor = Color(0xFF238636);
const kInProgressColor = Color(0xFFD29922);

// =============================================================================
// CLASS WRAPPER: BỌC PROVIDER
// =============================================================================
class BacklogGraphScreen extends StatelessWidget {
  final String backlogId;
  final String backlogName;

  const BacklogGraphScreen({
    Key? key,
    required this.backlogId,
    required this.backlogName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GraphViewModel(),
      child: _BacklogGraphScreenContent(
        backlogId: backlogId,
        backlogName: backlogName,
      ),
    );
  }
}

// =============================================================================
// CLASS VIEW CONTENT
// =============================================================================
class _BacklogGraphScreenContent extends StatefulWidget {
  final String backlogId;
  final String backlogName;

  const _BacklogGraphScreenContent({
    Key? key,
    required this.backlogId,
    required this.backlogName,
  }) : super(key: key);

  @override
  _BacklogGraphScreenContentState createState() =>
      _BacklogGraphScreenContentState();
}

class _BacklogGraphScreenContentState extends State<_BacklogGraphScreenContent>
    with SingleTickerProviderStateMixin {
  Map<String, Offset> nodePositions = {};
  Map<String, String> verbToTargetKey = {};

  Set<String> expandedSubjects = {};
  Set<String> zonedSubjects = {};
  bool _isZoningMode = false;
  String? _hoveredNodeKey;

  // --- LASSO SELECTION STATE ---
  bool _isLassoMode = false;
  List<Offset> _drawnPoints = [];
  Set<String> _selectedNodeKeys = {};

  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Nạp dữ liệu khi mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final vm = context.read<GraphViewModel>();
    await vm.fetchGraphData(widget.backlogId);

    if (mounted && vm.stories.isNotEmpty) {
      setState(() {
        expandedSubjects.addAll(_getUniqueSubjects(vm.stories));
        _calculateLayout(vm.stories);
      });
    }
  }

  List<String> _getUniqueSubjects(List<AnalyzedStory> stories) {
    List<String> subjects = [];
    for (var s in stories) {
      if (!subjects.contains(s.subject)) subjects.add(s.subject);
    }
    return subjects;
  }

  bool _isObjectASubject(String objectName, List<AnalyzedStory> stories) {
    return _getUniqueSubjects(stories).contains(objectName);
  }

  String _makeObjectKey(String name, USStatus status) =>
      "obj_${name}_${status.name}";

  void _calculateLayout(List<AnalyzedStory> stories) {
    nodePositions.clear();
    verbToTargetKey.clear();

    List<String> subjects = _getUniqueSubjects(stories);
    const double subjectX = 150;
    const double verbX = 420;
    const double objectX = 720;
    double currentSubjectY = 140;
    const double subjectSpacing = 160;
    const double verbSpacing = 80;

    for (var subName in subjects) {
      nodePositions["sub_$subName"] = Offset(subjectX, currentSubjectY);
      currentSubjectY += subjectSpacing;
    }

    double globalVerbY = 140;
    for (var subName in subjects) {
      if (!expandedSubjects.contains(subName)) continue;
      final filteredStories = stories
          .where((e) => e.subject == subName)
          .toList();
      for (var story in filteredStories) {
        String verbKey = "verb_${story.id}";
        nodePositions[verbKey] = Offset(verbX, globalVerbY);
        String targetKey = _isObjectASubject(story.object, stories)
            ? "sub_${story.object}"
            : _makeObjectKey(story.object, story.status);
        verbToTargetKey[verbKey] = targetKey;
        globalVerbY += verbSpacing;
      }
    }

    Map<String, List<String>> targetToVerbs = {};
    for (var entry in verbToTargetKey.entries) {
      if (entry.value.startsWith("sub_")) continue;
      targetToVerbs.putIfAbsent(entry.value, () => []).add(entry.key);
    }

    for (var targetKey in targetToVerbs.keys) {
      List<String> verbIds = targetToVerbs[targetKey]!;
      double totalY = verbIds
          .where((v) => nodePositions.containsKey(v))
          .map((v) => nodePositions[v]!.dy)
          .fold(0.0, (a, b) => a + b);
      double avgY = totalY / verbIds.length;
      nodePositions[targetKey] = Offset(objectX, avgY);
    }
  }

  void _avoidCollision(String movedKey, Offset newPos) {
    const minDist = 70.0;
    nodePositions[movedKey] = newPos;
    for (var key in nodePositions.keys) {
      if (key == movedKey) continue;
      final other = nodePositions[key]!;
      final dist = (newPos - other).distance;
      if (dist < minDist && dist > 0) {
        final push = (other - newPos) / dist * (minDist - dist) * 0.5;
        nodePositions[key] = other + push;
      }
    }
  }

  int _countStoriesForObject(String objectName, List<AnalyzedStory> stories) {
    return stories.where((s) => s.object == objectName).length;
  }

  // --- LASSO GESTURE HANDLERS ---
  void _onLassoPanStart(DragStartDetails details) {
    setState(() {
      _drawnPoints = [details.localPosition];
      _selectedNodeKeys.clear();
    });
  }

  void _onLassoPanUpdate(DragUpdateDetails details) {
    setState(() {
      _drawnPoints.add(details.localPosition);
    });
  }

  void _onLassoPanEnd(DragEndDetails details) {
    setState(() {
      if (_drawnPoints.length > 2) {
        Path selectionPath = Path()..addPolygon(_drawnPoints, true);
        nodePositions.forEach((key, pos) {
          if (selectionPath.contains(pos)) {
            _selectedNodeKeys.add(key);
          }
        });
      }
      _drawnPoints.clear();
      _isLassoMode = false; 
    });
  }

  int get _selectedStoriesCount {
    return _selectedNodeKeys.where((k) => k.startsWith('verb_')).length;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GraphViewModel>();

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        title: Text(
          widget.backlogName.isNotEmpty ? widget.backlogName : "Backlog Graph",
          style: const TextStyle(
            color: kTextPrimary,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF30363D), height: 1),
        ),
      ),
      floatingActionButton: _buildFab(vm.stories),
      body: vm.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: kSubjectBorder),
            )
          : vm.errorMessage != null
          ? Center(
              child: Text(
                vm.errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 16),
              ),
            )
          : Stack(
              children: [
                InteractiveViewer(
                  panEnabled: !_isLassoMode,
                  scaleEnabled: !_isLassoMode,
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(2000),
                  minScale: 0.1,
                  maxScale: 4.0,
                  child: GestureDetector(
                    onPanStart: _isLassoMode ? _onLassoPanStart : null,
                    onPanUpdate: _isLassoMode ? _onLassoPanUpdate : null,
                    onPanEnd: _isLassoMode ? _onLassoPanEnd : null,
                    child: SizedBox(
                      width: 2500,
                      height: 2500,
                      child: Stack(
                        children: [
                          AnimatedBuilder(
                            animation: _spinController,
                            builder: (_, __) => CustomPaint(
                              size: const Size(2500, 2500),
                              painter: DarkLinesPainter(
                                nodePositions: nodePositions,
                                expandedSubjects: expandedSubjects,
                                mockData: vm.stories,
                                verbToTargetKey: verbToTargetKey,
                                subjects: _getUniqueSubjects(vm.stories),
                                hoveredKey: _hoveredNodeKey,
                              ),
                            ),
                          ),
                          CustomPaint(
                            size: const Size(2500, 2500),
                            painter: ZoningPainter(
                              nodePositions: nodePositions,
                              zonedSubjects: zonedSubjects,
                              mockData: vm.stories,
                              isObjectASubject: (obj) =>
                                  _isObjectASubject(obj, vm.stories),
                              makeObjectKey: _makeObjectKey,
                            ),
                          ),
                          // Lasso Painter vẽ đường nét
                          if (_isLassoMode && _drawnPoints.isNotEmpty)
                            CustomPaint(
                              size: const Size(2500, 2500),
                              painter: LassoPainter(drawnPoints: _drawnPoints),
                            ),
                          ..._buildNodeWidgets(vm.stories),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(top: 16, right: 16, child: _buildLegend(vm.stories)),

                // --- START SPRINT PANEL ---
                if (_selectedNodeKeys.isNotEmpty)
                  Positioned(
                    bottom: 32,
                    left: 0,
                    right: 0,
                    child: Center(child: _buildStartSprintPanel()),
                  ),
              ],
            ),
    );
  }

  Widget _buildStartSprintPanel() {
    int storiesCount = _selectedStoriesCount;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: kVerbBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: kVerbBorder.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_selectedNodeKeys.length} Nodes Selected ($storiesCount Stories)',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kVerbBorder,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Bắt đầu Sprint với $storiesCount stories!'),
                ),
              );
              setState(() {
                _selectedNodeKeys.clear();
              });
            },
            child: const Text(
              'Start Sprint',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, color: kTextSecondary),
            onPressed: () => setState(() => _selectedNodeKeys.clear()),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(List<AnalyzedStory> stories) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        border: Border.all(color: const Color(0xFF30363D)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RADIAL S-V-O GRAPH',
            style: TextStyle(
              color: kTextSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          _legendItem(kSubjectBorder, 'Actor (S)', isCircle: true),
          _legendItem(kObjectBorder, 'Object (O)', isCircle: false),
          _legendItem(kVerbBorder, 'Action (V)', isCircle: true),
          const SizedBox(height: 6),
          _legendItem(kDoneColor, 'Done', isDot: true),
          _legendItem(kInProgressColor, 'In Progress', isDot: true),
          const SizedBox(height: 8),
          Text(
            '${_getUniqueSubjects(stories).length} entities / ${stories.length} stories',
            style: const TextStyle(color: kTextSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(
    Color color,
    String label, {
    bool isCircle = false,
    bool isDot = false,
  }) {
    Widget icon;
    if (isDot) {
      icon = Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    } else if (isCircle) {
      icon = Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
          color: Colors.transparent,
        ),
      );
    } else {
      icon = Container(
        width: 18,
        height: 12,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(3),
          color: Colors.transparent,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: kTextSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNodeWidgets(List<AnalyzedStory> stories) {
    List<Widget> widgets = [];
    List<String> subjects = _getUniqueSubjects(stories);

    for (var subName in subjects) {
      String key = "sub_$subName";
      if (nodePositions.containsKey(key)) {
        widgets.add(_buildNode(key, subName, NodeType.subject, null, stories));
      }
    }

    for (var subName in expandedSubjects) {
      final subStories = stories.where((e) => e.subject == subName).toList();
      for (var s in subStories) {
        String verbKey = "verb_${s.id}";
        if (nodePositions.containsKey(verbKey)) {
          widgets.add(_buildNode(verbKey, s.verb, NodeType.verb, s, stories));
        }
      }
    }

    Set<String> renderedObjectKeys = {};
    for (var story in stories) {
      if (_isObjectASubject(story.object, stories)) continue;
      String objKey = _makeObjectKey(story.object, story.status);
      if (!renderedObjectKeys.contains(objKey) &&
          nodePositions.containsKey(objKey)) {
        renderedObjectKeys.add(objKey);
        widgets.add(
          _buildNode(objKey, story.object, NodeType.object, story, stories),
        );
      }
    }

    return widgets;
  }

  Widget _buildNode(
    String key,
    String text,
    NodeType type,
    AnalyzedStory? story,
    List<AnalyzedStory> stories,
  ) {
    Offset pos = nodePositions[key]!;
    double width = type == NodeType.verb ? 64 : 110;
    double height = type == NodeType.verb
        ? 64
        : (type == NodeType.subject ? 60 : 44);

    bool isHovered = _hoveredNodeKey == key;
    bool isSelected = _selectedNodeKeys.contains(key);
    int storyCount = type == NodeType.object
        ? _countStoriesForObject(text, stories)
        : 0;

    return Positioned(
      left: pos.dx - width / 2,
      top: pos.dy - height / 2 - (type == NodeType.verb ? 12 : 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MouseRegion(
            cursor: _isLassoMode
                ? SystemMouseCursors.precise
                : SystemMouseCursors.move,
            onEnter: (_) => setState(() => _hoveredNodeKey = key),
            onExit: (_) => setState(() => _hoveredNodeKey = null),
            child: GestureDetector(
              onPanUpdate: (d) {
                if (!_isZoningMode && !_isLassoMode) {
                  setState(() => _avoidCollision(key, pos + d.delta));
                }
              },
              onTap: () {
                if (_isLassoMode) {
                  setState(() {
                    if (_selectedNodeKeys.contains(key))
                      _selectedNodeKeys.remove(key);
                    else
                      _selectedNodeKeys.add(key);
                  });
                } else {
                  _handleTap(key, text, type, story, stories);
                }
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildNodeUI(
                    text,
                    type,
                    story,
                    width,
                    height,
                    isHovered,
                    isSelected,
                  ),
                  if (isHovered && type == NodeType.object)
                    Positioned(
                      left: width + 8,
                      top: 0,
                      child: _buildTooltip(text, storyCount),
                    ),
                ],
              ),
            ),
          ),
          if (type == NodeType.verb)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'expand',
                style: TextStyle(
                  color: kTextSecondary.withOpacity(0.7),
                  fontSize: 9,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNodeUI(
    String text,
    NodeType type,
    AnalyzedStory? story,
    double w,
    double h,
    bool isHovered,
    bool isSelected,
  ) {
    switch (type) {
      case NodeType.subject:
        return _buildSubjectNode(text, w, h, isHovered, isSelected);
      case NodeType.verb:
        return _buildVerbNode(text, w, h, isHovered, isSelected);
      case NodeType.object:
        return _buildObjectNode(text, story, w, h, isHovered, isSelected);
    }
  }

  Widget _buildSubjectNode(
    String text,
    double w,
    double h,
    bool isHovered,
    bool isSelected,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: w,
      height: h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? kSubjectBorder.withOpacity(0.3) : kSubjectFill,
        borderRadius: BorderRadius.circular(h / 2),
        border: Border.all(
          color: isSelected
              ? Colors.white
              : (isHovered ? kSubjectBorder : kSubjectBorder.withOpacity(0.7)),
          width: isSelected || isHovered ? 2.5 : 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: kSubjectBorder.withOpacity(
              isSelected || isHovered ? 0.4 : 0.15,
            ),
            blurRadius: isSelected || isHovered ? 20 : 12,
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: kTextPrimary,
          fontWeight: FontWeight.bold,
          fontSize: text.length > 8 ? 12 : 14,
        ),
      ),
    );
  }

  Widget _buildVerbNode(
    String text,
    double w,
    double h,
    bool isHovered,
    bool isSelected,
  ) {
    return AnimatedBuilder(
      animation: _spinController,
      builder: (context, child) {
        return CustomPaint(
          painter: _GlowCirclePainter(
            color: isSelected ? Colors.white : kVerbBorder,
            glowRadius: (isSelected || isHovered) ? 0.8 : 0.4,
            animValue: _spinController.value,
          ),
          child: Container(
            width: w,
            height: h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: kVerbFill,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Colors.white
                    : kVerbBorder.withOpacity(isHovered ? 1.0 : 0.8),
                width: isSelected ? 2.5 : 1.5,
              ),
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kTextPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildObjectNode(
    String text,
    AnalyzedStory? story,
    double w,
    double h,
    bool isHovered,
    bool isSelected,
  ) {
    Color borderColor = story?.status == USStatus.done
        ? kDoneColor
        : (story?.status == USStatus.inProgress
              ? kInProgressColor
              : kObjectBorder);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: w,
      height: h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? borderColor.withOpacity(0.3) : kObjectFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? Colors.white
              : (isHovered ? borderColor : borderColor.withOpacity(0.7)),
          width: isSelected || isHovered ? 2.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(
              isSelected || isHovered ? 0.35 : 0.1,
            ),
            blurRadius: isSelected || isHovered ? 16 : 6,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: kTextPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTooltip(String objectName, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        border: Border.all(color: const Color(0xFF30363D)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            objectName,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Object entity -- reused in $count ${count == 1 ? 'story' : 'stories'}',
            style: const TextStyle(color: kTextSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _handleTap(
    String key,
    String text,
    NodeType type,
    AnalyzedStory? story,
    List<AnalyzedStory> stories,
  ) {
    if (_isZoningMode && type == NodeType.subject) {
      setState(() {
        if (zonedSubjects.contains(text))
          zonedSubjects.remove(text);
        else
          zonedSubjects.add(text);
      });
    } else if (type == NodeType.subject && !_isZoningMode) {
      setState(() {
        if (expandedSubjects.contains(text))
          expandedSubjects.remove(text);
        else
          expandedSubjects.add(text);
        _calculateLayout(stories);
      });
    } else if (type == NodeType.object && story != null) {
      _showActionMenu(context, story);
    }
  }

  Widget _buildFab(List<AnalyzedStory> stories) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _fabButton(
          heroTag: "lasso",
          icon: Icons.gesture,
          active: _isLassoMode,
          onPressed: () => setState(() {
            _isLassoMode = !_isLassoMode;
            if (!_isLassoMode) _drawnPoints.clear();
          }),
        ),
        const SizedBox(height: 10),
        _fabButton(
          heroTag: "z",
          icon: Icons.ads_click,
          active: _isZoningMode,
          onPressed: () => setState(() => _isZoningMode = !_isZoningMode),
        ),
        const SizedBox(height: 10),
        _fabButton(
          heroTag: "expand",
          icon: expandedSubjects.isEmpty
              ? Icons.unfold_more
              : Icons.unfold_less,
          onPressed: () => setState(() {
            if (expandedSubjects.length == _getUniqueSubjects(stories).length)
              expandedSubjects.clear();
            else
              expandedSubjects.addAll(_getUniqueSubjects(stories));
            _calculateLayout(stories);
          }),
        ),
        const SizedBox(height: 10),
        _fabButton(heroTag: "r", icon: Icons.refresh, onPressed: _loadData),
      ],
    );
  }

  Widget _fabButton({
    required String heroTag,
    required IconData icon,
    required VoidCallback onPressed,
    bool active = false,
  }) {
    return FloatingActionButton(
      heroTag: heroTag,
      mini: true,
      backgroundColor: active ? kVerbBorder : const Color(0xFF161B22),
      elevation: 4,
      onPressed: onPressed,
      child: Icon(icon, color: active ? Colors.white : kTextPrimary, size: 20),
    );
  }

  void _showActionMenu(BuildContext context, AnalyzedStory story) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: Color(0xFF30363D)),
      ),
      builder: (c) => Container(
        height: 180,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              story.rawText,
              style: const TextStyle(
                color: kTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _statusChip(story.status),
                const SizedBox(width: 12),
                Text(
                  '${story.subject} → ${story.verb} → ${story.object}',
                  style: const TextStyle(color: kTextSecondary, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'ID: ${story.id}',
              style: const TextStyle(color: kTextSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(USStatus status) {
    Color color = status == USStatus.done
        ? kDoneColor
        : (status == USStatus.inProgress ? kInProgressColor : kTextSecondary);
    String label = status == USStatus.done
        ? 'Done'
        : (status == USStatus.inProgress ? 'In Progress' : 'Todo');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// =============================================================================
// GRAPH PAINTERS (DarkLinesPainter, ZoningPainter, _GlowCirclePainter, LassoPainter)
// =============================================================================
class DarkLinesPainter extends CustomPainter {
  final Map<String, Offset> nodePositions;
  final Set<String> expandedSubjects;
  final List<AnalyzedStory> mockData;
  final Map<String, String> verbToTargetKey;
  final List<String> subjects;
  final String? hoveredKey;

  DarkLinesPainter({
    required this.nodePositions,
    required this.expandedSubjects,
    required this.mockData,
    required this.verbToTargetKey,
    required this.subjects,
    this.hoveredKey,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var subName in subjects) {
      if (!expandedSubjects.contains(subName)) continue;
      String subKey = "sub_$subName";
      if (!nodePositions.containsKey(subKey)) continue;

      Offset subCenter = nodePositions[subKey]!;
      final stories = mockData.where((e) => e.subject == subName).toList();

      for (var s in stories) {
        String verbKey = "verb_${s.id}";
        if (!nodePositions.containsKey(verbKey)) continue;

        Offset verbCenter = nodePositions[verbKey]!;
        bool isHighlighted =
            hoveredKey == verbKey ||
            hoveredKey == subKey ||
            (verbToTargetKey[verbKey] != null &&
                hoveredKey == verbToTargetKey[verbKey]);

        final paint = Paint()
          ..color = isHighlighted ? kHighlightLine.withOpacity(0.9) : kLineColor
          ..strokeWidth = isHighlighted ? 2.0 : 1.0
          ..style = PaintingStyle.stroke;

        _drawCurvedLine(canvas, subCenter, verbCenter, paint);

        if (verbToTargetKey.containsKey(verbKey)) {
          String targetKey = verbToTargetKey[verbKey]!;
          if (nodePositions.containsKey(targetKey)) {
            Offset objCenter = nodePositions[targetKey]!;
            _drawCurvedLine(canvas, verbCenter, objCenter, paint);
          }
        }
      }
    }
  }

  void _drawCurvedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(mid.dx, from.dy, to.dx, to.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant DarkLinesPainter old) =>
      old.hoveredKey != hoveredKey || true;
}

class ZoningPainter extends CustomPainter {
  final Map<String, Offset> nodePositions;
  final Set<String> zonedSubjects;
  final List<AnalyzedStory> mockData;
  final Function(String) isObjectASubject;
  final Function(String, USStatus) makeObjectKey;

  ZoningPainter({
    required this.nodePositions,
    required this.zonedSubjects,
    required this.mockData,
    required this.isObjectASubject,
    required this.makeObjectKey,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (zonedSubjects.isEmpty) return;
    final paint = Paint()
      ..color = kVerbBorder.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (var subName in zonedSubjects) {
      final stories = mockData.where((e) => e.subject == subName).toList();
      for (var s in stories) {
        if (!isObjectASubject(s.object)) {
          String objKey = makeObjectKey(s.object, s.status);
          if (nodePositions.containsKey(objKey)) {
            _drawDashedCircle(canvas, nodePositions[objKey]!, 54, paint);
          }
        }
      }
    }
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    const double dashWidth = 8, dashSpace = 6;
    Path path = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    for (ui.PathMetric metric in path.computeMetrics()) {
      double d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dashWidth), paint);
        d += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class _GlowCirclePainter extends CustomPainter {
  final Color color;
  final double glowRadius;
  final double animValue;

  _GlowCirclePainter({
    required this.color,
    required this.glowRadius,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    double pulse = 0.5 + 0.5 * sin(animValue * 2 * pi);
    final glowPaint = Paint()
      ..color = color.withOpacity(0.15 + 0.1 * pulse)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + 4 * pulse);
    canvas.drawCircle(center, radius + 4, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _GlowCirclePainter old) =>
      old.animValue != animValue || old.glowRadius != glowRadius;
}

class LassoPainter extends CustomPainter {
  final List<Offset> drawnPoints;

  LassoPainter({required this.drawnPoints});

  @override
  void paint(Canvas canvas, Size size) {
    if (drawnPoints.isEmpty) return;

    final path = Path();
    path.moveTo(drawnPoints.first.dx, drawnPoints.first.dy);
    for (int i = 1; i < drawnPoints.length; i++) {
      path.lineTo(drawnPoints[i].dx, drawnPoints[i].dy);
    }

    final strokePaint = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant LassoPainter oldDelegate) {
    return true;
  }
}
