import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  runApp(MaterialApp(home: GameScreen()));
}

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

/*
class _GameScreenState extends State<GameScreen> {
  List<dynamic> players = [];
  List<dynamic> cards = [];

  @override
  void initState() {
    super.initState();
    fetchGameData();
  }

  Future<void> fetchGameData() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:3000/game/play'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        players = data['players'];
        cards = data['cards'];
      });
    } else {
      throw Exception('Error al cargar datos');
    }
  }

 */

class _GameScreenState extends State<GameScreen> {
  List<dynamic> players = [
    {'Player1': 3},
    {'Player2': 5},
    {'Player3': 4},
  ];
  List<dynamic> cards = [
    {'Attack': 1},
    {'BeardCat': 2},
    {'Cattermelon': 3},
    {'Nope': 4},
    {'Nope': 5},
    {'Skip': 6},
    {'Tacocat': 7},
  ];

  final ScrollController _scrollController = ScrollController(); // Controlador para el Scrollbar
  List<int> selectedCards = [];


  int remainingTime = 60;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingTime > 0) {
          remainingTime--;
        } else {
          timer.cancel();
          endTurn();
        }
      });
    });
  }

  void endTurn() {
    // Lógica para terminar el turno del jugador actual
    print("Turno terminado");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Game Info'),
        automaticallyImplyLeading: false,),
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
                Text('username', style: TextStyle(color: Colors.white, fontSize: 18)),
                SizedBox(width: 8),
                Icon(Icons.monetization_on, color: Colors.yellow, size: 30),
                SizedBox(width: 4),
                Text('5 coins', style: TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
          ),
          if (players.length >= 1)
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
            bottom: 290,
            left: MediaQuery.of(context).size.width / 2 - 60,
            child: Container(
              margin: EdgeInsets.all(8.0),
              padding: EdgeInsets.all(16.0),
              height: 150,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
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
                  onPressed: selectedCards.length >= 1 && selectedCards.length <= 3
                      ? () {
                    // Acción de jugar cartas
                  }
                      : null,
                  child: Text('Play Cards'),
                ),
                SizedBox(width: 60),
                ElevatedButton(
                  onPressed: () {
                    // Acción de robar carta
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
                    children: cards.map((card) {
                      String cardName = card.keys.first;
                      int cardID = card.values.first;
                      String imagePath = 'assets/images/$cardName.jpg';
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (selectedCards.contains(cardID)) {
                              selectedCards.remove(cardID);
                            } else {
                              selectedCards.add(cardID);
                            }
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 8.0),
                          //padding: EdgeInsets.all(16.0),
                          height: 150,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selectedCards.contains(cardID) ? Colors.blue : Colors.transparent,
                              width: 3,
                            ),
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

  Widget buildPlayerCard(Map<String, dynamic> player) {
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
          '${player.keys.first}: ${player.values.first} cards',
          style: TextStyle(color: Colors.black, fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
