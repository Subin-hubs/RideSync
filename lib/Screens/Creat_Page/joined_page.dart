import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Simple overlay toast notification
void showAppToast(BuildContext context, String msg) {
  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
    builder: (context) => Positioned(
      bottom: 80,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Text(
            msg,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  Future.delayed(const Duration(seconds: 2)).then((_) => entry.remove());
}

/// ---------------------- MAIN PAGE ----------------------
class JoinedPage extends StatefulWidget {
  const JoinedPage({super.key});

  @override
  State<JoinedPage> createState() => _JoinedPageState();
}

class _JoinedPageState extends State<JoinedPage> {
  final TextEditingController codeController = TextEditingController();
  bool isLoading = false;

  Future<void> joinGroup() async {
    final code = codeController.text.trim().toUpperCase();

    if (code.length != 6) {
      showAppToast(context, "Enter a valid 6-character code");
      return;
    }

    setState(() => isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser!;
      final uid = currentUser.uid;

      /// 1️⃣ Find group by joinCode
      final query = await FirebaseFirestore.instance
          .collection("groups")
          .where("joinCode", isEqualTo: code)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        showAppToast(context, "Invalid group code");
        setState(() => isLoading = false);
        return;
      }

      final groupDoc = query.docs.first;
      final groupId = groupDoc.id;
      final groupRef =
      FirebaseFirestore.instance.collection("groups").doc(groupId);

      /// 2️⃣ Check if already joined
      final joinedDoc =
      await groupRef.collection("joined_users").doc(uid).get();

      if (joinedDoc.exists) {
        showAppToast(context, "You already joined this group!");
        setState(() => isLoading = false);
        return;
      }

      /// 3️⃣ Add user to groups/{groupId}/joined_users/{uid}
      await groupRef.collection("joined_users").doc(uid).set({
        "uid": uid,
        "displayName": currentUser.displayName ?? "Rider",
        "joined_at": FieldValue.serverTimestamp(),
      });

      /// 4️⃣ Save group reference under users/{uid}/joined/{groupId}
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("joined")
          .doc(groupId)
          .set({
        "groupId": groupId,
        "groupName": groupDoc["groupName"],
        "joinCode": code,
        "joined_at": FieldValue.serverTimestamp(),
      });

      /// 5️⃣ Increment group member count
      await groupRef.update({
        "member_count": FieldValue.increment(1),
      });

      /// 6️⃣ Post a system welcome message so the user is visible in chat
      await groupRef.collection("messages").add({
        "senderId": "system",
        "senderName": "RideSync",
        "text":
        "${currentUser.displayName ?? 'A new rider'} joined the group 🏍️",
        "timestamp": FieldValue.serverTimestamp(),
      });

      showAppToast(context, "Successfully joined!");
      Navigator.pop(context);
    } catch (e) {
      showAppToast(context, "Error: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FA),
      appBar: AppBar(
        title: const Text("Join Group"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Code entry card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Enter Group Code",
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Ask your group admin for the 6-character code",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: codeController,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 6,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        counterText: "", // hide the "0/6" counter
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : joinGroup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                            : const Text(
                          "Join Group",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // How it works card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "How it works",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 15),
                    _StepTile(
                        num: 1,
                        text: "Get the group code from your admin"),
                    _StepTile(num: 2, text: "Enter the code above"),
                    _StepTile(
                        num: 3, text: "Start sharing your location"),
                    _StepTile(
                        num: 4, text: "Chat with group members"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Numbered step row
class _StepTile extends StatelessWidget {
  final int num;
  final String text;

  const _StepTile({required this.num, required this.text, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: const Color(0xFF6C63FF),
            child: Text(
              "$num",
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}