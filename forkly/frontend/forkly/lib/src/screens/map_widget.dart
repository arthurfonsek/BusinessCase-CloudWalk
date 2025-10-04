import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/maps_loader_stub.dart' if (dart.library.html) '../services/maps_loader_web.dart';


class MapWidget extends StatelessWidget {
  final double latitude;
  final double longitude;
  final Set<MapMarker> markers;
  final Function(double, double)? onMapCreated;
  final Function(double, double)? onCameraMove;
  final Function(MapMarker)? onMarkerTap;

  const MapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.markers = const {},
    this.onMapCreated,
    this.onCameraMove,
    this.onMarkerTap,
  });

  @override
  Widget build(BuildContext context) {
    // Use kIsWeb for web detection, and Platform only when not on web
    if (kIsWeb) {
      return _WebMapWidget(
        latitude: latitude,
        longitude: longitude,
        markers: markers,
        onMapCreated: onMapCreated,
        onCameraMove: onCameraMove,
        onMarkerTap: onMarkerTap,
      );
    } else {
      // For mobile platforms, use the mobile widget
      return _MobileMapWidget(
        latitude: latitude,
        longitude: longitude,
        markers: markers,
        onMapCreated: onMapCreated,
        onCameraMove: onCameraMove,
        onMarkerTap: onMarkerTap,
      );
    }
  }
}

class _LinuxMapWidget extends StatelessWidget {
  final double latitude;
  final double longitude;
  final Set<MapMarker> markers;
  final Function(double, double)? onMapCreated;
  final Function(double, double)? onCameraMove;

  const _LinuxMapWidget({
    required this.latitude,
    required this.longitude,
    this.markers = const {},
    this.onMapCreated,
    this.onCameraMove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map, size: 64, color: Colors.grey[600]),
              const SizedBox(height: 16),
              Text(
                'Google Maps is not supported on Linux desktop yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please run on mobile or web for full map functionality.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              if (markers.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Found ${markers.length} locations:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...markers.take(3).map((marker) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.blue[600]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                marker.title,
                                style: TextStyle(color: Colors.blue[700]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )),
                      if (markers.length > 3)
                        Text(
                          '... and ${markers.length - 3} more',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WebMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final Set<MapMarker> markers;
  final Function(double, double)? onMapCreated;
  final Function(double, double)? onCameraMove;
  final Function(MapMarker)? onMarkerTap;

  const _WebMapWidget({
    required this.latitude,
    required this.longitude,
    this.markers = const {},
    this.onMapCreated,
    this.onCameraMove,
    this.onMarkerTap,
  });

  @override
  State<_WebMapWidget> createState() => _WebMapWidgetState();
}

class _WebMapWidgetState extends State<_WebMapWidget> {
  GoogleMapController? _controller;
  bool _mapsReady = false;
  bool _mapsFailed = false;
  Future<void>? _loaderFuture;

  Future<void> _ensureMaps() async {
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
          onTap: () => widget.onMarkerTap?.call(marker),
        )).toSet(),
        myLocationButtonEnabled: false,
      );
    } else if (_mapsFailed) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.red[50],
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[600]),
                const SizedBox(height: 16),
                Text(
                  'Google Maps failed to load',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.red[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Provide MAPS_API_KEY via --dart-define to run on web.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: Colors.blue[50],
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading Google Maps...'),
            ],
          ),
        ),
      );
    }
  }
}

class _MobileMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final Set<MapMarker> markers;
  final Function(double, double)? onMapCreated;
  final Function(double, double)? onCameraMove;
  final Function(MapMarker)? onMarkerTap;

  const _MobileMapWidget({
    required this.latitude,
    required this.longitude,
    this.markers = const {},
    this.onMapCreated,
    this.onCameraMove,
    this.onMarkerTap,
  });

  @override
  State<_MobileMapWidget> createState() => _MobileMapWidgetState();
}

class _MobileMapWidgetState extends State<_MobileMapWidget> {
  @override
  Widget build(BuildContext context) {
    // For mobile, show a placeholder
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 64, color: Colors.blue[600]),
            const SizedBox(height: 16),
            Text(
              'Map View (Mobile)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lat: ${widget.latitude.toStringAsFixed(4)}, Lng: ${widget.longitude.toStringAsFixed(4)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue[600],
              ),
            ),
            if (widget.markers.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '${widget.markers.length} locations found',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MapMarker {
  final String id;
  final double latitude;
  final double longitude;
  final String title;
  final String snippet;

  const MapMarker({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.title,
    required this.snippet,
  });
}
