import 'package:flutter/material.dart';
import 'package:very_good_coffee/presentation/brew_swipe/brew_swipe_page.dart';

void main() {
  runApp(const VeryGoodCoffeeApp());
}

class VeryGoodCoffeeApp extends StatelessWidget {
  const VeryGoodCoffeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Very Good Coffee',
      theme: ThemeData(
        colorSchemeSeed: Colors.brown,
        useMaterial3: true,
      ),
      home: const BrewSwipePage(),
    );
  }
}
