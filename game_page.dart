import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:async';

class GameItem {
  final String id;
  final String type;
  bool placed;
  bool isCorrect;
  Offset position;
  String? shelf;

  GameItem({
    required this.id,
    required this.type,
    this.placed = false,
    this.isCorrect = false,
    this.position = Offset.zero,
    this.shelf,
  });
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final player = AudioPlayer();
  late ConfettiController confetti;

  int score = 0;
  int highScore = 0;
  int level = 1;
  int timeLeft = 60;

  Timer? timer;

  String feedback = "";
  String? activeShelf;

  /// SHAKE ANIMATION
  late AnimationController shakeController;
  late Animation<double> shakeAnimation;

  final Map<String, String> correctMapping = {
    "folic": "Vitamins",
    "vitamin": "Vitamins",
    "multivitamin": "Vitamins",
    "pill": "Birth Control Methods",
    "condom": "Birth Control Methods",
    "iron": "Pregnancy Care",
    "mosquito": "Pregnancy Care",
    "prenatal_food": "Pregnancy Care",
  };

  List<GameItem> items = [];

  final List<String> shelves = [
    "Pregnancy Care",
    "Birth Control Methods",
    "Vitamins",
  ];

  final List<Offset> occupiedSlots = [];

  @override
  void initState() {
    super.initState();

    confetti = ConfettiController(duration: const Duration(seconds: 1));

    shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    shakeAnimation = Tween<double>(begin: 0, end: 10).animate(shakeController);

    loadHighScore();
    startLevel();
    startTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    confetti.dispose();
    shakeController.dispose();
    player.stop();
    player.dispose();
    super.dispose();
  }

  /// 🚀 START LEVEL
  void startLevel() {
    occupiedSlots.clear();
    items.clear();

    // Group items by correct shelf
    final shelfItems = {
      "Pregnancy Care": ["iron", "mosquito", "prenatal_food"],
      "Birth Control Methods": ["pill", "condom"],
      "Vitamins": ["folic", "vitamin", "multivitamin"],
    };

    final Set<String> usedTypes = {};
    final List<String> availableTypes = [];

    for (String shelf in shelves) {
      final types = shelfItems[shelf] ?? [];
      availableTypes.addAll(types);
    }

    int itemIndex = 0;
    int targetItems = shelves.length * level;

    while (items.length < targetItems && availableTypes.isNotEmpty) {
      final randomIndex = Random().nextInt(availableTypes.length);
      final type = availableTypes[randomIndex];

      if (!usedTypes.contains(type) || items.length < shelves.length) {
        items.add(
          GameItem(
            id: "${DateTime.now().millisecondsSinceEpoch}-$itemIndex-$type",
            type: type,
            placed: false,
            isCorrect: false,
            position: Offset.zero,
            shelf: correctMapping[type]!,
          ),
        );

        // ❌ REMOVED DUPLICATE ITEM HERE

        usedTypes.add(type);
        itemIndex++;
      }

      availableTypes.removeAt(randomIndex);
      if (availableTypes.isEmpty) break;
    }

    // Fill remaining if needed
    while (items.length < targetItems) {
      final allTypes = [...usedTypes];
      if (allTypes.isEmpty) break;

      final type = allTypes[Random().nextInt(allTypes.length)];

      items.add(
        GameItem(
          id: "${DateTime.now().millisecondsSinceEpoch}-$itemIndex-$type",
          type: type,
          placed: false,
          isCorrect: false,
          position: Offset.zero,
          shelf: correctMapping[type],
        ),
      );

      itemIndex++;
    }

    items.shuffle();

    debugPrint(
      "Level $level: Generated ${items.length} unique items: ${items.map((i) => i.type).toList()}",
    );
  }

  /// ⏱ TIMER
  void startTimer() {
    timer?.cancel();
    timeLeft = max(30, 90 - level * 5);

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        timeLeft--;
        if (timeLeft <= 0) {
          timer?.cancel();
          showGameOver();
        }
      });
    });
  }

  /// 🏆 HIGH SCORE PERSISTENCE
  Future<void> loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('game_high_score') ?? 0;
    });
  }

  Future<void> saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (score > highScore) {
      highScore = score;
      await prefs.setInt('game_high_score', highScore);
    }
  }

  void showGameOver() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Game Over"),
        content: Text("Score: $score\nHigh Score: $highScore"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                score = 0;
                level = 1;
                startLevel();
                startTimer();
              });
            },
            child: const Text("Restart"),
          ),
        ],
      ),
    );
    saveHighScore(); // Save final score if improved
  }

  /// 🔊 SOUND
  void playSound(bool correct) {
    try {
      player.stop();
      player.play(
        AssetSource(correct ? "sounds/correct.mp3" : "sounds/wrong.mp3"),
      );
      debugPrint("Playing sound: ${correct ? 'correct' : 'wrong'}");
    } catch (e) {
      debugPrint("Audio error: $e");
    }
  }

  /// 🎯 SLOT SYSTEM (RESPONSIVE)
  Offset getSlot(int index, double width, double y) {
    double spacing = width / 4;
    return Offset(spacing * (index + 1), y);
  }

  Offset? getAvailableSlot(String shelf, double width, double y) {
    for (int i = 0; i < 3; i++) {
      final slot = getSlot(i, width, y);
      if (!occupiedSlots.contains(slot)) return slot;
    }
    return null;
  }

  /// 🧲 DROP LOGIC
  void handleDrop(GameItem item, String shelf, double width, double y) {
    final slot = getAvailableSlot(shelf, width, y);
    if (slot == null) return;

    bool correct = correctMapping[item.type] == shelf;

    setState(() {
      item.position = slot;
      item.shelf = shelf;
      occupiedSlots.add(slot);
    });

    if (correct) {
      item.placed = true;
      item.isCorrect = true;
      score += 10;
      if (score > highScore) {
        saveHighScore();
      }
      feedback = "Correct! +10 Points";
      confetti.play();
      playSound(true);
      checkLevelComplete();
    } else {
      // Fully revert wrong drop
      item.placed = false;
      item.isCorrect = false;
      item.position = Offset.zero;
      item.shelf = null;
      occupiedSlots.removeLast();
      feedback = "Wrong shelf! Try again.";
      shakeController.forward(from: 0);
      playSound(false);
    }
  }

  /// 📊 LEVEL PROGRESS
  void checkLevelComplete() {
    // Only advance if ALL current items are correctly placed
    if (items.every((i) => i.placed && i.isCorrect)) {
      level++;
      startLevel();
      startTimer();
      feedback = "Level Complete! 🎉";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;

          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset("assets/images/bg.jpeg", fit: BoxFit.cover),
              ),

              /// 🎉 CONFETTI
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(confettiController: confetti),
              ),

              SafeArea(
                child: Column(
                  children: [
                    _topBar(width),
                    _header(width),
                    Expanded(child: _shelves(width)),
                    _feedback(),
                  ],
                ),
              ),

              /// 🧺 TRAY OVERLAY
              Positioned(
                bottom: 110,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.brown.shade200.withValues(alpha: 0.95),
                  padding: const EdgeInsets.all(12),
                  child: _tray(width),
                ),
              ),

              /// ❓ ASK MOMTEEN BUTTON
              Positioned(
                bottom: 80,
                right: 20,
                child: FloatingActionButton(
                  heroTag: "ask_momteen",
                  onPressed: () {
                    Navigator.pushNamed(context, '/note');
                  },
                  backgroundColor: Colors.pink,
                  child: const Icon(Icons.help_outline, color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 🔝 TOP BAR
  Widget _topBar(double width) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, size: 20, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  "$score",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 10,
                  width: (width * 0.6) * (timeLeft / 60),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer, size: 20, color: Colors.red),
                  const SizedBox(width: 2),
                  Text(
                    "$timeLeft",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.trending_up, size: 20, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  "HI: $highScore",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 👩 HEADER
  Widget _header(double width) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        children: [
          CircleAvatar(
            radius: (width * 0.12).clamp(25.0, 35.0),
            backgroundImage: const AssetImage("assets/images/nurse.jpeg"),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  child: Text(
                    "LEVEL $level (${items.length} items)",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "MEDICINE SORTING",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🪵 SHELVES
  Widget _shelves(double width) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: shelves.length,
      itemBuilder: (context, index) {
        final shelf = shelves[index];
        final y = index * 110.0 + 200;

        return DragTarget<GameItem>(
          onWillAcceptWithDetails: (_) {
            setState(() => activeShelf = shelf);
            return true;
          },
          onLeave: (_) => setState(() => activeShelf = null),
          onAcceptWithDetails: (details) {
            handleDrop(details.data, shelf, width, y);
            setState(() => activeShelf = null);
          },
          builder: (context, _, child) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  _tag(shelf),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 90,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage("assets/images/shelves.jpeg"),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        if (activeShelf == shelf)
                          BoxShadow(
                            color: Colors.greenAccent.withValues(alpha: 0.7),
                            blurRadius: 15,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }

  /// 🎯 FEEDBACK + SHAKE
  Widget _feedback() {
    return SizedBox(
      height: 50,
      child: AnimatedBuilder(
        animation: shakeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(shakeAnimation.value, 0),
            child: Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: feedback.contains("Correct") ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                feedback,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }

  /// 🧺 TRAY
  Widget _tray(double width) {
    double itemWidth = (width / 8).clamp(55.0, 70.0);
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.brown.shade200,
      height: 100,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.start,
          children: items
              .where((i) => !i.placed)
              .map(
                (item) => SizedBox(
                  width: itemWidth,
                  height: itemWidth,
                  child: _draggableItem(item),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _draggableItem(GameItem item) {
    String image;
    switch (item.type) {
      case "folic":
        image = "assets/images/Folic Acid.jpeg";
        break;
      case "pill":
        image = "assets/images/pills.jpeg";
        break;
      case "vitamin":
      case "multivitamin":
        image = "assets/images/Vitamin D.jpeg";
        break;
      case "condom":
        image = "assets/images/condom.jpeg";
        break;
      case "iron":
        image = "assets/images/Iron Supplements.jpeg";
        break;
      case "mosquito":
        image =
            "assets/images/mosquito_net.jpeg"; // Add if available, fallback below
        break;
      case "prenatal_food":
        image =
            "assets/images/prenatal_food.jpeg"; // Add if available, fallback below
        break;
      default:
        image = "assets/images/Vitamin D.jpeg"; // fallback
    }

    return Draggable<GameItem>(
      data: item,
      feedback: Transform.scale(scale: 1.1, child: _itemCard(image)),
      childWhenDragging: Opacity(opacity: 0.3, child: _itemCard(image)),
      child: _itemCard(image),
    );
  }

  Widget _itemCard(String image) {
    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Image.asset(image),
      ),
    );
  }
}

class GamePage extends StatelessWidget {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GameScreen();
  }
}
