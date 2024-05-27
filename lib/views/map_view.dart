import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lemun/models/vehicle.dart';
import 'package:lemun/models/vehicle_types.dart';
import 'package:lemun/providers/position_provider.dart';
import 'package:lemun/views/compass_view.dart';
import 'package:provider/provider.dart';

// Stateful class that displays a map with vehicle markers and a legend
// Allows users to filter through the legend buttons and move to their location
class MapView extends StatefulWidget {
  final List<Vehicle> vehicles;

  // Creates a MapView with a given list of vehicles on it
  // Parameters:
  //      vehicles: a list of Vehicle objects to display on the map
  const MapView({super.key, required this.vehicles});

  @override
  MapViewState createState() => MapViewState();
}

class MapViewState extends State<MapView> {
  late final MapController _mapController; // Controls view of map
  bool _mapReady = false;
  bool _needsUpdate = true;
  LatLng _currentPosition = const LatLng(47.6061, -122.3328); // Default to Seattle;
  final double _defaultZoom = 17;

  // Set of displayed supported vehicle types
  final Set<VehicleType> _visibleVehicleTypes = {VehicleType.bike, VehicleType.scooter, VehicleType.bus};

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  // called when map is ready to update current location
  void _onMapReady() {
    setState(() {
      _mapReady = true;
    });
    _updateCurrentLocation();
  }

  @override
  void dispose() {
    final positionProvider = Provider.of<PositionProvider>(context, listen: false);
    positionProvider.removeListener(_updateCurrentLocation);
    super.dispose();
  }

  // Update current location based on the position provider
  void _updateCurrentLocation() {
    if (_mapReady) {
      final positionProvider = Provider.of<PositionProvider>(context, listen: false);
      if (positionProvider.status) {
        _currentPosition = LatLng(positionProvider.latitude, positionProvider.longitude);
        if (_needsUpdate) {
          _mapController.moveAndRotate(_currentPosition, _defaultZoom, 0);
          setState(() {
            _needsUpdate = false;
          });
        }
      }
    }
  }

  // Create a list of markers to place on the map signifying available vehicles
  // Parameters:
  //      vehicles: a list of Vehicle objects to create markers for
  // Returns: a list of marker widgets
  List<Marker> createVehicleMarkers(List<Vehicle> vehicles) {
    return vehicles
        .where((vehicle) => _visibleVehicleTypes.contains(vehicle.vehicleType))
        .map((vehicle) {
      return Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(vehicle.latitude, vehicle.longitude),
        child: GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => CompassView(vehicle: vehicle)));
          },
          child: getVehicleIcon(vehicle.vehicleType)
        )
      );
    }).toList();
  }

  // Get an icon representing the given vehicle type
  // Parameters:
  //      type: the VehicleType to get an icon for
  // Returns: an Icon
  Icon getVehicleIcon(VehicleType type) {
    switch (type) {
    case VehicleType.bike:
      return const Icon(Icons.directions_bike, color: Colors.green, size: 40);
    case VehicleType.scooter:
      return const Icon(Icons.electric_scooter, color: Colors.orange, size: 40);
    case VehicleType.bus:
      return const Icon(Icons.directions_bus, color: Colors.blue, size: 40);
    default:
      return const Icon(Icons.location_on, color: Colors.red, size: 40);
    }
  }

  // Toggle the visiblility of a given vehicle type marker on the map
  // Parameters:
  //      type: the VehicleType to toggle
  void _toggleVehicleType(VehicleType type) {
    setState(() {
      if (_visibleVehicleTypes.contains(type)) {
        _visibleVehicleTypes.remove(type);
      } else {
        _visibleVehicleTypes.add(type);
      }
    });
  }

  // Create a legend that shows all vehicle type icons and whether they are visible
  // Returns: the legend widget
  Widget buildLegend() {

    var bikeColor = switch (_visibleVehicleTypes.contains(VehicleType.bike)) {
      true => Colors.green,
      false => Colors.grey
    };

    var scooterColor = switch (_visibleVehicleTypes.contains(VehicleType.scooter)) {
      true => Colors.orange,
      false => Colors.grey
    };

    var busColor = switch (_visibleVehicleTypes.contains(VehicleType.bus)) {
      true => Colors.blue,
      false => Colors.grey
    };

    return Semantics(
      label: 'Legend',
      child: Container(
        padding: const EdgeInsets.all(10.0),
        color: Colors.amber[100],
        width: double.infinity,
        child: Align(
          alignment: Alignment.center,
          child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: Semantics(
                        label: (bikeColor == Colors.grey ? 'currently unselected' : 'currently selected'),
                        selected: true,
                        child: GestureDetector(
                          onTap: () {
                            _toggleVehicleType(VehicleType.bike);
                          },
                          child: legendItem(Icons.directions_bike, bikeColor, 'Bike')
                        ),
                      ),
                    ),
                    Expanded(
                      child: Semantics(
                        label: (scooterColor == Colors.grey ? 'currently unselected' : 'currently selected'),
                        child: GestureDetector(
                          onTap: () {
                            _toggleVehicleType(VehicleType.scooter);
                          },
                          child: legendItem(Icons.electric_scooter, scooterColor, 'Scooter')
                        ),
                      ),
                    ),
                    Expanded(
                      child: Semantics(
                        label: (busColor == Colors.grey ? 'currently unselected' : 'currently selected'),
                        child: GestureDetector(
                          onTap: () {
                            _toggleVehicleType(VehicleType.bus);
                          },
                          child: legendItem(Icons.directions_bus, busColor, 'Bus Stop')
                        ),
                      ),
                    ),
                    Expanded(
                      child: Semantics(
                        label: 'Navigate to ',
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _needsUpdate = true;
                            });
                            _updateCurrentLocation();
                          },
                          child: legendItem(Icons.catching_pokemon, Colors.red, 'You')
                        ),
                      ),
                    ),
                  ],
                ),
        ),
          ),
    );
    }

  // Create a singular legend Item for a given item
  // Parameters:
  //      iconData: the Icon to display for the item
  //      color: the color of the icon
  //      label: the text label of the item
  // Returns: a legend item widget
  Widget legendItem(IconData iconData, Color color, String label) {
    return Column(
        children: [
          Icon(iconData, color: color, size: 48),
          Text(
            label,
            style: const TextStyle(color: Colors.purple, fontSize: 10),
          ),
        ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PositionProvider>(
        builder: (context, positionProvider, child) {
          if (!positionProvider.status && !positionProvider.loadFailure) {
            return const Center(child: CircularProgressIndicator());
          } else if (positionProvider.loadFailure) {
            return const Center(child: Text('Failed to load location'));
          }

          if (_mapReady) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateCurrentLocation();
            });
          }
          return Column(
            children: [
              Expanded(
                flex: 3,
                child: Semantics(
                  label: 'map view',
                  excludeSemantics: true,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      maxZoom: 19,
                      minZoom: 14,
                      initialCenter:  _currentPosition,
                      onMapReady: _onMapReady,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                      ),
                      MarkerLayer(
                        markers: [
                          ...createVehicleMarkers(widget.vehicles),
                          Marker(
                            width: 80,
                            height: 80,
                            point: _currentPosition,
                            rotate: false,
                            child: const Icon(Icons.catching_pokemon, color: Colors.red, size: 40),
                          )                    
                        ]
                      )
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: buildLegend(),
              )
            ],
          );
        }
      ),
    );
  }
}
