import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Chat_Page/chat_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  LatLng _currentPosition = LatLng(27.7172, 85.3240);
  final MapController _mapController = MapController();
  bool _mapReady = false;
  bool _locating = true;

  // Active group being tracked on the map
  String? _activeGroupId;
  // Real-time member locations keyed by uid
  Map<String, Map<String, dynamic>> _memberLocations = {};
  StreamSubscription<QuerySnapshot>? _locationSub;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    Location location = Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) serviceEnabled = await location.requestService();

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
    }

    if (serviceEnabled && permissionGranted == PermissionStatus.granted) {
      final loc = await location.getLocation();
      setState(() {
        _currentPosition = LatLng(loc.latitude!, loc.longitude!);
        _locating = false;
      });
      if (_mapReady) _mapController.move(_currentPosition, 15);
    } else {
      setState(() => _locating = false);
    }
  }

  // Subscribe to a group's locations subcollection in real-time.
  // Cancels any previous subscription before starting a new one.
  void _listenToGroupLocations(String groupId) {
    _locationSub?.cancel();
    setState(() => _memberLocations.clear());

    final uid = FirebaseAuth.instance.currentUser!.uid;

    _locationSub = FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('locations')
        .snapshots()
        .listen((snap) {
      final updated = <String, Map<String, dynamic>>{};

      for (final doc in snap.docs) {
        if (doc.id == uid) continue; // skip self — shown as blue dot

        final data = doc.data();
        final lat = data['latitude'];
        final lng = data['longitude'];
        final updatedAt = data['updatedAt'] as Timestamp?;

        // Filter out stale locations older than 60 seconds
        if (updatedAt != null) {
          final age = DateTime.now().difference(updatedAt.toDate());
          if (age.inSeconds > 60) continue;
        }

        if (lat != null && lng != null) {
          updated[doc.id] = data;
        }
      }

      setState(() => _memberLocations = updated);
    });
  }

  // Build pink markers for all active group members (excluding self)
  List<Marker> _buildMemberMarkers() {
    return _memberLocations.entries.map((entry) {
      final data = entry.value;
      final pos = LatLng(data['latitude'], data['longitude']);

      return Marker(
        width: 56,
        height: 56,
        point: pos,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF6584).withOpacity(0.15),
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF6584),
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6584).withOpacity(0.4),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchGroups() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final List<Map<String, dynamic>> groups = [];

    final createdSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('created_groups')
        .get();

    for (final doc in createdSnap.docs) {
      groups.add({...doc.data(), '_source': 'created', '_id': doc.id});
    }

    final joinedSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('joined')
        .get();

    for (final doc in joinedSnap.docs) {
      groups.add({...doc.data(), '_source': 'joined', '_id': doc.id});
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LIVE indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8FFF3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      "LIVE",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF22C55E),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Map container
          Container(
            height: 380,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentPosition,
                      initialZoom: 15,
                      onMapReady: () {
                        setState(() => _mapReady = true);
                        _mapController.move(_currentPosition, 15);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                        userAgentPackageName: 'com.example.ride_sync',
                      ),
                      MarkerLayer(
                        markers: [
                          // Blue dot — current user
                          Marker(
                            width: 60,
                            height: 60,
                            point: _currentPosition,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF6C63FF)
                                        .withOpacity(0.15),
                                  ),
                                ),
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF6C63FF),
                                    border: Border.all(
                                        color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF6C63FF)
                                            .withOpacity(0.4),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Pink dots — other group members (real-time)
                          ..._buildMemberMarkers(),
                        ],
                      ),
                    ],
                  ),

                  // Locating overlay
                  if (_locating)
                    Container(
                      color: Colors.white.withOpacity(0.85),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              color: Color(0xFF6C63FF),
                              strokeWidth: 2.5,
                            ),
                            SizedBox(height: 12),
                            Text(
                              "Fetching your location...",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6C63FF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Recenter button
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () {
                        if (_mapReady) _mapController.move(_currentPosition, 15);
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.my_location_rounded,
                            color: Color(0xFF6C63FF), size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Your Groups",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1D23),
                  letterSpacing: -0.3,
                ),
              ),
              const Text(
                "View All",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6C63FF),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Groups list
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchGroups(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(
                      color: Color(0xFF6C63FF),
                      strokeWidth: 2.5,
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFEAECF0)),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.group_off_rounded,
                            size: 40, color: Color(0xFFCBD5E1)),
                        SizedBox(height: 10),
                        Text(
                          "No groups yet",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Create or join a group to get started",
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFFCBD5E1)),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final groups = snapshot.data!;
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groups.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final group = groups[index];
                  final name = group['groupName'] ?? 'Unnamed Group';
                  final code = group['joinCode'] ?? '------';
                  final isCreated = group['_source'] == 'created';
                  final avatarCol = _avatarColor(name);
                  // Prefer groupId field, fall back to Firestore doc id
                  final gid =
                      group['groupId'] as String? ?? group['_id'] as String;

                  return GestureDetector(
                    onTap: () {
                      // existing — activates location tracking
                      setState(() => _activeGroupId = gid);
                      _listenToGroupLocations(gid);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Tracking: $name"),
                          duration: const Duration(seconds: 2),
                          backgroundColor: const Color(0xFF6C63FF),
                        ),
                      );
                    },
                    onLongPress: () {
                      // long press — opens group chat
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            groupId: gid,
                            groupName: name,
                          ),
                        ),
                      );
                    },
                    child: Container( /* card unchanged */ ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// Stat chip widget — kept for use elsewhere in the app
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEAECF0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1D23),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}