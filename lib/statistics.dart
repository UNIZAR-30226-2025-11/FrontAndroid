import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';

class StatisticsScreen extends StatefulWidget {
  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int gamesWon = 0;
  int gamesLost = 0;
  int totalGames = 0;
  List<Map<String, String>> lastFiveGames = [];

  @override
  void initState() {
    super.initState();
    fetchStatistics();
  }

  Future<void> fetchStatistics() async {
    await Future.delayed(Duration(seconds: 2)); // Simulating network delay
    setState(() {
      gamesWon = 25;
      gamesLost = 15;
      totalGames = gamesWon + gamesLost;
      lastFiveGames = [
        {'result': 'Win'},
        {'result': 'Loss'},
        {'result': 'Win'},
        {'result': 'Loss'},
        {'result': 'Win'},
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: Text('Statistics')),
      backgroundColor: Color(0xFF9D0514),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Game Statistics', style:
                                    Theme.of(context).textTheme.headlineMedium),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY:
                                    gamesWon.toDouble(), color: Colors.green)]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY:
                                    gamesLost.toDouble(), color: Colors.red)]),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          switch (value.toInt()) {
                            case 0:
                              return Text('Wins');
                            case 1:
                              return Text('Losses');
                            default:
                              return Container();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text('Total Games Played: $totalGames'),
            Text('Games Won: $gamesWon'),
            Text('Games Lost: $gamesLost'),
            SizedBox(height: 16),
            Text('Last 5 Games:', style: Theme.of(context).textTheme.titleSmall),
            Column(
              children: lastFiveGames.map((game) => ListTile(
                leading: Icon(game['result'] == 'Win' ? Icons.check : Icons.close, color: game['result'] == 'Win' ? Colors.green : Colors.red),
                title: Text('${game['result']}'),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
