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

    // Gọi API nền
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
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 380,
        height: 500,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
              child: Row(
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF172B4D),
                    ),
                  ),
                  const Spacer(),

                  if (_notifications.isNotEmpty && _activeTab == 'Direct')
                    IconButton(
                      icon: const Icon(
                        Icons.done_all,
                        size: 20,
                        color: Color(0xFF42526E),
                      ),
                      onPressed: _markAllAsRead,
                      tooltip: 'Mark all as read',
                    ),

                  IconButton(
                    icon: const Icon(
                      Icons.open_in_new,
                      size: 20,
                      color: Color(0xFF42526E),
                    ),
                    onPressed: () {},
                    tooltip: 'Open in full page',
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.more_vert,
                      size: 20,
                      color: Color(0xFF42526E),
                    ),
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
                  _buildTab('Direct'),
                  const SizedBox(width: 16),
                  _buildTab('Watching'),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFDFE1E6)),

            // --- NỘI DUNG CHÍNH ---
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF0052CC),
                        ),
                      ),
                    )
                  : _activeTab == 'Direct'
                  ? _buildNotificationList()
                  : const Center(
                      child: Text(
                        'No watching items',
                        style: TextStyle(color: Color(0xFF5E6C84)),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title) {
    final isActive = _activeTab == title;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = title),
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF0052CC) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? const Color(0xFF0052CC) : const Color(0xFF5E6C84),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationList() {
    if (_notifications.isEmpty) {
      // GIAO DIỆN HỘP THƯ RỖNG
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              "You're all caught up!",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF172B4D),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "You have no unread notifications.",
              style: TextStyle(fontSize: 14, color: Color(0xFF5E6C84)),
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
            color: notif.read
                ? Colors.transparent
                : const Color(0xFFE9F2FF).withOpacity(0.5),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Notification
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Icon(
                    Icons.assignment_ind,
                    size: 20,
                    color: Color(0xFF0052CC),
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
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF172B4D),
                          ),
                          children: [
                            TextSpan(
                              text: notif.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: '  $timeAgo',
                              style: const TextStyle(
                                color: Color(0xFF5E6C84),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif.content,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF172B4D),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'View details',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF5E6C84),
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
                    decoration: const BoxDecoration(
                      color: Color(0xFF0052CC),
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
