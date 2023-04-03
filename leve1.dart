import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame/collisions.dart';
import 'package:flame/parallax.dart';
import 'overlays/game_over_menu.dart';

class EnemyManager extends Component with HasGameRef<SpaceShooterGame> { //這是一個EnemyManager的物件
  final SpaceShooterGame game; //這是一個SpaceShooterGame的物件
  final List<Enemy> _enemies = []; //這是一個Enemy的物件
  final List<SuicideEnemy> _suicideEnemies = []; //這是一個SuicideEnemy的物件
  double enemyRate = 0.3; //這是enemy的速率
  double enemySpeed = 200; //這是enemy的速度
  double enemyCreateRate = 0.4; //這是enemy的生產速率
  double suicideEnemyCreateRate = 0.1; //這是suicideEnemy的生產速率
  final double suicideEnemyIncreaseScore = 100; //這是suicideEnemy的增加分數
  EnemyManager(this.game); //這是一個EnemyManager的物件

  void spawnEnemy() {
    final enemy = Enemy();
    enemy.position = Vector2(
      Random().nextDouble() * game.size.x,
      0,
    ); //這是隨機產生enemy的位置在x軸
    game.add(enemy); //這是將enemy加入到game裡面
    _enemies.add(enemy); //這是將enemy加入到_enemies裡面
  } //這是一個spawnEnemy的方法

  void spawnSuicideEnemy() {
    final enemy = SuicideEnemy(); //這是一個SuicideEnemy的物件
    enemy.position = Vector2(180, 0); //這是隨機產生enemy的位置在x軸
    game.add(enemy); //這是將enemy加入到game裡面
    _suicideEnemies.add(enemy); //這是將enemy加入到_suicideEnemies裡面
  } //這是一個spawnSuicideEnemy的方法

  @override
  void update(double dt) {
    enemyRate += dt; //這是一個判斷enemyRate是否大於enemyCreateRate的方法
    if (enemyRate >= enemyCreateRate) {
      enemyRate = 0; //這是一個判斷enemyRate是否大於enemyCreateRate的方法
      if (game._score > suicideEnemyIncreaseScore) {
        enemyCreateRate = 0.3; //這是一個判斷enemyRate是否大於enemyCreateRate的方法
        suicideEnemyCreateRate = 0.6; //這是一個判斷enemyRate是否大於enemyCreateRate的方法
      } //這是一個判斷enemyRate是否大於enemyCreateRate的方法
      if (Random().nextDouble() < suicideEnemyCreateRate) {
        spawnSuicideEnemy(); //這是一個判斷enemyRate是否大於enemyCreateRate的方法
      } else { 
        spawnEnemy(); //這是一個判斷enemyRate是否大於enemyCreateRate的方法
      } //這是一個判斷enemyRate是否大於enemyCreateRate的方法
    } //這是一個判斷enemyRate是否大於enemyCreateRate的方法
  } //這是一個update的方法

  void reset() {
    _enemies.forEach((enemy) {
      enemy.reset();
    });
    _suicideEnemies.forEach((enemy) {
      enemy.reset(); 
    });
  } //這是一個reset的方法
}

class Enemy extends SpriteComponent
    with CollisionCallbacks, HasGameRef<SpaceShooterGame> { //這是一個Enemy的物件
  final double _speed = 150; //這是一個double的物件

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await gameRef.loadSprite('enemy.png');
    width = 35;
    height = 40;
    anchor = Anchor.center;
  } //這是一個onLoad的方法, 用來載入圖片 

  @override
  void update(double dt) {
    super.update(dt);
    position += Vector2(0, _speed * dt);
    if (position.y > gameRef.size.y) {
      gameRef.remove(this);
    }
  } //這是一個update的方法, 用來更新位置

  @override
  void onMount() {
    super.onMount();
    final shape = CircleHitbox.relative(
      0.8, 
      parentSize: size, //parentSize 是圖片的大小
      position: size / 2,
      anchor: Anchor.center, //ancher 是圖片的中心點
    );
    add(shape);
  } //這是一個onMount的方法, 用來設定碰撞範圍

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Player) {
      gameRef.remove(this); //這是一個判斷other是否為Player的方法
      other.health -= 10; //碰撞到Player就會扣10的血
    }
  } //這是一個onCollision的方法, 用來判斷是否碰撞到Player

  void reset() {
    position = Vector2(
      Random().nextDouble() * gameRef.size.x,
      0,
    );
  } //這是一個reset的方法, 用來重置位置
}

class SuicideEnemy extends SpriteComponent
    with CollisionCallbacks, HasGameRef<SpaceShooterGame> { //這是一個SuicideEnemy的物件
  final double _speed = 200; //SuicideEnemy 的速度
 
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
  } //這是一個moveTowardsPlayer的方法, 用來讓SuicideEnemy朝著Player移動

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
        HasGameRef<SpaceShooterGame> { //這是一個SpaceShooterGame的物件
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
  } //這是一個onPanUpdate的方法, 用來讓Player跟著手指移動

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
  } //這是一個update的方法, 用來更新分數, 血量, 以及判斷是否遊戲結束

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
  } //這是一個reset的方法, 用來重置分數, 血量, 以及刪除所有的子彈
}

class Player extends SpriteComponent
    with CollisionCallbacks, HasGameRef<SpaceShooterGame> { //這是一個Player的物件
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
    } //這是一個onCollision的方法, 用來判斷是否撞到敵人, 如果撞到敵人就會震動
  } 

  void move(Vector2 delta) {
    position.add(delta);
  } //這是一個move的方法, 用來讓Player跟著手指移動
 
  void shoot() {
    final bullet = Bullet();
    bullet.position = position + Vector2(0, -height / 2);
    gameRef.add(bullet);
  } //這是一個shoot的方法, 用來讓Player發射子彈

  @override
  void update(double dt) {
    super.update(dt);
    lastShootTime += dt;
    if (lastShootTime >= shootRate) {
      lastShootTime = 0;
      shoot();
    }
  } //這是一個update的方法, 用來讓Player發射子彈

  void reset() {
    health = 100;
    position = Vector2(gameRef.size.x / 2, gameRef.size.y - 100);
  }
}

class Bullet extends SpriteComponent
    with CollisionCallbacks, HasGameRef<SpaceShooterGame> { //這是一個Bullet的物件
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
    } //這是一個onCollision的方法, 用來判斷是否撞到敵人, 如果撞到敵人就會加分
  }

  @override
  void update(double dt) {
    super.update(dt);

    position.add(Vector2(0, -100 * dt));

    if (position.y < 0) { 
      gameRef.remove(this);
    } //如果子彈超出螢幕就會刪除
  } //這是一個update的方法, 用來讓子彈移動
}
