import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class CreatePage extends StatefulWidget {
  @override
  _CreatePageState createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  final TextEditingController groupNameController = TextEditingController();
  String joinCode = "------";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    generateCode();
  }

  Future<void> generateCode() async {
    setState(() => isLoading = true);
    joinCode = await generateUniqueJoinCode();
    setState(() => isLoading = false);
  }

  Future<String> generateUniqueJoinCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();

    while (true) {
      final code = List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
      final snapshot = await FirebaseFirestore.instance
          .collection('groups')
          .where('joinCode', isEqualTo: code)
          .get();

      if (snapshot.docs.isEmpty) return code;
    }
  }

  Future<void> createGroup() async {
    if (groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Enter group name")));
      return;
    }

    setState(() => isLoading = true);

    final userUid = FirebaseAuth.instance.currentUser!.uid;
    final groupRef = FirebaseFirestore.instance.collection("groups").doc();

    // Save group inside main groups collection
    await groupRef.set({
      "groupId": groupRef.id,
      "groupName": groupNameController.text.trim(),
      "joinCode": joinCode,
      "createdBy": userUid,
      "createdAt": FieldValue.serverTimestamp(),
    });

    // Save group under user's created groups
    await FirebaseFirestore.instance
        .collection("users")
        .doc(userUid)
        .collection("created_groups")
        .doc(groupRef.id)
        .set({
      "groupId": groupRef.id,
      "groupName": groupNameController.text.trim(),
      "joinCode": joinCode,
      "createdAt": FieldValue.serverTimestamp(),
    });

    setState(() => isLoading = false);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create Group"),
        leading: BackButton(),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Group Details",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),

                      // Group Name
                      TextField(
                        controller: groupNameController,
                        decoration: InputDecoration(
                          labelText: "Group Name",
                          hintText: "e.g. Weekend Riders",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      SizedBox(height: 20),

                      // Join Code
                      Text("Join Code", style: TextStyle(fontSize: 16)),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        margin: EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              joinCode,
                              style: TextStyle(
                                  fontSize: 20,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: Icon(Icons.copy),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: joinCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Join code copied!")),
                                );
                              },
                            )
                          ],
                        ),
                      ),

                      SizedBox(height: 30),

                      Text("Features",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),

                      featureTile("Real-time location sharing"),
                      featureTile("Group chat"),
                      featureTile("Member tracking on map"),
                      featureTile("Ride statistics"),

                      Spacer(),

                      // Create Group Button
                      ElevatedButton(
                        onPressed: isLoading ? null : createGroup,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 55),
                          backgroundColor: Colors.blueAccent,
                        ),
                        child: isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text("Create Group",
                            style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget featureTile(String text) {
    return Row(
      children: [
        Icon(Icons.check_circle, color: Colors.green),
        SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 16)),
      ],
    );
  }
}