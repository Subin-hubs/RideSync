import 'package:flutter/material.dart';

class NotificatationPage extends StatefulWidget {
  const NotificatationPage({super.key});

  @override
  State<NotificatationPage> createState() => _NotificatationPageState();
}

class _NotificatationPageState extends State<NotificatationPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Column(children: [Text("This is Notificatation")],));
  }
}
