import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
  }

  LatLng latLng = const LatLng(34.757245951399064, 10.772160363349858);

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: latLng,
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: latLng,
              width: 60,
              height: 60,
              alignment: Alignment.topCenter,
              child: Icon(
                Icons.location_pin,
                color: Colors.red.shade700,
                size: 60,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
