import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

import 'SessionManager.dart';
import 'models/models.dart';

class StatisticsScreen extends StatefulWidget {
  final String username;
  const StatisticsScreen({Key? key, required this.username}) : super(key: key);

  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  UserJSON? userData;
  late String username;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    username = widget.username;
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // First ensure we have the username
      if (username.isEmpty) {
        final String? user = await SessionManager.getUsername();
        if (user != null && user.isNotEmpty) {
          username = user;
        } else {
          throw Exception("Username not available");
        }
      }

      // Then fetch the user data
      final String? token = await SessionManager.getSessionData();
      if (token == null || token.isEmpty) {
        throw Exception("Authentication token not available");
      }

      final res = await http.get(
          Uri.parse('http://10.0.2.2:8000/user'),
          headers: {
            'Cookie': 'access_token=$token',
          }
      );

      final data = jsonDecode(res.body);

      if (res.statusCode != 200) {
        var errorMessage = data.containsKey('message')
            ? data['message']
            : "Server error: ${res.statusCode}";
        throw Exception(errorMessage);
      }

      // Parsear los datos usando nuestras clases JSON
      setState(() {
        userData = UserJSON.fromJson(data);
      });
    } catch (e) {
      print("Error fetching user data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"))
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Obtener el número de partidas perdidas
  int get gamesLost => (userData?.statistics.gamesPlayed ?? 0) - (userData?.statistics.gamesWon ?? 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF9D0514),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.white))
          : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User and coins info row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // User info
                  Row(
                    children: [
                      Icon(Icons.person, size: 30, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        userData?.username ?? username,
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                  // Coins info
                  Row(
                    children: [
                      Icon(Icons.monetization_on, color: Colors.yellow, size: 30),
                      SizedBox(width: 8),
                      Text(
                        '${userData?.coins ?? 0}',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 24),
              Text(
                'Game Statistics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 32),
              (userData?.statistics.gamesPlayed ?? 0) > 0
                  ? Container(
                height: 240,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    barGroups: [
                      BarChartGroupData(x: 0, barRods: [
                        BarChartRodData(
                          toY: (userData?.statistics.gamesWon ?? 0).toDouble(),
                          color: Colors.green,
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(4)
                          ),
                        )
                      ]),
                      BarChartGroupData(x: 1, barRods: [
                        BarChartRodData(
                          toY: gamesLost.toDouble(),
                          color: Colors.red,
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(4)
                          ),
                        )
                      ]),
                    ],
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            switch (value.toInt()) {
                              case 0:
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Wins',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              case 1:
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Losses',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              default:
                                return Container();
                            }
                          },
                          reservedSize: 40,
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              )
                  : Center(
                child: Text(
                  'No games played yet',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              SizedBox(height: 24),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Summary',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Total Games Played: ${userData?.statistics.gamesPlayed ?? 0}',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Games Won: ${userData?.statistics.gamesWon ?? 0}',
                      style: TextStyle(color: Colors.green, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Games Lost: $gamesLost',
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Current Streak: ${userData?.statistics.currentStreak ?? 0}',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Best Streak: ${userData?.statistics.bestStreak ?? 0}',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Total Time Played: ${_formatPlayTime(userData?.statistics.totalTimePlayed ?? 0)}',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Total Turns Played: ${userData?.statistics.totalTurnsPlayed ?? 0}',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              if ((userData?.statistics.lastFiveGames.length ?? 0) > 0) ...[
                Text(
                  'Recent Games',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: userData?.statistics.lastFiveGames
                        .map((game) => ListTile(
                      leading: Icon(
                        game.isWinner ? Icons.check_circle : Icons.cancel,
                        color: game.isWinner ? Colors.green : Colors.red,
                        size: 28,
                      ),
                      title: Text(
                        '${game.isWinner ? 'Win' : 'Loss'} - ${_formatDate(game.gameDate)}',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Lobby: ${game.lobbyId}',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ))
                        .toList() ?? [],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Función para formatear el tiempo de juego
  String _formatPlayTime(int seconds) {
    if (seconds < 60) {
      return '$seconds seconds';
    } else if (seconds < 3600) {
      int minutes = seconds ~/ 60;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    } else {
      int hours = seconds ~/ 3600;
      int remainingMinutes = (seconds % 3600) ~/ 60;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} $remainingMinutes ${remainingMinutes == 1 ? 'minute' : 'minutes'}';
    }
  }

  // Función para formatear la fecha
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}