import 'services/auth_service.dart';
import 'services/game_service.dart';

class GamesApiClient {
  final String baseUrl;
  final String apiKey;
  late final AuthService auth;
  late final GameService games;

  GamesApiClient({
    required this.baseUrl,
    required this.apiKey,
  }) {
    auth = AuthService(
      baseUrl: baseUrl,
      apiKey: apiKey,
    );
    games = GameService(
      baseUrl: baseUrl,
      apiKey: apiKey,
      authService: auth,
    );
  }

  /// Create client for development (localhost)
  factory GamesApiClient.development() {
    return GamesApiClient(
      baseUrl: 'http://localhost:8100',
      apiKey: 'change_me_in_production_api_key',
    );
  }

  /// Create client for production
  factory GamesApiClient.production() {
    return GamesApiClient(
      baseUrl: 'https://games-api.base.al',
      apiKey: 'change_me_in_production_api_key',
    );
  }
}
