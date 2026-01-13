import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WasteBin {
  final String id;
  final String name;
  final LatLng location;
  double fillLevel; // 0.0 to 100.0
  String status; // 'Active', 'Maintenance', 'Not Active'

  WasteBin({
    required this.id,
    required this.name,
    required this.location,
    this.fillLevel = 0.0,
    this.status = 'Active',
  });

  factory WasteBin.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WasteBin(
      id: doc.id,
      name: data['name'] ?? 'Unknown Station',
      location: LatLng(
        (data['latitude'] as num?)?.toDouble() ?? 0.0,
        (data['longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      fillLevel: (data['fillLevel'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'Active',
    );
  }
}

class WasteBinMap extends StatefulWidget {
  const WasteBinMap({super.key});

  @override
  State<WasteBinMap> createState() => _WasteMapScreenState();
}

class _WasteMapScreenState extends State<WasteBinMap> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;

  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<QuerySnapshot>? _binsSubscription;

  final Distance _distance = const Distance();
  List<WasteBin> _bins = [];

  @override
  void initState() {
    super.initState();
    _startListeningToLocation();
    _fetchWasteBins();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _binsSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _fetchWasteBins() {
    _binsSubscription = FirebaseFirestore.instance
        .collection('waste_bins')
        .snapshots()
        .listen(
          (snapshot) {
            final List<WasteBin> loadedBins =
                snapshot.docs.map((doc) {
                  return WasteBin.fromFirestore(doc);
                }).toList();

            if (mounted) {
              setState(() {
                _bins = loadedBins;
              });
            }
          },
          onError: (e) {
            debugPrint("Error fetching bins: $e");
          },
        );
  }

  Future<void> _startListeningToLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    });
  }

  Color _getBinColor(WasteBin bin) {
    if (bin.status == 'Not Active') return Colors.grey;
    if (bin.status == 'Maintenance') return Colors.grey;

    double level = bin.fillLevel;
    if (level == 100) return const Color.fromARGB(255, 160, 15, 5);
    if (level >= 80) return Colors.red;
    if (level >= 50) return Colors.orange;
    return Colors.green;
  }

  void _showStationList() {
    List<WasteBin> sortedList = List.from(_bins);

    if (_currentLocation != null) {
      sortedList.sort((a, b) {
        // 1. Active comes first
        bool aIsActive = a.status == 'Active';
        bool bIsActive = b.status == 'Active';

        if (aIsActive && !bIsActive) return -1;
        if (!aIsActive && bIsActive) return 1;

        // 2. Then sort by distance
        double distA = _distance.as(
          LengthUnit.Meter,
          _currentLocation!,
          a.location,
        );
        double distB = _distance.as(
          LengthUnit.Meter,
          _currentLocation!,
          b.location,
        );
        return distA.compareTo(distB);
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.25,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    height: 5,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      "Nearby Waste Stations",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child:
                        sortedList.isEmpty
                            ? const Center(child: Text("No stations found."))
                            : ListView.separated(
                              controller: scrollController,
                              itemCount: sortedList.length,
                              separatorBuilder:
                                  (ctx, i) => const Divider(height: 1),
                              itemBuilder: (ctx, index) {
                                final bin = sortedList[index];

                                final bool isActive = bin.status == 'Active';
                                final Color mainColor =
                                    isActive ? Colors.black : Colors.grey;
                                final Color subColor =
                                    isActive ? Colors.grey[700]! : Colors.grey;
                                final Color iconColor =
                                    isActive ? _getBinColor(bin) : Colors.grey;

                                String distanceText = "Calculating...";
                                if (_currentLocation != null) {
                                  double km =
                                      _distance.as(
                                        LengthUnit.Meter,
                                        _currentLocation!,
                                        bin.location,
                                      ) /
                                      1000;
                                  distanceText =
                                      "${km.toStringAsFixed(2)} km away";
                                }

                                return ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: iconColor.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.delete, color: iconColor),
                                  ),
                                  title: Text(
                                    bin.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: mainColor,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "$distanceText • ${bin.status}",
                                    style: TextStyle(color: subColor),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "${bin.fillLevel.toInt()}%",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: iconColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        bin.status != 'Active'
                                            ? bin.status
                                            : (bin.fillLevel == 100
                                                ? "Full"
                                                : (bin.fillLevel >= 80
                                                    ? "Almost Full"
                                                    : (bin.fillLevel >= 50
                                                        ? "Half"
                                                        : "Empty"))),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: subColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _mapController.move(bin.location, 18);
                                    _showBinDetails(bin);
                                  },
                                );
                              },
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

  void _showBinDetails(WasteBin bin) {
    double tempLevel = bin.fillLevel;
    String tempStatus = bin.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final Color currentColor =
            tempStatus == 'Active'
                ? (tempLevel >= 100
                    ? const Color.fromARGB(255, 160, 15, 5)
                    : (tempLevel >= 80 ? Colors.red : (tempLevel >= 50 ? Colors.orange : Colors.green)))
                : (tempStatus == 'Maintenance'
                    ? Colors.orange.shade800
                    : Colors.grey);

        return Container(
          padding: const EdgeInsets.all(20),
          height: 300, // Reduced height since controls are gone
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bin.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "Status: $tempStatus",
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
              const SizedBox(height: 20),

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
              const SizedBox(height: 10),
              const Text(
                "This is a live view of the bin capacity.",
                style: TextStyle(color: Colors.grey),
              ),
              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Close"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Waste Bin Map"), centerTitle: true),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "list_btn",
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            onPressed: _showStationList,
            child: const Icon(Icons.format_list_bulleted),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "gps_btn",
            onPressed: () {
              if (_currentLocation != null)
                _mapController.move(_currentLocation!, 16);
            },
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: const MapOptions(
          initialCenter: LatLng(5.3555, 100.3000),
          initialZoom: 15.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.uniwasteApp',
          ),
          MarkerLayer(
            markers: [
              ..._bins.map((bin) {
                final Color markerColor = _getBinColor(bin);
                return Marker(
                  point: bin.location,
                  width: 50,
                  height: 50,
                  child: GestureDetector(
                    onTap: () => _showBinDetails(bin),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: markerColor, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Icon(
                        bin.status == 'Maintenance'
                            ? Icons.build_circle
                            : Icons.delete,
                        color: markerColor,
                        size: 20,
                      ),
                    ),
                  ),
                );
              }),
              if (_currentLocation != null)
                Marker(
                  point: _currentLocation!,
                  width: 60,
                  height: 60,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_pin_circle_rounded,
                          color: Colors.blue,
                          size: 30,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "You",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
