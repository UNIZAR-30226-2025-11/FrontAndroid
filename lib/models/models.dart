// lib/models.dart


class BackendNotifyActionJSON {
  final bool error;
  final String errorMsg;
  final int creatorId;
  final int actionedPlayerId;
  final String action;

  BackendNotifyActionJSON({
    required this.error,
    required this.errorMsg,
    required this.creatorId,
    required this.actionedPlayerId,
    required this.action,
  });

  factory BackendNotifyActionJSON.fromJson(Map<String, dynamic> json) {
    return BackendNotifyActionJSON(
      error: json['error'],
      errorMsg: json['errorMsg'],
      creatorId: json['creatorId'],
      actionedPlayerId: json['actionedPlayerId'],
      action: json['action'],
    );
  }
}

// lib/models.dart

class PlayerJSON {
  final int id;
  final int numCards;
  final bool active;

  PlayerJSON({required this.id, required this.numCards, required this.active});

  factory PlayerJSON.fromJson(Map<String, dynamic> json) {
    return PlayerJSON(
      id: json['id'],
      numCards: json['numCards'],
      active: json['active'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numCards': numCards,
      'active': active,
    };
  }
}

class BackendStateUpdateJSON {
  final bool error;
  final String errorMsg;
  final String playerCards;
  final List<PlayerJSON> players;
  final int turn;
  final int timeOut;
  final int playerId;

  BackendStateUpdateJSON({
    required this.error,
    required this.errorMsg,
    required this.playerCards,
    required this.players,
    required this.turn,
    required this.timeOut,
    required this.playerId,
  });

  factory BackendStateUpdateJSON.fromJson(Map<String, dynamic> json) {
    return BackendStateUpdateJSON(
      error: json['error'],
      errorMsg: json['errorMsg'],
      playerCards: json['playerCards'],
      players: (json['players'] as List)
          .map((player) => PlayerJSON.fromJson(player))
          .toList(),
      turn: json['turn'],
      timeOut: json['timeOut'],
      playerId: json['playerId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'playerCards': playerCards,
      'players': players.map((player) => player.toJson()).toList(),
      'turn': turn,
      'timeOut': timeOut,
      'playerId': playerId,
    };
  }
}

class FrontendGamePlayedCardsJSON {
  final bool error;
  final String errorMsg;
  final String playedCards;
  final String lobbyId;

  FrontendGamePlayedCardsJSON({
    required this.error,
    required this.errorMsg,
    required this.playedCards,
    required this.lobbyId,
  });

  factory FrontendGamePlayedCardsJSON.fromJson(Map<String, dynamic> json) {
    return FrontendGamePlayedCardsJSON(
      error: json['error'],
      errorMsg: json['errorMsg'],
      playedCards: json['playedCards'],
      lobbyId: json['lobbyId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'playedCards': playedCards,
      'lobbyId': lobbyId,
    };
  }
}

class BackendGamePlayedCardsResponseJSON {
  final bool error;
  final String errorMsg;
  final String cardsSeeFuture;
  final bool hasShuffled;
  final bool skipTurn;
  final bool hasWonAttack;
  final bool hasStolenRandomCard;
  final bool hasStolenCardByType;

  BackendGamePlayedCardsResponseJSON({
    required this.error,
    required this.errorMsg,
    required this.cardsSeeFuture,
    required this.hasShuffled,
    required this.skipTurn,
    required this.hasWonAttack,
    required this.hasStolenRandomCard,
    required this.hasStolenCardByType,
  });

  factory BackendGamePlayedCardsResponseJSON.fromJson(Map<String, dynamic> json) {
    return BackendGamePlayedCardsResponseJSON(
      error: json['error'],
      errorMsg: json['errorMsg'],
      cardsSeeFuture: json['cardsSeeFuture'],
      hasShuffled: json['hasShuffled'],
      skipTurn: json['skipTurn'],
      hasWonAttack: json['hasWonAttack'],
      hasStolenRandomCard: json['hasStolenRandomCard'],
      hasStolenCardByType: json['hasStolenCardByType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'cardsSeeFuture': cardsSeeFuture,
      'hasShuffled': hasShuffled,
      'skipTurn': skipTurn,
      'hasWonAttack': hasWonAttack,
      'hasStolenRandomCard': hasStolenRandomCard,
      'hasStolenCardByType': hasStolenCardByType,
    };
  }
}

class BackendWinnerJSON {
  final bool error;
  final String errorMsg;
  final int userId;
  final int coinsEarned;

  BackendWinnerJSON({
    required this.error,
    required this.errorMsg,
    required this.userId,
    required this.coinsEarned,
  });

  factory BackendWinnerJSON.fromJson(Map<String, dynamic> json) {
    return BackendWinnerJSON(
      error: json['error'],
      errorMsg: json['errorMsg'],
      userId: json['userId'],
      coinsEarned: json['coinsEarned'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'userId': userId,
      'coinsEarned': coinsEarned,
    };
  }
}

class BackendGameSelectPlayerJSON {
  final bool error;
  final String errorMsg;
  final String lobbyId;

  BackendGameSelectPlayerJSON({
    required this.error,
    required this.errorMsg,
    required this.lobbyId,
  });

  factory BackendGameSelectPlayerJSON.fromJson(Map<String, dynamic> json) {
    return BackendGameSelectPlayerJSON(
      error: json['error'],
      errorMsg: json['errorMsg'],
      lobbyId: json['lobbyId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'lobbyId': lobbyId,
    };
  }
}

class FrontendGameSelectPlayerResponseJSON {
  final bool error;
  final String errorMsg;
  final int userId;
  final String lobbyId;

  FrontendGameSelectPlayerResponseJSON({
    required this.error,
    required this.errorMsg,
    required this.userId,
    required this.lobbyId,
  });

  factory FrontendGameSelectPlayerResponseJSON.fromJson(Map<String, dynamic> json) {
    return FrontendGameSelectPlayerResponseJSON(
      error: json['error'],
      errorMsg: json['errorMsg'],
      userId: json['userId'],
      lobbyId: json['lobbyId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'userId': userId,
      'lobbyId': lobbyId,
    };
  }
}

class BackendGameSelectCardJSON {
  final bool error;
  final String errorMsg;
  final String lobbyId;

  BackendGameSelectCardJSON({
    required this.error,
    required this.errorMsg,
    required this.lobbyId,
  });

  factory BackendGameSelectCardJSON.fromJson(Map<String, dynamic> json) {
    return BackendGameSelectCardJSON(
      error: json['error'],
      errorMsg: json['errorMsg'],
      lobbyId: json['lobbyId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'lobbyId': lobbyId,
    };
  }
}

class FrontendGameSelectCardResponseJSON {
  final bool error;
  final String errorMsg;
  final String card;
  final String lobbyId;

  FrontendGameSelectCardResponseJSON({
    required this.error,
    required this.errorMsg,
    required this.card,
    required this.lobbyId,
  });

  factory FrontendGameSelectCardResponseJSON.fromJson(Map<String, dynamic> json) {
    return FrontendGameSelectCardResponseJSON(
      error: json['error'],
      errorMsg: json['errorMsg'],
      card: json['card'],
      lobbyId: json['lobbyId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'card': card,
      'lobbyId': lobbyId,
    };
  }
}

class BackendGameSelectCardTypeJSON {
  final bool error;
  final String errorMsg;
  final String lobbyId;

  BackendGameSelectCardTypeJSON({
    required this.error,
    required this.errorMsg,
    required this.lobbyId,
  });

  factory BackendGameSelectCardTypeJSON.fromJson(Map<String, dynamic> json) {
    return BackendGameSelectCardTypeJSON(
      error: json['error'],
      errorMsg: json['errorMsg'],
      lobbyId: json['lobbyId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'lobbyId': lobbyId,
    };
  }
}

class FrontendGameSelectCardTypeResponseJSON {
  final bool error;
  final String errorMsg;
  final String cardType;
  final String lobbyId;

  FrontendGameSelectCardTypeResponseJSON({
    required this.error,
    required this.errorMsg,
    required this.cardType,
    required this.lobbyId,
  });

  factory FrontendGameSelectCardTypeResponseJSON.fromJson(Map<String, dynamic> json) {
    return FrontendGameSelectCardTypeResponseJSON(
      error: json['error'],
      errorMsg: json['errorMsg'],
      cardType: json['cardType'],
      lobbyId: json['lobbyId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'cardType': cardType,
      'lobbyId': lobbyId,
    };
  }
}

class FrontendCreateLobbyJSON {
  final bool error;
  final String errorMsg;
  final int maxPlayers;

  FrontendCreateLobbyJSON({
    required this.error,
    required this.errorMsg,
    required this.maxPlayers,
  });

  factory FrontendCreateLobbyJSON.fromJson(Map<String, dynamic> json) {
    return FrontendCreateLobbyJSON(
      error: json['error'],
      errorMsg: json['errorMsg'],
      maxPlayers: json['maxPlayers'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'maxPlayers': maxPlayers,
    };
  }
}

class BackendCreateLobbyResponseJSON {
  final bool error;
  final String errorMsg;
  final String lobbyId;

  BackendCreateLobbyResponseJSON({
    required this.error,
    required this.errorMsg,
    required this.lobbyId,
  });

  factory BackendCreateLobbyResponseJSON.fromJson(Map<String, dynamic> json) {
    return BackendCreateLobbyResponseJSON(
      error: json['error'],
      errorMsg: json['errorMsg'],
      lobbyId: json['lobbyId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'lobbyId': lobbyId,
    };
  }
}

class FrontendJoinLobbyJSON {
  final bool error;
  final String errorMsg;
  final String lobbyId;

  FrontendJoinLobbyJSON({
    required this.error,
    required this.errorMsg,
    required this.lobbyId,
  });

  factory FrontendJoinLobbyJSON.fromJson(Map<String, dynamic> json) {
    return FrontendJoinLobbyJSON(
      error: json['error'],
      errorMsg: json['errorMsg'],
      lobbyId: json['lobbyId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'lobbyId': lobbyId,
    };
  }
}

class BackendJoinLobbyResponseJSON {
  final bool error;
  final String errorMsg;

  BackendJoinLobbyResponseJSON({
    required this.error,
    required this.errorMsg,
  });

  factory BackendJoinLobbyResponseJSON.fromJson(Map<String, dynamic> json) {
    return BackendJoinLobbyResponseJSON(
      error: json['error'],
      errorMsg: json['errorMsg'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
    };
  }
}
