import 'package:flutter/material.dart';

// lib/models.dart

enum CardType {
  Bomb,
  SeeFuture,
  Shuffle,
  Skip,
  Attack,
  Favor,
  Deactivate,
  RainbowCat,
  TacoCat,
  HairyPotatoCat,
  Cattermelon,
  BeardCat
}

enum ActionType {
  ShuffleDeck,
  Attack,
  AttackFailed,
  CardReceived,
  BombDefused,
  BombExploded,
  DrawCard,
  SkipTurn,
  FutureSeen,
  NopeUsed,
  FavorAttack,
  TwoWildCardAttackSuccessful,
  ThreeWildCardAttackSuccessful,
  AskingNope,
  AskingPlayer,
  AskingCard,
  AskingCardType,
}

class PlayerJSON {
  final String playerUsername;
  final int numCards;
  final bool active;

  PlayerJSON(
      {required this.playerUsername,
      required this.numCards,
      required this.active});

  factory PlayerJSON.fromJson(Map<String, dynamic> json) {
    return PlayerJSON(
      playerUsername: json['playerUsername'],
      numCards: json['numCards'],
      active: json['active'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerUsername': playerUsername,
      'numCards': numCards,
      'active': active,
    };
  }
}

class CardJSON {
  final int id;
  final String type;

  CardJSON({
    required this.id,
    required this.type,
  });

  factory CardJSON.fromJson(Map<String, dynamic> json) {
    return CardJSON(
      id: json['id'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
    };
  }
}

class BackendStateUpdateJSON {
  final bool error;
  final String errorMsg;
  final String lobbyID;
  final List<CardJSON> playerCards;
  final List<PlayerJSON> players;
  final String turnUsername;
  final int timeOut;
  final String username;
  final int cardsLeftInDeck;

  BackendStateUpdateJSON({
    required this.error,
    required this.errorMsg,
    required this.lobbyID,
    required this.playerCards,
    required this.players,
    required this.turnUsername,
    required this.timeOut,
    required this.username,
    required this.cardsLeftInDeck,
  });

  factory BackendStateUpdateJSON.fromJson(Map<String, dynamic> json) {
    return BackendStateUpdateJSON(
        error: json['error'],
        errorMsg: json['errorMsg'],
        lobbyID: json['lobbyID'],
        playerCards: (json['playerCards'] as List)
            .map((cards) => CardJSON.fromJson(cards))
            .toList(),
        players: (json['players'] as List)
            .map((player) => PlayerJSON.fromJson(player))
            .toList(),
        turnUsername: json['turnUsername'],
        timeOut: json['timeOut'],
        username: json['playerUsername'],
        cardsLeftInDeck: json['cardsLeftInDeck']);
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'lobbyID': lobbyID,
      'playerCards': playerCards.map((cards) => cards.toJson()).toList(),
      'players': players.map((player) => player.toJson()).toList(),
      'turnUsername': turnUsername,
      'timeOut': timeOut,
      'username': username,
      'cardsLeftInDeck': cardsLeftInDeck,
    };
  }
}

class FrontendGamePlayedCardsJSON {
  final bool error;
  final String errorMsg;
  final List<CardJSON> playedCards;
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
      playedCards: (json['playedCards'] as List)
          .map((cards) => CardJSON.fromJson(cards))
          .toList(),
      lobbyId: json['lobbyId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'playedCards': playedCards.map((cards) => cards.toJson()).toList(),
      'lobbyId': lobbyId,
    };
  }
}

class BackendGamePlayedCardsResponseJSON {
  final bool error;
  final String errorMsg;
  final List<CardJSON>? cardsSeeFuture;
  final CardJSON? cardReceived;

  BackendGamePlayedCardsResponseJSON(
      {required this.error,
      required this.errorMsg,
      required this.cardsSeeFuture,
      required this.cardReceived});

  factory BackendGamePlayedCardsResponseJSON.fromJson(
      Map<String, dynamic> json) {
    return BackendGamePlayedCardsResponseJSON(
      error: json['error'] ?? false,
      errorMsg: json['errorMsg'] ?? '',
      cardsSeeFuture: json['cardsSeeFuture'] != null
          ? (json['cardsSeeFuture'] as List)
          .map((cards) => CardJSON.fromJson(cards))
          .toList()
          : null,
      cardReceived: json['cardReceived'] != null
          ? CardJSON.fromJson(json['cardReceived'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'cardsSeeFuture': cardsSeeFuture,
      'cardsReceived': cardReceived,
    };
  }
}

class BackendWinnerJSON {
  final bool error;
  final String errorMsg;
  final String winnerUsername;
  final int coinsEarned;
  final String lobbyId;

  BackendWinnerJSON({
    required this.error,
    required this.errorMsg,
    required this.winnerUsername,
    required this.coinsEarned,
    required this.lobbyId,
  });

  factory BackendWinnerJSON.fromJson(Map<String, dynamic> json) {
    return BackendWinnerJSON(
        error: json['error'],
        errorMsg: json['errorMsg'],
        winnerUsername: json['winnerUsername'],
        coinsEarned: json['coinsEarned'],
        lobbyId: json['lobbyId']);
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'winnerUsername': winnerUsername,
      'coinsEarned': coinsEarned,
      'lobbyId': lobbyId,
    };
  }
}

class FrontendWinnerResponseJSON {
  final bool error;
  final String errorMsg;
  final String winnerUsername;
  final int coinsEarned;
  final String lobbyId;

  FrontendWinnerResponseJSON({
    required this.error,
    required this.errorMsg,
    required this.winnerUsername,
    required this.coinsEarned,
    required this.lobbyId,
  });

  factory FrontendWinnerResponseJSON.fromJson(Map<String, dynamic> json) {
    return FrontendWinnerResponseJSON(
        error: json['error'],
        errorMsg: json['errorMsg'],
        winnerUsername: json['winnerUsername'],
        coinsEarned: json['coinsEarned'],
        lobbyId: json['lobbyId']);
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'winnerUsername': winnerUsername,
      'coinsEarned': coinsEarned,
      'lobbyId': lobbyId,
    };
  }
}

class BackendGameSelectPlayerJSON {
  final bool error;
  final String errorMsg;
  final String lobbyId;
  final int timeOut;

  BackendGameSelectPlayerJSON({
    required this.error,
    required this.errorMsg,
    required this.lobbyId,
    required this.timeOut,
  });

  factory BackendGameSelectPlayerJSON.fromJson(Map<String, dynamic> json) {
    return BackendGameSelectPlayerJSON(
        error: json['error'],
        errorMsg: json['errorMsg'],
        lobbyId: json['lobbyId'],
        timeOut: json['timeOut']);
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'lobbyId': lobbyId,
      'timeOut': timeOut,
    };
  }
}

class FrontendGameSelectPlayerResponseJSON {
  final bool error;
  final String errorMsg;
  final String playerUsername;
  final String lobbyId;

  FrontendGameSelectPlayerResponseJSON({
    required this.error,
    required this.errorMsg,
    required this.playerUsername,
    required this.lobbyId,
  });

  factory FrontendGameSelectPlayerResponseJSON.fromJson(
      Map<String, dynamic> json) {
    return FrontendGameSelectPlayerResponseJSON(
      error: json['error'],
      errorMsg: json['errorMsg'],
      playerUsername: json['playerUsername'],
      lobbyId: json['lobbyId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'userId': playerUsername,
      'lobbyId': lobbyId,
    };
  }
}

class BackendGameSelectCardJSON {
  final bool error;
  final String errorMsg;
  final String lobbyId;
  final int timeOut;

  BackendGameSelectCardJSON({
    required this.error,
    required this.errorMsg,
    required this.lobbyId,
    required this.timeOut,
  });

  factory BackendGameSelectCardJSON.fromJson(Map<String, dynamic> json) {
    return BackendGameSelectCardJSON(
      error: json['error'],
      errorMsg: json['errorMsg'],
      lobbyId: json['lobbyId'],
      timeOut: json['timeOut'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'lobbyId': lobbyId,
      'timeOut': timeOut,
    };
  }
}

class FrontendGameSelectCardResponseJSON {
  final bool error;
  final String errorMsg;
  final CardJSON card;
  final String lobbyId;

  FrontendGameSelectCardResponseJSON({
    required this.error,
    required this.errorMsg,
    required this.card,
    required this.lobbyId,
  });

  factory FrontendGameSelectCardResponseJSON.fromJson(
      Map<String, dynamic> json) {
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
  final int timeOut;

  BackendGameSelectCardTypeJSON({
    required this.error,
    required this.errorMsg,
    required this.lobbyId,
    required this.timeOut,
  });

  factory BackendGameSelectCardTypeJSON.fromJson(Map<String, dynamic> json) {
    return BackendGameSelectCardTypeJSON(
      error: json['error'],
      errorMsg: json['errorMsg'],
      lobbyId: json['lobbyId'],
      timeOut: json['timeOut'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'lobbyId': lobbyId,
      'timeOut': timeOut,
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

  factory FrontendGameSelectCardTypeResponseJSON.fromJson(
      Map<String, dynamic> json) {
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

class BackendGameSelectNopeJSON {
  final bool error;
  final String errorMsg;
  final String lobbyId;
  final int timeOut;

  BackendGameSelectNopeJSON({
    required this.error,
    required this.errorMsg,
    required this.lobbyId,
    required this.timeOut,
  });

  factory BackendGameSelectNopeJSON.fromJson(Map<String, dynamic> json) {
    return BackendGameSelectNopeJSON(
      error: json['error'],
      errorMsg: json['errorMsg'],
      lobbyId: json['lobbyId'],
      timeOut: json['timeOut'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'lobbyId': lobbyId,
      'timeOut': timeOut,
    };
  }
}

class FrontendGameSelectNopeResponseJSON {
  final bool error;
  final String errorMsg;
  final bool useNope;
  final String lobbyId;

  FrontendGameSelectNopeResponseJSON({
    required this.error,
    required this.errorMsg,
    required this.useNope,
    required this.lobbyId,
  });

  factory FrontendGameSelectNopeResponseJSON.fromJson(
      Map<String, dynamic> json) {
    return FrontendGameSelectNopeResponseJSON(
      error: json['error'],
      errorMsg: json['errorMsg'],
      useNope: json['useNope'],
      lobbyId: json['lobbyId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'useNope': useNope,
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
  final String lobbyId;

  BackendJoinLobbyResponseJSON({
    required this.error,
    required this.errorMsg,
    required this.lobbyId,
  });

  factory BackendJoinLobbyResponseJSON.fromJson(Map<String, dynamic> json) {
    return BackendJoinLobbyResponseJSON(
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

class BackendLobbyStateUpdateJSON {
  final bool error;
  final String errorMsg;
  final List<PlayerLobbyJSON> players;
  final bool disband;
  final String lobbyId;

  BackendLobbyStateUpdateJSON({
    required this.error,
    required this.errorMsg,
    required this.players,
    required this.disband,
    required this.lobbyId,
  });

  factory BackendLobbyStateUpdateJSON.fromJson(Map<String, dynamic> json) {
    return BackendLobbyStateUpdateJSON(
        error: json['error'],
        errorMsg: json['errorMsg'],
        players: (json['players'] as List)
            .map((players) => PlayerLobbyJSON.fromJson(players))
            .toList(),
        disband: json['disband'],
        lobbyId: json['lobbyId']);
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'players': players,
      'disband': disband,
      'lobbyId': lobbyId,
    };
  }
}

class PlayerLobbyJSON {
  final String name;
  final bool isLeader;

  PlayerLobbyJSON({
    required this.name,
    required this.isLeader,
  });

  factory PlayerLobbyJSON.fromJson(Map<String, dynamic> json) {
    return PlayerLobbyJSON(
      name: json['name'],
      isLeader: json['isLeader'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isLeader': isLeader,
    };
  }
}

class FrontendStartLobbyJSON {
  final bool error;
  final String errorMsg;
  final String lobbyId;

  FrontendStartLobbyJSON({
    required this.error,
    required this.errorMsg,
    required this.lobbyId,
  });

  factory FrontendStartLobbyJSON.fromJson(Map<String, dynamic> json) {
    return FrontendStartLobbyJSON(
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

class BackendStartLobbyResponseJSON {
  final bool error;
  final String errorMsg;
  final int numPlayers;

  BackendStartLobbyResponseJSON({
    required this.error,
    required this.errorMsg,
    required this.numPlayers,
  });

  factory BackendStartLobbyResponseJSON.fromJson(Map<String, dynamic> json) {
    return BackendStartLobbyResponseJSON(
      error: json['error'],
      errorMsg: json['errorMsg'],
      numPlayers: json['numPlayers'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'numPlayers': numPlayers,
    };
  }
}

class BackendStartGameResponseJSON {
  final bool error;
  final String errorMsg;

  BackendStartGameResponseJSON({
    required this.error,
    required this.errorMsg,
  });

  factory BackendStartGameResponseJSON.fromJson(Map<String, dynamic> json) {
    return BackendStartGameResponseJSON(
        error: json['error'], errorMsg: json['errorMsg']);
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
    };
  }
}

class BackendNotifyActionJSON {
  final bool error;
  final String errorMsg;
  final String triggerUser;
  final String targetUser;
  final String action;

  BackendNotifyActionJSON({
    required this.error,
    required this.errorMsg,
    required this.triggerUser,
    required this.targetUser,
    required this.action,
  });

  factory BackendNotifyActionJSON.fromJson(Map<String, dynamic> json) {
    return BackendNotifyActionJSON(
      error: json['error'],
      errorMsg: json['errorMsg'],
      triggerUser: json['triggerUser'],
      targetUser: json['targetUser'],
      action: json['action'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'triggerUser': triggerUser,
      'targetUser': targetUser,
      'action': action,
    };
  }
}

class BackendPlayerStatusJSON {
  final bool error;
  final String errorMsg;
  final String playerUsername;
  final bool connected;

  BackendPlayerStatusJSON({
    required this.error,
    required this.errorMsg,
    required this.playerUsername,
    required this.connected,
  });

  factory BackendPlayerStatusJSON.fromJson(Map<String, dynamic> json) {
    return BackendPlayerStatusJSON(
      error: json['error'],
      errorMsg: json['errorMsg'],
      playerUsername: json['playerUsername'],
      connected: json['connected'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'playerUsername': playerUsername,
      'connected': connected,
    };
  }
}

class FrontendPostMsgJSON {
  final bool error;
  final String errorMsg;
  final String msg;
  final String lobbyId;

  FrontendPostMsgJSON({
    required this.error,
    required this.errorMsg,
    required this.msg,
    required this.lobbyId,
  });

  factory FrontendPostMsgJSON.fromJson(Map<String, dynamic> json) {
    return FrontendPostMsgJSON(
      error: json['error'],
      errorMsg: json['errorMsg'],
      msg: json['msg'],
      lobbyId: json['lobbyId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'msg': msg,
      'lobbyId': lobbyId,
    };
  }
}

class BackendGetMessagesJSON {
  final bool error;
  final String errorMsg;
  final List<MsgJSON> messages;
  final String lobbyId;

  BackendGetMessagesJSON({
    required this.error,
    required this.errorMsg,
    required this.messages,
    required this.lobbyId,
  });

  factory BackendGetMessagesJSON.fromJson(Map<String, dynamic> json) {
    return BackendGetMessagesJSON(
      error: json['error'],
      errorMsg: json['errorMsg'],
      messages: (json['messages'] as List)
          .map((msgs) => MsgJSON.fromJson(msgs))
          .toList(),
      lobbyId: json['lobbyId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'messages': messages,
      'lobbyId': lobbyId,
    };
  }
}

class MsgJSON {
  final String msg;
  final String username;
  final String date;

  MsgJSON({
    required this.msg,
    required this.username,
    required this.date,
  });

  factory MsgJSON.fromJson(Map<String, dynamic> json) {
    return MsgJSON(
      msg: json['msg'],
      username: json['username'],
      date: json['date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'msg': msg,
      'username': username,
      'date': date,
    };
  }
}


class UserPersonalizeData {
  String avatar;
  String background;

  UserPersonalizeData({
    this.avatar = 'assets/images/avatares/avatar1.png',
    this.background = 'assets/images/backgrounds/background.jpg',
  });

  factory UserPersonalizeData.fromJson(Map<String, dynamic> json) {
    return UserPersonalizeData(
      avatar: json['avatar'] ?? 'assets/images/avatares/avatar1.png',
      background: json['background'] ?? 'assets/images/backgrounds/background.jpg',
    );
  }

  Map<String, dynamic> toJson() => {
    'avatar': avatar,
    'background': background,
  };
}


// Clase para los registros de partidas
class RecordJSON {
  DateTime gameDate;
  bool isWinner;
  String lobbyId;

  RecordJSON({
    required this.gameDate,
    this.isWinner = false,
    this.lobbyId = '',
  });

  // Constructor desde JSON
  factory RecordJSON.fromJson(Map<String, dynamic> json) {
    return RecordJSON(
      gameDate: json['gameDate'] != null
          ? DateTime.parse(json['gameDate'])
          : DateTime.now(),
      isWinner: json['isWinner'] ?? false,
      lobbyId: json['lobbyId'] ?? '',
    );
  }

  // Convertir a JSON
  Map<String, dynamic> toJson() => {
    'gameDate': gameDate.toIso8601String(),
    'isWinner': isWinner,
    'lobbyId': lobbyId,
  };
}

// Clase para las estadísticas del usuario
class StatisticsJSON {
  int gamesPlayed;
  int gamesWon;
  int currentStreak;
  int bestStreak;
  int totalTimePlayed; // en segundos
  int totalTurnsPlayed;
  List<RecordJSON> lastFiveGames;

  StatisticsJSON({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.totalTimePlayed = 0,
    this.totalTurnsPlayed = 0,
    List<RecordJSON>? lastFiveGames,
  }) : this.lastFiveGames = lastFiveGames ?? [];

  // Constructor desde JSON
  factory StatisticsJSON.fromJson(Map<String, dynamic> json) {
    // Procesar el array de los últimos cinco juegos
    List<RecordJSON> gameRecords = [];
    if (json['lastFiveGames'] != null) {
      gameRecords = (json['lastFiveGames'] as List)
          .map((game) => RecordJSON.fromJson(game))
          .toList();
    }

    return StatisticsJSON(
      gamesPlayed: json['gamesPlayed'] ?? 0,
      gamesWon: json['gamesWon'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      bestStreak: json['bestStreak'] ?? 0,
      totalTimePlayed: json['totalTimePlayed'] ?? 0,
      totalTurnsPlayed: json['totalTurnsPlayed'] ?? 0,
      lastFiveGames: gameRecords,
    );
  }

  // Convertir a JSON
  Map<String, dynamic> toJson() => {
    'gamesPlayed': gamesPlayed,
    'gamesWon': gamesWon,
    'currentStreak': currentStreak,
    'bestStreak': bestStreak,
    'totalTimePlayed': totalTimePlayed,
    'totalTurnsPlayed': totalTurnsPlayed,
    'lastFiveGames': lastFiveGames.map((game) => game.toJson()).toList(),
  };

  // Método auxiliar para agregar un nuevo registro
  void addGameRecord(RecordJSON record) {
    lastFiveGames.add(record);
    if (lastFiveGames.length > 5) {
      lastFiveGames.removeAt(0); // Mantener solo los últimos 5 juegos
    }
  }
}

// Clase para los datos personalizados del usuario
class UserPersonalizedDataJSON {
  String avatar;
  String background;

  UserPersonalizedDataJSON({
    this.avatar = 'default_avatar.png',
    this.background = 'default_background.png',
  });

  // Constructor desde JSON
  factory UserPersonalizedDataJSON.fromJson(Map<String, dynamic> json) {
    return UserPersonalizedDataJSON(
      avatar: json['avatar'] ?? 'default_avatar.png',
      background: json['background'] ?? 'default_background.png',
    );
  }

  // Convertir a JSON
  Map<String, dynamic> toJson() => {
    'avatar': avatar,
    'background': background,
  };
}

// Clase principal de usuario
class UserJSON {
  String username;
  int coins;
  StatisticsJSON statistics;
  UserPersonalizedDataJSON userPersonalizedData;

  UserJSON({
    required this.username,
    this.coins = 0,
    StatisticsJSON? statistics,
    UserPersonalizedDataJSON? userPersonalizedData,
  }) :
        this.statistics = statistics ?? StatisticsJSON(),
        this.userPersonalizedData = userPersonalizedData ?? UserPersonalizedDataJSON();

  // Constructor desde JSON
  factory UserJSON.fromJson(Map<String, dynamic> json) {
    return UserJSON(
      username: json['username'] ?? '',
      coins: json['coins'] ?? 0,
      statistics: json['statistics'] != null
          ? StatisticsJSON.fromJson(json['statistics'])
          : StatisticsJSON(),
      userPersonalizedData: json['userPersonalizedData'] != null
          ? UserPersonalizedDataJSON.fromJson(json['userPersonalizedData'])
          : UserPersonalizedDataJSON(),
    );
  }

  // Convertir a JSON
  Map<String, dynamic> toJson() => {
    'username': username,
    'coins': coins,
    'statistics': statistics.toJson(),
    'userPersonalizedData': userPersonalizedData.toJson(),
  };
}

