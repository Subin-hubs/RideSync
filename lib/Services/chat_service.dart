import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> sendMessage({
    required String groupId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser!;

    await _db
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .add({
      'senderId': user.uid,
      'senderName': user.displayName ?? 'Rider',
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Real-time stream of messages ordered oldest → newest
  Stream<QuerySnapshot> messagesStream(String groupId) {
    return _db
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limitToLast(50) // load last 50 messages only
        .snapshots();
  }
}