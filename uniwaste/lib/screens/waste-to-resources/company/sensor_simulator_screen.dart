import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uniwaste/screens/waste-to-resources/waste_bin_map.dart';
import 'package:uniwaste/services/notification_service.dart';

class SensorSimulatorScreen extends StatefulWidget {
  const SensorSimulatorScreen({super.key});

  @override
  State<SensorSimulatorScreen> createState() => _SensorSimulatorScreenState();
}

class _SensorSimulatorScreenState extends State<SensorSimulatorScreen> {
  // Helper to determine color based on simulator logic
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

  void _showBinDetails(WasteBin bin) {
    double tempLevel = bin.fillLevel;
    String tempStatus = bin.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final Color currentColor =
                tempStatus == 'Active'
                    ? (tempLevel == 100
                        ? const Color.fromARGB(255, 160, 15, 5)
                        : (tempLevel >= 80
                            ? Colors.red
                            : (tempLevel >= 50 ? Colors.orange : Colors.green)))
                    : Colors.grey;

            return Container(
              padding: const EdgeInsets.all(20),
              height: 500,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Sensor Simulator",
                    style: TextStyle(
                      color: Color.fromRGBO(119, 136, 115, 1.0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    bin.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "ID: ${bin.id}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  // Progress Bar
                  Row(
                    children: [
                      Text(
                        "${tempLevel.toInt()}%",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: currentColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: tempLevel / 100,
                          color: currentColor,
                          backgroundColor: Colors.grey.shade200,
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Slider
                  const Text(
                    "Adjust Fill Level:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: tempLevel,
                    min: 0,
                    max: 100,
                    divisions: 10,
                    activeColor: currentColor,
                    label: "${tempLevel.toInt()}%",
                    onChanged: (val) => setModalState(() => tempLevel = val),
                  ),

                  const SizedBox(height: 10),

                  // Status Cards
                  const Text(
                    "Station Status:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildStatusCard(
                        "Active",
                        Colors.green,
                        tempStatus,
                        (val) => setModalState(() => tempStatus = val),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusCard(
                        "Maintenance",
                        Colors.orange,
                        tempStatus,
                        (val) => setModalState(() => tempStatus = val),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusCard(
                        "Not Active",
                        Colors.grey,
                        tempStatus,
                        (val) => setModalState(() => tempStatus = val),
                      ),
                    ],
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(
                          119,
                          136,
                          115,
                          1.0,
                        ),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        try {
                          await FirebaseFirestore.instance
                              .collection('waste_bins')
                              .doc(bin.id)
                              .update({
                                'fillLevel': tempLevel,
                                'status': tempStatus,
                              });

                          // Trigger Notification if level is 100%
                          if (tempLevel == 100) {
                            NotificationService().showNotification(
                              id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                              title: "Bin Full Alert",
                              body: "Bin ${bin.name} is at 100% capacity",
                              payload: 'waste_collection',
                            );
                          }

                          if (mounted) Navigator.pop(ctx);
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text("Error: $e")));
                        }
                      },
                      child: const Text("Update Sensor Data"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusCard(
    String status,
    Color color,
    String currentStatus,
    Function(String) onTap,
  ) {
    bool isSelected = status == currentStatus;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(status),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                Icons.circle,
                size: 14,
                color: isSelected ? color : Colors.grey,
              ),
              const SizedBox(height: 4),
              Text(
                status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sensor Simulator"), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('waste_bins').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No bins found to simulate."));
          }

          final bins =
              snapshot.data!.docs
                  .map((doc) => WasteBin.fromFirestore(doc))
                  .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bins.length,
            itemBuilder: (context, index) {
              final bin = bins[index];
              final color = _getBinColor(bin);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                    ),
                    child: Icon(Icons.delete, color: color),
                  ),
                  title: Text(
                    bin.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text("Level: ${bin.fillLevel.toInt()}%"),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              bin.status,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(
                    Icons.tune,
                    color: Color.fromRGBO(119, 136, 115, 1.0),
                  ),
                  onTap: () => _showBinDetails(bin),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
