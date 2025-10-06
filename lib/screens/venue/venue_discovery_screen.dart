import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/venue.dart';
import '../../models/venue_review.dart';
import '../../services/venue_service.dart';
import '../../core/widgets/app_text_form_field.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/error_widget.dart';
import '../venue/widgets/venue_card.dart';
import '../venue/widgets/venue_filters_bottom_sheet.dart';
import '../venue/widgets/venue_map_view.dart';
import '../venue/venue_profile_screen.dart';

class VenueDiscoveryScreen extends StatefulWidget {
  const VenueDiscoveryScreen({super.key});

  @override
  State<VenueDiscoveryScreen> createState() => _VenueDiscoveryScreenState();
}

class _VenueDiscoveryScreenState extends State<VenueDiscoveryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Venue> _venues = [];
  List<Venue> _filteredVenues = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  VenueFilter _currentFilter = VenueFilter();
  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;

  // Map related
  final Set<Marker> _markers = {};
  LatLng? _currentLocation;
  bool _isMapView = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    _getCurrentLocation();
    _loadVenues();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    setState(() {
      _isMapView = _tabController.index == 1;
    });
    if (_isMapView) {
      _updateMapMarkers();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMoreVenues();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _loadVenues({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _error = null;
        _lastDocument = null;
        _hasMoreData = true;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      List<Venue> venues = await VenueService.getVenues(
        filter: _currentFilter,
        lastDocument: _lastDocument,
      );

      setState(() {
        if (refresh) {
          _venues = venues;
        } else {
          _venues.addAll(venues);
        }
        _filteredVenues = _venues;
        _lastDocument = venues.isNotEmpty ? null : _lastDocument;
        _hasMoreData = venues.length >= 20;
        _isLoading = false;
        _isLoadingMore = false;
        _error = null;
      });

      if (_isMapView) {
        _updateMapMarkers();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMoreVenues() async {
    await _loadVenues(refresh: false);
  }

  void _updateMapMarkers() {
    _markers.clear();
    for (Venue venue in _filteredVenues) {
      _markers.add(
        Marker(
          markerId: MarkerId(venue.id),
          position: LatLng(venue.latitude, venue.longitude),
          infoWindow: InfoWindow(
            title: venue.name,
            snippet: venue.address,
          ),
          onTap: () => _navigateToVenueProfile(venue),
        ),
      );
    }
    setState(() {});
  }

  void _onSearchChanged(String query) {
    setState(() {
      _currentFilter = _currentFilter.copyWith(searchQuery: query);
    });
    _performSearch();
  }

  void _performSearch() {
    if (_currentFilter.searchQuery?.isEmpty ?? true) {
      setState(() {
        _filteredVenues = _venues;
      });
    } else {
      setState(() {
        _filteredVenues = _venues.where((venue) {
          String searchQuery = _currentFilter.searchQuery!.toLowerCase();
          return venue.name.toLowerCase().contains(searchQuery) ||
              venue.description.toLowerCase().contains(searchQuery) ||
              venue.address.toLowerCase().contains(searchQuery) ||
              venue.sports.any((sport) => sport.toLowerCase().contains(searchQuery));
        }).toList();
      });
    }
    if (_isMapView) {
      _updateMapMarkers();
    }
  }

  Future<void> _showFilters() async {
    final VenueFilter? result = await showModalBottomSheet<VenueFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VenueFiltersBottomSheet(
        currentFilter: _currentFilter,
        onApplyFilters: (filter) {
          setState(() {
            _currentFilter = filter;
          });
          _loadVenues(refresh: true);
        },
      ),
    );

    if (result != null) {
      setState(() {
        _currentFilter = result;
      });
      _loadVenues(refresh: true);
    }
  }

  void _navigateToVenueProfile(Venue venue) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VenueProfileScreen(venue: venue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Venues'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'List'),
            Tab(icon: Icon(Icons.map), text: 'Map'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search venues, sports, locations...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      fillColor: Colors.black,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _showFilters,
                  icon: const Icon(Icons.filter_list, color: Colors.white),
                  tooltip: 'Filters',
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildListView(),
                _buildMapView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    if (_isLoading && _venues.isEmpty) {
      return const Center(child: LoadingWidget());
    }

    if (_error != null) {
      return Center(
        child: AppErrorWidget(
          message: _error!,
          onRetry: () => _loadVenues(refresh: true),
        ),
      );
    }

    if (_filteredVenues.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No venues found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadVenues(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredVenues.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _filteredVenues.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final venue = _filteredVenues[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: VenueCard(
              venue: venue,
              onTap: () => _navigateToVenueProfile(venue),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapView() {
    if (_currentLocation == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Getting your location...'),
          ],
        ),
      );
    }

    return VenueMapView(
      venues: _filteredVenues,
      currentLocation: _currentLocation!,
      onVenueTap: _navigateToVenueProfile,
    );
  }
}
