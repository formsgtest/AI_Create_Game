import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame/collisions.dart';
import 'package:flame/parallax.dart';
import 'overlays/game_over_menu.dart';
import 'overlays/pause_button.dart';
import 'overlays/pause_menu.dart';
import 'overlays/finish_menu.dart';

class EnemyManager extends Component with HasGameRef<SpaceShooterGame> {
  final SpaceShooterGame game;
  final List<Enemy> _enemies = [];
  final List<SuicideEnemy> _suicideEnemies = [];
  double enemyRate = 0.3;
  double enemySpeed = 200;
  double enemyCreateRate = 0.4;
  double suicideEnemyCreateRate = 0.1;
  final double suicideEnemyIncreaseScore = 100;
  EnemyManager(this.game);

  void spawnEnemy() {
    final enemy = Enemy();
    enemy.position = Vector2(
      Random().nextDouble() * game.size.x,
      0,
    );
    game.add(enemy);
    _enemies.add(enemy);
  }

  void spawnSuicideEnemy() {
    final enemy = SuicideEnemy();
    enemy.position = Vector2(180, 0);
    game.add(enemy);
    _suicideEnemies.add(enemy);
  }

  @override
  void update(double dt) {
    enemyRate += dt;
    if (enemyRate >= enemyCreateRate) {
      enemyRate = 0;
      if (game._score > suicideEnemyIncreaseScore) {
        enemyCreateRate = 0.3;
        suicideEnemyCreateRate = 0.6;
      }
      if (Random().nextDouble() < suicideEnemyCreateRate) {
        spawnSuicideEnemy();
      } else {
        spawnEnemy();
      }
    }
  }

  void reset() {
    _enemies.forEach((enemy) {
      enemy.reset();
    });
    _suicideEnemies.forEach((enemy) {
      enemy.reset();
    });
  }
}

class Enemy extends SpriteComponent
    with CollisionCallbacks, HasGameRef<SpaceShooterGame> {
  final double _speed = 150;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await gameRef.loadSprite('enemy.png');
    width = 35;
    height = 40;
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += Vector2(0, _speed * dt);
    if (position.y > gameRef.size.y) {
      gameRef.remove(this);
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
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Player) {
      gameRef.remove(this);
      other.health -= 10;
    }
  }

  void reset() {
    position = Vector2(
      Random().nextDouble() * gameRef.size.x,
      0,
    );
  }
}

class SuicideEnemy extends SpriteComponent
    with CollisionCallbacks, HasGameRef<SpaceShooterGame> {
  final double _speed = 200;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await gameRef.loadSprite('SuicideEnemy.png');
    width = 35;
    height = 40;
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);
    moveTowardsPlayer(dt);
  }

  void moveTowardsPlayer(double dt) {
    final player = gameRef._player;
    final diff = player.position - position;
    final direction = diff.normalized();
    position += direction * _speed * dt;
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
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Player) {
      gameRef.remove(this);
      other.health -= 20;
    }
  }

  void reset() {
    position = Vector2(180, 0);
  }
}

class SpaceShooterGame extends FlameGame
    with
        HasCollisionDetection,
        PanDetector,
        TapDetector,
        HasGameRef<SpaceShooterGame> {
  bool _isAlreadyLoaded = false;
  late Player _player;
  late EnemyManager _enemyManager;
  late TextComponent _scoreText;
  int _score = 0;
  late TextComponent _playerhealth;
  late Bullet _bullet;

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
      _player = Player();
      add(_player);
      _bullet = Bullet();
      add(_bullet);
      _enemyManager = EnemyManager(this);
      _enemyManager.spawnEnemy();
      _enemyManager.spawnSuicideEnemy();
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
    _enemyManager.update(dt);
    _playerhealth.text = 'Health: ${_player.health}';
    _scoreText.text = 'Score: $_score';
    if (_player.health <= 0) {
      _playerhealth.text = 'Health: ${_player.health}';
      overlays.add(GameOverMenu.id);
      pauseEngine();
    }
  }

  void reset() {
    _player.health = 100;
    _score = 0;
    _enemyManager.reset();
    _player.reset();
    _scoreText.text = 'Score: $_score';
    _playerhealth.text = 'Health: ${_player.health}';
    children.whereType<Bullet>().forEach((bullet) {
      bullet.removeFromParent();
    });
  }
}

class Player extends SpriteComponent
    with CollisionCallbacks, HasGameRef<SpaceShooterGame> {
  int health = 100;
  double shootRate = 0.3;
  double lastShootTime = 0;
  double speed = 200;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await gameRef.loadSprite('player.png');
    position = Vector2(gameRef.size.x / 2, gameRef.size.y - 100);
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
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Enemy) {
      gameRef.camera.shake(intensity: 10);
    } else if (other is SuicideEnemy) {
      gameRef.camera.shake(intensity: 10);
    }
  }

  void move(Vector2 delta) {
    position.add(delta);
  }

  void shoot() {
    final bullet = Bullet();
    bullet.position = position + Vector2(0, -height / 2);
    gameRef.add(bullet);
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

  void reset() {
    health = 100;
    position = Vector2(gameRef.size.x / 2, gameRef.size.y - 100);
  }
}

class Bullet extends SpriteComponent
    with CollisionCallbacks, HasGameRef<SpaceShooterGame> {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await gameRef.loadSprite('bullet.png');
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
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Enemy) {
      gameRef._score += 10;
      gameRef.remove(other);
    } else if (other is SuicideEnemy) {
      gameRef._score += 20;
      gameRef.remove(other);
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
