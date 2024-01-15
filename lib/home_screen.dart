import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  final String gender;

  HomeScreen({Key? key, required this.gender}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class LogEntry {
  double amount;
  DateTime time;

  LogEntry({required this.amount, required this.time});
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  double sum = 0.0;
  double percentage = 0.0;
  double _currentPercentage = 0.0;
  DateTime currentDate = DateTime.now();
  List<LogEntry> logEntries = [];
  late AnimationController _controller;
  late Animation<double> _indicatorAnimation;
  late Timer dataRefreshTimer;
  Duration refreshDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    );
    _animateIndicator();
    fetchDataFromThingSpeak(currentDate);
    startDataRefreshTimer();
  }

  void startDataRefreshTimer() {
    dataRefreshTimer = Timer.periodic(refreshDuration, (timer) {
      fetchDataFromThingSpeak(currentDate);
    });
  }

  void _animateIndicator() {
    final double startValue = _currentPercentage;
    final double endValue = percentage;

    _indicatorAnimation = Tween<double>(
      begin: startValue,
      end: endValue,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward(from: 0);

    _controller.addListener(() {
      setState(() {
        _currentPercentage = _indicatorAnimation.value;
      });
    });
  }

  Future<void> fetchDataFromThingSpeak(DateTime selectedDay) async {
    try {
      String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDay);
      var url = Uri.parse(
          'https://api.thingspeak.com/channels/2396033/feeds.json?start=$formattedDate%2000:00:00');

      var response = await http.get(url);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        List feeds = data['feeds'];

        List<LogEntry> newLogEntries = [];

        for (var feed in feeds) {
          var value = double.tryParse(feed['field2'].toString());
          if (value != null) {
            DateTime time = DateTime.parse(feed['created_at']);

            bool isAlreadyAdded = logEntries.any((entry) =>
                entry.amount == value &&
                entry.time.isAtSameMomentAs(time.toLocal()));

            if (!isAlreadyAdded) {
              newLogEntries.add(LogEntry(amount: value, time: time.toLocal()));
            }
          }
        }

        logEntries.addAll(newLogEntries);

        double dailyTotal = widget.gender == 'male' ? 2500.0 : 2000.0;
        sum = logEntries.fold(0, (prev, entry) => prev + entry.amount);
        percentage = sum / dailyTotal;
        _animateIndicator();

        setState(() {});
      } else {
        print('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final darkTheme = ThemeData.dark().copyWith(
      scaffoldBackgroundColor: Colors.black,
      primaryColor: Colors.white,
      hintColor: Colors.white24,
      textTheme: TextTheme(
        bodyText2: TextStyle(color: Colors.white),
      ),
    );

    double dailyTotal = widget.gender == 'male' ? 2500.0 : 2000.0;
    String consumptionDisplay =
        '${sum.toStringAsFixed(0)}ml / ${dailyTotal.toStringAsFixed(0)}ml';
    return MaterialApp(
      theme: darkTheme,
      home: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          toolbarHeight: 0,
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Smart Drinking',
                style: TextStyle(
                  fontFamily: 'Pacifico',
                  fontSize: 35,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    '${currentDate.isAtSameMomentAs(DateTime.now()) ? "Today" : DateFormat('yyyy-MM-dd').format(currentDate)}',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            Center(
              child: sum == 0
                  ? CircularProgressIndicator()
                  : AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                height: 150,
                                width: 150,
                                child: CircularProgressIndicator(
                                  value: _currentPercentage,
                                  strokeWidth: 10,
                                  backgroundColor: Colors.grey[700],
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                ),
                              ),
                              Text(
                                '${(_currentPercentage * 100).toStringAsFixed(2)}%',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                consumptionDisplay,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: logEntries.length,
                itemBuilder: (context, index) {
                  LogEntry entry = logEntries[index];
                  if (entry.time.day == currentDate.day) {
                    return ListTile(
                      title: Text(
                        'Amount: ${entry.amount.toStringAsFixed(2)} ml',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        'Date: ${DateFormat('yyyy-MM-dd').format(entry.time)}\nTime: ${DateFormat('HH:mm').format(entry.time)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    );
                  } else {
                    return SizedBox.shrink();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    dataRefreshTimer.cancel();
    super.dispose();
  }
}

void main() {
  runApp(HomeScreen(gender: 'male'));
}
