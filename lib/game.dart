import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
    {'Card1': 1},
    {'Card2': 2},
    {'Card3': 3},
    {'Card4': 4},
    {'Card5': 5},
    {'Card6': 6},
    {'Card7': 7},
  ];

  final ScrollController _scrollController = ScrollController(); // Controlador para el Scrollbar

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Game Info')),
      body: Stack(
        children: [
          if (players.length >= 1)
            Positioned(
              top: 50,
              left: MediaQuery.of(context).size.width / 2 - 60,
              child: buildPlayerCard(players[0]),
            ),
          if (players.length >= 2)
            Positioned(
              bottom: 350,
              left: 50,
              child: buildPlayerCard(players[1]),
            ),
          if (players.length >= 3)
            Positioned(
              bottom: 350,
              right: 50,
              child: buildPlayerCard(players[2]),
            ),

          // Barra deslizable de cartas
          Positioned(
            bottom: 20,
            left: MediaQuery.of(context).size.width / 2 - 150,
            child: Container(
              height: 180,
              width: 300, // Define un ancho para la barra de cartas
              child: Scrollbar(
                controller: _scrollController, // Asigna el controlador
                thumbVisibility: true, // Hace visible el scrollbar
                child: SingleChildScrollView(
                  controller: _scrollController, // Usa el mismo controlador
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: cards.map((card) {
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 8.0),
                        padding: EdgeInsets.all(16.0),
                        height: 150,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            card.keys.first,
                            style: TextStyle(color: Colors.white, fontSize: 16),
                            textAlign: TextAlign.center,
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
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          '${player.keys.first}: ${player.values.first} cards',
          style: TextStyle(color: Colors.white, fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}