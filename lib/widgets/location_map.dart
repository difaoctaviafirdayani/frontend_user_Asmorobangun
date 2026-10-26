import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/config.dart';
import '../core/theme.dart';
import 'common.dart';

const double sanggarLat = -8.0166;
const double sanggarLng = 112.5836;

class LocationMap extends StatelessWidget {
  final double height;
  const LocationMap({super.key, this.height = 190});

  @override
  Widget build(BuildContext context) {
    const point = LatLng(sanggarLat, sanggarLng);
    return GestureDetector(
      onTap: () => openUrl(context, AppConfig.mapsUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.wood700, width: 1.5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.5),
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: point,
                initialZoom: 16,
                interactionOptions: InteractionOptions(flags: InteractiveFlag.none),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'id.asmorobangun.app',
                ),
                const MarkerLayer(markers: [
                  Marker(
                    point: point,
                    width: 44,
                    height: 44,
                    alignment: Alignment.topCenter,
                    child: Icon(Icons.location_on, size: 44, color: AppColors.danger),
                  ),
                ]),
                const RichAttributionWidget(
                  alignment: AttributionAlignment.bottomRight,
                  attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}