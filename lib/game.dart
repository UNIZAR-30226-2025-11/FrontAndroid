import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'SessionManager.dart';
import 'homePage.dart';
import 'models/models.dart';

class GameScreen extends StatefulWidget {
  final IO.Socket socket;
  final String lobbyId;
  final String username;
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
  late int coins=-1;

  final ScrollController _scrollController = ScrollController();
  List<int> selectedCards = [];
  int remainingTime = 60;
  //late Timer timer;
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
      dynamic data = widget.initialGameState;
      setState(() {
        error = data['error'];
        errorMsg = data['errorMsg'];
        print(data['playerCards']);
        //playerCards = List<String>.from(data['playerCards']);
        // If playerCards is already a List (not a JSON string)
        playerCards = (data['playerCards'] as List)
            .map((card) => CardJSON.fromJson(card as Map<String, dynamic>))
            .toList();
        print(data['playerCards']); // Para ver qué tipo de dato es
        players = (data['players'] as List)
            .map((player) => PlayerJSON.fromJson(player))
            .where((player) =>
                player.playerUsername !=
                username)
            .toList();
        timeOut = data['timeOut'];
        remainingTime = timeOut;
        turnUsername = data['turnUsername'];
        cardsLeftInDeck = data['cardsLeftInDeck'];
      });
      print('fin');
    }
    setupSocketListeners();
    _initializeUsername();
    _initializeCoins();
    //startTimer();
  }

  Future<String?> _initializeUsername() async {
    try {
      final String? user = await SessionManager.getUsername();
      setState(() {
        username = user ?? ""; // Actualiza el username cuando esté disponible

      });
      return user;
    } catch (e) {
      print("Error initializing username: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Username error: $e"))
      );
      return "";
    }
  }

  Future<void> _initializeCoins() async {
    try {
      final String? token = await SessionManager.getSessionData();
      final res = await http.get(
          Uri.parse('http://10.0.2.2:8000/users'),
          headers: {
            'Cookie': 'access_token=$token',
          }
      );

      print('Current username: $username');
      final data = jsonDecode(res.body);

      if (res.statusCode != 200) {
        var errorMessage = data.containsKey('message')
            ? data['message']
            : "Something went wrong. Try later";

        print(errorMessage);
        return;
      } else {
        // Find the user with matching username
        final user = (data as List).firstWhere(
              (user) => user['username'] == username,
          orElse: () => null,
        );

        if (user != null) {
          // Use setState to update the UI
          setState(() {
            coins = int.parse(user['coins'].toString());
          });
          print("Found user, coins: $coins");
        } else {
          print("User not found in the response data");
        }
      }
    } catch (e) {
      print("Error initializing coins: $e");
      if (mounted) {  // Check if widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Coins error: $e"))
        );
      }
    }
  }

  void setupSocketListeners() {
    socket.off('game-state');
    socket.on('game-state', (data) {
      print('before mounted');
      if (mounted) {
        // Add this check
        print('Nuevo estado recibido');
        setState(() {
          print(data);
          error = data['error'];
          errorMsg = data['errorMsg'];
          // If playerCards is already a List (not a JSON string)
          playerCards = (data['playerCards'] as List)
              .map((card) => CardJSON.fromJson(card as Map<String, dynamic>))
              .toList();
          players = (data['players'] as List)
              .map((player) => PlayerJSON.fromJson(player))
              .where((player) => player.playerUsername != username)
              .toList();
          timeOut = data['timeOut'];
          remainingTime = timeOut;
          turnUsername = data['turnUsername'];
          cardsLeftInDeck = data['cardsLeftInDeck'];
        });
      }
    });

    remainingTime = timeOut;

    void showTemporaryMessage(String message) {
      OverlayEntry overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          top: MediaQuery.of(context).size.height * 0.1,
          width: MediaQuery.of(context).size.width,
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      Overlay.of(context).insert(overlayEntry);

      // Eliminar el mensaje después de 2.5 segundos
      Future.delayed(Duration(milliseconds: 2500), () {
        overlayEntry.remove();
      });
    }


    void accion(dynamic action) {
      String targetName = action['targetUser'];
      String triggerName = action['triggerUser'];
      String act = action['action'];
      switch (act) {
      // TODO: realizar accion según campo action

      }
      showTemporaryMessage('Action: $act with target $targetName and trigger $triggerName');
    }

    socket.on('notify-action', (data) {
      setState(() {
        //BackendNotifyActionJSON action = BackendNotifyActionJSON.fromJson(data);
        accion(data);
      });
    });

    void winner(BackendWinnerJSON winnerData) {
      if (winnerData.error) {
        print('Error: ${winnerData.errorMsg}');
      } else {
        print(
            'Jugador ${winnerData
                .winnerUsername} ha ganado y ha ganado ${winnerData
                .coinsEarned} coins');
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
                      style: TextStyle(fontWeight: FontWeight.bold,color: Colors.green),
                    ),
                    TextSpan(text: 'has won '),
                    TextSpan(
                      text: 'and you have won ${winnerData.coinsEarned} coins',
                      //style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Close'),
                  onPressed: () {
                    //Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => MainScreen(

                          )), // Placeholder
                    );
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
      print('select-game recibido');
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
                          'assets/images/${cardType
                          .toString()
                          .split('.')
                          .last}.jpg';

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

    socket.on('game-select-nope', (data) {
      setState(() {
        BackendGameSelectNopeJSON nopeData = BackendGameSelectNopeJSON.fromJson(data);
        int timeLeft = nopeData.timeOut;

        // Show dialog to ask if player wants to use a Nope card
        showDialog(
          context: context,
          barrierDismissible: false, // Prevent dismissing by tapping outside
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Play Nope Card?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Do you want to play your Nope card?'),
                  SizedBox(height: 10),
                  Text('Time left: $timeLeft seconds',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('No'),
                  onPressed: () {
                    FrontendGameSelectNopeResponseJSON response =
                    FrontendGameSelectNopeResponseJSON(
                      error: false,
                      errorMsg: "",
                      useNope: false,
                      lobbyId: widget.lobbyId,
                    );
                    socket.emit('game-select-nope', response.toJson());

                    // Close the dialog
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                  ),
                  child: Text('Yes, use Nope!',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    // Send response with useNope = true
                    FrontendGameSelectNopeResponseJSON response =
                    FrontendGameSelectNopeResponseJSON(
                      error: false,
                      errorMsg: "",
                      useNope: true,
                      lobbyId: widget.lobbyId,
                    );
                    socket.emit('game-select-nope', response.toJson());

                    // Close the dialog
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      });
    });
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
          if (response.cardsSeeFuture != null){
            //TODO: mostrar cartas
          }
          if(response.cardReceived != null){
            //TODO: animacion mostrar carta?
          }
          timeOut = 0;
          _buildTimerIndicator();
          selectedCards.clear();
        });
      }
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

  }

  /*void startTimer() {
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
  }*/

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
    //timer.cancel();

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
              Text('$coins',
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
            top: 100,
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
          left: MediaQuery.of(context).size.width / 2 - 165,
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
              SizedBox(width: 90),
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
      duration: Duration(milliseconds: timeOut),
      tween: Tween<double>(begin: 1.0, end: 0.0),
      builder: (context, value, child) {
        // Calculate remaining time from the animation value
        int displayTime = (timeOut * value / 1000).ceil();

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
              '$displayTime',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: displayTime <= 10 ? Colors.red : Colors.black,
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
      width: 180,
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
      animatingCards.clear(); // Clear previous animations

      // Calculate the starting position (position of the card in the hand)
      final double startX = MediaQuery.of(context).size.width / 2 - 150;
      final double startY = MediaQuery.of(context).size.height - 100;

      // Create animation data for each selected card
      animatingCards = selectedCards.asMap().entries.map((entry) {
        final index = entry.key;
        final cardIndex = entry.value;

        final controller = AnimationController(
          duration: const Duration(milliseconds: 800),
          vsync: this,
        );

        final position = Tween<Offset>(
          begin: Offset(startX + (index * 116), 0), // Starting from card position
          end: Offset(
            MediaQuery.of(context).size.width / 2 - 50, // Center of screen
            MediaQuery.of(context).size.height * 0.3,   // Target Y position
          ),
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Curves.easeOut,
        ));

        return {
          'card': playerCards[cardIndex],
          'controller': controller,
          'position': position,
        };
      }).toList();
    });

    // Start all animations
    for (final card in animatingCards) {
      (card['controller'] as AnimationController).forward();
    }

    // When animation completes, send the action and clean up
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;

      sendGameAction(selectedCards);
      setState(() {
        isAnimating = false;
        animatingCards.clear();
      });
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
