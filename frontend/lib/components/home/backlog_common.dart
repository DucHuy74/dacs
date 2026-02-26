import 'package:flutter/material.dart';

// Widget hiển thị số lượng trạng thái (Status Badge)
class StatusBadge extends StatelessWidget {
  final String count;
  final Color bgColor;
  final Color textColor;

  const StatusBadge({
    Key? key,
    required this.count,
    required this.bgColor,
    required this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

// Widget thanh tìm kiếm và filter
class BacklogSearchBar extends StatelessWidget {
  const BacklogSearchBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFDFE1E6)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Search backlog',
                hintStyle: TextStyle(fontSize: 14, color: Color(0xFF6B778C)),
                prefixIcon: Icon(Icons.search, size: 20, color: Color(0xFF6B778C)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Avatar circle mockup
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
            ],
          ),
          child: const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF6554C0),
            child: Text(
              'U',
              style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.filter_list, size: 18),
          label: const Text('Filter'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF42526E),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFDFE1E6)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}