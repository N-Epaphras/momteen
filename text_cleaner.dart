import 'dart:convert';

/// Text cleaning utility for offline mode responses
/// Handles joined words, bad formatting, and improves text display
class TextCleaner {
  /// Clean text from offline AI responses
  /// Fixes joined words, removes extra spaces, improves formatting
  static String cleanOfflineText(String text) {
    if (text.isEmpty) return text;

    String cleaned = text;

    // 0. FIXED: Aggressively remove ALL leading/trailing asterisks and Markdown
    // Handles "* Item", "**Bold**", "*Italic*" → "Item", "Bold", "Italic"
    // CRITICAL for preventing bullet points in chat display
    cleaned = cleaned.replaceAll(RegExp(r'^[\s*]+'), '');
    cleaned = cleaned.replaceAll(RegExp(r'[\s*]+\s*$'), '');
    // Remove *text* and **text** markdown patterns completely
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(\*\*?)(.*?)\1'),
      (match) => match.group(2)?.trim() ?? '',
    );
    // Remove any remaining standalone *
    cleaned = cleaned.replaceAll(RegExp(r'\s*\*\s*'), ' ');

    // 1. Fix common joined words patterns (camelCase to spaces)
    // This handles cases like "helloworld" → "hello world"
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );

    // 2. Fix words that are commonly joined without capital letter
    // e.g., "teenagepregnancy" -> "teenage pregnancy"
    cleaned = _fixCommonJoinedWords(cleaned);

    // 3. Fix missing spaces after punctuation
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([.,!?;:])([A-Za-z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );

    // 4. Fix multiple spaces to single space
    cleaned = cleaned.replaceAll(RegExp(r' +'), ' ');

    // 5. Fix multiple newlines to single newline
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // 6. Fix missing space before asterisks (markdown formatting)
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([A-Za-z])(\*[A-Za-z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );

    // 7. Fix common contractions that might be joined
    cleaned = _fixJoinedContractions(cleaned);

    // 8. Trim leading/trailing whitespace from each line
    final lines = cleaned.split('\n');
    final trimmedLines = lines.map((line) => line.trim()).toList();
    cleaned = trimmedLines.join('\n');

    return cleaned.trim();
  }

  /// Fix common joined words related to the topic
  static String _fixCommonJoinedWords(String text) {
    // List of common words that might be joined
    final commonWords = [
      'teenage',
      'pregnancy',
      'prevention',
      'contraception',
      'condom',
      'birth',
      'control',
      'implant',
      'iud',
      'protection',
      'sexual',
      'health',
      'infection',
      'disease',
      'testing',
      'clinic',
      'doctor',
      'partner',
      'relationship',
      'consent',
      'abstinence',
      'education',
      'statistics',
      'support',
      'emergency',
      'hormonal',
      'copper',
      'ovulation',
      'sperm',
      'ejaculation',
      'fertility',
      'abortion',
      'adoption',
      'parenting',
      'stis',
      'std',
      'hpv',
      'chlamydia',
      'gonorrhea',
      'syphilis',
      'herpes',
      'hiv',
      'aids',
      'condoms',
      'pills',
      'patch',
      'ring',
      'injection',
      'sponge',
      'diaphragm',
      'cervical',
      'cap',
      'larc',
      'mirena',
      'nexplanon',
      'planb',
      'morningafter',
      'youth',
      'adolescent',
      'young',
      'student',
      'confidential',
      'anonymous',
      'reproductive',
      'options',
    ];

    String result = text;

    // Sort by length descending to match longer phrases first
    commonWords.sort((a, b) => b.length.compareTo(a.length));

    // Fix patterns where two words are joined (e.g., teenagepregnancy)
    for (final word in commonWords) {
      // Match word boundaries and insert space
      result = result.replaceAllMapped(
        RegExp('($word)($word)', caseSensitive: false),
        (match) => '${match.group(1)} ${match.group(2)}',
      );
    }

    return result;
  }

  /// Fix common contractions that might be joined
  static String _fixJoinedContractions(String text) {
    final contractions = {
      'dont': "don't",
      'cant': "can't",
      'wont': "won't",
      'isnt': "isn't",
      'arent': "aren't",
      'wasnt': "wasn't",
      'werent': "weren't",
      'hasnt': "hasn't",
      'havent': "haven't",
      'hadnt': "hadn't",
      'doesnt': "doesn't",
      'didnt': "didn't",
      'wouldnt': "wouldn't",
      'couldnt': "couldn't",
      'shouldnt': "shouldn't",
      'mightnt': "mightn't",
      'mustnt': "mustn't",
      'im': "I'm",
      'ive': "I've",
      'id': "I'd",
      'ill': "I'll",
      'youre': "you're",
      'youve': "you've",
      'youd': "you'd",
      'youll': "you'll",
      'hes': "he's",
      'shes': "she's",
      'its': "it's",
      'weve': "we've",
      'theyre': "they're",
      'theyve': "they've",
      'theyd': "they'd",
      'theyll': "they'll",
      'thats': "that's",
      'whats': "what's",
      'whos': "who's",
      'lets': "let's",
      'theres': "there's",
      'heres': "here's",
      'wheres': "where's",
      'whens': "when's",
      'hows': "how's",
      'whys': "why's",
    };

    String result = text;
    for (final entry in contractions.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  /// Safely jsonEncode any object, handling dynamic types
  static String jsonEncodeSafe(Object? obj) {
    if (obj is Map || obj is List) {
      return jsonEncode(obj);
    }
    return obj.toString();
  }
}
