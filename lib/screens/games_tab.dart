import 'package:flutter/material.dart';

class GamesTab extends StatelessWidget {
  const GamesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Games Coming Soon',
          style: TextStyle(fontSize: 24, color: Colors.grey),
        ),
      ),
    );
  }
}
