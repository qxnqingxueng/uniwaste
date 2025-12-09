import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class WasteBin {
  final String id;
  final String name;
  final LatLng location;
  double fillLevel; // 0.0 to 100.0

  WasteBin({
    required this.id,
    required this.name,
    required this.location,
    this.fillLevel = 0.0,
  });
}

class WasteBinMap extends StatefulWidget {
  const WasteBinMap({super.key});

  @override
  State<WasteBinMap> createState() => _WasteMapScreenState();
}

class _WasteMapScreenState extends State<WasteBinMap> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;

  // Distance calculator
  final Distance _distance = const Distance();

  // Predefined USM Locations
  static final List<WasteBin> _bins = [
    WasteBin(
      id: '1',
      name: 'M07, Cafeteria Restu Saujana',
      location: const LatLng(5.356628403652195, 100.28968668817554),
      fillLevel: 10.0,
    ),
    WasteBin(
      id: '2',
      name: 'K10, Cafeteria Damai',
      location: const LatLng(5.354427702236065, 100.29619879512569),
      fillLevel: 65.0,
    ),
    WasteBin(
      id: '3',
      name: 'F24, Cafeteria Fajar Harapan',
      location: const LatLng(5.355028210052069, 100.29999711603578),
      fillLevel: 95.0,
    ),
    WasteBin(
      id: '4',
      name: 'Nasi Kandar Subaidah (USM)',
      location: const LatLng(5.35685986572801, 100.30446278351704),
      fillLevel: 40.0,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // Get GPS Location
  Future<void> _determinePosition() async {
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

    Position position = await Geolocator.getCurrentPosition();

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  Color _getBinColor(double level) {
    if (level == 100) return const Color.fromARGB(255, 160, 15, 5);
    if (level >= 80) return Colors.red;
    if (level >= 50) return Colors.orange;
    return Colors.green;
  }

  // Function to show the sorted list
  void _showStationList() {
    List<WasteBin> sortedList = List.from(_bins);

    // Sort by distance
    if (_currentLocation != null) {
      sortedList.sort((a, b) {
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
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: sortedList.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1),
                      itemBuilder: (ctx, index) {
                        final bin = sortedList[index];
                        String distanceText = "Calculating...";
                        if (_currentLocation != null) {
                          double km =
                              _distance.as(
                                LengthUnit.Meter,
                                _currentLocation!,
                                bin.location,
                              ) /
                              1000;
                          distanceText = "${km.toStringAsFixed(2)} km away";
                        }

                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getBinColor(
                                bin.fillLevel,
                              ).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.delete,
                              color: _getBinColor(bin.fillLevel),
                            ),
                          ),
                          title: Text(
                            bin.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(distanceText),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "${bin.fillLevel.toInt()}%",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getBinColor(bin.fillLevel),
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                bin.fillLevel == 100
                                    ? "Full"
                                    : (bin.fillLevel >= 80
                                        ? "Almost Full"
                                        : (bin.fillLevel >= 50
                                            ? "Half"
                                            : "Empty")),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
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

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: 350,
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
                  const SizedBox(height: 10),
                  const Text(
                    "Simulate Sensor Data",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        "${tempLevel.toInt()}%",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _getBinColor(tempLevel),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: tempLevel / 100,
                          color: _getBinColor(tempLevel),
                          backgroundColor: Colors.grey.shade200,
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text("Adjust Fill Level (Simulation):"),
                  Slider(
                    value: tempLevel,
                    min: 0,
                    max: 100,
                    divisions: 10,
                    activeColor: _getBinColor(tempLevel),
                    label: "${tempLevel.toInt()}%",
                    onChanged: (val) => setModalState(() => tempLevel = val),
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
                      ),
                      onPressed: () {
                        setState(() => bin.fillLevel = tempLevel);
                        Navigator.pop(ctx);
                      },
                      child: const Text("Update Map Status"),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Waste Bin Map"), centerTitle: true),

      // Changed FAB to a Column
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "list_btn", // Unique Tag
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            onPressed: _showStationList,
            child: const Icon(Icons.format_list_bulleted),
          ),

          const SizedBox(height: 12),

          FloatingActionButton(
            heroTag: "gps_btn", // Unique Tag
            onPressed: () {
              if (_currentLocation != null) {
                _mapController.move(_currentLocation!, 16);
              } else {
                _determinePosition();
              }
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
                        border: Border.all(
                          color: _getBinColor(bin.fillLevel),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.delete,
                        color: _getBinColor(bin.fillLevel),
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 2,
                            ),
                          ],
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
