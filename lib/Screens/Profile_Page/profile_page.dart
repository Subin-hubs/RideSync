import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // ── Data ───────────────────────────────────────────────────────────────
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isDark = false;

  // Stats — will be populated from rides collection when it exists
  // For now: all 0. Just add rides to Firestore and these will auto-populate.
  int _totalRides = 0;
  double _totalKm = 0.0;
  double _totalHours = 0.0;

  // ── Animation ──────────────────────────────────────────────────────────
  late AnimationController _animCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  // ── Theme tokens ───────────────────────────────────────────────────────
  Color get _bg =>
      _isDark ? const Color(0xFF0D0D12) : const Color(0xFFF4F4F6);
  Color get _surface =>
      _isDark ? const Color(0xFF16161F) : Colors.white;
  Color get _border =>
      _isDark ? const Color(0xFF252535) : const Color(0xFFE4E4E8);
  Color get _primary =>
      _isDark ? Colors.white : const Color(0xFF111111);
  Color get _secondary =>
      _isDark ? const Color(0xFF7A7A90) : const Color(0xFF8A8A8E);
  Color get _dividerColor =>
      _isDark ? const Color(0xFF252535) : const Color(0xFFEEEEF0);

  // Accent: neon lime in dark, pitch black in light
  Color get _accent =>
      _isDark ? const Color(0xFFCBFF3F) : const Color(0xFF111111);
  Color get _accentFg => _isDark ? const Color(0xFF0D0D12) : Colors.white;
  Color get _accentSubtle =>
      _isDark ? const Color(0xFFCBFF3F).withOpacity(0.12) : const Color(0xFF111111).withOpacity(0.08);

  Color get _iconBg =>
      _isDark ? const Color(0xFF1E1E2C) : const Color(0xFFF0F0F3);
  Color get _chevronColor =>
      _isDark ? const Color(0xFF353548) : const Color(0xFFD1D1D8);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _loadData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Firestore fetch ────────────────────────────────────────────────────
  Future<void> _loadData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Load user profile from users/{uid}
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() => _userData = doc.data());
      }

      // Load rides — collection: 'rides', documents with field uid == user.uid
      // Fields expected per doc: distance_km (number), duration_hours (number)
      // This returns 0s until you create the rides collection — no errors thrown.
      try {
        final ridesSnap = await _firestore
            .collection('rides')
            .where('uid', isEqualTo: user.uid)
            .get();

        double km = 0;
        double hrs = 0;
        for (final d in ridesSnap.docs) {
          km += (d['distance_km'] as num? ?? 0).toDouble();
          hrs += (d['duration_hours'] as num? ?? 0).toDouble();
        }
        if (mounted) {
          setState(() {
            _totalRides = ridesSnap.docs.length;
            _totalKm = km;
            _totalHours = hrs;
          });
        }
      } catch (_) {
        // rides collection doesn't exist yet — stays 0, no crash
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

  // ── Helpers ────────────────────────────────────────────────────────────
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

  String _fmt(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}K' : v.toStringAsFixed(0);

  void _toggleTheme() => setState(() => _isDark = !_isDark);

  Future<void> _signOut() async {
    await _auth.signOut();
    // Navigator.pushReplacement to your LoginPage if needed
  }

  // ── Root ───────────────────────────────────────────────────────────────
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
              ? Center(child: CircularProgressIndicator(color: _accent))
              : CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildBanner()),
              SliverToBoxAdapter(child: _buildIdentity()),
              SliverToBoxAdapter(child: _buildStats()),
              SliverToBoxAdapter(child: _buildActions()),
              const SliverToBoxAdapter(child: SizedBox(height: 48)),
            ],
          ),
        ),
      ),
    );
  }

  // ── BANNER + AVATAR ────────────────────────────────────────────────────
  Widget _buildBanner() {
    return SizedBox(
      height: 260,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Dark banner (same in both themes — feels intentional)
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            height: 190,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isDark
                    ? [const Color(0xFF1A1A2A), const Color(0xFF0D0D14)]
                    : [const Color(0xFF111111), const Color(0xFF2A2A2A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Subtle glow
                Positioned(
                  top: -60,
                  right: -60,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        (_isDark
                            ? const Color(0xFFCBFF3F)
                            : Colors.white)
                            .withOpacity(0.07),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
                // Brand
                Positioned(
                  top: 52,
                  left: 22,
                  child: Row(children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _isDark
                            ? const Color(0xFFCBFF3F)
                            : Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'RIDESYNC',
                      style: TextStyle(
                        color: _isDark
                            ? const Color(0xFFCBFF3F)
                            : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3.5,
                      ),
                    ),
                  ]),
                ),
                // Theme toggle
                Positioned(
                  top: 44,
                  right: 16,
                  child: GestureDetector(
                    onTap: _toggleTheme,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.15)),
                      ),
                      child: Icon(
                        _isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                  ),
                ),
                // Join date
                if (_joinDate.isNotEmpty)
                  Positioned(
                    bottom: 16,
                    left: 22,
                    child: Text(
                      _joinDate,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),

          // Avatar — centered, overlapping banner bottom
          Positioned(
            top: 138,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fade,
              child: Center(
                child: Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isDark
                              ? const Color(0xFFCBFF3F)
                              : Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isDark
                                ? const Color(0xFFCBFF3F)
                                : Colors.black)
                                .withOpacity(_isDark ? 0.45 : 0.18),
                            blurRadius: 22,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _avatar != null
                            ? Image(image: _avatar!, fit: BoxFit.cover)
                            : AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          color: _isDark
                              ? const Color(0xFF1E1E2C)
                              : const Color(0xFFE8E8EC),
                          child: Icon(Icons.person_rounded,
                              size: 40,
                              color: _isDark
                                  ? const Color(0xFF454560)
                                  : const Color(0xFFB0B0B8)),
                        ),
                      ),
                    ),
                    // Online dot
                    Positioned(
                      bottom: 3,
                      right: 3,
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          color: const Color(0xFF34C759),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isDark
                                ? const Color(0xFF0D0D12)
                                : Colors.white,
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── NAME + EMAIL + BADGE ───────────────────────────────────────────────
  Widget _buildIdentity() {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
          child: Column(children: [
            // Name — from Firestore Full_Name
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                color: _primary,
                fontSize: 23,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
              child: Text(_name, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 5),
            // Email — from Firestore Email
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(color: _secondary, fontSize: 13),
              child: Text(_email, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 14),
            // Badge
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              padding:
              const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
              decoration: BoxDecoration(
                color: _accentSubtle,
                borderRadius: BorderRadius.circular(20),
                border: _isDark
                    ? Border.all(
                    color: const Color(0xFFCBFF3F).withOpacity(0.35),
                    width: 1)
                    : null,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.electric_bolt_rounded,
                    size: 12, color: _accent),
                const SizedBox(width: 5),
                Text(
                  'ACTIVE RIDER',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  // ── STATS ──────────────────────────────────────────────────────────────
  Widget _buildStats() {
    final items = [
      {'label': 'RIDES', 'value': '$_totalRides'},
      {'label': 'KM', 'value': _fmt(_totalKm)},
      {'label': 'HOURS', 'value': _fmt(_totalHours)},
    ];

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
              boxShadow: _isDark
                  ? []
                  : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  Expanded(
                    child: Column(children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          color: _primary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                        child: Text(items[i]['value']!),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i]['label']!,
                        style: TextStyle(
                          color: _secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ]),
                  ),
                  if (i < items.length - 1)
                    Container(width: 1, height: 34, color: _dividerColor),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── ACTION TILES ───────────────────────────────────────────────────────
  Widget _buildActions() {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tile(
                icon: Icons.person_outline_rounded,
                label: 'Edit Profile',
                onTap: () {
                  // TODO: navigate to edit profile page
                },
              ),
              _tile(
                icon: Icons.route_rounded,
                label: 'My Rides',
                badge: _totalRides > 0 ? '$_totalRides' : null,
                onTap: () {
                  // TODO: navigate to rides page
                },
              ),
              _tile(
                icon: _isDark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                label: _isDark ? 'Switch to Light' : 'Switch to Dark',
                onTap: _toggleTheme,
              ),
              const SizedBox(height: 8),
              // Sign out — destructive
              GestureDetector(
                onTap: _signOut,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border:
                    Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded,
                          color: Colors.redAccent, size: 17),
                      SizedBox(width: 8),
                      Text(
                        'Sign Out',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
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
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        margin: const EdgeInsets.only(bottom: 10),
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: _isDark
              ? []
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: _iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: _accent, size: 17),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                  color: _primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
              child: Text(label),
            ),
          ),
          if (badge != null) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              padding:
              const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: _accentSubtle,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                style: TextStyle(
                    color: _accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Icon(Icons.chevron_right_rounded,
              color: _chevronColor, size: 20),
        ]),
      ),
    );
  }
}