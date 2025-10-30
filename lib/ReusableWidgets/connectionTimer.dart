// ignore_for_file: file_names
import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConnectionTimer extends StatefulWidget {
  const ConnectionTimer({super.key});

  @override
  State<ConnectionTimer> createState() => _ConnectionTimerState();
}

class _ConnectionTimerState extends State<ConnectionTimer> {
  Duration duration = Duration();
  late Timer timer;

  @override
  void initState() {
    super.initState();
    loadStoredTime();
    startTimer();
  }

  /// Load the stored time (if exists) from GetStorage
  Future<void> loadStoredTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    log('Time loaded from storage: ${prefs.getString('connectTime')}');
    final storedTime = DateTime.parse(
      prefs.getString('connectTime') ?? DateTime.now().toString(),
    );
    duration = DateTime.now().difference(storedTime);
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        duration = duration + Duration(seconds: 1);
      });
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String twoDigit(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigit(duration.inHours);
    final minutes = twoDigit(duration.inMinutes.remainder(60));
    final seconds = twoDigit(duration.inSeconds.remainder(60));

    return Text(
      '$hours:$minutes:$seconds',
      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
    );
  }
}
