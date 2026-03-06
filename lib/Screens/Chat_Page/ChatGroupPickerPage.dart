import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';

class ChatGroupPickerPage extends StatefulWidget {
  const ChatGroupPickerPage({super.key});

  @override
  State<ChatGroupPickerPage> createState() => _ChatGroupPickerPageState();
}

class _ChatGroupPickerPageState extends State<ChatGroupPickerPage> {
  Future<List<Map<String, dynamic>>> _fetchGroups() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final List<Map<String, dynamic>> groups = [];

    final createdSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('created_groups')
        .get();

    for (final doc in createdSnap.docs) {
      groups.add({...doc.data(), '_source': 'created'});
    }

    final joinedSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('joined')
        .get();

    for (final doc in joinedSnap.docs) {
      groups.add({...doc.data(), '_source': 'joined'});
    }

    return groups;
  }

  Color _avatarColor(String name) {
    const colors = [
      Color(0xFF6C63FF),
      Color(0xFF48C6EF),
      Color(0xFFFF6584),
      Color(0xFF22C55E),
      Color(0xFFFFB347),
      Color(0xFFE040FB),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Messages",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1D23),
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchGroups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6C63FF),
                strokeWidth: 2.5,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 48, color: Color(0xFFCBD5E1)),
                  SizedBox(height: 12),
                  Text(
                    "No groups yet",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Create or join a group to start chatting",
                    style: TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
                  ),
                ],
              ),
            );
          }

          final groups = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: groups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final group = groups[index];
              final name = group['groupName'] ?? 'Unnamed Group';
              final gid = group['groupId'] as String? ?? '';
              final isCreated = group['_source'] == 'created';
              final avatarCol = _avatarColor(name);

              // Skip any group with a missing ID — safety guard
              if (gid.isEmpty) return const SizedBox.shrink();

              return GestureDetector(
                onTap: () {
                  // Full screen push — navbar is completely hidden inside ChatPage
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        groupId: gid,
                        groupName: name,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEAECF0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Group avatar
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: avatarCol.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.group_rounded,
                            color: avatarCol, size: 26),
                      ),
                      const SizedBox(width: 14),

                      // Group name + role
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1D23),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isCreated
                                  ? "You created this group"
                                  : "You are a member",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Arrow indicator
                      const Icon(Icons.chevron_right_rounded,
                          color: Color(0xFFCBD5E1), size: 22),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}