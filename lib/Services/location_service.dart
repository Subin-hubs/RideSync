import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart';


class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Timer? _timer;
  final Location _location = Location();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Call once after login / on app start.
  /// [intervalSeconds] — how often to push location (default 5 s).
  Future<void> startSharing({int intervalSeconds = 5}) async {
    await _ensurePermissions();
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: intervalSeconds), (_) => _push());
    _push(); // immediate first push
  }

  void stopSharing() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _ensurePermissions() async {
    bool svc = await _location.serviceEnabled();
    if (!svc) svc = await _location.requestService();
    PermissionStatus perm = await _location.hasPermission();
    if (perm == PermissionStatus.denied) perm = await _location.requestPermission();
  }

  Future<void> _push() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    LocationData loc;
    try {
      loc = await _location.getLocation();
    } catch (_) {
      return;
    }

    final uid = user.uid;
    final payload = {
      'uid': uid,
      'latitude': loc.latitude,
      'longitude': loc.longitude,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Collect all group IDs this user belongs to
    final groupIds = await _getGroupIds(uid);

    // Batch write to every group's locations subcollection
    final batch = _db.batch();
    for (final gid in groupIds) {
      final ref = _db
          .collection('groups')
          .doc(gid)
          .collection('locations')
          .doc(uid);
      batch.set(ref, payload, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<List<String>> _getGroupIds(String uid) async {
    final futures = await Future.wait([
      _db.collection('users').doc(uid).collection('created_groups').get(),
      _db.collection('users').doc(uid).collection('joined').get(),
    ]);
    return futures.expand((snap) => snap.docs.map((d) => d.id)).toList();
  }
}