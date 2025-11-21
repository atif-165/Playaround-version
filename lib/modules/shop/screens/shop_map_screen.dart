import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../theming/colors.dart';
import '../../../theming/public_profile_theme.dart';
import '../../../theming/typography.dart';
import '../../../core/widgets/material3/material3_components.dart';
import '../widgets/shop_theme.dart';
import '../models/shop_location.dart';
import '../services/shop_location_service.dart';
import 'location_detail_screen.dart';
import 'add_location_screen.dart';

const _shopHeroGradient = ShopTheme.heroGradient;

/// Map screen with Google Maps integration for shop locations
class ShopMapScreen extends StatefulWidget {
  const ShopMapScreen({super.key});

  @override
  State<ShopMapScreen> createState() => _ShopMapScreenState();
}

class _ShopMapScreenState extends State<ShopMapScreen> {
  final ShopLocationService _locationService = ShopLocationService();
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  List<ShopLocation> _locations = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Equipment',
    'Outwear',
    'Repairing',
  ];

  // Location variables
  Position? _currentPosition;
  bool _locationPermissionGranted = false;
  bool _isRequestingLocation = false;

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194), // San Francisco
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _loadLocations();
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _isRequestingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location services are disabled. Please enable them to use this feature.'),
            ),
          );
        }
        setState(() {
          _isRequestingLocation = false;
        });
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Location permissions are denied. You can still use the map but won\'t see your current location.'),
              ),
            );
          }
          setState(() {
            _isRequestingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location permissions are permanently denied. Please enable them in app settings.'),
            ),
          );
        }
        setState(() {
          _isRequestingLocation = false;
        });
        return;
      }

      // Permission granted, get current location
      setState(() {
        _locationPermissionGranted = true;
        _isRequestingLocation = false;
      });

      await _getCurrentLocation();
    } catch (e) {
      setState(() {
        _isRequestingLocation = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      // Move camera to current location
      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get current location: $e')),
        );
      }
    }
  }

  Future<void> _loadLocations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final locations = await _locationService.getAllLocations();
      print('Loaded ${locations.length} locations from Firestore');
      setState(() {
        _locations = locations;
        _isLoading = false;
      });
      _updateMarkers();
      print('Updated ${_markers.length} markers on map');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading locations: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load locations: $e')),
        );
      }
    }
  }

  void _updateMarkers() {
    final markers = <Marker>{};

    print('Creating markers for ${_locations.length} locations');
    for (final location in _locations) {
      print(
          'Creating marker for: ${location.title} at (${location.latitude}, ${location.longitude})');
      markers.add(
        Marker(
          markerId: MarkerId(location.id),
          position: LatLng(location.latitude, location.longitude),
          infoWindow: InfoWindow(
            title: location.title,
            snippet: location.description,
          ),
          onTap: () => _onMarkerTap(location),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
    print('Set ${_markers.length} markers on map');
  }

  void _onMarkerTap(ShopLocation location) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationDetailScreen(location: location),
      ),
    );
  }

  Future<void> _onMapTap(LatLng position) async {
    // Show dialog to add new location
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorsManager.surface,
        title: Text(
          'Add Location Pin',
          style: AppTypography.headlineSmall.copyWith(
            color: ColorsManager.onSurface,
          ),
        ),
        content: Text(
          'Do you want to add a new shop location pin at this position?',
          style: AppTypography.bodyMedium.copyWith(
            color: ColorsManager.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge.copyWith(
                color: ColorsManager.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Add Pin',
              style: AppTypography.labelLarge.copyWith(
                color: ColorsManager.primary,
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      final addResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddLocationScreen(
            initialPosition: position,
          ),
        ),
      );

      // Refresh the map if a location was added
      if (addResult == true) {
        _loadLocations();
      }
    }
  }

  Future<void> _searchLocations() async {
    if (_searchQuery.isEmpty) {
      await _loadLocations();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final locations = await _locationService.searchLocations(_searchQuery);
      setState(() {
        _locations = locations;
        _isLoading = false;
      });
      _updateMarkers();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    }
  }

  Future<void> _filterByCategory() async {
    if (_selectedCategory == 'All') {
      await _loadLocations();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final locations =
          await _locationService.getLocationsByCategory(_selectedCategory);
      setState(() {
        _locations = locations;
        _isLoading = false;
      });
      _updateMarkers();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Filter failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PublicProfileTheme.backgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: PublicProfileTheme.backgroundGradient,
              ),
              child: Column(
                children: [
                  _buildSearchBar(),
                  _buildCategoryFilter(),
                  Expanded(
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: _currentPosition != null
                              ? CameraPosition(
                                  target: LatLng(_currentPosition!.latitude,
                                      _currentPosition!.longitude),
                                  zoom: 15,
                                )
                              : _defaultPosition,
                          markers: _markers,
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                            if (_currentPosition != null) {
                              controller.animateCamera(
                                CameraUpdate.newLatLng(
                                  LatLng(_currentPosition!.latitude,
                                      _currentPosition!.longitude),
                                ),
                              );
                            }
                          },
                          onTap: _onMapTap,
                          myLocationEnabled: _locationPermissionGranted,
                          myLocationButtonEnabled: _locationPermissionGranted,
                          zoomControlsEnabled: true,
                          mapType: MapType.normal,
                        ),
                        if (_isLoading || _isRequestingLocation)
                          Container(
                            color: Colors.black.withValues(alpha: 0.3),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(
                                    color: ColorsManager.primary,
                                  ),
                                  SizedBox(height: 16.h),
                                  Text(
                                    _isRequestingLocation
                                        ? 'Requesting location permission...'
                                        : 'Loading locations...',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_locationPermissionGranted &&
                            _currentPosition != null)
                          Positioned(
                            top: 16.h,
                            right: 16.w,
                            child: FloatingActionButton(
                              mini: true,
                              onPressed: _getCurrentLocation,
                              backgroundColor: ColorsManager.primary,
                              child: const Icon(
                                Icons.my_location,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final position = _currentPosition != null
              ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
              : null;

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddLocationScreen(
                initialPosition: position,
              ),
            ),
          );

          if (result == true) {
            _loadLocations();
          }
        },
        backgroundColor: ColorsManager.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, topPadding + 6.h, 20.w, 6.h),
      decoration: const BoxDecoration(
        gradient: _shopHeroGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Gap(8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Shop Map',
                  style: AppTypography.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Gap(4.h),
                Text(
                  'Find community gear spots & pro shops near you.',
                  style: AppTypography.bodyMedium
                      .copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          Row(
            children: [
              if (!_locationPermissionGranted)
                IconButton(
                  onPressed: _requestLocationPermission,
                  icon: const Icon(Icons.location_on, color: Colors.white),
                  tooltip: 'Enable Location',
                ),
              IconButton(
                onPressed: _loadLocations,
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Expanded(
              child: AppTextField(
                hintText: 'Search locations...',
                prefixIcon: const Icon(Icons.search),
                onChanged: (value) => setState(() => _searchQuery = value),
                onSubmitted: (_) => _searchLocations(),
              ),
            ),
            Gap(12.w),
            AppFilledButton(
              text: 'Search',
              onPressed: _searchLocations,
              size: ButtonSize.small,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 48.h,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          return Padding(
            padding: EdgeInsets.only(right: 10.w),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedCategory = category);
                _filterByCategory();
              },
              selectedColor: ColorsManager.mainBlue,
              backgroundColor: Colors.white.withOpacity(0.05),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
          );
        },
      ),
    );
  }
}
