import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'models/models.dart';





class GameScreen extends StatefulWidget {
  final IO.Socket socket;
  final String lobbyId;
  final String username="user";
  final int coins=3;
  final Map<String, dynamic> initialGameState;

  GameScreen({required this.socket, required this.lobbyId, required this.initialGameState});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
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

  @override
  void initState() {
    super.initState();
    socket = widget.socket;
    if (widget.initialGameState.isNotEmpty) {
      dynamic data = widget.initialGameState;
      setState(() {
        error = data['error'];
        errorMsg = data['errorMsg'];
        playerCards = List<String>.from(data['playerCards']);
        players = (data['players'] as List)
            .map((player) => PlayerJSON.fromJson(player))
            .toList();
        turn = data['turn'];
        timeOut = data['timeOut'];
      });
    }
    setupSocketListeners();
    startTimer();
  }

  void setupSocketListeners() {
    print("Listens ");
    socket.on('game-state', (data) {
      print("game-state");
      setState(() {
        error = data['error'];
        errorMsg = data['errorMsg'];
        playerCards = List<String>.from(data['playerCards']);
        players = (data['players'] as List)
            .map((player) => PlayerJSON.fromJson(player))
            .toList();
        turn = data['turn'];
        timeOut = data['timeOut'];
      });
    });

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
    List<String> playedCards = selectedCardIndices.map((index) => playerCards[index]).toList();

    FrontendGamePlayedCardsJSON gamePlayedData = FrontendGamePlayedCardsJSON(
      error: false,
      errorMsg: "",
      playedCards: playedCards.join(", "),
      lobbyId: widget.lobbyId,
    );

    // Enviar el evento al servidor
    socket.emit('game-played-cards', gamePlayedData.toJson());

    socket.once('game-played-cards-response', (data) {
      BackendGamePlayedCardsResponseJSON response = BackendGamePlayedCardsResponseJSON
          .fromJson(data);

      if (response.error) {
        setState(() {
          error = true;
          errorMsg = response.errorMsg;
        });
      } else {
        setState(() {
          //TODO: COMPROBAR QUE ACTUALIZA EL ESTADO
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
    socket.off('game-state');
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Game Info'),
        automaticallyImplyLeading: false,
      ),
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
          if (players.isNotEmpty)
            Positioned(
              top: 50,
              left: MediaQuery.of(context).size.width / 2 - 60,
              child: buildPlayerCard(players[0]),
            ),
          if (players.length >= 2)
            Positioned(
              bottom: 460,
              left: 25,
              child: buildPlayerCard(players[1]),
            ),
          if (players.length >= 3)
            Positioned(
              bottom: 460,
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
                    sendGameAction(selectedCards);
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
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 8.0),
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
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPlayerCard(PlayerJSON player) {
    return Container(
      margin: EdgeInsets.all(8.0),
      padding: EdgeInsets.all(16.0),
      height: 150,
      width: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          'Player ${player.id}: ${player.numCards} cards',
          style: TextStyle(color: Colors.black, fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
