import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'overlays/game_over_menu.dart';
import 'overlays/pause_button.dart';
import 'overlays/pause_menu.dart';
import 'game.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flame/flame.dart';

Future<void> main() async {
  await Hive.initFlutter();
  await Flame.device.fullScreen();
  runApp(const PlatformView());
}

class PlatformView extends StatelessWidget {
  const PlatformView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Platform View',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.blue,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Image.asset(
                          'assets/images/ship_H.png',
                          width: 200,
                          height: 200,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const MyGamePage()),
                            );
                          },
                          child: const Text('Start Game'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MyGamePage extends StatefulWidget {
  const MyGamePage({super.key});

  @override
  State createState() => _MyGamePageState();
}

class _MyGamePageState extends State<MyGamePage> {
  late final SpaceShooterGame _game;

  @override
  void initState() {
    super.initState();
    _game = SpaceShooterGame();
  }

  @override
  Widget build(BuildContext context) {
    return GameWidget(
      game: _game,
      initialActiveOverlays: const [PauseButton.id],
      overlayBuilderMap: {
        PauseButton.id: (BuildContext context, SpaceShooterGame gameRef) =>
            PauseButton(
              gameRef: gameRef,
            ),
        PauseMenu.id: (BuildContext context, SpaceShooterGame gameRef) =>
            PauseMenu(
              gameRef: gameRef,
            ),
        GameOverMenu.id: (BuildContext context, SpaceShooterGame gameRef) =>
            GameOverMenu(
              gameRef: gameRef,
            ),
      },
    );
  }
}
