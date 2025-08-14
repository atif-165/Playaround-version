import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/chat_message.dart';
import '../widgets/entity_card.dart';

/// Screen for selecting entities to share in chat
class EntitySelectorScreen extends StatefulWidget {
  final Function(SharedEntity) onEntitySelected;

  const EntitySelectorScreen({
    super.key,
    required this.onEntitySelected,
  });

  @override
  State<EntitySelectorScreen> createState() => _EntitySelectorScreenState();
}

class _EntitySelectorScreenState extends State<EntitySelectorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.chatBackground,
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfilesTab(),
          _buildVenuesTab(),
          _buildTeamsTab(),
          _buildTournamentsTab(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Share',
        style: TextStyles.font18DarkBlue600Weight,
      ),
      backgroundColor: ColorsManager.neonBlue,
      foregroundColor: ColorsManager.darkBlue,
      elevation: 0,
      bottom: TabBar(
        controller: _tabController,
        labelColor: ColorsManager.mainBlue,
        unselectedLabelColor: ColorsManager.gray,
        indicatorColor: ColorsManager.mainBlue,
        isScrollable: true,
        tabs: const [
          Tab(text: 'Profiles'),
          Tab(text: 'Venues'),
          Tab(text: 'Teams'),
          Tab(text: 'Tournaments'),
        ],
      ),
    );
  }

  Widget _buildProfilesTab() {
    // Mock data - in a real app, this would come from a service
    final profiles = [
      EntityHelper.fromUserProfile(
        id: 'profile_1',
        name: 'John Doe',
        imageUrl: 'https://example.com/profile1.jpg',
        location: 'New York',
        role: 'Coach',
      ),
      EntityHelper.fromUserProfile(
        id: 'profile_2',
        name: 'Jane Smith',
        imageUrl: 'https://example.com/profile2.jpg',
        location: 'Los Angeles',
        role: 'Player',
      ),
    ];

    return _buildEntityList(profiles, 'No profiles to share');
  }

  Widget _buildVenuesTab() {
    // Mock data - in a real app, this would come from a service
    final venues = [
      EntityHelper.fromVenue(
        id: 'venue_1',
        name: 'Central Sports Complex',
        imageUrl: 'https://example.com/venue1.jpg',
        location: 'Downtown',
        rating: 4.5,
        priceRange: '\$\$',
      ),
      EntityHelper.fromVenue(
        id: 'venue_2',
        name: 'Elite Fitness Center',
        imageUrl: 'https://example.com/venue2.jpg',
        location: 'Uptown',
        rating: 4.8,
        priceRange: '\$\$\$',
      ),
    ];

    return _buildEntityList(venues, 'No venues to share');
  }

  Widget _buildTeamsTab() {
    // Mock data - in a real app, this would come from a service
    final teams = [
      EntityHelper.fromTeam(
        id: 'team_1',
        name: 'Thunder Bolts',
        imageUrl: 'https://example.com/team1.jpg',
        sport: 'Basketball',
        memberCount: 12,
        location: 'New York',
      ),
      EntityHelper.fromTeam(
        id: 'team_2',
        name: 'Fire Dragons',
        imageUrl: 'https://example.com/team2.jpg',
        sport: 'Soccer',
        memberCount: 18,
        location: 'Los Angeles',
      ),
    ];

    return _buildEntityList(teams, 'No teams to share');
  }

  Widget _buildTournamentsTab() {
    // Mock data - in a real app, this would come from a service
    final tournaments = [
      EntityHelper.fromTournament(
        id: 'tournament_1',
        name: 'Summer Championship',
        imageUrl: 'https://example.com/tournament1.jpg',
        sport: 'Tennis',
        location: 'Miami',
        date: 'July 15-20',
        prizePool: '\$10,000',
      ),
      EntityHelper.fromTournament(
        id: 'tournament_2',
        name: 'City League Finals',
        imageUrl: 'https://example.com/tournament2.jpg',
        sport: 'Basketball',
        location: 'Chicago',
        date: 'August 5-7',
        prizePool: '\$5,000',
      ),
    ];

    return _buildEntityList(tournaments, 'No tournaments to share');
  }

  Widget _buildEntityList(List<SharedEntity> entities, String emptyMessage) {
    if (entities.isEmpty) {
      return _buildEmptyState(emptyMessage);
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: entities.length,
      itemBuilder: (context, index) {
        final entity = entities[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: EntityCard(
            entity: entity,
            onTap: () => _selectEntity(entity),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80.sp,
              color: ColorsManager.gray76,
            ),
            Gap(24.h),
            Text(
              'Nothing to share',
              style: TextStyles.font18DarkBlue600Weight,
              textAlign: TextAlign.center,
            ),
            Gap(8.h),
            Text(
              message,
              style: TextStyles.font14Grey400Weight,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _selectEntity(SharedEntity entity) {
    widget.onEntitySelected(entity);
    Navigator.of(context).pop();
  }
}

/// Helper function to show entity selector bottom sheet
void showEntitySelector({
  required BuildContext context,
  required Function(SharedEntity) onEntitySelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: EntitySelectorScreen(onEntitySelected: onEntitySelected),
    ),
  );
}
