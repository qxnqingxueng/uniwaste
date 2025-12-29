import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uniwaste/screens/waste-to-resources/waste_bin_map.dart'; // Import WasteBin model

class WasteCollectionScreen extends StatelessWidget {
  const WasteCollectionScreen({super.key});

  Color _getBinColor(WasteBin bin) {
    if (bin.status == 'Not Active' || bin.status == 'Maintenance') {
      return Colors.grey;
    }
    double level = bin.fillLevel;
    if (level == 100) return const Color.fromARGB(255, 160, 15, 5);
    if (level >= 80) return Colors.red;
    if (level >= 50) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Waste Collection")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('waste_bins').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final bins =
              snapshot.data!.docs
                  .map((doc) => WasteBin.fromFirestore(doc))
                  .toList();

          // Sort: Fullest bins first
          bins.sort((a, b) => b.fillLevel.compareTo(a.fillLevel));

          if (bins.isEmpty) return const Center(child: Text("No bins found"));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bins.length,
            itemBuilder: (context, index) {
              final bin = bins[index];
              final statusColor = _getBinColor(bin);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircularProgressIndicator(
                    value: bin.fillLevel / 100,
                    backgroundColor: Colors.grey[200],
                    color: statusColor,
                  ),
                  title: Text(
                    bin.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Fill Level: ${bin.fillLevel.toInt()}% • ${bin.status}",
                    style: TextStyle(
                      color:
                          (bin.status == 'Maintenance' ||
                                  bin.status == 'Not Active')
                              ? Colors.grey
                              : Colors.black87,
                    ),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      if (bin.fillLevel <= 0)
                        return; // Don't collect empty bins

                      // 1. Calculate weight (100% = 5kg)
                      double collectedWeight = (bin.fillLevel / 100.0) * 5.0;

                      // 2. Update Global Stats (Accumulate)
                      // We use SetOptions(merge: true) so it creates the doc if it doesn't exist
                      final statsRef = FirebaseFirestore.instance
                          .collection('stats')
                          .doc('impact');

                      await statsRef.set({
                        'totalWasteKg': FieldValue.increment(collectedWeight),
                      }, SetOptions(merge: true));

                      // 3. Reset Bin
                      await FirebaseFirestore.instance
                          .collection('waste_bins')
                          .doc(bin.id)
                          .update({'fillLevel': 0});

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Collected ${collectedWeight.toStringAsFixed(1)}kg!",
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: const Text("Collect"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
