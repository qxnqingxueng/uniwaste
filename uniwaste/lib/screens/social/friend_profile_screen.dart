import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FriendProfileScreen extends StatelessWidget {
  const FriendProfileScreen({
    super.key,
    required this.friendUserId, // ✅ needed to fetch real data
    required this.name,
    required this.email,
    this.avatarBase64,
  });

  final String friendUserId;
  final String name;
  final String email;
  final String? avatarBase64;

  static const Color _accent = Color(0xFFA1BC98);
  static const Color _bgTop = Color(0xFFF1F3E0);

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ✅ FIX: replace "Your ..." and "You ..." safely (avoid Daidir / Blur)
  String _fixPerspective(String text, String friendName) {
    // 1) "Your ..." -> "Daidi's ..."
    text = text.replaceAll('Your ', "$friendName's ");

    // 2) "You ..." -> "Daidi ..."
    // add space to avoid touching "Your"
    text = text.replaceAll('You ', '$friendName ');

    return text;
  }

  // ---------------- Rank helper: compute "Top X%" based on points vs all users ----------------
  Future<String> _computeTopPercent(int points) async {
    try {
      final totalSnap = await _db.collection('users').get();
      final total = totalSnap.size;
      if (total <= 0) return 'Top 100%';

      final higherSnap =
          await _db.collection('users').where('points', isGreaterThan: points).get();
      final higher = higherSnap.size;

      final pct = ((total - higher) / total) * 100;
      final top = (100 - pct).round().clamp(1, 100);

      return 'Top $top%';
    } catch (_) {
      return 'Top --%';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRef = _db.collection('users').doc(friendUserId);

    return Scaffold(
      backgroundColor: _bgTop,
      appBar: AppBar(
        backgroundColor: _bgTop,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Friend profile',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: userRef.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Text(
                "Failed to load profile: ${snap.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = (snap.data?.data() as Map<String, dynamic>?) ?? {};

          final String gender = (data['gender'] ?? 'other').toString();
          final int points = (data['points'] ?? 0) is int
              ? (data['points'] ?? 0) as int
              : int.tryParse('${data['points']}') ?? 0;

          final String activityUserId = (data['userId'] ?? friendUserId).toString();

          debugPrint("🧪 FriendProfileScreen friendUserId(docId) = $friendUserId");
          debugPrint("🧪 FriendProfileScreen activityUserId(used for activities) = $activityUserId");

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatar(radius: 54),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildGenderIcon(gender),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  email,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),

                const SizedBox(height: 24),

                FutureBuilder<String>(
                  future: _computeTopPercent(points),
                  builder: (context, rankSnap) {
                    final String rank = rankSnap.data ?? 'Top --%';

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(color: _accent.withOpacity(0.5), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Points',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  points.toString(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey.withOpacity(0.25),
                          ),

                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Ranking',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _accent.withOpacity(0.95),
                                        const Color(0xFF7C9473),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.emoji_events_outlined,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        rank,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 28),

                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Activity',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                StreamBuilder<QuerySnapshot>(
                  stream: _db
                      .collection('activities')
                      .where('userId', isEqualTo: activityUserId)
                      .limit(3)
                      .snapshots(),
                  builder: (context, actSnap) {
                    if (actSnap.hasError) {
                      debugPrint("❌ Activity query error: ${actSnap.error}");
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          "Failed to load activities: ${actSnap.error}",
                          style: const TextStyle(fontSize: 13, color: Colors.red),
                        ),
                      );
                    }

                    if (!actSnap.hasData) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          "Loading activities...",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      );
                    }

                    final docs = actSnap.data!.docs;
                    debugPrint("🧪 Activities found = ${docs.length}");

                    if (docs.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          "No activities yet.",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      );
                    }

                    return Column(
                      children: List.generate(docs.length, (index) {
                        final d = docs[index].data() as Map<String, dynamic>;
                        final rawTitle = (d['title'] ?? '').toString();
                        final rawDesc = (d['description'] ?? '').toString();

                        // ✅ FIXED TEXT
                        final title = _fixPerspective(rawTitle, name);
                        final desc = _fixPerspective(rawDesc, name);

                        final text =
                            title.isNotEmpty ? title : (desc.isNotEmpty ? desc : 'Activity');

                        return Container(
                          constraints: const BoxConstraints(minHeight: 100),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: _accent.withOpacity(0.2),
                              child: const Icon(
                                Icons.check_circle_outline,
                                size: 18,
                                color: _accent,
                              ),
                            ),
                            title: Text(
                              text,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: desc.isNotEmpty && desc != text
                                ? Text(
                                    desc,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar({double radius = 54}) {
    if (avatarBase64 != null && avatarBase64!.isNotEmpty) {
      try {
        final Uint8List bytes = base64Decode(avatarBase64!);
        return CircleAvatar(
          radius: radius,
          backgroundColor: _accent.withOpacity(0.2),
          backgroundImage: MemoryImage(bytes),
        );
      } catch (_) {}
    }

    final String initial =
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: radius,
      backgroundColor: _accent.withOpacity(0.2),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius - 8,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF5C6C4A),
        ),
      ),
    );
  }

  Widget _buildGenderIcon(String gender) {
    IconData icon;
    Color color;

    switch (gender.toLowerCase()) {
      case 'male':
        icon = Icons.male;
        color = Colors.blueAccent;
        break;
      case 'female':
        icon = Icons.female;
        color = Colors.pinkAccent;
        break;
      default:
        icon = Icons.person_outline;
        color = Colors.grey;
    }

    return Icon(icon, size: 22, color: color);
  }
}
