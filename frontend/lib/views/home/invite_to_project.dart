import 'package:flutter/material.dart';

class InviteToProjectPage extends StatefulWidget {
  final String projectName;
  final Map<String, dynamic> selectedTemplate;
  final String selectedManagement;
  final String selectedAccess;

  const InviteToProjectPage({
    Key? key,
    required this.projectName,
    required this.selectedTemplate,
    required this.selectedManagement,
    required this.selectedAccess,
  }) : super(key: key);

  @override
  State<InviteToProjectPage> createState() => _InviteToProjectPageState();
}

class _InviteToProjectPageState extends State<InviteToProjectPage> {
  final _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();

  String _selectedRole = 'Member';
  final List<String> _invitedMembers = [];
  bool _showSuccessMessage = true;
  bool _isInputFocused = false;

  // Jira/Atlassian Colors
  static const primaryColor = Color(0xFF0052CC);
  static const textDark = Color(0xFF172B4D);
  static const textGrey = Color(0xFF5E6C84);
  static const borderGrey = Color(0xFFDFE1E6);
  static const successBg = Color(0xFFE3FCEF);
  static const successText = Color(0xFF006644);

  final List<Map<String, String>> _roleDescriptions = [
    {
      'title': 'Administrator',
      'description':
          'Admins can do most things, like update settings and add other admins.',
    },
    {
      'title': 'Member',
      'description':
          'Members are part of the team, and can add, edit, and collaborate on all work.',
    },
    {
      'title': 'Viewer',
      'description':
          'Viewers can search through, view, and comment on your team\'s work, but not much else.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      setState(() {
        _isInputFocused = _emailFocusNode.hasFocus;
      });
    });
  }

  void _addMember() {
    final email = _emailController.text.trim();
    if (email.isNotEmpty && !_invitedMembers.contains(email)) {
      setState(() {
        _invitedMembers.add(email);
        _emailController.clear();
      });
      _emailFocusNode.requestFocus();
    }
  }

  void _removeMember(String email) {
    setState(() {
      _invitedMembers.remove(email);
    });
  }

  String _getCurrentRoleDescription() {
    final role = _roleDescriptions.firstWhere(
      (element) => element['title'] == _selectedRole,
      orElse: () => {'description': ''},
    );
    return role['description']!;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Back to project setup',
          style: TextStyle(
            fontSize: 15,
            color: textGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header ---
                  const Text(
                    'Bring your team along',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Collaborate instantly. Add people you\'ve already worked with, or invite someone new to start tracking.',
                    style: TextStyle(
                      fontSize: 16,
                      color: textGrey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    'Email addresses',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 8),

                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _isInputFocused ? primaryColor : borderGrey,
                        width: _isInputFocused ? 2 : 1,
                      ),
                      boxShadow: _isInputFocused
                          ? [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.2),
                                blurRadius: 4,
                                spreadRadius: 0,
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_invitedMembers.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _invitedMembers.map((email) {
                                return InputChip(
                                  label: Text(
                                    email,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: textDark,
                                    ),
                                  ),
                                  backgroundColor: const Color(0xFFEBECF0),
                                  deleteIcon: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: textGrey,
                                  ),
                                  onDeleted: () => _removeMember(email),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  side: BorderSide.none,
                                );
                              }).toList(),
                            ),
                          ),
                        TextField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          onSubmitted: (_) => _addMember(),
                          decoration: const InputDecoration(
                            hintText: 'e.g., name@company.com',
                            hintStyle: TextStyle(color: Color(0xFF97A0AF)),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          style: const TextStyle(color: textDark),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- Role Selection ---
                  Row(
                    children: [
                      const Text(
                        'Role',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: "Assign permissions for these users",
                        child: Icon(
                          Icons.info_outline,
                          size: 16,
                          color: textGrey.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderGrey),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: ButtonTheme(
                        alignedDropdown: true,
                        child: DropdownButton<String>(
                          value: _selectedRole,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: textDark,
                          ),
                          style: const TextStyle(color: textDark, fontSize: 15),
                          borderRadius: BorderRadius.circular(6),
                          items: _roleDescriptions.map((role) {
                            return DropdownMenuItem<String>(
                              value: role['title']!,
                              child: Text(
                                role['title']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() => _selectedRole = newValue!);
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDEEBFF).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFDEEBFF)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.admin_panel_settings_outlined,
                          color: primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getCurrentRoleDescription(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF0049B0),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: textGrey,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Skip for now'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Invited ${_invitedMembers.length} people as $_selectedRole',
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFF00875A),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        child: const Text('Invite and continue'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
