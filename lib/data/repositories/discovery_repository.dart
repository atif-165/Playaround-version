import '../datasources/mock_data_source.dart';
import '../models/listing_model.dart';
import '../models/player_model.dart';
import '../models/team_model.dart';
import '../models/venue_model.dart';
import 'matchmaking_repository.dart';

class DiscoveryRepository {
  DiscoveryRepository({
    MatchmakingRepository? matchmakingRepository,
    MockDataSource? mockDataSource,
  })  : _matchmakingRepository =
            matchmakingRepository ?? MatchmakingRepository(),
        _mockDataSource = mockDataSource ?? MockDataSource();

  final MatchmakingRepository _matchmakingRepository;
  final MockDataSource _mockDataSource;

  Future<List<PlayerModel>> loadPlayers() =>
      _matchmakingRepository.loadPlayers();

  Future<List<TeamModel>> loadTeams() => _matchmakingRepository.loadTeams();

  Future<List<VenueModel>> loadVenues() => _matchmakingRepository.loadVenues();

  Future<List<ListingModel>> loadListings() => _mockDataSource.loadListings();
}
