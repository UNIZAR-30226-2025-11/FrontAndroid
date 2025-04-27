import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_example/UserInfo.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
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
  bool _isChatVisible = false;
  List<MsgJSON> _messages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  final ScrollController _scrollController = ScrollController();
  List<int> selectedCards = [];
  int remainingTime = 60;
  //late Timer timer;
  late String username;

  // for animating cards when being played
  List<Map<String, dynamic>> animatingCards = [];
  bool isAnimating = false;

  // to prevent bomb explosions' animations from being cut off
  bool _isBombAnimating = false;
  BackendWinnerJSON? _pendingWinner;

  // for the user's info (avatar, etc.)
  final UserInfo userInfo = UserInfo();
  final myId = 1;

  // for the timer
  int _animationRestartKey = 0;
  double _animationValue = 1.0;

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
    setupChatSocketListeners();
    _initializeUser();
    //_initializeUsername();
    //_initializeCoins();
    //startTimer();
  }

  Future<void> _initializeUser() async {
    await userInfo.initialize();
    username = userInfo.username;
    coins = userInfo.coins;
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
          Uri.parse('http://10.0.2.2:8000/user'),
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

        // Use setState to update the UI
        setState(() {
          coins = int.parse(data['coins'].toString());
        });
        print("Found user, coins: $coins");
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
          // Increment the restart key to trigger rebuild
          if (turnUsername == username) {
            _animationValue = 1.0;
          } else {
            _animationValue = 0.0;
          }
          _animationRestartKey++;
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

    void _showWinnerDialog(BackendWinnerJSON winnerData) {
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
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  TextSpan(text: 'has won '),
                  TextSpan(
                    text: 'and you have won ${winnerData.coinsEarned} coins',
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Leave game'),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => MainScreen()),
                  );
                },
              ),
            ],
          );
        },
      );
    }

    void accion(dynamic action) {
      String targetName = action['targetUser'];
      String triggerName = action['triggerUser'];
      String act = action['action'];
      print('Action received: $action');
      switch (act) {
        case("ShuffleDeck"):
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const ShuffleAnimationWidget(),
          );
          break;
        case("BombExploded"):
          _isBombAnimating = true;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => BombExplosionDialog(
              eliminatedPlayer: triggerName,
            ),
          ).then((_) {
            // Animation finished
            _isBombAnimating = false;

            // If a winner was waiting, show it now
            if (_pendingWinner != null) {
              _showWinnerDialog(_pendingWinner!);
              _pendingWinner = null;
            }
          });
          break;
        case("BombDefused"):
          showDialog(
            context: context,
            builder: (_) => BombDiffusedDialog(player: triggerName),
          );
          break;
        case("FutureSeen"):
          if (triggerName != username) {
            showDialog(
              context: context,
              builder: (_) => FutureSeenDialog(player: triggerName),
            );
          }
          break;
      }
      //showTemporaryMessage('Action: $act with target $targetName and trigger $triggerName');
    }

    socket.on('notify-action', (data) {
      setState(() {
        //BackendNotifyActionJSON action = BackendNotifyActionJSON.fromJson(data);
        accion(data);
      });
    });


    socket.on('winner', (data) {
      print("WINNER");
      print(data);
      setState(() {
        BackendWinnerJSON winnerData = BackendWinnerJSON.fromJson(data);
        if (_isBombAnimating) {
          _pendingWinner = winnerData;
        } else {
          _showWinnerDialog(winnerData);
        }
      });
    });


    socket.on('game-select-player', (data) {
      print('select-game-player recibido');
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
      print('select card recibido');
      setState(() {
        BackendGameSelectCardJSON selectCardData =
        BackendGameSelectCardJSON.fromJson(data);
        int timeLeft = selectCardData.timeOut;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 300, // You can adjust this width as needed
                height: 450, // And the height too
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Text(
                        'Select a Card',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Time left: $timeLeft seconds',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                    SizedBox(height: 12),
                    Expanded(
                      child: GridView.builder(
                        itemCount: playerCards.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemBuilder: (context, index) {
                          CardJSON card = playerCards[index];
                          String imagePath = 'assets/images/${card.type}.jpg';

                          return GestureDetector(
                            onTap: () {
                              FrontendGameSelectCardResponseJSON response =
                              FrontendGameSelectCardResponseJSON(
                                error: false,
                                errorMsg: "",
                                card: card,
                                lobbyId: widget.lobbyId,
                              );
                              socket.emit('game-select-card', response.toJson());
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
                                        top: Radius.circular(10),
                                      ),
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
                                      overflow: TextOverflow.ellipsis, // Truncate with ellipsis if text is too long
                                      maxLines: 1, // Ensure it stays on a single line
                                      textAlign: TextAlign.center, // Center the text
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      });
    });

    socket.on('game-select-card-type', (data) {
      print('select card type recibido');
      setState(() {
        BackendGameSelectCardTypeJSON selectCardTypeData =
        BackendGameSelectCardTypeJSON.fromJson(data);
        int timeLeft = selectCardTypeData.timeOut;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 300,
                height: 450,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Text(
                        'Select a Card Type',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Time left: $timeLeft seconds',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                    SizedBox(height: 12),
                    Expanded(
                      child: GridView.builder(
                        itemCount: CardType.values.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.0,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemBuilder: (context, index) {
                          CardType cardType = CardType.values[index];
                          String typeName =
                              cardType.toString().split('.').last;
                          String imagePath = 'assets/images/$typeName.jpg';

                          return GestureDetector(
                            onTap: () {
                              FrontendGameSelectCardTypeResponseJSON response =
                              FrontendGameSelectCardTypeResponseJSON(
                                error: false,
                                errorMsg: "",
                                cardType: typeName,
                                lobbyId: widget.lobbyId,
                              );
                              socket.emit('game-select-card-type', response.toJson());

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
                                    typeName,
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
                    ),
                  ],
                ),
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
        bool hasNopeCard = playerCards.any((card) => card.type == 'Nope'); // This should be based on the player's actual card availability

        // Check if the player has a Nope card
        if (!hasNopeCard) {
          // Print and emit response for not using the Nope card
          print('Player does not have a Nope card.');

          // Emit that the player doesn't want to use the Nope card
          FrontendGameSelectNopeResponseJSON response = FrontendGameSelectNopeResponseJSON(
            error: false,
            errorMsg: "",
            useNope: false,
            lobbyId: widget.lobbyId,
          );
          socket.emit('game-select-nope', response.toJson());
          return; // Exit the function since we don't need to show the dialog
        }

        // If the player has a Nope card, show the dialog
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
      print("Raw data: $data");
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
            List<String> imagePaths = response.cardsSeeFuture!
                .map((cardJson) => 'assets/images/${cardJson.type}.jpg')
                .toList();
            if (imagePaths.isNotEmpty) {
              showCardPopup(context, imagePaths);
            }
          }
          if(response.cardReceived != null &&
              response.cardReceived!.id != -1) {
            print("Received card: ${response.cardReceived?.type}");
            String imagePath = 'assets/images/${response.cardReceived!.type}.jpg';
            print(imagePath);
            showCardPopup(context, [imagePath]);
          }
          timeOut = 0;
          _buildTimerIndicator();
          selectedCards.clear();
        });
      }
    });
  }

  void setupChatSocketListeners() {
    socket.on('get-messages', (data) {
      if (mounted) {
        setState(() {
          BackendGetMessagesJSON messagesData = BackendGetMessagesJSON.fromJson(data);
          if (!messagesData.error) {
            _messages = messagesData.messages;

            // Desplaza automáticamente hasta el último mensaje
            Future.delayed(Duration(milliseconds: 100), () {
              if (_chatScrollController.hasClients) {
                _chatScrollController.animateTo(
                  _chatScrollController.position.maxScrollExtent,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
          } else {
            print('Error getting messages: ${messagesData.errorMsg}');
          }
        });
      }
    });
  }

  void _sendChatMessage() {
    if (_chatController.text.isEmpty) return;

    FrontendPostMsgJSON postMsg = FrontendPostMsgJSON(
      error: false,
      errorMsg: "",
      msg: _chatController.text,
      lobbyId: widget.lobbyId,
    );

    socket.emit('post-message', postMsg.toJson());
    _chatController.clear();
  }


  void sendGameAction(List<int> selectedCardIndices) {
    List<CardJSON> playedCards = selectedCardIndices.isEmpty
        ? []
        : selectedCardIndices.map((index) => playerCards[index]).toList();

    // Start card animation before sending
    if (selectedCardIndices.isNotEmpty) {
      animatePlayedCards(selectedCardIndices);
    }

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
    socket.off('get-messages');

    // Cancel timers
    //timer.cancel();

    // Dispose all animation controllers
    for (var card in animatingCards) {
      (card['controller'] as AnimationController).dispose();
    }

    _chatController.dispose();
    _chatScrollController.dispose();
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
      body: Stack(
          children: [
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: userInfo.avatarUrl.isNotEmpty
                      ? DecorationImage(
                    image: AssetImage('assets/images/avatar/${userInfo.avatarUrl}.png'),
                    fit: BoxFit.cover,
                  )
                      : null,
                  color: Colors.grey, // fallback background color
                ),
                child: userInfo.avatarUrl.isEmpty
                    ? Icon(Icons.person, size: 24, color: Colors.white)
                    : null,
              ),
              SizedBox(width: 8),
              Text(
                username,
                style: TextStyle(
                  color: turnUsername == username ? Colors.yellow : Colors.white,
                  fontSize: 18,
                  fontWeight: turnUsername == username ? FontWeight.bold : FontWeight.normal,
                ),
              ),
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
                onPressed: selectedCards.isNotEmpty && selectedCards.length <= 3 && turnUsername == username
                    ? () {
                  sendGameAction(selectedCards);
                  setState(() {
                    selectedCards.clear();  // <-- Clear immediately after pressing!
                  });
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
            if (isAnimating)
              ...animatingCards.map((cardData) {
                return AnimatedBuilder(
                  animation: cardData['controller'],
                  builder: (context, child) {
                    // Calculate position - start from bottom center, move to center
                    final screenWidth = MediaQuery.of(context).size.width;
                    final screenHeight = MediaQuery.of(context).size.height;

                    // Starting position (player's hand)
                    double startX = screenWidth / 2 + (cardData['index'] - selectedCards.length / 2) * 30;
                    double startY = screenHeight - 100;

                    // Ending position (center of screen)
                    double endX = screenWidth / 2;
                    double endY = screenHeight / 2;

                    // Calculate current position
                    double currentX = startX + (endX - startX) * cardData['moveAnimation'].value;
                    double currentY = startY + (endY - startY) * cardData['moveAnimation'].value;

                    // Calculate rotation based on position
                    double rotation = (cardData['moveAnimation'].value * 0.3) * (cardData['index'] % 2 == 0 ? 1 : -1);

                    return Positioned(
                      left: currentX - 50, // Adjust for card width
                      top: currentY - 75, // Adjust for card height
                      child: Transform.rotate(
                        angle: rotation,
                        child: Opacity(
                          opacity: cardData['opacityAnimation'].value,
                          child: Container(
                            height: 150,
                            width: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 5,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                cardData['imagePath'],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            Positioned(
              top: 100,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isChatVisible = !_isChatVisible;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Badge(
                    isLabelVisible: _messages.isNotEmpty && !_isChatVisible,
                    child: Icon(
                      Icons.chat_bubble_outline,
                      color: Color(0xFF9D0514),
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),

            // Panel deslizante del chat
            AnimatedPositioned(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              right: _isChatVisible ? 0 : -300,
              top: 0,
              bottom: 0,
              width: 300,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(-2, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Encabezado del chat
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: Color(0xFF9D0514),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Chat',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _isChatVisible = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    // Lista de mensajes
                    Expanded(
                      child: _messages.isEmpty
                          ? Center(
                        child: Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                          : ListView.builder(
                        controller: _chatScrollController,
                        padding: EdgeInsets.all(10),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMe = message.username == username;

                          return Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: 230,
                                ),
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.blue.shade100 : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isMe)
                                      Padding(
                                        padding: EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          message.username,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF9D0514),
                                          ),
                                        ),
                                      ),
                                    Text(message.msg),
                                    SizedBox(height: 2),
                                    Text(
                                      _formatDate(message.date),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Input para enviar mensajes
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, -1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _chatController,
                              decoration: InputDecoration(
                                hintText: 'Write a message...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendChatMessage(),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.send, color: Color(0xFF9D0514)),
                            onPressed: _sendChatMessage,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
      ),
    );
  }

  Widget _buildTimerIndicator() {
    return TweenAnimationBuilder(
      key: ValueKey(_animationRestartKey), // Use timeOut as the key to restart the animation
      duration: Duration(milliseconds: timeOut),
      tween: Tween<double>(begin: _animationValue, end: 0.0),
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
              player.playerAvatar.isNotEmpty
                  ? Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage('assets/images/avatar/${player.playerAvatar}.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : Icon(Icons.person, size: 40, color: player.active ? Colors.blue : Colors.grey),

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

  void animatePlayedCards(List<int> cardIndices) {
    if (cardIndices.isEmpty) return;

    setState(() {
      isAnimating = true;
      animatingCards.clear();

      for (int index in cardIndices) {
        // Create an animation controller for each card
        AnimationController controller = AnimationController(
          duration: Duration(milliseconds: 800),
          vsync: this,
        );

        // Get the card data
        CardJSON card = playerCards[index];
        String imagePath = 'assets/images/${card.type}.jpg';

        // Create animations for position and opacity
        Animation<double> moveAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutQuad,
        ));

        Animation<double> opacityAnimation = Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Interval(0.5, 1.0, curve: Curves.easeOut),
        ));

        // Store all animation data
        animatingCards.add({
          'controller': controller,
          'moveAnimation': moveAnimation,
          'opacityAnimation': opacityAnimation,
          'imagePath': imagePath,
          'index': index,
        });

        // Start animation with a slight delay for each card
        Future.delayed(Duration(milliseconds: 100 * animatingCards.length - 1), () {
          controller.forward().then((_) {
            // When the last animation completes, clear the list
            if (index == cardIndices.last) {
              setState(() {
                isAnimating = false;
                animatingCards.clear();
              });
            }
          });
        });
      }
    });
  }
}

String _formatDate(String dateStr) {
  try {
    // Intenta parsear como ISO 8601 primero
    DateTime date = DateTime.parse(dateStr);
    return DateFormat('HH:mm').format(date);
  } catch (e) {
    try {
      // formato dd/MM/yyyy HH:mm:ss
      List<String> parts = dateStr.split(' ');
      if (parts.length == 2) {
        List<String> dateParts = parts[0].split('/');
        List<String> timeParts = parts[1].split(':');

        if (dateParts.length == 3 && timeParts.length == 3) {
          DateTime date = DateTime(
            int.parse(dateParts[2]),  // año
            int.parse(dateParts[1]),  // mes
            int.parse(dateParts[0]),  // día
            int.parse(timeParts[0]),  // hora
            int.parse(timeParts[1]),  // minuto
            int.parse(timeParts[2]),  // segundo
          );
          return DateFormat('HH:mm').format(date);
        }
      }
      return DateFormat('HH:mm').format(DateTime.now());
    } catch (e) {
      return dateStr.contains(' ') ? dateStr.split(' ')[1].substring(0, 5) : 'Ahora';
    }
  }
}

// Method to show received cards (for actions like SeeFuture)
void showCardPopup(BuildContext context, List<String> cardImagePaths) {
  if (cardImagePaths.isEmpty) return;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: 200,
          padding: const EdgeInsets.all(20),
          child: Center(
            child: cardImagePaths.length > 1
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: cardImagePaths.map((path) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Image.asset(path, width: 80, height: 120),
                );
              }).toList(),
            )
                : Image.asset(cardImagePaths[0], width: 100, height: 150),
          ),
        ),
      );
    },
  );

  Future.delayed(const Duration(seconds: 1), () {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  });
}

class ShuffleAnimationWidget extends StatefulWidget {
  final VoidCallback? onComplete;

  const ShuffleAnimationWidget({super.key, this.onComplete});

  @override
  State<ShuffleAnimationWidget> createState() => _ShuffleAnimationWidgetState();
}

class _ShuffleAnimationWidgetState extends State<ShuffleAnimationWidget> with TickerProviderStateMixin {
  late AnimationController _mainShuffleController;
  late AnimationController _secondaryShuffleController;
  late AnimationController _sparkleController;
  bool _show = true;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _mainShuffleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _secondaryShuffleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _sparkleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();

    _mainShuffleController.forward().then((_) {
      _secondaryShuffleController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _sparkleController.stop();
          widget.onComplete?.call();
          Navigator.of(context).pop(); // <-- THIS LINE closes the dialog
        });
      });
    });
  }

  @override
  void dispose() {
    _mainShuffleController.dispose();
    _secondaryShuffleController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Sparkles
            for (int i = 0; i < 8; i++) _buildSparkle(),

            // Cards
            ...List.generate(3, (i) => _buildCard(i)),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(int index) {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainShuffleController, _secondaryShuffleController]),
      builder: (_, __) {
        double offset1 = 30.0 * sin(_mainShuffleController.value * pi + index);
        double offset2 = 10.0 * sin(_secondaryShuffleController.value * pi + index * 0.5);
        double rotation = 0.1 * sin((_mainShuffleController.value + _secondaryShuffleController.value) * pi + index);

        return Transform.translate(
          offset: Offset(offset1 + offset2 + (index - 1) * 20, 0),
          child: Transform.rotate(
            angle: rotation,
            child: Opacity(
              opacity: 1.0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 140,
                height: 200,
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage('assets/images/back_card.jpg'), // Your card back image
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(2, 4)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSparkle() {
    double top = _random.nextDouble() * 100 - 50;
    double left = _random.nextDouble() * 150 - 75;
    double size = 6 + _random.nextDouble() * 6;

    return AnimatedBuilder(
      animation: _sparkleController,
      builder: (_, __) {
        double offsetY = 10 * sin(_sparkleController.value * 2 * pi);
        double opacity = 0.5 + 0.5 * cos(_sparkleController.value * 2 * pi);

        return Positioned(
          top: 60 + top + offsetY,
          left: 100 + left,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}

class BombExplosionDialog extends StatefulWidget {
  final String eliminatedPlayer;

  const BombExplosionDialog({super.key, required this.eliminatedPlayer});

  @override
  State<BombExplosionDialog> createState() => _BombExplosionDialogState();
}

class _BombExplosionDialogState extends State<BombExplosionDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _explosionScale;
  bool _showExplosion = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _explosionScale = Tween<double>(begin: 0.0, end: 1.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            setState(() {
              _showExplosion = false;
            });

            // Auto-dismiss after 2 more seconds
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) Navigator.of(context).pop();
            });
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black87.withOpacity(0.85),
      child: Container(
        width: 300,
        height: 300,
        padding: const EdgeInsets.all(20),
        child: Center(
          child: _showExplosion
              ? ScaleTransition(
            scale: _explosionScale,
            child: Image.asset('assets/images/explosion.jpg',
                width: 150, height: 150),
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning,
                  color: Colors.red, size: 50),
              const SizedBox(height: 12),
              Text(
                '${widget.eliminatedPlayer} has been eliminated!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BombDiffusedDialog extends StatelessWidget {
  final String player;

  const BombDiffusedDialog({Key? key, required this.player}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Schedule dialog to close after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    });

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/diffuse_cat.jpg', height: 150),
            const SizedBox(height: 20),
            Text(
              '$player has successfully defused the bomb!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FutureSeenDialog extends StatelessWidget {
  final String player;

  FutureSeenDialog({required this.player});

  @override
  Widget build(BuildContext context) {
    // Close the dialog after 1 second
    Future.delayed(Duration(seconds: 1), () {
      Navigator.of(context).pop();
    });

    return AlertDialog(
      title: Text('Future Seen'),
      content: Text('$player has seen the future!'),
    );
  }
}

