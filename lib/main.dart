import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:very_good_coffee/domain/entities/coffee_image.dart';
import 'package:very_good_coffee/domain/entities/coffee_image_hive.dart';
import 'package:very_good_coffee/presentation/brew_swipe/brew_swipe_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(CoffeeImageAdapter());
  }
  await Hive.openBox<CoffeeImage>('favorites');
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
