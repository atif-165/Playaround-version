import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../theming/colors.dart';
import 'tabs/venues_tab.dart';
import 'tabs/teams_tab.dart';
import 'tabs/players_tab.dart';
import 'tabs/tournaments_tab.dart';
import 'widgets/explore_search_bar.dart';
import 'widgets/explore_filter_button.dart';

/// Main explore screen with tabs for different content types
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  Map<String, dynamic> _filters = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onFiltersChanged(Map<String, dynamic> filters) {
    setState(() {
      _filters = filters;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Explore',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(120.h),
          child: Column(
            children: [
              // Search and Filter Row
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Row(
                  children: [
                    Expanded(
                      child: ExploreSearchBar(
                        onSearchChanged: _onSearchChanged,
                        hintText: 'Search venues, teams, players...',
                      ),
                    ),
                    Gap(12.w),
                    ExploreFilterButton(
                      onFiltersChanged: _onFiltersChanged,
                      currentFilters: _filters,
                    ),
                  ],
                ),
              ),
              
              // Tab Bar
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: ColorsManager.mainBlue,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: ColorsManager.mainBlue,
                  indicatorWeight: 3,
                  labelStyle: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.location_city, size: 20),
                      text: 'Venues',
                    ),
                    Tab(
                      icon: Icon(Icons.groups, size: 20),
                      text: 'Teams',
                    ),
                    Tab(
                      icon: Icon(Icons.person, size: 20),
                      text: 'Players',
                    ),
                    Tab(
                      icon: Icon(Icons.emoji_events, size: 20),
                      text: 'Tournaments',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          VenuesTab(
            searchQuery: _searchQuery,
            filters: _filters,
          ),
          TeamsTab(
            searchQuery: _searchQuery,
            filters: _filters,
          ),
          PlayersTab(
            searchQuery: _searchQuery,
            filters: _filters,
          ),
          TournamentsTab(
            searchQuery: _searchQuery,
            filters: _filters,
          ),
        ],
      ),
    );
  }
}
