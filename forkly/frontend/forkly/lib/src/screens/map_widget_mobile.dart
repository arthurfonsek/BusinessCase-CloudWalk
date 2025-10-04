import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'map_widget.dart';
import '../services/maps_loader_stub.dart' if (dart.library.html) '../services/maps_loader_web.dart';

class MobileMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final Set<MapMarker> markers;
  final Function(double, double)? onMapCreated;
  final Function(double, double)? onCameraMove;

  const MobileMapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.markers = const {},
    this.onMapCreated,
    this.onCameraMove,
  });

  @override
  State<MobileMapWidget> createState() => _MobileMapWidgetState();
}

class _MobileMapWidgetState extends State<MobileMapWidget> {
  GoogleMapController? _controller;
  bool _mapsReady = !kIsWeb && !Platform.isLinux;
  bool _mapsFailed = false;
  Future<void>? _loaderFuture;

  Future<void> _ensureMaps() async {
    if (!kIsWeb && !Platform.isLinux) return;
    if (_loaderFuture != null) return _loaderFuture;
    _loaderFuture = ensureGoogleMapsLoaded(const String.fromEnvironment('MAPS_API_KEY', defaultValue: ''))
        .then((_) => setState(() => _mapsReady = true))
        .catchError((_) => setState(() => _mapsFailed = true));
    return _loaderFuture;
  }

  @override
  void initState() {
    super.initState();
    _ensureMaps();
  }

  @override
  Widget build(BuildContext context) {
    if (_mapsReady) {
      return GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(widget.latitude, widget.longitude),
          zoom: 13,
        ),
        onMapCreated: (GoogleMapController controller) {
          _controller = controller;
          widget.onMapCreated?.call(widget.latitude, widget.longitude);
        },
        onCameraMove: (CameraPosition position) {
          widget.onCameraMove?.call(position.target.latitude, position.target.longitude);
        },
        markers: widget.markers.map((marker) => Marker(
          markerId: MarkerId(marker.id),
          position: LatLng(marker.latitude, marker.longitude),
          infoWindow: InfoWindow(
            title: marker.title,
            snippet: marker.snippet,
          ),
        )).toSet(),
        myLocationButtonEnabled: false,
      );
    } else if (_mapsFailed) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Google Maps failed to load. Provide MAPS_API_KEY via --dart-define to run on web.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }
}
