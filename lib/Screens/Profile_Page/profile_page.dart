import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'edit_profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isDark = false;

  int _createdGroups = 0;
  int _joinedGroups = 0;

  late AnimationController _animCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  Color get _bg => _isDark ? const Color(0xFF0D0D12) : const Color(0xFFF4F6FB);
  Color get _surface => _isDark ? const Color(0xFF16161F) : Colors.white;
  Color get _border => _isDark ? const Color(0xFF252535) : const Color(0xFFEAECF0);
  Color get _primary => _isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1D23);
  Color get _secondary => _isDark ? const Color(0xFF7A7A90) : const Color(0xFF94A3B8);
  Color get _accent => _isDark ? const Color(0xFFCBFF3F) : const Color(0xFF6C63FF);
  Color get _accentSubtle => _accent.withOpacity(_isDark ? 0.12 : 0.1);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _loadData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // User profile
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) setState(() => _userData = doc.data());

      // Created groups count
      final createdSnap = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('created_groups')
          .get();

      // Joined groups count
      final joinedSnap = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('joined_uid_data')
          .get();

      if (mounted) {
        setState(() {
          _createdGroups = createdSnap.docs.length;
          _joinedGroups = joinedSnap.docs.length;
        });
      }
    } catch (e) {
      debugPrint('Profile load error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _animCtrl.forward();
      }
    }
  }

  ImageProvider? get _avatar {
    final raw = _userData?['profile_image'];
    if (raw == null || raw.toString().isEmpty) return null;
    try {
      return MemoryImage(base64Decode(raw.toString()));
    } catch (_) {
      return null;
    }
  }

  String get _name => _userData?['Full_Name'] ?? 'Rider';
  String get _email => _userData?['Email'] ?? '';
  String get _initials {
    final parts = _name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return _name.isNotEmpty ? _name[0].toUpperCase() : 'R';
  }

  String get _joinDate {
    try {
      final ts = _userData?['Date'];
      if (ts == null) return '';
      final dt = (ts as dynamic).toDate() as DateTime;
      const m = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
      return 'Joined ${m[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  void _toggleTheme() => setState(() => _isDark = !_isDark);
  Future<void> _signOut() async => await _auth.signOut();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        color: _bg,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2))
              : CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildBanner()),
              SliverToBoxAdapter(child: _buildGroupsCard()),
              SliverToBoxAdapter(child: _buildActions()),
              const SliverToBoxAdapter(child: SizedBox(height: 48)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return FadeTransition(
      opacity: _fade,
      child: SizedBox(
        height: 280,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Banner
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(children: [
                Positioned(
                  top: -40, right: -40,
                  child: Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        _accent.withOpacity(0.18),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(color: _accent, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          const Text('RIDESYNC', style: TextStyle(
                            color: Colors.white, fontSize: 11,
                            fontWeight: FontWeight.w800, letterSpacing: 3,
                          )),
                        ]),
                        GestureDetector(
                          onTap: _toggleTheme,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withOpacity(0.12)),
                            ),
                            child: Icon(
                              _isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                              color: Colors.white, size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_joinDate.isNotEmpty)
                  Positioned(
                    bottom: 16, left: 22,
                    child: Text(_joinDate, style: TextStyle(
                      color: Colors.white.withOpacity(0.35), fontSize: 12,
                    )),
                  ),
              ]),
            ),

            // Curved bottom
            Positioned(
              bottom: 60, left: 0, right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                height: 36,
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                ),
              ),
            ),

            // Avatar
            Positioned(
              top: 148, left: 0, right: 0,
              child: Column(children: [
                Stack(children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _accent, width: 2.5),
                      boxShadow: [BoxShadow(
                        color: _accent.withOpacity(0.3),
                        blurRadius: 20,
                      )],
                    ),
                    child: ClipOval(
                      child: _avatar != null
                          ? Image(image: _avatar!, fit: BoxFit.cover)
                          : AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        color: _isDark ? const Color(0xFF1E1E2C) : const Color(0xFFEEEEF6),
                        child: Center(
                          child: Text(_initials, style: TextStyle(
                            color: _accent, fontSize: 28, fontWeight: FontWeight.w800,
                          )),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 3, right: 3,
                    child: Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isDark ? const Color(0xFF0D0D12) : Colors.white,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                ]),
              ]),
            ),

            // Name + email + badge
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: SlideTransition(
                position: _slide,
                child: FadeTransition(
                  opacity: _fade,
                  child: Column(children: [
                    Text(_name, style: TextStyle(
                      color: _primary, fontSize: 22,
                      fontWeight: FontWeight.w800, letterSpacing: -0.3,
                    )),
                    if (_email.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(_email, style: TextStyle(color: _secondary, fontSize: 13)),
                    ],
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _accentSubtle,
                        borderRadius: BorderRadius.circular(20),
                        border: _isDark ? Border.all(color: _accent.withOpacity(0.3)) : null,
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.electric_bolt_rounded, size: 11, color: _accent),
                        const SizedBox(width: 5),
                        Text('ACTIVE RIDER', style: TextStyle(
                          color: _accent, fontSize: 10,
                          fontWeight: FontWeight.w800, letterSpacing: 1.5,
                        )),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── GROUPS CARD (replaces static stats row) ───────────────────────────
  Widget _buildGroupsCard() {
    final total = _createdGroups + _joinedGroups;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _border),
              boxShadow: _isDark ? [] : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(Icons.group_rounded, color: _accent, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text('My Groups', style: TextStyle(
                        color: _primary, fontSize: 16, fontWeight: FontWeight.w700,
                      )),
                    ]),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _accentSubtle,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$total total',
                        style: TextStyle(
                          color: _accent, fontSize: 12, fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Two counters
                Row(children: [
                  Expanded(
                    child: _groupCounter(
                      label: 'Created',
                      count: _createdGroups,
                      icon: Icons.add_circle_outline_rounded,
                      color: const Color(0xFF6C63FF),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _groupCounter(
                      label: 'Joined',
                      count: _joinedGroups,
                      icon: Icons.login_rounded,
                      color: const Color(0xFF22C55E),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _groupCounter({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: _primary, fontSize: 22,
                fontWeight: FontWeight.w800, letterSpacing: -0.5,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: _secondary, fontSize: 11, fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ]),
    );
  }

  Widget _buildActions() {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text('ACCOUNT', style: TextStyle(
                  color: _secondary, fontSize: 10,
                  fontWeight: FontWeight.w700, letterSpacing: 2,
                )),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border),
                  boxShadow: _isDark ? [] : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12, offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(children: [
                  _tile(
                    icon: Icons.person_outline_rounded,
                    label: 'Edit Profile',
                    iconColor: const Color(0xFF6C63FF),
                    onTap: () async {
                      final updatedName = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfilePage(currentName: _name),
                        ),
                      );
                      if (updatedName != null && mounted) {
                        setState(() => _userData?['Full_Name'] = updatedName);
                      }
                    },
                    isFirst: true,
                  ),
                  Divider(height: 1, indent: 68, color: _border),
                  _tile(
                    icon: _isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    label: _isDark ? 'Light Mode' : 'Dark Mode',
                    iconColor: const Color(0xFFF59E0B),
                    onTap: _toggleTheme,
                    isLast: true,
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _signOut,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.07),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 16),
                      SizedBox(width: 8),
                      Text('Sign Out', style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w700, fontSize: 15,
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(20) : Radius.zero,
          bottom: isLast ? const Radius.circular(20) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: TextStyle(
                color: _primary, fontSize: 15, fontWeight: FontWeight.w500,
              )),
            ),
            Icon(Icons.chevron_right_rounded,
                color: _secondary.withOpacity(0.5), size: 20),
          ]),
        ),
      ),
    );
  }
}