import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:passenger_app/core/routing/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int secondsRemaining = 3;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() async {
    await Future.delayed(Duration(seconds: secondsRemaining));
    if (mounted) {
      context.goNamed(sessionRoute.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_taxi,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}