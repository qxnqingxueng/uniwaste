import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminReportScreen extends StatefulWidget {
  const AdminReportScreen({super.key});

  @override
  State<AdminReportScreen> createState() => _AdminReportScreenState();
}

class _AdminReportScreenState extends State<AdminReportScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- ACTIONS ---

  /// Punish: Sets 10-day ban. Deletes ticket.
  Future<void> _punishUser(String reportId, String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Restriction"),
        content: const Text(
          "This user has reached the threshold.\n"
          "This action will RESTRICT the user for 10 DAYS.\n"
          "Proceed?",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Restrict (10 Days)", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

if (confirm != true) return;

    try {
      final userRef = _db.collection('users').doc(userId);
      final tenDaysLater = DateTime.now().add(const Duration(days: 10));

      await _db.runTransaction((transaction) async {
        transaction.update(userRef, {
          // ❌ REMOVED: 'reportCount': FieldValue.increment(1), 
          // REASON: The count already went up when the student submitted the report.
          // We don't want to double count the same incident.
          
          'reputationScore': FieldValue.increment(-20.0), // Apply Penalty
          'banExpiresAt': Timestamp.fromDate(tenDaysLater), // Apply Ban
        });
        
        // Resolve the ticket
        transaction.delete(_db.collection('reports').doc(reportId));
      });

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User restricted for 10 days.")));
    } catch (e) {
      debugPrint("Error punishing user: $e");
    }
  }

  /// Unban: Clears ban timestamp.
  Future<void> _unbanUser(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Unban User?"),
        content: const Text("This will lift the 10-day restriction immediately."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Unban", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _db.collection('users').doc(userId).update({
        'banExpiresAt': null, // Lift Ban
      });
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User Unbanned.")));
    } catch (e) {
      debugPrint("Error unbanning: $e");
    }
  }

  Future<void> _dismissReport(String reportId) async {
    try {
      await _db.collection('reports').doc(reportId).delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Report dismissed.")));
    } catch (e) {
      debugPrint("Error dismissing: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Admin Panel"),
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Review Queue", icon: Icon(Icons.rate_review)),
              Tab(text: "Banned Users", icon: Icon(Icons.lock_clock)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFilteredReportList(),
            _buildBannedUserList(),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: FILTERED REPORTS (Only >=3 Reports OR Score < 20) ---
  Widget _buildFilteredReportList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('reports').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final reports = snapshot.data!.docs;
        if (reports.isEmpty) return const Center(child: Text("No Pending Reports"));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final data = reports[index].data() as Map<String, dynamic>;
            final String reportedUserId = data['reported_user'] ?? '';

            // ✅ FILTER LOGIC: Fetch user to check stats before showing
            return FutureBuilder<DocumentSnapshot>(
              future: _db.collection('users').doc(reportedUserId).get(),
              builder: (context, userSnap) {
                if (!userSnap.hasData) return const SizedBox.shrink(); // Loading...

                final userData = userSnap.data!.data() as Map<String, dynamic>? ?? {};
                final int userReports = (userData['reportCount'] ?? 0) as int;
                final double userScore = (userData['reputationScore'] is int)
                    ? (userData['reputationScore'] as int).toDouble()
                    : (userData['reputationScore'] as double? ?? 100.0);

                // 🚨 CRITICAL CHECK: Only show if thresholds met
                bool shouldReview = (userReports >= 3) || (userScore < 20.0);

                if (!shouldReview) {
                  return const SizedBox.shrink(); // Hide report if user is still "safe"
                }

                // If unsafe, show the card
                return _ReportCard(
                  reportId: reports[index].id,
                  data: data,
                  userStats: userData, // Pass stats to avoid re-fetching
                  onPunish: () => _punishUser(reports[index].id, reportedUserId),
                  onDismiss: () => _dismissReport(reports[index].id),
                );
              },
            );
          },
        );
      },
    );
  }

  // --- TAB 2: BANNED USERS ---
  Widget _buildBannedUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('users').snapshots(), 
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final bannedUsers = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final Timestamp? banExp = data['banExpiresAt'];
          if (banExp == null) return false;
          // Filter: Expiry must be in the FUTURE
          return banExp.toDate().isAfter(DateTime.now());
        }).toList();

        if (bannedUsers.isEmpty) return const Center(child: Text("No Active Bans"));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bannedUsers.length,
          itemBuilder: (context, index) {
            final userDoc = bannedUsers[index];
            final data = userDoc.data() as Map<String, dynamic>;
            final Timestamp exp = data['banExpiresAt'];
            final dateStr = DateFormat('MMM d, yyyy').format(exp.toDate());
            final daysLeft = exp.toDate().difference(DateTime.now()).inDays + 1;

            return Card(
              color: Colors.red.shade50,
              child: ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: Text(data['name'] ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Restricted until: $dateStr\n($daysLeft days remaining)"),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () => _unbanUser(userDoc.id),
                  child: const Text("Unban", style: TextStyle(color: Colors.white)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String reportId;
  final Map<String, dynamic> data;
  final Map<String, dynamic> userStats;
  final VoidCallback onPunish;
  final VoidCallback onDismiss;

  const _ReportCard({
    required this.reportId,
    required this.data,
    required this.userStats,
    required this.onPunish,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final String listingId = data['listing_id'] ?? '';
    final Timestamp? ts = data['timestamp'];
    final String dateStr = ts != null ? DateFormat('MMM d, h:mm a').format(ts.toDate()) : '-';

    // ✅ Get Report Proof Image
    Uint8List? reportProofBytes;
    if (data['report_proof_blob'] is Blob) {
      reportProofBytes = (data['report_proof_blob'] as Blob).bytes;
    }

    final int reports = (userStats['reportCount'] ?? 0) as int;
    final double score = (userStats['reputationScore'] is int)
        ? (userStats['reputationScore'] as int).toDouble()
        : (userStats['reputationScore'] as double? ?? 100.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.notification_important, color: Colors.redAccent),
                const SizedBox(width: 8),
                const Text("Needs Review", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                const Spacer(),
                Text(dateStr, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
            const Divider(),

            // 1. REPORT PROOF IMAGE
            if (reportProofBytes != null)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(reportProofBytes, fit: BoxFit.cover),
                ),
              )
            else
               const Padding(
                 padding: EdgeInsets.symmetric(vertical: 8),
                 child: Text("⚠️ No proof image provided.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
               ),

            // 2. CONTEXT
            Text("Reason: ${data['reason'] ?? 'None'}", style: const TextStyle(fontWeight: FontWeight.bold)),
            if (listingId.isNotEmpty)
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('food_listings').doc(listingId).get(),
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox();
                  final itemData = snap.data!.data() as Map<String, dynamic>?;
                  if (itemData == null) return const Text("Item: [Deleted]");
                  return Text("Related Item: ${itemData['description']}", style: const TextStyle(fontSize: 13, color: Colors.grey));
                },
              ),

            const SizedBox(height: 12),
            
            // 3. SUSPECT STATS
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Suspect: ${userStats['name'] ?? 'Unknown'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("Reports: $reports  |  Score: ${score.toStringAsFixed(0)}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            
            // 4. ACTIONS
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: onDismiss, 
                  child: const Text("Dismiss", style: TextStyle(color: Colors.grey))
                ),
                ElevatedButton(
                  onPressed: onPunish,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Restrict 10 Days", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}