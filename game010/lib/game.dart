import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import 'package:flutter/material.dart';
import 'package:flame/collisions.dart';
import 'package:flame/parallax.dart';
import 'package:hive/hive.dart';
import 'package:flame_audio/flame_audio.dart';
import 'overlays/game_over_menu.dart';

class SpaceShooterGame extends FlameGame
    with HasCollisionDetection, PanDetector, TapDetector {
  bool _isAlreadyLoaded = false;
  late Enemy _enemy;
  late EnemyManager _enemyManager;
  late Player _player;
  late Bullet _bullet;
  late TextComponent _scoreText;
  int _score = 0;
  late TextComponent _playerhealth;
  int _health = 100;
  late AudioPlayerComponent _audioPlayerComponent;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    if (!_isAlreadyLoaded) {
      camera.viewport = FixedResolutionViewport(Vector2(360, 640));
      final parallax = await loadParallaxComponent(
        [
          ParallaxImageData('stars1.png'),
        ],
        repeat: ImageRepeat.repeat,
        baseVelocity: Vector2(0, -50),
        velocityMultiplierDelta: Vector2(0, 1.5),
      );
      add(parallax);

      _enemy = Enemy();
      add(_enemy);
      _enemyManager = EnemyManager();
      add(_enemyManager);
      _player = Player();
      _bullet = Bullet();

      add(_bullet);
      add(_player);
      _scoreText = TextComponent(
        text: 'Score: 0',
        position: Vector2(10, 10),
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontFamily: 'BungeeInline',
          ),
        ),
      );
      add(_scoreText);

      _playerhealth = TextComponent(
        text: 'Health: 100',
        position: Vector2(10, 30),
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontFamily: 'BungeeInline',
          ),
        ),
      );
      add(_playerhealth);
      _audioPlayerComponent = AudioPlayerComponent();
      add(_audioPlayerComponent);
      _audioPlayerComponent.playBgm();
    }
    _isAlreadyLoaded = true;
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    _player.move(info.delta.game);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _scoreText.text = 'Score: $_score';
    _playerhealth.text = 'Health: $_health';
    if (_health <= 0) {
      _health = 0;
      _playerhealth.text = 'Health: $_health';
      overlays.add(GameOverMenu.id);
      pauseEngine();
      _audioPlayerComponent.stopBgm();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
  }

  Future<void> updateScore(int score) async {
    final box = await Hive.openBox('scoreBox');
    _score = score;
    await box.put('score', _score);
  }

  void addScore(int score) async {
    _score += score;
    await updateScore(_score);
  }

  void reduceHealth(int health) {
    _health -= health;
    _playerhealth.text = 'Health: $_health';
  }

  void addHealth(int health) {
    _health += health;
    _playerhealth.text = 'Health: $_health';
  }

  @override
  void onDetach() {
    super.onDetach();
    _audioPlayerComponent.stopBgm();
  }

  void reset() {
    _player.reset();
    _enemyManager.reset();

    _score = 0;
    _scoreText.text = 'Score: $_score';
    _health = 100;
    _playerhealth.text = 'Health: $_health';
    _playerhealth.textRenderer = TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontFamily: 'BungeeInline',
      ),
    );

    children.whereType<Enemy>().forEach((enemy) {
      enemy.removeFromParent();
    });

    children.whereType<Bullet>().forEach((bullet) {
      bullet.removeFromParent();
    });
  }

  void stopBgm() {
    _audioPlayerComponent.stopBgm();
  }

  void playBgm() {
    _audioPlayerComponent.playBgm();
  }
}

class Player extends SpriteComponent
    with CollisionCallbacks, HasGameRef<SpaceShooterGame> {
  double shootRate = 0.5;
  double lastShootTime = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await gameRef.loadSprite('ship_H.png');
    position = Vector2(gameRef.size.x / 2, gameRef.size.y - 100);
    width = 60;
    height = 70;
    anchor = Anchor.center;
  }

  void shoot() {
    final bullet = Bullet();
    bullet.position = position;
    gameRef.add(bullet);
  }

  void move(Vector2 delta) {
    position.add(delta);
  }

  @override
  void update(double dt) {
    super.update(dt);
    lastShootTime += dt;
    if (lastShootTime >= shootRate) {
      lastShootTime = 0;
      shoot();
    }
  }

  @override
  void onMount() {
    super.onMount();
    final shape = CircleHitbox.relative(
      0.8,
      parentSize: size,
      position: size / 2,
      anchor: Anchor.center,
    );
    add(shape);
  }

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    super.onCollision(points, other);
    if (other is Enemy) {
      gameRef.camera.shake(intensity: 20);
      gameRef._audioPlayerComponent.playSfx('error.wav');
    }
  }

  void reset() {
    position = Vector2(gameRef.size.x / 2, gameRef.size.y - 100);
  }
}

class Bullet extends SpriteComponent
    with CollisionCallbacks, HasGameRef<SpaceShooterGame> {
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    sprite = await gameRef.loadSprite('ship_B.png');

    width = 10;
    height = 10;
    anchor = Anchor.center;
  }

  @override
  void onMount() {
    super.onMount();
    final shape = CircleHitbox.relative(
      0.8,
      parentSize: size,
      position: size / 2,
      anchor: Anchor.center,
    );
    add(shape);
  }

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    super.onCollision(points, other);
    if (other is Enemy) {
      gameRef.remove(this);
      gameRef.addScore(10);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    position.add(Vector2(0, -100 * dt));

    if (position.y < 0) {
      gameRef.remove(this);
    }
  }
}

class EnemyManager extends Component with HasGameRef<SpaceShooterGame> {
  double enemyRate = 0.5;

  double enemySpeed = 100;

  double enemyCreateRate = 0.5;

  @override
  void update(double dt) {
    super.update(dt);
    enemyRate -= dt;
    enemyCreateRate -= dt;
    if (enemyRate <= 0) {
      enemyRate = 0.5;
      enemySpeed += 10;
    }
    if (enemyCreateRate <= 0) {
      enemyCreateRate = 0.5;
      createEnemy();
    }
  }

  void createEnemy() {
    final enemy = Enemy();
    enemy.position = Vector2(
      Random().nextDouble() * gameRef.size.x,
      0,
    );
    gameRef.add(enemy);
  }

  void reset() {
    enemyRate = 0.5;
    enemySpeed = 100;
    enemyCreateRate = 0.5;
  }
}

class Enemy extends SpriteComponent
    with CollisionCallbacks, HasGameRef<SpaceShooterGame> {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await gameRef.loadSprite('enemy.png');
    width = 60;
    height = 70;
    anchor = Anchor.center;
  }

  @override
  void onMount() {
    super.onMount();

    final shape = CircleHitbox.relative(
      0.8,
      parentSize: size,
      position: size / 2,
      anchor: Anchor.center,
    );
    add(shape);
  }

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    super.onCollision(points, other);
    if (other is Bullet) {
      gameRef.remove(this);
    } else if (other is Player) {
      gameRef.remove(this);
      gameRef.reduceHealth(10);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    position.add(Vector2(0, 100 * dt));

    if (position.y > gameRef.size.y) {
      gameRef.remove(this);
    }
  }

  final _hpText = TextComponent(
    text: '10 HP',
    textRenderer: TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontFamily: 'BungeeInline',
      ),
    ),
  );

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _hpText.render(canvas);
  }
}

class AudioPlayerComponent extends Component with HasGameRef<SpaceShooterGame> {
  @override
  Future<void>? onLoad() async {
    FlameAudio.bgm.initialize();
    await FlameAudio.audioCache.loadAll([
      'background_music.mp3',
      'blastoff.wav',
    ]);

    return super.onLoad();
  }

  void playBgm() {
    FlameAudio.bgm.play(
      'background_music.mp3',
      volume: 0.25,
    );
  }

  void stopBgm() {
    FlameAudio.bgm.stop();
  }

  void playSfx(String filename) {
    FlameAudio.play('blastoff.wav', volume: 0.3);
  }

  void playGameOver() {
    FlameAudio.play('Game Over.ogg', volume: 0.3);
  }
}
