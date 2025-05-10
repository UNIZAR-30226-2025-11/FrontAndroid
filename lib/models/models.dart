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
  final String playerAvatar;
  final int numCards;
  final bool active;
  final bool disconnected;

  PlayerJSON(
      {required this.playerUsername,
      required this.numCards,
      required this.active,
      required this.playerAvatar,
      required this.disconnected});

  factory PlayerJSON.fromJson(Map<String, dynamic> json) {
    return PlayerJSON(
      playerUsername: json['playerUsername'],
      playerAvatar: json['playerAvatar'],
      numCards: json['numCards'],
      active: json['active'],
      disconnected: json['disconnected']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerUsername': playerUsername,
      'playerAvatar': playerAvatar,
      'numCards': numCards,
      'active': active,
      'disconnected': disconnected,
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
  final CardJSON? lastCardPlayed;
  final int turnsLeft;

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
    required this.lastCardPlayed,
    required this.turnsLeft,
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
        cardsLeftInDeck: json['cardsLeftInDeck'],
        lastCardPlayed: json['lastCardPlayed'] is Map<String, dynamic>
          ? CardJSON.fromJson(json['lastCardPlayed'] as Map<String, dynamic>)
          : null, // If it's not a Map, assign null
        turnsLeft: json['turnsLeft'],
    );
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
      'lastCardPlayed': lastCardPlayed,
      'turnsLeft': turnsLeft,
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
  final bool isWinner;
  final String gameDate;
  final int timePlayed;
  final int turnsPlayed;

  BackendWinnerJSON({
    required this.error,
    required this.errorMsg,
    required this.winnerUsername,
    required this.coinsEarned,
    required this.lobbyId,
    required this.isWinner,
    required this.gameDate,
    required this.timePlayed,
    required this.turnsPlayed,
  });

  factory BackendWinnerJSON.fromJson(Map<String, dynamic> json) {
    return BackendWinnerJSON(
        error: json['error'],
        errorMsg: json['errorMsg'],
        winnerUsername: json['winnerUsername'],
        coinsEarned: json['coinsEarned'],
        lobbyId: json['lobbyId'],
        isWinner: json['isWinner'],
        gameDate: json['gameDate'],
        timePlayed: json['timePlayed'],
        turnsPlayed: json['turnsPlayed'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'winnerUsername': winnerUsername,
      'coinsEarned': coinsEarned,
      'lobbyId': lobbyId,
      'isWinner': isWinner,
      'gameDate': gameDate,
      'timePlayed': timePlayed,
      'turnsPlayed': turnsPlayed,
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
      'playerUsername': playerUsername,
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
  final String nopeAction;

  BackendGameSelectNopeJSON({
    required this.error,
    required this.errorMsg,
    required this.lobbyId,
    required this.timeOut,
    required this.nopeAction,
  });

  factory BackendGameSelectNopeJSON.fromJson(Map<String, dynamic> json) {
    return BackendGameSelectNopeJSON(
      error: json['error'],
      errorMsg: json['errorMsg'],
      lobbyId: json['lobbyId'],
      timeOut: json['timeOut'],
      nopeAction: json['nopeAction'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'lobbyId': lobbyId,
      'timeOut': timeOut,
      'nopeAction':nopeAction,
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
  final bool isYou;

  PlayerLobbyJSON({
    required this.name,
    required this.isLeader,
    required this.isYou,
  });

  factory PlayerLobbyJSON.fromJson(Map<String, dynamic> json) {
    return PlayerLobbyJSON(
      name: json['name'],
      isLeader: json['isLeader'],
      isYou: json['isYou'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isLeader': isLeader,
      'isYou': isYou,
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


class BackendPlayerCanReconnectJSON {
  final bool error;
  final String errorMsg;
  final String lobbyId;

  BackendPlayerCanReconnectJSON({
    required this.error,
    required this.errorMsg,
    required this.lobbyId,
  });

  factory BackendPlayerCanReconnectJSON.fromJson(Map<String, dynamic> json) {
    return BackendPlayerCanReconnectJSON(
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

// El archivo contiene todos los modelos necesarios para manejar
// los mensajes JSON de sockets para la funcionalidad de amigos y lobby

class FrontendRequestConnectedFriendsJSON {
  final bool error;
  final String errorMsg;
  final String lobbyId;

  FrontendRequestConnectedFriendsJSON({
    required this.error,
    required this.errorMsg,
    required this.lobbyId,
  });

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'lobbyId': lobbyId,
    };
  }

  factory FrontendRequestConnectedFriendsJSON.fromJson(Map<String, dynamic> json) {
    return FrontendRequestConnectedFriendsJSON(
      error: json['error'] ?? false,
      errorMsg: json['errorMsg'] ?? '',
      lobbyId: json['lobbyId'] ?? '',
    );
  }
}

class ConnectedFriend {
  final String username;
  final String avatar;
  final bool connected;
  final bool isInGame;
  final bool isAlreadyInThisLobby;

  ConnectedFriend({
    required this.username,
    required this.avatar,
    required this.connected,
    required this.isInGame,
    required this.isAlreadyInThisLobby,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'avatar': avatar,
      'connected': connected,
      'isInGame': isInGame,
      'isAlreadyInThisLobby': isAlreadyInThisLobby,
    };
  }

  factory ConnectedFriend.fromJson(Map<String, dynamic> json) {
    return ConnectedFriend(
      username: json['username'] ?? '',
      avatar: json['avatar'] ?? '',
      connected: json['connected'] ?? false,
      isInGame: json['isInGame'] ?? false,
      isAlreadyInThisLobby: json['isAlreadyInThisLobby'] ?? false,
    );
  }
}

class BackendSendConnectedFriendsJSON {
  final bool error;
  final String errorMsg;
  final List<ConnectedFriend> connectedFriends;

  BackendSendConnectedFriendsJSON({
    required this.error,
    required this.errorMsg,
    required this.connectedFriends,
  });

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'connectedFriends': connectedFriends.map((friend) => friend.toJson()).toList(),
    };
  }

  factory BackendSendConnectedFriendsJSON.fromJson(Map<String, dynamic> json) {
    List<dynamic> friendsList = json['connectedFriends'] ?? [];
    List<ConnectedFriend> friends = friendsList
        .map((friendJson) => ConnectedFriend.fromJson(friendJson))
        .toList();

    return BackendSendConnectedFriendsJSON(
      error: json['error'] ?? false,
      errorMsg: json['errorMsg'] ?? '',
      connectedFriends: friends,
    );
  }
}

class FrontendSendFriendRequestEnterLobbyJSON {
  final bool error;
  final String errorMsg;
  final String lobbyId;
  final String friendUsername;

  FrontendSendFriendRequestEnterLobbyJSON({
    required this.error,
    required this.errorMsg,
    required this.lobbyId,
    required this.friendUsername,
  });

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'lobbyId': lobbyId,
      'friendUsername': friendUsername,
    };
  }

  factory FrontendSendFriendRequestEnterLobbyJSON.fromJson(Map<String, dynamic> json) {
    return FrontendSendFriendRequestEnterLobbyJSON(
      error: json['error'] ?? false,
      errorMsg: json['errorMsg'] ?? '',
      lobbyId: json['lobbyId'] ?? '',
      friendUsername: json['friendUsername'] ?? '',
    );
  }
}

class BackendResponseFriendRequestEnterLobbyJSON {
  final bool error;
  final String errorMsg;
  final String lobbyId;
  final String friendUsername;
  final bool accept;

  BackendResponseFriendRequestEnterLobbyJSON({
    required this.error,
    required this.errorMsg,
    required this.lobbyId,
    required this.friendUsername,
    required this.accept,
  });

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'lobbyId': lobbyId,
      'friendUsername': friendUsername,
      'accept': accept,
    };
  }

  factory BackendResponseFriendRequestEnterLobbyJSON.fromJson(Map<String, dynamic> json) {
    return BackendResponseFriendRequestEnterLobbyJSON(
      error: json['error'] ?? false,
      errorMsg: json['errorMsg'] ?? '',
      lobbyId: json['lobbyId'] ?? '',
      friendUsername: json['friendUsername'] ?? '',
      accept: json['accept'] ?? false,
    );
  }
}

class BackendSendFriendRequestEnterLobbyJSON {
  final bool error;
  final String errorMsg;
  final String lobbyId;
  final String friendSendingRequest;
  final String friendSendingRequestAvatar;

  BackendSendFriendRequestEnterLobbyJSON({
    required this.error,
    required this.errorMsg,
    required this.lobbyId,
    required this.friendSendingRequest,
    required this.friendSendingRequestAvatar,
  });

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'lobbyId': lobbyId,
      'friendSendingRequest': friendSendingRequest,
      'friendSendingRequestAvatar': friendSendingRequestAvatar,
    };
  }

  factory BackendSendFriendRequestEnterLobbyJSON.fromJson(Map<String, dynamic> json) {
    return BackendSendFriendRequestEnterLobbyJSON(
      error: json['error'] ?? false,
      errorMsg: json['errorMsg'] ?? '',
      lobbyId: json['lobbyId'] ?? '',
      friendSendingRequest: json['friendSendingRequest'] ?? '',
      friendSendingRequestAvatar: json['friendSendingRequestAvatar'] ?? '',
    );
  }
}

class FrontendResponseFriendRequestEnterLobbyJSON {
  final bool error;
  final String errorMsg;
  final String lobbyId;
  final bool accept;
  final String friendSendingRequest;

  FrontendResponseFriendRequestEnterLobbyJSON({
    required this.error,
    required this.errorMsg,
    required this.lobbyId,
    required this.accept,
    required this.friendSendingRequest,
  });

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'errorMsg': errorMsg,
      'lobbyId': lobbyId,
      'accept': accept,
      'friendSendingRequest': friendSendingRequest,
    };
  }

  factory FrontendResponseFriendRequestEnterLobbyJSON.fromJson(Map<String, dynamic> json) {
    return FrontendResponseFriendRequestEnterLobbyJSON(
      error: json['error'] ?? false,
      errorMsg: json['errorMsg'] ?? '',
      lobbyId: json['lobbyId'] ?? '',
      accept: json['accept'] ?? false,
      friendSendingRequest: json['friendSendingRequest'] ?? '',
    );
  }
}

