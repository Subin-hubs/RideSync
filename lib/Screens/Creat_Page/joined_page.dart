import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';


class JoinedPage extends StatefulWidget {
  const JoinedPage({super.key});

  @override
  State<JoinedPage> createState() => _JoinedPageState();
}

class _JoinedPageState extends State<JoinedPage> {
  final TextEditingController codeController = TextEditingController();
  bool isLoading = false;

  Future<void> joinGroup() async {
    String code = codeController.text.trim();
    if (code.length != 6) {
      Fluttertoast.showToast(msg: "Enter a valid 6-character code");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Reference to the group document
      DocumentReference groupRef =
      FirebaseFirestore.instance.collection("groups").doc(code);

      // Check if group exists
      DocumentSnapshot groupDoc = await groupRef.get();
      if (!groupDoc.exists) {
        Fluttertoast.showToast(msg: "Invalid group code");
        setState(() => isLoading = false);
        return;
      }

      String uid = FirebaseAuth.instance.currentUser!.uid;

      // Check if user already joined
      DocumentSnapshot joinedDoc =
      await groupRef.collection("joined_users").doc(uid).get();

      if (joinedDoc.exists) {
        Fluttertoast.showToast(msg: "You have already joined this group!");
        setState(() => isLoading = false);
        return;
      }

      await groupRef.collection("joined_users").doc(uid).set({
        "uid": uid,
        "joined_at": FieldValue.serverTimestamp(),
      });

      // Optional: update the group's total member count
      await groupRef.update({
        "member_count": FieldValue.increment(1),
      });

      Fluttertoast.showToast(msg: "Successfully Joined Group!");

      // Navigate to group page or back
      Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: ${e.toString()}");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f5fa),
      appBar: AppBar(
        title: const Text("Join Group"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card 1
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Enter Group Code",
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w600)),

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
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none)),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : joinGroup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Join Group",
                          style:
                          TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Card 2 (How it works)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("How it works",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  SizedBox(height: 15),
                  _StepTile(num: 1, text: "Get the group code from your admin"),
                  _StepTile(num: 2, text: "Enter the code above"),
                  _StepTile(num: 3, text: "Start sharing your location"),
                  _StepTile(num: 4, text: "Chat with group members"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final int num;
  final String text;

  const _StepTile({required this.num, required this.text, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: Colors.blueAccent,
          child: Text("$num",
              style: const TextStyle(color: Colors.white, fontSize: 14)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 15, color: Colors.black87)),
        )
      ],
    );
  }
}