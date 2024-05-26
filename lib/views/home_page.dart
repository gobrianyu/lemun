import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lemun/helpers/scooter_checker.dart';
import 'package:lemun/models/bus_stop.dart';
import 'package:lemun/models/lime.dart';
import 'package:lemun/models/vehicle.dart';
import 'package:lemun/providers/drawing_provider.dart';
import 'package:lemun/providers/opacity_provider.dart';
import 'package:lemun/providers/position_provider.dart';
import 'package:lemun/views/city_selector.dart';
import 'package:lemun/views/draw_area.dart';
import 'package:lemun/views/palette.dart';
import 'package:provider/provider.dart';
import 'package:lemun/providers/scooter_provider.dart';
import 'package:lemun/views/map_view.dart';


class HomePage extends StatefulWidget {

  HomePage({super.key, required this.busStops});
  bool showCanvas = false;
  final List<BusStop> busStops;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Timer _checkerTimer;
  late final ScooterChecker _sc;

  @override
  Widget build(BuildContext context) {

    return Consumer3<ScooterProvider, OpacityProvider, PositionProvider>(
      builder: (context, scooterProvider, opacityProvider, positionProvider, child) {

        // List<Text> coords = [Text('no coords yet')];

        List<Vehicle> limes = scooterProvider.limes ?? [];
        List<Vehicle> links = scooterProvider.links ?? [];

        List<Vehicle> allVehicles = [];
        for (Vehicle busStop in widget.busStops) { 
          allVehicles.add(busStop);
        }

        for (Vehicle lime in limes) {
          allVehicles.add(lime);
        }

        for (Vehicle link in links) {
          allVehicles.add(link);
        }

        // limes = scooterProvider.limes ?? [];

        return Scaffold(
          appBar: opacityProvider.appBar,
          drawer: opacityProvider.drawer,
          body: Center(
          child: Stack(
            children: [
              MapView(vehicles: allVehicles),
              opacityProvider.canvas
            ],
          ),
        ),
        );
      }
    );
  }

  @override
  void initState() {
    super.initState();

    final singleUseScooterProvider = Provider.of<ScooterProvider>(context, listen: false);
    _sc = ScooterChecker(singleUseScooterProvider);
    final singleUseOpacityProvider = Provider.of<OpacityProvider>(context, listen: false);
    final singleUsePositionProver = Provider.of<PositionProvider>(context, listen: false);
    singleUseOpacityProvider.appBar = _buildAppBar(context, true);
    singleUseOpacityProvider.drawer = Drawer(
      child: CitySelector(context)
    );
    // get initial scooter and bike list
    _sc.updateLocation(latitude: singleUsePositionProver.latitude, longitude: singleUsePositionProver.longitude);
    _sc.fetchLinkScooter();
    _sc.fetchLime();

    // update bike and scooter list periodically so it is up to date
    _checkerTimer = Timer.periodic(
      const Duration(seconds: 60), 
      (timer) { 
        _sc.updateLocation(latitude: singleUsePositionProver.latitude, longitude: singleUsePositionProver.longitude);
        _sc.fetchLinkScooter();
        _sc.fetchLime();
      }
    );
  }
  @override 
  dispose(){
    super.dispose();
    _checkerTimer.cancel();
  }

  _clear(BuildContext context) {
    final nonListen = Provider.of<DrawingProvider>(context, listen: false);
    nonListen.clear();
  }

  _showHideCanvas(BuildContext context) {
    final nonListen = Provider.of<OpacityProvider>(context, listen: false);
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    Opacity canvas;
    AppBar appBar = _buildAppBar(context, nonListen.showCanvas);
    Drawer? drawer;

    if (nonListen.showCanvas) {
      canvas = const Opacity(opacity: 0.0);
      drawer = Drawer(
        child: CitySelector(context)
      );
    } else {
      canvas = Opacity(
        opacity: 0.99,
        child: DrawArea(width: width, height: height)
      );
      drawer = Drawer(
        child: Palette(context),
      );
    }
    nonListen.updateCanvas(canvas, !nonListen.showCanvas, appBar, drawer);
  }

  // Build the appbar based on whether the canvas should be on or off
  AppBar _buildAppBar(BuildContext context, bool showCanvas) {
    // Default look, 1 button to show the canvas
    if (showCanvas) {
      return AppBar(
        title: const Text('LemÚn'),
        actions: <Widget>[
          Semantics(
            button: true,
            label: 'Canvas',
            hint: 'allows drawing on the map',
            child: SizedBox(
              width: 50,
              child: ElevatedButton(
                onPressed: () => _showHideCanvas(context),
                child: const Icon(Icons.edit)
              ),
            )
          )
        ]
      );
    }

    // Button to display the canvas has been tapped. Show button to exit, undo, and color drawer.
    return AppBar(
          title: const Text('Draw your path'),
          actions: <Widget>[
            Semantics(
              button: true,
              label: 'Clear',
              hint: 'clears the canvas',
              child: SizedBox(
                width: 50,
                child: ElevatedButton(
                  onPressed: () => _clear(context), 
                  child: const Icon(Icons.clear)
                ),
              ),
            ),
            Semantics(
              button: true,
              label: 'Canvas',
              hint: 'allows drawing on the map',
              child: SizedBox(
                width: 50,
                child: ElevatedButton(
                  onPressed: () => _showHideCanvas(context),
                  child: const Icon(Icons.edit)
                ),
              )
            ),
          ]
        );
  }
}