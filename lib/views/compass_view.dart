import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lemun/models/bus_stop.dart';
import 'package:lemun/models/vehicle.dart';
import 'package:lemun/models/vehicle_types.dart';
import 'package:lemun/providers/position_provider.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:text_scroll/text_scroll.dart';

class CompassView extends StatefulWidget {  
  final Vehicle vehicle;
  final double latitude;
  final double longitude;

  CompassView({super.key, required this.vehicle}): latitude = vehicle.latitude, longitude = vehicle.longitude;

  @override
  State<CompassView> createState() => _CompassViewState();
}

class _CompassViewState extends State<CompassView> {
  bool _hasPermissions = false;

  Color _getAccentColor(Vehicle vehicle) {
    if (vehicle is Lime) {
      return const Color.fromARGB(255, 100, 218, 65);
    } else if (vehicle is LinkScooter) {
      return const Color.fromARGB(255, 234, 254, 82);
    } else if (vehicle is BusStop) {
      return const Color.fromARGB(255, 53, 110, 134);
    }
    return Colors.white;
  }

  Color _getTextColor(Vehicle vehicle) {
    if (vehicle is Lime || vehicle is LinkScooter) {
      return Colors.black;
    }
    return Colors.white;
  }

  IconData _getIcon(Vehicle vehicle) {
    switch (vehicle.vehicleType) {
      case VehicleType.bike: return Icons.directions_bike;
      case VehicleType.scooter: return Icons.electric_scooter;
      case VehicleType.bus: return Icons.directions_bus;
      default: return Icons.help;
    }
  }


  @override
  void initState() {
    super.initState();
    _fetchPermissionStatus();
  }

  // Returns double representing user's distance (in metres) to selected vehicle.
  // Parameters:
  // - double myLat: user's latitude coordinate
  // - double myLong: user's longitude coordinate
  double getDistance(double myLat, double myLong) {
    return 100000 * math.sqrt(_squared(myLat - widget.latitude) + _squared(myLong - widget.longitude));
  }

  String distanceToString(double distance) {
    if (distance > 1000) {
      return '${(distance / 1000).toStringAsFixed(2)} km';
    }
    return '${distance.toStringAsFixed(0)} m';
  }

  String vehicleTypeAsString(Vehicle vehicle) {
    String stringRep = '';
    if (vehicle is Lime) {
      stringRep += 'Lime';
    } else if (vehicle is LinkScooter) {
      stringRep += 'Link';
    } else if (vehicle is BusStop) {
      stringRep += 'Bus Stop';
    } else {
      throw Exception('Invalid action');
    }
    switch(vehicle.vehicleType) {
      case VehicleType.bike: stringRep += ' Bike';
      case VehicleType.scooter: stringRep += ' Scooter';
      case VehicleType.bus: break; // Do nothing
      case VehicleType.none: throw Exception('Invalid action');
    }
    return stringRep;
  }

  bool _availStatus(Vehicle vehicle) {
    if (vehicle is BusStop) {
      return true;
    } else if (vehicle is LinkScooter) {
      return vehicle.vehicleStatus == "available";
    } else if (vehicle is Lime) {
      return !vehicle.isDisabled && !vehicle.isReserved;
    } else {
      throw Exception('Invalid vehicle');
    }
  }

  // Returns double representing bearing.
  double _getBearing(double myLat, double myLong) {
    double dLon = (widget.longitude - myLong);
    
    double x = math.cos(_degrees2Radians(widget.latitude)) * math.sin(_degrees2Radians(dLon));
    double y = math.cos(_degrees2Radians(myLat)) * math.sin(_degrees2Radians(widget.latitude)) 
             - math.sin(_degrees2Radians(myLat)) * math.cos(_degrees2Radians(widget.latitude)) * math.cos(_degrees2Radians(dLon));
    double bearing = math.atan2(x, y);
    return _radians2Degrees(bearing);
  }

  double _radians2Degrees(double x) {
    return x * 180 / math.pi;
  }

  double _degrees2Radians(double x) {
    return x / 180 * math.pi;
  }

  // Helper method; defines a square function. Returns the square of a provided number x.
  double _squared(double x) {
    return x * x;
  }

  @override
  Widget build(BuildContext context) {
    DateTime updatedAt = DateTime.now();
    Color accentColor = _getAccentColor(widget.vehicle);
    Color textColor = _getTextColor(widget.vehicle);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 4,
        shadowColor: Colors.black,
        iconTheme: IconThemeData(
          color: textColor,
        ),
        backgroundColor: accentColor,
        title: Row(
          children: [
            Text(
              '${vehicleTypeAsString(widget.vehicle)} ',
              style: TextStyle(color: textColor),
            ),
            Icon(_getIcon(widget.vehicle), color: textColor)
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Builder(
            builder:(context) {
              if (_hasPermissions) {
                String busStopNameAsOverride;
                if (widget.vehicle is BusStop) {
                  busStopNameAsOverride = (widget.vehicle as BusStop).name;
                  busStopNameAsOverride = busStopNameAsOverride.substring(1, busStopNameAsOverride.length - 1);
                  return _buildBusStopName(busStopNameAsOverride);
                } else if (widget.vehicle is Lime || widget.vehicle is LinkScooter) {
                  return _buildStatus(widget.vehicle, updatedAt);
                } else {
                  throw Exception("Invalid vehicle type: ${widget.vehicle}");
                }
              }
              return _buildBusStopName('⚠️ Location Permissions Disabled');
            }
          ),
          Consumer<PositionProvider>(
            builder: (context, positionProvider, child) {
              if (_hasPermissions) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 50),
                    _buildCompass(positionProvider, accentColor),
                    const SizedBox(height: 10),
                    Padding(
                      padding: EdgeInsets.all(25),
                      child: Container(
                        alignment: Alignment.center,
                        padding: EdgeInsets.only(left: 30, right: 30, top: 10, bottom: 10),
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, math.min(accentColor.red + 16, 255), math.min(accentColor.green + 31, 255), math.min(accentColor.blue + 38, 255)),
                          borderRadius: BorderRadius.all(Radius.circular(50))
                        ),
                        child: Text(
                          '~${distanceToString(getDistance(positionProvider.latitude, positionProvider.longitude))} away',
                          style: TextStyle(fontSize: 20, color: textColor),
                        ),
                      ),
                    )
                  ],
                );
              } else {
                return _buildPermissionSheet();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBusStopName(String name) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color:Color.fromARGB(255, 69, 141, 172),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: TextScroll(
          '$name          ',
          textAlign: TextAlign.center,
          velocity: const Velocity(pixelsPerSecond: Offset(100, 0)),
          mode: TextScrollMode.endless,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
          )
        ),
      )
    );
  }

  Widget _buildStatus(Vehicle vehicle, DateTime updatedAt) {
    Color accentColor = Color.fromARGB(255, 248, 221, 86);
    bool isAvailable = _availStatus(vehicle);
    String statusText = isAvailable ? 'Status: Available ' : 'Status: Unavailable ';
    IconData icon = isAvailable ? Icons.check_circle_rounded : Icons.remove_circle_rounded;
    Color iconColor = isAvailable ? Colors.green : Colors.red;
    String minute = updatedAt.minute.toString();
    if (updatedAt.minute < 10) {
      minute = '0$minute';
    }
    
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
              boxShadow: const [BoxShadow(
                color: Color.fromARGB(255, 167, 167, 167),
                offset: Offset(2.0, 2.0),
                blurRadius: 4.0,
                spreadRadius: 1.0,
              )],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      statusText,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      )
                    ),
                    Icon(
                      icon,
                      color: iconColor,
                    )
                  ],
                ),
                Text(
                  'Last updated ${updatedAt.hour}:$minute',
                  style: const TextStyle(
                    color: Color.fromARGB(255, 59, 59, 59),
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Builds compass
  Widget _buildCompass(PositionProvider positionProvider, Color compassColor) {
    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error reading heading: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        double? direction = snapshot.data!.heading;

        // if direction is null, then device does not support this sensor
        // show error message
        if (direction == null) {
          return const Center(
            child: Text("Device does not have sensors !"),
          );
        }
        return Transform.rotate(
          angle: (_degrees2Radians(direction) * -1 + _degrees2Radians(_getBearing(positionProvider.latitude, positionProvider.longitude))),
          child: const Image(image: AssetImage('lib/assets/lemun_compass.png'))
        );
      },
    );
  }

  Widget _buildPermissionSheet() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('Location Permission Required'),
          ElevatedButton(
            child: const Text('Open App Settings'),
            onPressed: () {
              openAppSettings().then((opened) {
                //
              });
            },
          )
        ],
      ),
    );
  }

  Future<void> _fetchPermissionStatus() async {
    // Permission.locationWhenInUse.status.then((status) {
    //   if (mounted) {
    //     setState(() => _hasPermissions = status == PermissionStatus.granted);
    //   }
    // });
    var perm = await Geolocator.isLocationServiceEnabled();
    setState(() => _hasPermissions = perm);
  }

}