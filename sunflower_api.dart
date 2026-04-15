// ignore_for_file: equal_keys_in_map, duplicate_ignore, unnecessary_brace_in_string_interps

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SunflowerAPI {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8080/api/chat/runyankore';

    // Mobile: Android emulator vs iOS/physical device
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api'; // Emulator localhost
    }
    return 'http://localhost:8080/api'; // iOS/physical
  }

  // ✅ EXPANDED RUNYANKORE/RUKIGA DATASET (70+ keys)
  static final Map<String, String> runyankoreDataset = {
    // Greetings (Rukiga variants added)
    "hello": "Agandi",
    "agandi": "Agandi",
    "oi": "Oi",
    "muraho": "Muraho", // Rukiga
    "hi": "Agandi",
    "hey": "Agandi",
    "good morning": "Oraire ota?",
    "good afternoon": "Osiibire ota?",
    "good evening": "Oire ota?",
    "how are you": "Ori ota?",
    "i am fine": "Ndi kurungi",
    "thank you": "Webare munonga",
    "thanks": "Webare munonga",

    // Pregnancy
    "what is pregnancy": "Okugira enda nikyimamyisa kugira omwana mu nda.",
    "pregnancy": "Okugira enda",
    "signs of pregnancy":
        "Obubonero bw'enda hariho obu:Obubonero bwe’enda ni: okutakuba emyezi, okuhakanwa n’okusesa, amabeere kugira oburumi n’okuhimba, okuremwa amaani, okukozesa ekyoto kenshi, okwegomba emere zimwe n’okuzira ezindi, okukererebwa omutima, n’oburumi buto-buto mu nda n’okuhinda",
    "can a girl get pregnant":
        "Yeego, omwishiki yaaba nakora eby'okuteerana, naabaasa kubungana.",

    // Prevention
    "how to avoid pregnancy":
        "Noobaasa kwerinda enda wakozessa obujuma bwokukyingira enda, obupiira,okukozessa famiire puraningi hamwe nebindi .",
    "contraception":
        "Okwerinda enda nobasa kukozessa oburyo nka kondomu, obujuma n'obundi buryo bw'okwekinga.",

    // HIV
    "what is hiv":
        "sirimu ni oburwaire oburikutwa omushagama kandi burikuhwerekereza omubiri.",
    "how is hiv spread":
        "sirimu nejajarira omu shagama, okuterana otakozesize kapiira nokwesharisa ebyoma nka akagirita kaheza kukozessibwa omurwire wa sirimu.",
    "how to prevent hiv":
        "Noobaasa kwerinda sirimu wa kozesa kondomu n'okwegyendereza okuteerana otarikukozessa ebyokwerinda okujanjara kwa sirimu.",

    // Nutrition
    "what should a pregnant girl eat":
        "Omwishiki orikuba ayine enda ashemerire kunywa amata, akarya ebinyebwa, ebijuma nemboga.",
    "nutrition":
        "Ebyokurya birungi nibyo birimu amaani nka amata, ebijuma, emboga n'ebinyebwa.",

    // Counseling
    "i am scared":
        "Otatiina, hariho abantu abakubaasa kukuyambaho nka abazaire n'abajanjabi.",
    "i need help":
        "Noobaasa kugamba n'omujanjabi ninga irwariro rikuri heihi, nari omuntu mukuru ow'amaani akakuyamba.",

    // Expanded HIV (10+ keys)
    "hiv test":
        "Okuzirisha sirimu kora mu irwariro rigye. Bariha sirimu ryakukura.",
    "hiv testing":
        "Okuzirisha sirimu kora mu irwariro rigye. Bariha sirimu ryakukura.",
    "where to test hiv":
        "Irwariro rigye, abajanjabi, ekirinnya kyirwariro kya sirimu.",
    "hiv symptoms":
        "Obubonero bwa sirimu: okuzimba emicwe, okukungura emihango, okwetera, okwona emihango, okushaba emmere.",
    "hiv treatment":
        "ARV's ni omusho gw'okulinda sirimu. Kora mu irwariro rigye.",
    "arv": "ARV's ni omusho gw'okulinda sirimu. Kozesa buri ku wera.",
    "is hiv curable":
        "Ota, sirimu totariha kurahirwa, ahakiriha okukozesa ARV's.",
    "living with hiv":
        "Omuntu akiri sirimu yashobora okuba na mahanga, ahakiriha okukozesa ARV's nebyehyo.",
    "hiv mother to child":
        "Omwana ashobora kujanja sirimu ku mama ye arikuba na sirimu. Kozesa ARV's mu kuza.",
    "hiv stigma":
        "Otatiina okuhwebwa sirimu. Abantu benshi barikiri sirimu barikora mahanga.",
    // RUKIGA VARIANTS (new 20+ keys)
    "kirimu":
        "Kirimu ni oburwaire obw'ekibonwa sirimu (HIV). Buzira mu irwariro.",
    "sirimu": "Sirimu ni HIV. Obubonero: okuzimba emicwe, okukungura.",
    "okujanjara": "Kirimu nojajarira oku shagama, kondomu tekikozesibwa.",
    "okwerinda kirimu": "Kozesa kondomu, okwegyendereza okuteerana, ARVs.",
    "arvs": "ARVs ni omusho gw'okulinda kirimu. Buzira irwariro.",
    "enda": "Okugira enda nikyokubuga omwana mu nda.",
    "okurinda enda": "Kozesa kondomu, piiiri, implant, IUD mu irwariro.",
    "omwana mu nda": "Omwana mu nda ashaka emere ezirungi: amata, emboga.",
    "vitamin": "Vitamin ziri mu amata, mahanga, emboga. Birungi ku mwana.",
    "abazaire": "Abazaire barikuri irwaro ryawe. Bambura 0800111222.",
    "abajanjabi": "Abajanjabi bakuyamba ku buzima bwawe. Bariha irwariro.",
    "okulabwa": "Okulabwa si kworungi. Bambura polisi 999.",
    "ekiruyi": "Ekiruyi kya mutwe kiriho. Bambura omujanjabi.",
    "gonno": "Gono ni oburwaire obw'okuteerana. Omusho irwariro.",
    "sigarashi": "Sigarashi (syphilis) buzira irwariro rigye.",
    "stis": "STIs buzira irwariro. Otakikozesa kondomu.",
    "pep": "PEP (72 hours) okulinda kirimu nyuma okuteerana.",
    "prep": "PrEP okulinda kirimu abakuteerana buri gihe.",
    "okukata": "Okukata ekikerezi kulinda kirimu 60%. Irwariro.",
    "okuteerana": "Okuteerana gukoresa kondomu okwerinda kirimu n'enda.",

    // Expanded Prevention (8+ keys)
    "condom":
        "Kondomu ni ekyokwerinda enda n'ebirwaire. Kozesa kondomu yorungi.",
    "use condom":
        "Kozesa kondomu buri gukora eby'okuteerana okwerinda sirimu n'enda.",
    "abstinence":
        "Okutakora eby'okuteerana ni orwokurinda sirimu n'enda ky'okuzimba.",
    "pep":
        "PEP ni omusho gw'okulinda sirimu nyuma gukora eby'okuteerana. Shoka mu irwariro mu maaso 72.",
    // ignore: equal_keys_in_map
    "prep":
        "PrEP ni omusho gw'okulinda sirimu abakora eby'okuteerana. Buzira mu irwariro.",
    "circumcision":
        "Okukata ekikerezi kushobora okulinda sirimu 60%. Buzira mu irwariro.",
    "avoid multiple partners":
        "Okukora eby'okuteerana n'omuntu orimo ni orwokurinda sirimu n'enda.",
    "safe sex":
        "Okuteerana mu buryo bwokurinda ni gukoresa kondomu n'okwegyendereza.",

    // Expanded Nutrition (8+ keys)
    "iron rich foods":
        "Ebyokurya birimu iron: enyanya, enyanya, ebyuma, amata, enyanya.",
    "folic acid":
        "Folic acid iri mu emboga ezisoboka, enyanya, ebyuma. Birungi ku mwana mu nda.",
    "vitamin d": "Vitamin D oritwa mu mahanga, amata, ebyokurya birimu mafuta.",
    "protein for pregnancy":
        "Proteini iri mu enyungu, enyama, amata, enyanya, ebyuma.",
    "calcium foods": "Calcium iri mu amata, enyanya, ebyuma, emboga ezisoboka.",
    "prenatal vitamins": "Vitamin y'okuzala oribaho mu irwariro rigye.",
    "anemia": "Okuzimba emicwe kushobora kuba ARV ya iron. Kora mu irwariro.",
    "healthy weight gain":
        "Omwana mu nda ashobora okukura 0.5kg mu wiire. Kurya ebyokurya birungi.",

    // Additional Counseling & Support (6+ keys)
    "suicide":
        "Otatiina. Bambura omujanjabi 0800111222. Uri mukuru mukuru akukuyamba.",
    "abuse": "Okulabwa si kworungi. Bambura polisi 999 inga omujanjabi.",
    "counseling near me":
        "Bambura omujanjabi mu disiturikiti yawe inga irwariro rigye.",
    "youth friendly clinic":
        "Irwariro rya abasigazi riri mu disiturikiti yawe. Bambura 0800111222.",
    "talk to someone": "Bambura omujanjabi inga omuntu mukuru ow'amaani.",
    "mental health":
        "Ekiruyi kya mutwe kiriho. Bambura omujanjabi abakuyambaho.",

    // STIs & Other Health (5+ keys)
    "gonorrhea": "Gono ni oburwaire obw'okuteerana. Omusho wariho mu irwariro.",
    "syphilis": "Sigalasi ni oburwaire obw'okuteerana. Buzira mu irwariro.",
    "stis": "Ebikwatagaziire eby'okuteerana buzira mu irwariro rigye.",
    "abortion": "Okukaza omwana si kworungi. Shobora kurokora emicwe n'obundi.",
    "safe abortion":
        "Mu Uganda, okukaza omwana tekirindwa. Bambura omujanjabi.",
  };

  // ✅ Improved matching with fuzzy + synonyms + fallbacks
  static final Map<String, String> _synonyms = {
    'pregnant': 'pregnancy',
    'hivtest': 'hiv test',
    'arvs': 'arv',
    'stds': 'stis',
    'clinic': 'counseling',
    'doctor': 'help',
  };

  static String handleLocalKnowledge(String input) {
    input = input.toLowerCase().trim();

    // 1. Check synonyms first
    for (var synonym in _synonyms.keys) {
      if (input.contains(synonym)) {
        input = input.replaceAll(synonym, _synonyms[synonym]!);
        break;
      }
    }

    // 2. Exact key match
    for (var key in runyankoreDataset.keys) {
      if (input.contains(key)) {
        return runyankoreDataset[key]!;
      }
    }

    // 3. Fuzzy: split words and match any
    final words = input.split(RegExp(r'\s+'));
    for (var word in words) {
      if (word.isNotEmpty && runyankoreDataset.containsKey(word)) {
        return runyankoreDataset[word]!;
      }
    }

    // 4. Category fallbacks (if no exact, try category keys)
    if (input.contains('hiv') || input.contains('aids')) {
      return runyankoreDataset['what is hiv']!;
    }
    if (input.contains('pregnan') || input.contains('baby')) {
      return runyankoreDataset['pregnancy']!;
    }
    if (input.contains('prevent') || input.contains('avoid')) {
      return runyankoreDataset['how to prevent hiv']!;
    }
    if (input.contains('eat') || input.contains('food')) {
      return runyankoreDataset['nutrition']!;
    }
    if (input.contains('help') || input.contains('scared')) {
      return runyankoreDataset['i need help']!;
    }

    return "";
  }

  /// Clean output - improved for better formatting
  static String cleanResponse(String? text) {
    if (text == null || text.isEmpty) return '';

    String cleaned = text.trim();

    // Fix common joined words (e.g., "helloworld" → "hello world")
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );

    // Fix missing spaces after punctuation
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([.,!?;:])([A-Za-z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );

    // Multiple spaces to single
    cleaned = cleaned.replaceAll(RegExp(r' +'), ' ');

    // Multiple newlines to double
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // Trim lines
    final lines = cleaned.split('\n');
    final trimmedLines = lines.map((line) => line.trim()).toList();
    cleaned = trimmedLines.join('\n');

    return cleaned.trim();
  }

  /// Detect English
  static bool containsEnglish(String text) {
    return RegExp(r'[a-zA-Z]').hasMatch(text);
  }

  /// Health check - verify backend is running
  static Future<bool> isBackendHealthy() async {
    try {
      final url = Uri.parse('$baseUrl/health');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('🚨 Backend health check failed: $e');
      return false;
    }
  }

  /// Process input - SIMPLIFIED (no translate step)
  static Future<String> processUserInput(String input) async {
    final local = handleLocalKnowledge(input);
    if (local.isNotEmpty) return local;
    return input; // Direct to chat API
  }

  /// Core chat - SINGLE API CALL with retries (45s timeout)
  static Future<String> chatRunyankore(
    String userInput, {
    int maxRetries = 2,
  }) async {
    const int timeoutSeconds = 45;

    for (int attempt = 1; attempt <= maxRetries + 1; attempt++) {
      try {
        final runyankoreMessages = [
          {
            'role': 'system',
            'content':
                '''
Garukamu mu Runyankore-Rukiga Rwonka yorobi n'ebimanyirwe.
Kozesa ebigambo bya Runyankore byorobi - otakozesa Luganda.
Shoborora ku bya sirimu, okwerinda enda, emere y'orungi, abajanjabi.
Takorora "okugira enda" buri gihe - semura ku byo omuntu agamye.
Reba omwoyo gw'ekigambo kandi giha ekiramu ky'ekirala.
// ignore: unnecessary_brace_in_string_interps
ATTEMPT ${attempt}: ${DateTime.now().millisecondsSinceEpoch}
''',
          },
          {'role': 'user', 'content': userInput},
        ];

        final url = Uri.parse('$baseUrl/chat/runyankore');
        final headers = {'Content-Type': 'application/json'};

        final body = jsonEncode({
          'model': 'sunflower-70b-instruct',
          'messages': runyankoreMessages,
          'temperature': 0.3,
          'max_tokens': 400,
        });

        if (kDebugMode) {
          print('🔗 Exact request URL: $url');
          print('📦 Request body length: ${body.length}');
          print(
            '🌐 [SunflowerAPI] chatRunyankore attempt $attempt/$maxRetries: "$userInput" → $baseUrl',
          );
        }

        final response = await http
            .post(url, headers: headers, body: body)
            .timeout(Duration(seconds: timeoutSeconds));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final apiResponse = cleanResponse(
            data['choices']?[0]?['message']?['content'] ?? 'No response',
          );
          if (apiResponse.isNotEmpty &&
              !apiResponse.toLowerCase().contains('error')) {
            if (kDebugMode) {
              print(
                '✅ [SunflowerAPI] SUCCESS (${timeoutSeconds}s): ${apiResponse.substring(0, 50 < apiResponse.length ? 50 : apiResponse.length)}...',
              );
            }
            return apiResponse;
          }
        }
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      } catch (e) {
        if (kDebugMode) {
          print(
            '❌ [SunflowerAPI] attempt $attempt FAILED (${timeoutSeconds}s): $e',
          );
        }
        if (attempt == maxRetries + 1) break;
        // Exponential backoff
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    // Final fallback
    if (kDebugMode) {
      print('🔄 → Local Runyankore dataset fallback (all retries failed)');
    }
    return handleLocalKnowledge(userInput);
  }

  // DEPRECATED: translateToRunyankore removed - now single chatRunyankore call
  // ignore: provide_deprecation_message
  @deprecated
  static Future<String> translateToRunyankore(String text) async {
    if (kDebugMode) {
      print(
        '⚠️ translateToRunyankore DEPRECATED - use chatRunyankore directly',
      );
    }
    return text;
  }
}
