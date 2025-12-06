import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class FriendProfileScreen extends StatelessWidget {
  const FriendProfileScreen({
    super.key,
    required this.name,
    required this.email,
    this.avatarBase64,
  });

  final String name;
  final String email;
  final String? avatarBase64;

  static const Color _accent = Color(0xFFA1BC98);
  static const Color _bgTop = Color(0xFFF1F3E0);

  @override
  Widget build(BuildContext context) {
    // --- Static placeholder data (replace with real data later) ---
    const String gender = 'female'; // 'male' / 'female' / 'other'
    const int points = 1240;
    const String rank = 'Top 5%';

    final List<String> activities = [
      'Completed 3 recycling tasks this week',
      'Joined “Campus Clean Up” event',
      'Shared a post in community feed',
      'Redeemed voucher at Uni Café',
      'Invited 2 new friends',
    ];

    final int visibleCount = activities.length > 3 ? 3 : activities.length;

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ---------- avatar ----------
            _buildAvatar(radius: 54),

            const SizedBox(height: 16),

            // ---------- name + gender ----------
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
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 24),

            // ---------- POINTS & RANK CARD (突出一点) ----------
            Container(
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
                border: Border.all(
                  color: _accent.withOpacity(0.5),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  // Points
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Points',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
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

                  // Rank badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Ranking',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
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
            ),

            const SizedBox(height: 28),

            // ---------- Activity header ----------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (activities.length > 3)
                  TextButton(
                    onPressed: () {
                      // TODO: navigate to full activity page later
                    },
                    child: const Text(
                      'More',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // ---------- Activity list (max 3) ----------
            if (activities.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  "No activities yet.",
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              )
            else
              Column(
                children: List.generate(visibleCount, (index) {
                  final text = activities[index];
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
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------- avatar helper ----------------
  Widget _buildAvatar({double radius = 54}) {
    if (avatarBase64 != null && avatarBase64!.isNotEmpty) {
      try {
        final Uint8List bytes = base64Decode(avatarBase64!);
        return CircleAvatar(
          radius: radius,
          backgroundColor: _accent.withOpacity(0.2),
          backgroundImage: MemoryImage(bytes),
        );
      } catch (_) {
        // fall through to initial
      }
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

  // ---------------- gender icon helper ----------------
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

    return Icon(
      icon,
      size: 22,
      color: color,
    );
  }
}
