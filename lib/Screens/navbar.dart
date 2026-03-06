import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:ride_sync/Screens/Creat_Page/button_sheets.dart';

import 'Chat_Page/ChatGroupPickerPage.dart';
import 'Creat_Page/create_page.dart';
import 'Home_Page/home_page.dart';
import 'Notificatation_Page/notificatation_page.dart';
import 'Profile_Page/profile_page.dart';

class NavbarSide extends StatefulWidget {
  final int currentIndex;

  const NavbarSide(this.currentIndex, {Key? key}) : super(key: key);

  @override
  State<NavbarSide> createState() => _NavbarSideState();
}

class _NavbarSideState extends State<NavbarSide> {
  late PersistentTabController _controller;

  // ChatPage is never placed here — it's pushed via Navigator.of(context, rootNavigator: true)
  // so it renders completely above the navbar with no bottom bar visible
  final List<Widget> _pages = [
    HomePage(),
    ChatGroupPickerPage(),
    CreatePage(),
    NotificatationPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: widget.currentIndex);
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home_outlined),
        title: "Home",
        activeColorPrimary: Colors.blueAccent,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.chat_bubble_outline),
        title: "Chat",
        activeColorPrimary: Colors.blueAccent,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.add, color: Colors.white),
        title: "Create",
        activeColorPrimary: Colors.blueAccent,
        inactiveColorPrimary: Colors.blueAccent,
        iconSize: 35,
        onPressed: (context) {
          showProfessionalBottomSheet(context!);
        },
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.notifications_none),
        title: "Notification",
        activeColorPrimary: Colors.blueAccent,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.person_outline),
        title: "Profile",
        activeColorPrimary: Colors.blueAccent,
        inactiveColorPrimary: Colors.grey,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: _pages,
      items: _navBarsItems(),
      confineToSafeArea: true,
      backgroundColor: Colors.white,
      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset: true,
      stateManagement: true,
      decoration: NavBarDecoration(
        borderRadius: BorderRadius.circular(0.0),
        colorBehindNavBar: Colors.white,
      ),
      navBarStyle: NavBarStyle.style15,
    );
  }
}