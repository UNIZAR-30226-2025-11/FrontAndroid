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
  final int coins=3;
  final Map<String, dynamic> initialGameState;

  GameScreen({required this.socket, required this.lobbyId, required this.initialGameState, required this.username});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin{
  late IO.Socket socket;
  bool error = false;
  String errorMsg = "";
  List<String> playerCards = [];
  List<PlayerJSON> players = [];
  int turn = 0;
  int timeOut = 0;

  final ScrollController _scrollController = ScrollController();
  List<int> selectedCards = [];
  int remainingTime = 60;
  late Timer timer;
  late String username;

  List<Map<String, dynamic>> animatingCards = [];
  bool isAnimating = false;

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
        playerCards = List<String>.from(jsonDecode(data['playerCards']));
        print(data['playerCards']);  // Para ver qué tipo de dato es
        players = (data['players'] as List)
            .map((player) => PlayerJSON.fromJson(player))
            .toList();
        turn = data['turn'];
        timeOut = data['timeOut'];
      });
      print('fin');
    }
    setupSocketListeners();
    startTimer();
  }

  void setupSocketListeners() {
    socket.on('game-state', (data) {
      if (mounted) {  // Add this check
        setState(() {
          error = data['error'];
          errorMsg = data['errorMsg'];
          playerCards = List<String>.from(jsonDecode(data['playerCards']));
          players = (data['players'] as List)
              .map((player) => PlayerJSON.fromJson(player))
              .toList();
          turn = data['turn'];
          timeOut = data['timeOut'];
        });
      }
    });


    remainingTime = timeOut;

    void accion(BackendNotifyActionJSON action) {
      // TODO: realizar accion según campo action
    }

    socket.on('notify-action', (data) {
      setState(() {
        BackendNotifyActionJSON action = BackendNotifyActionJSON.fromJson(data);
        accion(action);
      });
    });

    void winner(BackendWinnerJSON winnerData) {
      // TODO: Implementar la lógica para manejar el evento 'winner'
      if (winnerData.error) {
        print('Error: ${winnerData.errorMsg}');
      } else {
        print('Jugador ${winnerData.userId} ha ganado y ha ganado ${winnerData
            .coinsEarned} coins');
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
        BackendGameSelectPlayerJSON SelectPlayerData = BackendGameSelectPlayerJSON.fromJson(data);
        //TODO: el usuario elegirá el player
        int selectedUserId = 1;
        FrontendGameSelectPlayerResponseJSON response = FrontendGameSelectPlayerResponseJSON(
          error: false,
          errorMsg: "",
          userId: selectedUserId,
          lobbyId: widget.lobbyId,
        );
        socket.emit('game-select-player', response.toJson());
      });
    });

    socket.on('game-select-card', (data) {
      setState(() {
        BackendGameSelectCardJSON SelectCardData = BackendGameSelectCardJSON.fromJson(data);
        //TODO: el usuario elegirá la carta
        String selectedCard = "Attack";
        FrontendGameSelectCardResponseJSON response = FrontendGameSelectCardResponseJSON(
          error: false,
          errorMsg: "",
          card: selectedCard,
          lobbyId: widget.lobbyId,
        );
        socket.emit('game-select-card', response.toJson());
      });
    });


    socket.on('game-select-card-type', (data) {
      setState(() {
        BackendGameSelectCardTypeJSON SelectCardTypeData = BackendGameSelectCardTypeJSON.fromJson(data);
        //TODO: el usuario elegirá el tipo de carta
        String selectedCard = "Attack";
        FrontendGameSelectCardTypeResponseJSON response = FrontendGameSelectCardTypeResponseJSON(
          error: false,
          errorMsg: "",
          cardType: selectedCard,
          lobbyId: widget.lobbyId,
        );
        socket.emit('game-select-card-type', response.toJson());
      });
    });


  }


  void sendGameAction(List<int> selectedCardIndices) {
    List<String> playedCards = selectedCardIndices.isEmpty
        ? []  // Si la lista está vacía, asignamos una lista vacía
        : selectedCardIndices.map((index) => playerCards[index]).toList();

    // Usar jsonEncode para convertir la lista a una cadena JSON (incluso si es vacía)
    String playedCardsJson = jsonEncode(playedCards);

    print('enviando cartas');
    print(playedCardsJson);

    FrontendGamePlayedCardsJSON gamePlayedData = FrontendGamePlayedCardsJSON(
      error: false,
      errorMsg: "",
      playedCards: playedCardsJson,
      lobbyId: widget.lobbyId,
    );

    socket.emit('game-played-cards', gamePlayedData.toJson());

    print("cartas enviadas");

    socket.on('game-played-cards', (data) {
      print("respuesta a cartas recibida");
      BackendGamePlayedCardsResponseJSON response = BackendGamePlayedCardsResponseJSON
          .fromJson(data);

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
          if (response.cardsReceived != ""){
            playedCards.add(response.cardsReceived);
          }
        });
      }
    });
  }



  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingTime > 0) {
        setState(() {
          remainingTime--;
        });
      } else {
        timer.cancel();
        List<int> empty = [];
        sendGameAction(empty);
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
      body: Stack(
        children: [
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              children: [
                Icon(Icons.person, color: Colors.white, size: 30),
                SizedBox(width: 8),
                Text(widget.username, style: TextStyle(color: Colors.white, fontSize: 18)),
                SizedBox(width: 8),
                Icon(Icons.monetization_on, color: Colors.yellow, size: 30),
                SizedBox(width: 4),
                Text('${widget.coins} coins', style: TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
          ),
        // Only display other players, not the current player
          if (players.isNotEmpty)
            Positioned(
              top: 50,
              left: MediaQuery.of(context).size.width / 2 - 60,
              child: buildPlayerCard(players[0]),
            ),
          if (players.length >= 2)
            Positioned(
              bottom: 400,
              left: 25,
              child: buildPlayerCard(players[1]),
            ),
          if (players.length >= 3)
            Positioned(
              bottom: 400,
              right: 25,
              child: buildPlayerCard(players[2]),
            ),
          Positioned(
            bottom: 220,
            left: MediaQuery.of(context).size.width / 2 - 15,
            child: SizedBox(
              width: 25,
              height: 25,
              child: CircularProgressIndicator(
                value: remainingTime / 60,
                backgroundColor: Colors.grey,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                strokeWidth: 25,
              ),
            ),
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
                      String cardName = entry.value;
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
                            boxShadow: isSelected ? [
                              BoxShadow(
                              color: Colors.yellow.withOpacity(0.8),
                              blurRadius: 10,
                              spreadRadius: 2,
                              )
                              ] : [],
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
        ]
      ),
    );

  }

  Widget buildPlayerCard(PlayerJSON player) {
    // Determinar el color de fondo según si el jugador está activo
    Color backgroundColor = player.active ? Colors.white : Colors.grey[400]!;

    return Container(
      margin: EdgeInsets.all(8.0),
      padding: EdgeInsets.all(16.0),
      height: 150,
      width: 160,
      decoration: BoxDecoration(
        color: backgroundColor, // Color de fondo dinámico
        borderRadius: BorderRadius.circular(10),
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
          // Ícono de jugador
          Icon(
            Icons.person,
            size: 40,
            color: player.active ? Colors.blue : Colors.grey,
          ),
          SizedBox(width: 16),
          // Texto con el número de cartas
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Player ${player.id}',
                style: TextStyle(
                  color: player.active ? Colors.black : Colors.grey[600],
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '${player.numCards} cards',
                style: TextStyle(
                  color: player.active ? Colors.black : Colors.grey[600],
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
