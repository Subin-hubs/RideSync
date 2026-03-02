import 'package:flutter/material.dart';

/// Professional Button-style Bottom Sheet
void showProfessionalBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top draggable bar
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              "Choose an action",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),

            // Primary Action Button: Create New Group
            ElevatedButton.icon(
              icon: const CircleAvatar(
                radius: 15,
                backgroundColor: Colors.white,
                child: Icon(Icons.group_add, color: Colors.blueAccent, size: 20),
              ),
              label: const Text(
                "Create New Group",
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                shadowColor: Colors.black45,
                elevation: 5,
                minimumSize: const Size.fromHeight(55), // full width
              ),
              onPressed: () {
                Navigator.pop(context);
                // Add create group logic here
              },
            ),
            const SizedBox(height: 15),

            // Secondary Action Button: Join Group
            ElevatedButton.icon(
              icon: const CircleAvatar(
                radius: 15,
                backgroundColor: Colors.grey,
                child: Icon(Icons.group, color: Colors.white, size: 20),
              ),
              label: const Text(
                "Join Group",
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                minimumSize: const Size.fromHeight(55),
              ),
              onPressed: () {
                Navigator.pop(context);
                // Add join group logic here
              },
            ),
            const SizedBox(height: 20),

            // Cancel Button
            OutlinedButton(
              child: const Text(
                "Cancel",
                style: TextStyle(fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size.fromHeight(55),
              ),
              onPressed: () {
                Navigator.pop(context); // just close the sheet
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      );
    },
  );
}