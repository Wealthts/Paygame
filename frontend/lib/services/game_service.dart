import 'package:frontend/models/paygame_models.dart';
import 'package:frontend/services/api_service.dart';

class GameService {
  // Get all games for Admin
  static Future<List<GameModel>> getAdminGames() async {
    final response = await ApiService.get('/games/admin/all');

    List<dynamic> data;

    if (response is List) {
      data = response;
    } else if (response is Map && response['data'] is List) {
      data = response['data'];
    } else if (response is Map && response['games'] is List) {
      data = response['games'];
    } else {
      throw Exception('Invalid games response');
    }

    List<GameModel> games = [];

    for (var item in data) {
      games.add(GameModel.fromJson(item));
    }

    return games;
  }

  // Get active games for User
  static Future<List<GameModel>> getActiveGames() async {
    final response = await ApiService.get('/games', requiresAuth: false);

    List<dynamic> data;

    if (response is List) {
      data = response;
    } else if (response is Map && response['data'] is List) {
      data = response['data'];
    } else {
      throw Exception('Invalid games response');
    }

    List<GameModel> games = [];

    for (var item in data) {
      games.add(GameModel.fromJson(item));
    }

    return games;
  }

  // Add new game
  static Future<dynamic> addGame(GameModel game) async {
    return await ApiService.post('/games', game.toJson());
  }

  // Update game
  static Future<dynamic> updateGame(GameModel game) async {
    return await ApiService.put('/games/${game.gameId}', game.toJson());
  }

  // Delete game (Soft Delete)
  static Future<dynamic> deleteGame(String gameId) async {
    return await ApiService.delete('/games/$gameId');
  }
}
