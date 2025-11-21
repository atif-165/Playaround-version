import 'package:flutter/material.dart';
import '../../../models/venue_review.dart';

class VenueFiltersBottomSheet extends StatefulWidget {
  final VenueFilter currentFilter;
  final Function(VenueFilter) onApplyFilters;

  const VenueFiltersBottomSheet({
    Key? key,
    required this.currentFilter,
    required this.onApplyFilters,
  }) : super(key: key);

  @override
  State<VenueFiltersBottomSheet> createState() =>
      _VenueFiltersBottomSheetState();
}

class _VenueFiltersBottomSheetState extends State<VenueFiltersBottomSheet> {
  late VenueFilter _filter;

  final List<String> _sports = [
    'Football',
    'Basketball',
    'Tennis',
    'Badminton',
    'Volleyball',
    'Cricket',
    'Hockey',
    'Swimming',
    'Gym',
    'Squash',
  ];

  final List<String> _amenities = [
    'Parking',
    'Changing Rooms',
    'Lighting',
    'Air Conditioning',
    'WiFi',
    'Cafeteria',
    'First Aid',
    'Equipment Rental',
    'Shower Facilities',
    'Locker Rooms',
  ];

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter.copyWith();
  }

  void _resetFilters() {
    setState(() {
      _filter = VenueFilter();
    });
  }

  void _applyFilters() {
    widget.onApplyFilters(_filter);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Filters',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _resetFilters,
                  child:
                      const Text('Reset', style: TextStyle(color: Colors.blue)),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price Range
                  _buildSectionTitle('Price Range'),
                  const SizedBox(height: 12),
                  RangeSlider(
                    values: RangeValues(
                      _filter.minPrice ?? 0,
                      _filter.maxPrice ?? 200,
                    ),
                    min: 0,
                    max: 200,
                    divisions: 20,
                    labels: RangeLabels(
                      '\$${(_filter.minPrice ?? 0).toInt()}',
                      '\$${(_filter.maxPrice ?? 200).toInt()}',
                    ),
                    onChanged: (values) {
                      setState(() {
                        _filter = _filter.copyWith(
                          minPrice: values.start,
                          maxPrice: values.end,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  // Rating
                  _buildSectionTitle('Minimum Rating'),
                  const SizedBox(height: 12),
                  Slider(
                    value: _filter.minRating ?? 0,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    label:
                        '${(_filter.minRating ?? 0).toStringAsFixed(1)} stars',
                    onChanged: (value) {
                      setState(() {
                        _filter = _filter.copyWith(minRating: value);
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  // Sports
                  _buildSectionTitle('Sports'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _sports.map((sport) {
                      final isSelected = _filter.sports.contains(sport);
                      return FilterChip(
                        label: Text(sport),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _filter = _filter.copyWith(
                                sports: [..._filter.sports, sport],
                              );
                            } else {
                              _filter = _filter.copyWith(
                                sports: _filter.sports
                                    .where((s) => s != sport)
                                    .toList(),
                              );
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Amenities
                  _buildSectionTitle('Amenities'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _amenities.map((amenity) {
                      final isSelected = _filter.amenities.contains(amenity);
                      return FilterChip(
                        label: Text(amenity),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _filter = _filter.copyWith(
                                amenities: [..._filter.amenities, amenity],
                              );
                            } else {
                              _filter = _filter.copyWith(
                                amenities: _filter.amenities
                                    .where((a) => a != amenity)
                                    .toList(),
                              );
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Verification
                  _buildSectionTitle('Verification'),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Verified venues only',
                        style: TextStyle(color: Colors.white)),
                    value: _filter.isVerified ?? false,
                    onChanged: (value) {
                      setState(() {
                        _filter = _filter.copyWith(isVerified: value);
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),
                  // Availability
                  _buildSectionTitle('Availability'),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Available today',
                        style: TextStyle(color: Colors.white)),
                    value: _filter.hasAvailability ?? false,
                    onChanged: (value) {
                      setState(() {
                        _filter = _filter.copyWith(
                          hasAvailability: value,
                          availableDate: value ? DateTime.now() : null,
                        );
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),
                  // Sort By
                  _buildSectionTitle('Sort By'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _filter.sortBy ?? 'rating',
                    style: const TextStyle(color: Colors.white),
                    dropdownColor: Colors.black,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      fillColor: Colors.black,
                      filled: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'rating',
                          child: Text('Rating',
                              style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(
                          value: 'price',
                          child: Text('Price',
                              style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(
                          value: 'distance',
                          child: Text('Distance',
                              style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(
                          value: 'newest',
                          child: Text('Newest',
                              style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filter = _filter.copyWith(sortBy: value);
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Bottom Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
    );
  }
}
