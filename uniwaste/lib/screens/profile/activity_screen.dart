// lib/screens/profile/activity_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uniwaste/services/activity_service.dart';

class ActivityScreen extends StatelessWidget {
  final String userId; // MUST pass current user ID

  const ActivityScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final activityService = ActivityService();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFA1BC98),
        elevation: 0,
        title: const Text(
          "My Activity",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        // 🔴 no more "+" test button here
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: activityService.getUserActivities(userId),
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
              final data = activities[index].data() as Map<String, dynamic>;

              final title = data['title'] ?? 'Activity';
              final description = data['description'] ?? '';
              final points = data['points'] ?? 0;

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
                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Description
                    if (description.isNotEmpty)
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    const SizedBox(height: 8),

                    // Points + date
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
