import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/text_cleaner.dart';

class RunyankoleMatcher {
  static Map<String, dynamic>? _dataset;
  static bool _isLoaded = false;

  static const String _learnedKey = "runyankole_learned_data";

  /// =========================
  /// LOAD DATASET
  /// =========================
  static Future<Map<String, dynamic>> loadDataset() async {
    if (_isLoaded && _dataset != null) return _dataset!;

    try {
      String data = await rootBundle.loadString(
        'assets/data/runyankole_dataset.json',
      );
      _dataset = jsonDecode(data);
      _isLoaded = true;
      return _dataset!;
    } catch (e) {
      debugPrint('❌ Failed to load dataset: $e');
      return {};
    }
  }

  /// =========================
  /// FUZZY MATCHING
  /// =========================
  static double fuzzyScore(String input, String target) {
    input = input.toLowerCase();
    target = target.toLowerCase();

    final inputWords = input.split(RegExp(r'\s+'));
    final targetWords = target.split(RegExp(r'\s+'));

    int matches = 0;

    for (String inputWord in inputWords) {
      bool foundMatch = false;

      for (String targetWord in targetWords) {
        if (inputWord.contains(targetWord) || targetWord.contains(inputWord)) {
          matches++;
          foundMatch = true;
          break;
        }
      }

      if (foundMatch) continue;
    }

    if (inputWords.isEmpty) return 0;
    return matches / inputWords.length;
  }

  /// =========================
  /// CHECK IF DATASET SHOULD BE USED
  /// =========================
  static Future<bool> shouldUseDataset(String message) async {
    final data = await loadDataset();
    if (data.isEmpty) return false;

    message = message.toLowerCase();

    final keywords = [
      'runyankole',
      'rukiga',
      'omukazi',
      'munda',
      'okutwara',
      'okuzala',
      'pregnan',
      'maternal',
      'nutrition',
      'vitamin',
      'contraception',
      'condom',
    ];

    if (keywords.any((k) => message.contains(k))) return true;

    return false;
  }

  /// =========================
  /// SAVE LEARNED DATA
  /// =========================
  static Future<void> saveLearned(String question, String answer) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> learned = prefs.getStringList(_learnedKey) ?? [];

    learned.add(
      jsonEncode({"question": question.toLowerCase(), "answer": answer}),
    );

    await prefs.setStringList(_learnedKey, learned);
  }

  /// =========================
  /// GET LEARNED DATA
  /// =========================
  static Future<List<Map<String, dynamic>>> getLearned() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getStringList(_learnedKey) ?? [];

    return data.map((e) => jsonDecode(e)).cast<Map<String, dynamic>>().toList();
  }

  /// =========================
  /// MAIN RESPONSE FUNCTION
  /// =========================
  static Future<String> getResponse(String message) async {
    final data = await loadDataset();

    if (data.isEmpty) {
      return TextCleaner.cleanOfflineText(
        "Nimbasa kukuyamba? Nyabura ekibuuzo kyawe kurungi.",
      );
    }

    message = message.toLowerCase().trim();

    debugPrint("🔍 Searching: $message");

    // =========================
    // 1. LEARNED DATA MATCH
    // =========================
    final learned = await getLearned();

    for (var item in learned) {
      final q = item['question'].toString();
      final a = item['answer'].toString();

      if (message.contains(q) || fuzzyScore(message, q) > 0.6) {
        return TextCleaner.cleanOfflineText(a);
      }
    }

    // =========================
    // 2. QA PAIRS MATCH
    // =========================
    final qaPairs = data['qa_pairs'] as List? ?? [];
    List<Map<String, dynamic>> matches = [];

    for (var qa in qaPairs) {
      final qEn = (qa['question_en'] ?? '').toString().toLowerCase();
      final qRn = (qa['question_rn'] ?? '').toString().toLowerCase();

      double scoreEn = fuzzyScore(message, qEn);
      double scoreRn = fuzzyScore(message, qRn);
      double bestScore = scoreEn > scoreRn ? scoreEn : scoreRn;

      if (bestScore > 0.5) {
        matches.add({'qa': qa, 'score': bestScore});
      }
    }

    if (matches.isNotEmpty) {
      matches.sort(
        (a, b) => (b['score'] as double).compareTo(a['score'] as double),
      );

      final best = matches.first['qa'];
      final answer = best['answer'] ?? "";

      if (answer.isNotEmpty) {
        return TextCleaner.cleanOfflineText(answer);
      }
    }

    // =========================
    // 3. INTENTS MATCH
    // =========================
    final intents = data['intents'] as List? ?? [];

    for (var intent in intents) {
      final examples = intent['examples'] as List? ?? [];

      for (var ex in examples) {
        final text = ex.toString().toLowerCase();

        if (message.contains(text) || fuzzyScore(message, text) > 0.4) {
          return TextCleaner.cleanOfflineText(intent['answer']);
        }
      }
    }

    // =========================
    // 4. KEYWORDS MATCH
    // =========================
    for (var key in data.keys) {
      if (['metadata', 'qa_pairs', 'intents'].contains(key)) continue;

      final item = data[key];
      final keywords = item['keywords'] as List? ?? [];

      for (var kw in keywords) {
        if (message.contains(kw.toString().toLowerCase())) {
          return TextCleaner.cleanOfflineText(item['response']);
        }
      }
    }

    // =========================
    // 5. SMART FALLBACK (LEARN MODE)
    // =========================
    return TextCleaner.cleanOfflineText(
      "Nimbasa kukuyamba? Nindibasa kuhurira ekibuuzo kyawe, "
      "ariko ntekateeka ngu nyizire kukyiga.\n\n"
      "👉 Ekyokukora:\n"
      "Wandika eki:\n"
      "learn: question | answer\n\n"
      "Example:\n"
      "learn: What is folic acid? | Folic acid helps in baby development.",
    );
  }

  /// =========================
  /// CLEAR CACHE
  /// =========================
  static void clearCache() {
    _dataset = null;
    _isLoaded = false;
  }
}
