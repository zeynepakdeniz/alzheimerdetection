import 'package:flutter/material.dart';
import 'dart:math';


class BrainExercisesScreen extends StatelessWidget {
  const BrainExercisesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final exercises = [
      {'title': 'Yapboz', 'route': const PuzzleScreen()},
      {'title': 'Eşleştirme Oyunu', 'route': const MatchingGameScreen()},
      
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beyin Egzersizleri'),
      ),
      body: ListView.builder(
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              leading: const Icon(Icons.play_arrow),
              title: Text(exercises[index]['title'] as String),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => exercises[index]['route'] as Widget,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// *** Yapboz Oyunu ***
class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({Key? key}) : super(key: key);

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  late List<int> numbers;
  final int gridSize = 4;

  @override
  void initState() {
    super.initState();
    numbers = List.generate(gridSize * gridSize, (index) => index); // numbers'ı burada başlatıyoruz
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showGameInstructions();
    });
  }

  void _showGameInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yapboz Oyunu Kuralları'),
        content: const Text(
          'Bir yapbozu çözmek için kutucukları boş alan ile değiştirerek '
          'tüm kutucukları sıralı hale getirin. Boş kutu, doğru yerleşim '
          'için kullanılabilir. Hedefiniz tüm kutucukları 1\'den başlayarak '
          'doğru sıraya yerleştirmektir.\n\n'
          'İyi şanslar!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initializePuzzle();
            },
            child: const Text('Başla'),
          ),
        ],
      ),
    );
  }

  void _initializePuzzle() {
    numbers.shuffle(Random());
    setState(() {});
  }

  bool _isSolved() {
    for (int i = 0; i < numbers.length - 1; i++) {
      if (numbers[i] != i) {
        return false;
      }
    }
    return numbers.last == 0;
  }

  void _moveTile(int index) {
    int blankIndex = numbers.indexOf(0);
    int row = index ~/ gridSize;
    int col = index % gridSize;
    int blankRow = blankIndex ~/ gridSize;
    int blankCol = blankIndex % gridSize;

    if ((row == blankRow && (col - blankCol).abs() == 1) ||
        (col == blankCol && (row - blankRow).abs() == 1)) {
      setState(() {
        numbers[blankIndex] = numbers[index];
        numbers[index] = 0;

        if (_isSolved()) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Tebrikler!'),
              content: const Text('Bulmaca çözüldü!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Tamam'),
                ),
              ],
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yapboz Oyunu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializePuzzle,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridSize,
            crossAxisSpacing: 4.0,
            mainAxisSpacing: 4.0,
          ),
          itemCount: numbers.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _moveTile(index),
              child: Container(
                decoration: BoxDecoration(
                  color: numbers[index] == 0 ? Colors.grey[300] : Colors.blue,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Center(
                  child: Text(
                    numbers[index] == 0 ? '' : '${numbers[index]}',
                    style: const TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
// *** Eşleştirme Oyunu ***
class MatchingGameScreen extends StatefulWidget {
  const MatchingGameScreen({Key? key}) : super(key: key);

  @override
  State<MatchingGameScreen> createState() => _MatchingGameScreenState();
}

class _MatchingGameScreenState extends State<MatchingGameScreen> {
  List<String> cards = [
    '🍎', '🍌', '🍇', '🍓', '🍍', '🍉', '🍊', '🍒', '🍑', '🥭',
    '🍎', '🍌', '🍇', '🍓', '🍍', '🍉', '🍊', '🍒', '🍑', '🥭',
  ];
  List<bool> flipped = [];
  List<bool> matched = [];
  int? firstIndex;
  int? secondIndex;
  int score = 0;
  bool isProcessing = false; // Tıklama kontrolü

  @override
  void initState() {
    super.initState();
    cards.shuffle();
    flipped = List<bool>.filled(cards.length, false);
    matched = List<bool>.filled(cards.length, false);

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        flipped = List<bool>.filled(cards.length, true);
      });

      Future.delayed(const Duration(milliseconds: 800), () {
        setState(() {
          flipped = List<bool>.filled(cards.length, false);
        });
      });
    });
  }

  void checkMatch() async {
    if (cards[firstIndex!] == cards[secondIndex!]) {
      setState(() {
        matched[firstIndex!] = true;
        matched[secondIndex!] = true;
        score += 10;
      });
    } else {
      await Future.delayed(const Duration(milliseconds: 500)); // Hızlı tepki süresi
      setState(() {
        flipped[firstIndex!] = false;
        flipped[secondIndex!] = false;
      });
    }

    setState(() {
      firstIndex = null;
      secondIndex = null;
      isProcessing = false; // Yeni hamlelere izin
    });
  }

  void flipCard(int index) {
    if (isProcessing || flipped[index] || matched[index]) return;

    setState(() {
      flipped[index] = true;
      if (firstIndex == null) {
        firstIndex = index;
      } else {
        secondIndex = index;
        isProcessing = true; // Kart eşleşme kontrolü
        checkMatch();
      }
    });
  }

  bool isGameOver() {
    return matched.every((element) => element);
  }

  void resetGame() {
    setState(() {
      cards.shuffle();
      flipped = List<bool>.filled(cards.length, false);
      matched = List<bool>.filled(cards.length, false);
      firstIndex = null;
      secondIndex = null;
      score = 0;
      isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eşleştirme Oyunu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: resetGame,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Puan: $score', style: const TextStyle(fontSize: 24)),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => flipCard(index),
                  child: Card(
                    color: matched[index]
                        ? Colors.green
                        : flipped[index]
                            ? Colors.white
                            : Colors.blue,
                    child: Center(
                      child: Text(
                        flipped[index] ? cards[index] : '',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (isGameOver())
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: resetGame,
                child: const Text('Yeni Oyun Başlat'),
              ),
            ),
        ],
      ),
    );
  }
}
