import 'package:flutter/material.dart';
import 'map_widget.dart';

class LinuxMapWidget extends StatelessWidget {
  final double latitude;
  final double longitude;
  final Set<MapMarker> markers;
  final Function(double, double)? onMapCreated;
  final Function(double, double)? onCameraMove;

  const LinuxMapWidget({
    super.key,
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
