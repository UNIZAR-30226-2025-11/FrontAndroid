import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'models/models.dart';

class GameScreen extends StatefulWidget {
  final IO.Socket socket;
  final String lobbyId;
  final String username;
  final int coins = 3;
  final Map<String, dynamic> initialGameState;

  GameScreen(
      {required this.socket,
      required this.lobbyId,
      required this.initialGameState,
      required this.username});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late IO.Socket socket;
  bool error = false;
  String errorMsg = "";
  List<CardJSON> playerCards = [];
  List<PlayerJSON> players = [];
  int turn = 0;
  int timeOut = 0;
  String turnUsername = "";
  int cardsLeftInDeck = 0;

  final ScrollController _scrollController = ScrollController();
  List<int> selectedCards = [];
  int remainingTime = 60;
  late Timer timer;
  late String username;

  List<Map<String, dynamic>> animatingCards = [];
  bool isAnimating = false;

  final myId = 1;

  @override
  void initState() {
    super.initState();
    socket = widget.socket;
    username = widget.username;
    if (widget.initialGameState.isNotEmpty) {
      print('A');
      dynamic data = widget.initialGameState;
      setState(() {
        error = data['error'];
        errorMsg = data['errorMsg'];
        print(data['playerCards']);
        //playerCards = List<String>.from(data['playerCards']);
        playerCards = List<CardJSON>.from(jsonDecode(data['playerCards']));
        print(data['playerCards']); // Para ver qué tipo de dato es
        players = (data['players'] as List)
            .map((player) => PlayerJSON.fromJson(player))
            .where((player) =>
                player.playerUsername !=
                username) //FIXME cambiar id por username?
            .toList();
        turn = data['turn'];
        timeOut = data['timeOut'];
        remainingTime = timeOut;
        turnUsername = data['turnUsername'];
        cardsLeftInDeck = data['cardsLeftInDeck'];
      });
      print('fin');
    }
    setupSocketListeners();
    startTimer();
  }

  void setupSocketListeners() {
    socket.on('game-state', (data) {
      if (mounted) {
        // Add this check
        setState(() {
          error = data['error'];
          errorMsg = data['errorMsg'];
          playerCards = List<CardJSON>.from(jsonDecode(data['playerCards']));
          players = (data['players'] as List)
              .map((player) => PlayerJSON.fromJson(player))
              .where((player) => player.playerUsername != username)
              .toList();
          turn = data['turn'];
          timeOut = data['timeOut'];
          remainingTime = timeOut;
          turnUsername = data['turnUsername'];
          cardsLeftInDeck = data['cardsLeftInDeck'];
        });
      }
    });

    remainingTime = timeOut;

    void accion(dynamic action) {
      PlayerJSON target = action['targetUser'];
      PlayerJSON trigger = action['triggerUser'];
      String act = action['action'];
      switch (act) {
        // TODO: realizar accion según campo action
      }
    }

    socket.on('notify-action', (data) {
      setState(() {
        //BackendNotifyActionJSON action = BackendNotifyActionJSON.fromJson(data);
        accion(data);
      });
    });

    void winner(BackendWinnerJSON winnerData) {
      // TODO: Implementar la lógica para manejar el evento 'winner'
      if (winnerData.error) {
        print('Error: ${winnerData.errorMsg}');
      } else {
        print(
            'Jugador ${winnerData.winnerUsername} ha ganado y ha ganado ${winnerData.coinsEarned} coins');
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('¡We have a winner!'),
              content: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${winnerData.winnerUsername} ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: 'has won '),
                    TextSpan(
                      text: '${winnerData.coinsEarned} coins',
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cerrar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }

    socket.on('winner', (data) {
      setState(() {
        BackendWinnerJSON winnerData = BackendWinnerJSON.fromJson(data);
        winner(winnerData);
      });
    });

    socket.on('game-select-player', (data) {
      setState(() {
        BackendGameSelectPlayerJSON selectPlayerData =
            BackendGameSelectPlayerJSON.fromJson(data);
        int timeLeft = selectPlayerData.timeOut;

        // Show dialog to select a player
        showDialog(
          context: context,
          barrierDismissible: false, // Prevent dismissing by tapping outside
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Select a Player'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Time left: $timeLeft seconds'),
                  SizedBox(height: 10),
                  // Create a list of players to select from
                  Column(
                    children: players.map((player) {
                      return ListTile(
                        title: Text(player.playerUsername),
                        onTap: () {
                          // Send selected player back to the server
                          FrontendGameSelectPlayerResponseJSON response =
                              FrontendGameSelectPlayerResponseJSON(
                            error: false,
                            errorMsg: "",
                            playerUsername: player.playerUsername,
                            lobbyId: widget.lobbyId,
                          );
                          socket.emit('game-select-player', response.toJson());

                          // Close the dialog
                          Navigator.of(context).pop();
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      });
    });

    socket.on('game-select-card', (data) {
      setState(() {
        BackendGameSelectCardJSON selectCardData =
            BackendGameSelectCardJSON.fromJson(data);
        int timeLeft = selectCardData.timeOut;

        // Show dialog to select a card
        showDialog(
          context: context,
          barrierDismissible: false, // Prevent dismissing by tapping outside
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Select a Card'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Time left: $timeLeft seconds'),
                  SizedBox(height: 10),
                  // Create a grid of cards to select from
                  GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: playerCards.length,
                    itemBuilder: (context, index) {
                      CardJSON card = playerCards[index];
                      String imagePath = 'assets/images/${card.type}.jpg';

                      return GestureDetector(
                        onTap: () {
                          // Send selected card back to the server
                          FrontendGameSelectCardResponseJSON response =
                              FrontendGameSelectCardResponseJSON(
                            error: false,
                            errorMsg: "",
                            card: card,
                            lobbyId: widget.lobbyId,
                          );
                          socket.emit('game-select-card', response.toJson());

                          // Close the dialog
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(10)),
                                  child: Image.asset(
                                    imagePath,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  card.type,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      });
    });

    socket.on('game-select-card-type', (data) {
      setState(() {
        BackendGameSelectCardTypeJSON selectCardTypeData =
            BackendGameSelectCardTypeJSON.fromJson(data);
        int timeLeft = selectCardTypeData.timeOut;

        // Show dialog to select a card type
        showDialog(
          context: context,
          barrierDismissible: false, // Prevent dismissing by tapping outside
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Select a Card Type'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Time left: $timeLeft seconds'),
                  SizedBox(height: 10),
                  // Create a grid of card types to select from
                  GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: CardType.values.length,
                    itemBuilder: (context, index) {
                      CardType cardType = CardType.values[index];
                      String imagePath =
                          'assets/images/${cardType.toString().split('.').last}.jpg';

                      return GestureDetector(
                        onTap: () {
                          // Send selected card type back to the server
                          FrontendGameSelectCardTypeResponseJSON response =
                              FrontendGameSelectCardTypeResponseJSON(
                            error: false,
                            errorMsg: "",
                            cardType: cardType
                                .toString()
                                .split('.')
                                .last, // Send just the type name
                            lobbyId: widget.lobbyId,
                          );
                          socket.emit(
                              'game-select-card-type', response.toJson());

                          // Close the dialog
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey),
                            color: Colors.white,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                imagePath,
                                height: 80,
                                width: 80,
                                fit: BoxFit.contain,
                              ),
                              SizedBox(height: 8),
                              Text(
                                cardType
                                    .toString()
                                    .split('.')
                                    .last, // Display type name
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      });
    });
  }

  void sendGameAction(List<int> selectedCardIndices) {
    List<CardJSON> playedCards = selectedCardIndices.isEmpty
        ? [] // Si la lista está vacía, asignamos una lista vacía
        : selectedCardIndices.map((index) => playerCards[index]).toList();

    // Usar jsonEncode para convertir la lista a una cadena JSON (incluso si es vacía)
    String playedCardsJson = jsonEncode(playedCards);

    print('enviando cartas');
    print(playedCardsJson);

    FrontendGamePlayedCardsJSON gamePlayedData = FrontendGamePlayedCardsJSON(
      error: false,
      errorMsg: "",
      playedCards: playedCards,
      lobbyId: widget.lobbyId,
    );

    socket.emit('game-played-cards', gamePlayedData.toJson());

    print("cartas enviadas");

    socket.on('game-played-cards', (data) {
      print("respuesta a cartas recibida");
      BackendGamePlayedCardsResponseJSON response =
          BackendGamePlayedCardsResponseJSON.fromJson(data);

      if (response.error) {
        setState(() {
          error = true;
          errorMsg = response.errorMsg;
          print(errorMsg);
        });
      } else {
        setState(() {
          print("Actualizando estado");
          //TODO: METER NUEVA CARTA SI HA ROBADO
        });
      }
    });
  }

  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        if (remainingTime > 0) {
          setState(() {
            remainingTime--;
          });
        } else {
          timer.cancel();
          List<int> empty = [];
          sendGameAction(empty);
        }
      }
    });
  }

  @override
  void dispose() {
    // Remove all event listeners
    socket.off('game-state');
    socket.off('notify-action');
    socket.off('winner');
    socket.off('game-select-player');
    socket.off('game-select-card');
    socket.off('game-select-card-type');
    socket.off('game-played-cards');

    // Cancel timers
    timer.cancel();

    // Dispose animation controllers
    for (var card in animatingCards) {
      (card['controller'] as AnimationController).dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*appBar: AppBar(
        title: Text('Game Info'),
        automaticallyImplyLeading: false,
      ),*/
      backgroundColor: Color(0xFF9D0514),
      body: Stack(children: [
        Positioned(
          top: 48,
          right: 30,
          child: Row(
            children: [
              SizedBox(width: 8),
              Icon(Icons.monetization_on, color: Colors.yellow, size: 30),
              SizedBox(width: 8),
              Text('5 coins',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
        ),
        Positioned(
          top: 40,
          left: 30,
          child: Row(
            children: [
              SizedBox(width: 8),
              Icon(Icons.person, size: 30, color: Colors.white),
              SizedBox(width: 8),
              Text(username,
                  style: TextStyle(
                      color: turnUsername == username
                          ? Colors.yellow
                          : Colors.white,
                      fontSize: 18,
                      fontWeight: turnUsername == username
                          ? FontWeight.bold
                          : FontWeight.normal)),
            ],
          ),
        ),
        // Only display other players, not the current player
        if (players.isNotEmpty)
          Positioned(
            top: 50,
            left: MediaQuery.of(context).size.width / 2 - 60,
            child: buildPlayerCard(players[0],
                isCurrentTurn: players[0].playerUsername == turnUsername),
          ),
        if (players.length >= 2)
          Positioned(
            bottom: 400,
            left: 25,
            child: buildPlayerCard(players[1],
                isCurrentTurn: players[0].playerUsername == turnUsername),
          ),
        if (players.length >= 3)
          Positioned(
            bottom: 400,
            right: 25,
            child: buildPlayerCard(players[2],
                isCurrentTurn: players[0].playerUsername == turnUsername),
          ),
        Positioned(
          bottom: 220,
          left: MediaQuery.of(context).size.width / 2 - 15,
          /*child: SizedBox(
              width: 25,
              height: 25,
              child: CircularProgressIndicator(
                value: remainingTime / 60,
                backgroundColor: Colors.grey,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                strokeWidth: 25,
              ),
            ),*/
          child: _buildTimerIndicator(),
        ),
        Positioned(
          bottom: 210,
          left: MediaQuery.of(context).size.width / 2 - 150,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: selectedCards.isNotEmpty && selectedCards.length <= 3
                    ? () {
                        _animatePlayedCards();
                        //sendGameAction(selectedCards);
                      }
                    : null,
                child: Text('Play Cards'),
              ),
              SizedBox(width: 60),
              ElevatedButton(
                onPressed: () {
                  // Acción de robar carta
                  List<int> empty = [];
                  sendGameAction(empty);
                },
                child: Text('Steal a Card'),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 20,
          left: MediaQuery.of(context).size.width / 2 - 150,
          child: Container(
            height: 180,
            width: 300,
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: playerCards.asMap().entries.map((entry) {
                    int index = entry.key;
                    String cardName = entry.value.type;
                    String imagePath = 'assets/images/$cardName.jpg';
                    bool isSelected = selectedCards.contains(index);
                    double cardHeight = isSelected ? 170 : 150;
                    double cardWidth = isSelected ? 115 : 100;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (selectedCards.contains(index)) {
                            selectedCards.remove(index);
                          } else {
                            selectedCards.add(index);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 150),
                        margin: EdgeInsets.symmetric(horizontal: 8.0),
                        height: cardHeight,
                        width: cardWidth,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.yellow.withOpacity(0.8),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  )
                                ]
                              : [],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildTimerIndicator() {
    return TweenAnimationBuilder(
      duration: Duration(seconds: timeOut),
      tween: Tween<double>(begin: 1.0, end: 0.0),
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: value,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(value > 0.3
                  ? Colors.green
                  : (value > 0.1 ? Colors.orange : Colors.red)),
              strokeWidth: 10,
            ),
            Text(
              '$remainingTime',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: remainingTime <= 10 ? Colors.red : Colors.black,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildPlayerCard(PlayerJSON player, {bool isCurrentTurn = false}) {
    Color backgroundColor = isCurrentTurn
        ? Colors.yellowAccent.withOpacity(0.3) // Highlight for current turn
        : (player.active ? Colors.white : Colors.grey[400]!);

    return Container(
      margin: EdgeInsets.all(8.0),
      padding: EdgeInsets.all(16.0),
      height: 150,
      width: 160,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border:
            isCurrentTurn ? Border.all(color: Colors.yellow, width: 3) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Player icon with turn indicator
          Stack(
            children: [
              Icon(
                Icons.person,
                size: 40,
                color: player.active ? Colors.blue : Colors.grey,
              ),
              if (isCurrentTurn)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(
                    Icons.star,
                    color: Colors.yellow,
                    size: 20,
                  ),
                ),
            ],
          ),
          SizedBox(width: 16),
          // Player info
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                player.playerUsername,
                style: TextStyle(
                  color: isCurrentTurn
                      ? Colors.black
                      : (player.active ? Colors.black : Colors.grey[600]),
                  fontSize: 18,
                  fontWeight:
                      isCurrentTurn ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '${player.numCards} cards',
                style: TextStyle(
                  color: isCurrentTurn
                      ? Colors.black
                      : (player.active ? Colors.black : Colors.grey[600]),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _animatePlayedCards() {
    if (selectedCards.isEmpty || isAnimating) return;

    setState(() {
      isAnimating = true;

      // Create a copy of the selected cards for animation
      animatingCards = selectedCards.map((index) {
        return {
          'cardName': playerCards[index],
          'controller': AnimationController(
            duration: Duration(milliseconds: 800),
            vsync: this,
          ),
          'position': Tween<Offset>(
            begin: Offset(0, 0),
            end: Offset(
              (MediaQuery.of(context).size.width / 2) -
                  (MediaQuery.of(context).size.width / 2 - 150 + index * 116),
              (MediaQuery.of(context).size.height * 0.3) -
                  (MediaQuery.of(context).size.height - 100),
            ),
          ).animate(CurvedAnimation(
            parent: AnimationController(
              duration: Duration(milliseconds: 800),
              vsync: this,
            )..forward(),
            curve: Curves.easeOutQuad,
          )),
        };
      }).toList();
    });

    // Start animation
    Future.delayed(Duration(milliseconds: 50), () {
      for (var card in animatingCards) {
        (card['controller'] as AnimationController).forward();
      }
    });

    // After animation completes, send the game action
    Future.delayed(Duration(milliseconds: 1000), () {
      setState(() {
        isAnimating = false;
        animatingCards = [];
      });
      sendGameAction(selectedCards);
    });
  }

  Widget _buildPlayedCardsArea() {
    if (!isAnimating) return Container();

    return Stack(
      children: animatingCards.map((cardData) {
        String cardName = cardData['cardName'];
        String imagePath = 'assets/images/$cardName.jpg';
        AnimationController controller = cardData['controller'];
        Animation<Offset> position = cardData['position'];

        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return Transform.translate(
              offset: position.value,
              child: Container(
                height: 150,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
