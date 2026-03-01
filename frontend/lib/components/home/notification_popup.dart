import 'package:flutter/material.dart';
import '../../models/home/notification_model.dart';
import '../../services/home/notification_service.dart';

class NotificationPopup extends StatefulWidget {
  final VoidCallback onClose;

  const NotificationPopup({Key? key, required this.onClose}) : super(key: key);

  @override
  State<NotificationPopup> createState() => _NotificationPopupState();
}

class _NotificationPopupState extends State<NotificationPopup> {
  final NotificationService _service = NotificationService();
  bool _isLoading = true;
  List<NotificationModel> _notifications = [];
  String _activeTab = 'Direct';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final data = await _service.getUnreadNotifications();
    if (mounted) {
      setState(() {
        _notifications = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(int index) async {
    final notif = _notifications[index];
    if (notif.read) return;

    setState(() {
      _notifications[index] = NotificationModel(
        id: notif.id,
        title: notif.title,
        content: notif.content,
        type: notif.type,
        referenceId: notif.referenceId,
        createdAt: notif.createdAt,
        read: true, 
      );
    });

    final success = await _service.markAsRead(notif.id);
    if (!success) {
      print("Failed to mark as read for id: ${notif.id}");
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() => _isLoading = true);

    final success = await _service.markAllAsRead();
    if (success && mounted) {
      setState(() {
        _notifications.clear();
        _isLoading = false;
      });
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getTimeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7} weeks ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} mins ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDarkMode ? const Color(0xFF282E33) : Colors.white;
    final borderColor = isDarkMode ? const Color(0xFF38414A) : Colors.grey.shade300;
    final titleColor = isDarkMode ? const Color(0xFFB6C2CF) : const Color(0xFF172B4D);
    final iconColor = isDarkMode ? const Color(0xFF8C9BAB) : const Color(0xFF42526E);
    final dividerColor = isDarkMode ? const Color(0xFF38414A) : const Color(0xFFDFE1E6);
    final activeBrandColor = isDarkMode ? const Color(0xFF579DFF) : const Color(0xFF0052CC);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 380,
        height: 500,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.5 : 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
              child: Row(
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const Spacer(),

                  if (_notifications.isNotEmpty && _activeTab == 'Direct')
                    IconButton(
                      icon: Icon(Icons.done_all, size: 20, color: iconColor),
                      onPressed: _markAllAsRead,
                      tooltip: 'Mark all as read',
                    ),

                  IconButton(
                    icon: Icon(Icons.open_in_new, size: 20, color: iconColor),
                    onPressed: () {},
                    tooltip: 'Open in full page',
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert, size: 20, color: iconColor),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // --- TABS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildTab('Direct', isDarkMode),
                  const SizedBox(width: 16),
                  _buildTab('Watching', isDarkMode),
                ],
              ),
            ),
            Divider(height: 1, color: dividerColor),

            // --- NỘI DUNG CHÍNH ---
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(activeBrandColor),
                      ),
                    )
                  : _activeTab == 'Direct'
                  ? _buildNotificationList(isDarkMode)
                  : Center(
                      child: Text(
                        'No watching items',
                        style: TextStyle(color: isDarkMode ? const Color(0xFF8C9BAB) : const Color(0xFF5E6C84)),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, bool isDarkMode) {
    final isActive = _activeTab == title;
    final activeColor = isDarkMode ? const Color(0xFF579DFF) : const Color(0xFF0052CC);
    final inactiveColor = isDarkMode ? const Color(0xFF8C9BAB) : const Color(0xFF5E6C84);

    return GestureDetector(
      onTap: () => setState(() => _activeTab = title),
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? activeColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? activeColor : inactiveColor,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationList(bool isDarkMode) {
    final emptyTitleColor = isDarkMode ? const Color(0xFFB6C2CF) : const Color(0xFF172B4D);
    final emptySubColor = isDarkMode ? const Color(0xFF8C9BAB) : const Color(0xFF5E6C84);
    final unreadBgColor = isDarkMode ? const Color(0xFF1C2B41) : const Color(0xFFE9F2FF).withOpacity(0.5);
    final unreadDotColor = isDarkMode ? const Color(0xFF579DFF) : const Color(0xFF0052CC);

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: isDarkMode ? const Color(0xFF5A6978) : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              "You're all caught up!",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: emptyTitleColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You have no unread notifications.",
              style: TextStyle(fontSize: 14, color: emptySubColor),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notif = _notifications[index];
        final timeAgo = _getTimeAgo(notif.createdAt);

        return InkWell(
          onTap: () => _markAsRead(index),
          child: Container(
            color: notif.read ? Colors.transparent : unreadBgColor,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF22272B) : Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isDarkMode ? const Color(0xFF38414A) : Colors.grey.shade200,
                    ),
                  ),
                  child: Icon(
                    Icons.assignment_ind,
                    size: 20,
                    color: unreadDotColor,
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: emptyTitleColor, 
                          ),
                          children: [
                            TextSpan(
                              text: notif.title,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            TextSpan(
                              text: '  $timeAgo',
                              style: TextStyle(
                                color: emptySubColor, 
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif.content,
                        style: TextStyle(
                          fontSize: 14,
                          color: emptyTitleColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'View details',
                        style: TextStyle(
                          fontSize: 13,
                          color: emptySubColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Dấu chấm xanh unread
                if (!notif.read)
                  Container(
                    margin: const EdgeInsets.only(top: 6, left: 8),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: unreadDotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}