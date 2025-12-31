import 'dart:async';
import 'dart:convert'; // ✅ ADDED (for base64Decode)
import 'dart:typed_data'; // ✅ ADDED (for Uint8List)
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/blocs/authentication_bloc/authentication_bloc.dart';
import 'package:uniwaste/screens/waste-to-resources/waste_bin_map.dart';
// import 'package:uniwaste/screens/profile/voucher_screen.dart';
import 'package:uniwaste/screens/marketplace/cart/cart_screen.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final PageController _posterController = PageController();
  int _currentPoster = 0;
  Timer? _timer;

  final List<String> _posterImages = [
    "assets/images/get_points_ways.png",
    "assets/images/recycle_foodwaste_step.png",
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_currentPoster < _posterImages.length - 1) {
        _currentPoster++;
      } else {
        _currentPoster = 0;
      }
      if (_posterController.hasClients) {
        _posterController.animateToPage(
          _currentPoster,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _posterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get basic user info from Bloc (ID, Name)
    final user = context.select((AuthenticationBloc bloc) => bloc.state.user);
    final String userId = user?.userId ?? '';

    return Scaffold(
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        title: const Text(
          "UniWaste",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF1F3E0), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 120, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // StreamBuilder to listen for real-time name changes (e.g. Company Name)
                StreamBuilder<DocumentSnapshot>(
                  stream:
                      userId.isNotEmpty
                          ? FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .snapshots()
                          : null,
                  builder: (context, snapshot) {
                    // Fallback to Bloc state or 'Student'
                    String displayName = user?.name ?? 'Student';

                    if (snapshot.hasData &&
                        snapshot.data != null &&
                        snapshot.data!.exists) {
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>;
                      // If 'name' field exists and is not empty, use it
                      if (data['name'] != null &&
                          data['name'].toString().trim().isNotEmpty) {
                        displayName = data['name'].toString();
                      }
                    }

                    return Text(
                      "Good Morning, $displayName! 🍔",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  "Ready to make an impact today?",
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),

                // ✅ CHANGED: LEADERBOARD CARD (Top 3 + Bottom Sheet Top 50)
                _buildLeaderboardCard(userId),

                const SizedBox(height: 30),

                // --- CAROUSEL ---
                const Text(
                  "Highlights",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: PageView.builder(
                      controller: _posterController,
                      itemCount: _posterImages.length,
                      onPageChanged:
                          (index) => setState(() => _currentPoster = index),
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Image.asset(
                            _posterImages[index],
                            fit: BoxFit.cover,
                            errorBuilder:
                                (ctx, err, stack) => const Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_posterImages.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPoster == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color:
                            _currentPoster == index
                                ? const Color(0xFF6B8E23)
                                : Colors.grey.shade300,
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 30),

                // --- DISCOVER (MAP) ---
                const Text(
                  "Discover",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WasteBinMap(),
                      ),
                    );
                  },
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: AssetImage("assets/images/map.jpg"),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black38,
                          BlendMode.darken,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_outlined, color: Colors.white, size: 28),
                        SizedBox(width: 10),
                        Text(
                          "Find Waste Bins Near You",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // --- NEW: ENVIRONMENTAL IMPACT SECTION ---
                _buildEnvironmentalImpactSection(),

                const SizedBox(height: 30),

              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // ✅ NEW: LEADERBOARD CARD + SHEET (ONLY ADDED CODE)
  // =========================================================

  Widget _buildLeaderboardCard(String userId) {
    final top3Query = FirebaseFirestore.instance
        .collection('users')
        .orderBy('points', descending: true)
        .limit(3);

    return StreamBuilder<QuerySnapshot>(
      stream: top3Query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _leaderboardCardShell(
            title: "Leaderboard",
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Loading rankings...",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            onViewAll: () => _showFullLeaderboardSheet(context, userId),
          );
        }

        final docs = snapshot.data!.docs;

        return _leaderboardCardShell(
          title: "Leaderboard",
          onViewAll: () => _showFullLeaderboardSheet(context, userId),
          child: Column(
            children: [
              if (docs.isEmpty)
                const Text(
                  "No users found yet.",
                  style: TextStyle(color: Colors.white70),
                ),
              for (int i = 0; i < docs.length; i++)
                _leaderboardRow(
                  rank: i + 1,
                  doc: docs[i],
                  currentUserId: userId,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _leaderboardCardShell({
    required String title,
    required Widget child,
    required VoidCallback onViewAll,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B8E23), Color(0xFFA1BC98)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B8E23).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.leaderboard,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // content
          child,

          const SizedBox(height: 16),

          // button (opens bottom sheet)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onViewAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6B8E23),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: const Text(
                "View Full Ranking",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _leaderboardRow({
    required int rank,
    required QueryDocumentSnapshot doc,
    required String currentUserId,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    final String uid = doc.id;

    final String name =
        (data['name'] ?? data['username'] ?? data['fullName'] ?? 'User')
            .toString();

    final int points = (data['points'] ?? 0).toInt();
    final String? photoBase64 = data['photoBase64'] as String?;

    final bool isMe = (uid == currentUserId);

    String badge = "$rank";
    if (rank == 1) badge = "🥇";
    if (rank == 2) badge = "🥈";
    if (rank == 3) badge = "🥉";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:
            isMe
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border:
            isMe ? Border.all(color: Colors.white.withValues(alpha: 0.35)) : null,
      ),
      child: Row(
        children: [
          Text(
            badge,
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          _buildAvatar(photoBase64, name),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isMe ? "$name (You)" : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "$points pts",
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? photoBase64, String name) {
    Uint8List? bytes;

    if (photoBase64 != null && photoBase64.isNotEmpty) {
      try {
        bytes = base64Decode(photoBase64);
      } catch (_) {
        bytes = null;
      }
    }

    if (bytes != null) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: MemoryImage(bytes),
        backgroundColor: Colors.white.withValues(alpha: 0.25),
      );
    }

    final initial =
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : "U";

    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.white.withValues(alpha: 0.25),
      child: Text(
        initial,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showFullLeaderboardSheet(BuildContext context, String currentUserId) {
    final top50Query = FirebaseFirestore.instance
        .collection('users')
        .orderBy('points', descending: true)
        .limit(50);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Top 50 Leaderboard",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: top50Query.snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty) {
                          return const Center(
                            child: Text("No users found."),
                          );
                        }

                        return ListView.builder(
                          controller: scrollController,
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;

                            final String uid = doc.id;
                            final bool isMe = uid == currentUserId;

                            final String name =
                                (data['name'] ??
                                        data['username'] ??
                                        data['fullName'] ??
                                        'User')
                                    .toString();

                            final int points = (data['points'] ?? 0).toInt();
                            final String? photoBase64 =
                                data['photoBase64'] as String?;

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isMe
                                        ? const Color(0xFF6B8E23).withValues(
                                          alpha: 0.12,
                                        )
                                        : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: isMe
                                    ? Border.all(
                                        color: const Color(0xFF6B8E23).withValues(
                                          alpha: 0.35,
                                        ),
                                      )
                                    : Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 34,
                                    child: Text(
                                      "${index + 1}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  _buildAvatar(photoBase64, name),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      isMe ? "$name (You)" : name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    "$points",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6B8E23),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    "pts",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- UPDATED LOGIC FOR METHANE PREVENTED ---
  Widget _buildEnvironmentalImpactSection() {
    return StreamBuilder<DocumentSnapshot>(
      // Listen to the accumulated stats
      stream:
          FirebaseFirestore.instance
              .collection('stats')
              .doc('impact')
              .snapshots(),
      builder: (context, snapshot) {
        double accumulatedWaste = 0.0;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          accumulatedWaste = (data['totalWasteKg'] as num?)?.toDouble() ?? 0.0;
        }

        // Calculation:
        // 34 tonnes CH4 / 907 tonnes Waste = 0.0375 kg/kg
        // 0.0375 kg / 0.717 (Density) ≈ 0.053 m³ volume
        final double methanePrevented = accumulatedWaste * 0.053;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2D3E2E), // Dark Green Background
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                "Our Global Impact",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // LEFT: WASTE COLLECTED
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          accumulatedWaste.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "kg",
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Total Waste\nCollected",
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                        const SizedBox(height: 8),
                        Container(height: 2, width: 40, color: Colors.white30),
                      ],
                    ),
                  ),

                  // CENTER: EARTH ICON
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: 90,
                          width: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white12, width: 1),
                          ),
                        ),
                        const Icon(
                          Icons.public,
                          size: 80,
                          color: Colors.lightBlueAccent,
                        ),
                      ],
                    ),
                  ),

                  // RIGHT: METHANE PREVENTED (Label Changed)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          methanePrevented.toStringAsFixed(3),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "m³",
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Methane Gas\nPrevented",
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                        const SizedBox(height: 8),
                        Container(height: 2, width: 40, color: Colors.white30),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // [UPDATED] Centered Footnote
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, // Center the Row
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.white54,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        "1 kg waste recycled ≈ 0.053 m³ Methane prevented",
                        textAlign: TextAlign.center, // Center the Text
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
