import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uniwaste/services/activity_share_helper.dart';

class ActivityScreen extends StatelessWidget {
  final String userId; // MUST pass current user ID

  const ActivityScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFA1BC98),
        elevation: 0,
        title: const Text(
          "My Activity",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('activities')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No activity yet",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final activities = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final doc = activities[index];
              final data = doc.data() as Map<String, dynamic>;

              final title = data['title'] ?? 'Activity';
              final description = data['description'] ?? '';
              final points = data['points'] ?? 0;
              final type = data['type'] ?? 'generic';
              final extra = data['extra'] as Map<String, dynamic>?;

              final timestamp = data['createdAt'] as Timestamp?;
              final date =
                  timestamp != null ? timestamp.toDate() : DateTime.now();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4A4A4A),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share,
                              size: 20, color: Colors.grey),
                          onPressed: () async {
                            await ActivityShareHelper.recordAndMaybeShare(
                              context: context,
                              userId: userId,
                              title: title,
                              description: description,
                              points: points,
                              type: type,
                              extra: extra,
                              createActivity: false, // ✅ DO NOT create again
                              existingActivityId: doc.id, // ✅ link to this activity
                              userDisplayName: null,
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (description.isNotEmpty)
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "+$points pts",
                          style: const TextStyle(
                            color: Color(0xFF6B8E23),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${date.day}/${date.month}/${date.year}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
