import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../models/venue.dart';

class VenueMapView extends StatefulWidget {
  final List<Venue> venues;
  final LatLng currentLocation;
  final Function(Venue) onVenueTap;

  const VenueMapView({
    Key? key,
    required this.venues,
    required this.currentLocation,
    required this.onVenueTap,
  }) : super(key: key);

  @override
  State<VenueMapView> createState() => _VenueMapViewState();
}

class _VenueMapViewState extends State<VenueMapView> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Venue? _selectedVenue;

  @override
  void initState() {
    super.initState();
    _createMarkers();
  }

  @override
  void didUpdateWidget(VenueMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.venues != widget.venues) {
      _createMarkers();
    }
  }

  void _createMarkers() {
    _markers.clear();
    
    // Add current location marker
    _markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: widget.currentLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(
          title: 'Your Location',
        ),
      ),
    );

    // Add venue markers
    for (int i = 0; i < widget.venues.length; i++) {
      final venue = widget.venues[i];
      _markers.add(
        Marker(
          markerId: MarkerId('venue_${venue.id}'),
          position: LatLng(venue.latitude, venue.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            venue.isVerified ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: venue.name,
            snippet: '${venue.pricing.hourlyRate.toStringAsFixed(0)}/hour',
          ),
          onTap: () => _onMarkerTap(venue),
        ),
      );
    }

    setState(() {});
  }

  void _onMarkerTap(Venue venue) {
    setState(() {
      _selectedVenue = venue;
    });
    
    // Move camera to selected venue
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(venue.latitude, venue.longitude),
        16,
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedVenue = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: _onMapCreated,
          onTap: _onMapTap,
          initialCameraPosition: CameraPosition(
            target: widget.currentLocation,
            zoom: 12,
          ),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          mapToolbarEnabled: false,
          zoomControlsEnabled: true,
        ),
        // Selected Venue Info Card
        if (_selectedVenue != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildSelectedVenueCard(),
          ),
        // Venue Count
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '${widget.venues.length} venues found',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedVenueCard() {
    final venue = _selectedVenue!;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => widget.onVenueTap(venue),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Venue Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  venue.images.isNotEmpty ? venue.images.first : '',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Venue Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${venue.rating.toStringAsFixed(1)} (${venue.totalReviews})',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (venue.isVerified) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Verified',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      venue.address,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'From \$${venue.pricing.hourlyRate.toStringAsFixed(0)}/hour',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Tap to View
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
