import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'home_page.dart';
import 'models/chat_model.dart';
import 'models/api_cache_model.dart';
import 'models/user_model.dart';
import 'models/settings_model.dart';
import 'providers/locale_provider.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'utils/gemma_api.dart';
import 'utils/runyankole_matcher.dart';

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

  /// Format text for better display in chat
  /// Handles markdown-like formatting and creates proper widgets
  /// Safely jsonEncode any object, handling dynamic types
  static String jsonEncodeSafe(Object? obj) {
    if (obj is Map || obj is List) {
      return jsonEncode(obj);
    }
    return obj.toString();
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<Map<String, dynamic>> messages = [];
  final TextEditingController controller = TextEditingController();
  int? chatIndex;
  bool _isInit = false;
  bool _isLoading = false;
  String? topic;
  String? pendingImageBase64;
  String? userEmail;
  UserModel? currentUser;
  bool returnToGame = false;
  String? gameMedicine;

  // SECURITY: Extract API keys to private constants
  static const String _groqApiKey =
      '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';

  ImagePicker picker = ImagePicker();
  final GemmaAPI _gemma = GemmaAPI();

  @override
  void initState() {
    super.initState();
    _initializeGemma();
  }

  Future<void> _initializeGemma() async {
    await _gemma.initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        userEmail = args['userEmail'];
        final usersBox = Hive.box<UserModel>('users');
        currentUser =
            usersBox.values.cast<UserModel?>().firstWhere(
              (u) => u?.email == userEmail,
              orElse: () => null,
            ) ??
            (userEmail != null
                ? UserModel(email: userEmail!, username: 'User', password: '')
                : null);

        if (currentUser != null && args.containsKey('index')) {
          chatIndex = args['index'];
          if (chatIndex != null && chatIndex! < currentUser!.chats.length) {
            // Safe load existing messages
            final history = currentUser!.chats[chatIndex!].messages as List;
            for (var msg in history) {
              messages.add(Map<String, dynamic>.from(msg));
            }
          }
        } else if (args.containsKey('topic')) {
          topic = args['topic'];
        }
        returnToGame = args['returnToGame'] ?? args['returnToChat'] ?? false;
        gameMedicine = args['gameMedicine'];
      }
      if (returnToGame && gameMedicine != null && messages.isEmpty) {
        messages.add({
          "sender": "bot",
          "msg":
              "Hi! Need help with $gameMedicine? Ask about condoms, birth control pills, vitamins, or other reproductive health topics! 🤖",
          "isWelcome": true,
        });
      }
      _isInit = true;
    }
  }

  /// Get offline mode settings
  Future<Map<String, bool>> _getOfflineSettings() async {
    final settingsBox = Hive.box<SettingsModel>('settings');
    bool offlineModeEnabled = false;
    bool modelDownloaded = false;

    if (settingsBox.isNotEmpty) {
      final settings = settingsBox.getAt(0);
      offlineModeEnabled = settings?.offlineModeEnabled ?? false;
      modelDownloaded = settings?.modelDownloaded ?? false;
    }

    return {
      'offlineModeEnabled': offlineModeEnabled,
      'modelDownloaded': modelDownloaded,
    };
  }

  Future<void> sendMessage() async {
    if (controller.text.trim().isEmpty) return;

    // Get language for API messages (listen:false OK here - just for API call)
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final language = localeProvider.languageString;

    // Prepare the API content for the current message
    String apiText = controller.text;
    if (topic != null) {
      apiText =
          "Provide information about $topic in the context of teenage pregnancy prevention. User question: $apiText";
    }

    dynamic apiContent;
    if (pendingImageBase64 != null) {
      apiContent = [
        {'type': 'text', 'text': controller.text},
        {
          'type': 'image_url',
          'image_url': {'url': 'data:image/jpeg;base64,$pendingImageBase64'},
        },
      ];
    } else {
      apiContent = controller.text;
    }

    final userMsg = {
      "sender": "user",
      "msg": controller.text,
      "content": apiContent,
    };

    // Add user message immediately at top and set loading state
    final userMsgWithTime = Map<String, dynamic>.from(userMsg);
    userMsgWithTime['timestamp'] = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      messages.insert(0, userMsgWithTime);
      _isLoading = true;
    });

    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (!mounted) return;
    bool isOnline = !connectivityResult.contains(ConnectivityResult.none);

    // Get offline settings
    final offlineSettings = await _getOfflineSettings();
    bool offlineModeEnabled = offlineSettings['offlineModeEnabled'] ?? false;
    bool modelDownloaded = offlineSettings['modelDownloaded'] ?? false;
    bool canUseGemma = offlineModeEnabled && modelDownloaded;

    // BRAIN SWITCH: Decide which AI to use
    // If offline mode enabled + model downloaded → use Gemma (regardless of connectivity)
    // Otherwise → use Groq API (current behavior)
    bool useGemmaOffline = canUseGemma;

    // Detect language
    // Use app language setting instead of detection for consistency
    bool isRunyankore = language == 'Runyankole';
    if (kDebugMode) {
      print("🌐 App language: '$language' → isRunyankore: $isRunyankore");
    }

    try {
      // Check if question is related to teenage pregnancy prevention (skip for images and offline)
      if (pendingImageBase64 == null && isOnline && !useGemmaOffline) {
        final moderationUrl = Uri.parse(
          'https://api.groq.com/openai/v1/chat/completions',
        );
        final moderationHeaders = {
          'Authorization':
              'Bearer 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',
          'Content-Type': 'application/json',
        };
        final moderationBody = jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {
              'role': 'user',
              'content':
                  "Is the following question related to teenage pregnancy prevention, adolescent reproductive health, family planning for teenagers, or maternal health education? Answer only 'yes' or 'no': ${controller.text}",
            },
          ],
        });
        final moderationResponse = await http.post(
          moderationUrl,
          headers: moderationHeaders,
          body: moderationBody,
        );
        if (moderationResponse.statusCode == 200) {
          final moderationData = jsonDecode(moderationResponse.body);
          final moderationAnswer =
              moderationData['choices'][0]['message']['content']
                  .toLowerCase()
                  .trim();
          if (!moderationAnswer.contains('yes')) {
            String rejectionMsg =
                "I'm sorry, I can only answer questions related to teenage pregnancy prevention and maternal health education.";
            if (language == 'Runyankole') {
              try {
                rejectionMsg = await RunyankoleMatcher.getResponse(
                  "Translate to Runyankore: $rejectionMsg",
                );
              } catch (e) {
                rejectionMsg =
                    "Nsonyi, nshobora okukola ebitabo ku buzima bw'abato b'enteesaza okuzala n'okurinda entwala.";
              }
            }
            final botMsg = {"sender": "bot", "msg": rejectionMsg};
            setState(() {
              messages.add(botMsg);
              _isLoading = false;
            });
            controller.clear();
            return;
          }
        } else {
          // If moderation fails, proceed (to avoid blocking)
        }
      }

      // Build conversation messages for API
      List<Map<String, dynamic>> apiMessages = [];

      if (isRunyankore) {
        apiMessages.add({
          'role': 'system',
          'content':
              'You are a native Runyankole-Rukiga medical expert. Respond only in Runyankole. Use formal grammar (augments/initial vowels). If a medical term doesn\'t exist in Runyankole, describe it using Runyankole phrases rather than using the English word. Topic: teenage pregnancy prevention and maternal health education.',
        });
      } else {
        apiMessages.add({
          'role': 'system',
          'content':
              'You are a helpful assistant for teenage pregnancy prevention and maternal health education. Always respond in English. Only provide information about adolescent reproductive health, teenage pregnancy prevention, and maternal health education.',
        });
      }
      for (var msg in messages) {
        if (msg['sender'] == 'user') {
          dynamic content = msg['content'] ?? msg['msg'];
          apiMessages.add({'role': 'user', 'content': content});
        } else if (msg['sender'] == 'bot') {
          apiMessages.add({'role': 'assistant', 'content': msg['msg']});
        }
      }

      String botResponse;
      bool useCache =
          apiMessages.length <= 2; // Cache only for single questions
      String cacheKey = controller.text; // Simple key for cache

      // ============================================================
      // BRAIN SWITCH: Use Gemma if offline and model available
      // ============================================================
      if (useGemmaOffline) {
        // OFFLINE MODE: Use Gemma for AI response
        try {
          final responseStream = _gemma.getResponse(controller.text);
          String fullResponse = '';

          // Add empty bot message placeholder first (at top)
          setState(() {
            messages.insert(0, {
              "sender": "bot",
              "msg": "",
              "isOffline": true,
              "timestamp": DateTime.now().millisecondsSinceEpoch,
            });
          });

          await for (final chunk in responseStream) {
            fullResponse += chunk;
            // Clean the text and update UI with streaming response
            final cleanedResponse = TextCleaner.cleanOfflineText(fullResponse);
            setState(() {
              messages[0] = {
                "sender": "bot",
                "msg": cleanedResponse,
                "isOffline": true,
              };
            });
          }

          // Final cleaning of the complete response
          botResponse = TextCleaner.cleanOfflineText(fullResponse);
          // Add offline indicator
          botResponse += "\n\n*Offline mode: Powered by local AI*";

          // Update the final message with offline indicator (index 0)
          setState(() {
            messages[0] = {
              "sender": "bot",
              "msg": botResponse,
              "isOffline": true,
              "timestamp": messages[0]['timestamp'],
            };
          });

          // Skip the duplicate message addition at the end
          // by setting a flag or using a different approach
          controller.clear();
          return;
        } catch (e) {
          botResponse =
              "I'm offline and having trouble generating a response. Please try again when you're back online.";
        }
      }
      // ============================================================
      // ONLINE MODE: Use Groq API (original logic)
      // ============================================================
      else if (pendingImageBase64 != null) {
        if (isOnline) {
          final model = 'meta-llama/llama-4-scout-17b-16e-instruct';
          final url = Uri.parse(
            'https://api.groq.com/openai/v1/chat/completions',
          );
          final headers = {
            'Authorization':
                'Bearer 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',
            'Content-Type': 'application/json',
          };
          final body = jsonEncode({'model': model, 'messages': apiMessages});
          final response = await http.post(url, headers: headers, body: body);
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            botResponse = data['choices'][0]['message']['content'];
          } else {
            throw Exception(
              'Failed to get response: ${response.statusCode} ${response.body}',
            );
          }
        } else {
          botResponse = "Offline: unable to analyze images.";
        }
        pendingImageBase64 = null; // Reset after use
      } else if (!isRunyankore && useCache) {
        if (isOnline) {
          final cacheBox = Hive.box<ApiCacheModel>('cache');
          final cached = cacheBox.values.firstWhere(
            (c) => c.cacheKey == cacheKey,
            orElse: () => ApiCacheModel(
              cacheKey: '',
              response: '',
              timestamp: DateTime.now(),
            ),
          );
          if (cached.cacheKey.isNotEmpty &&
              DateTime.now().difference(cached.timestamp).inHours < 1) {
            botResponse = cached.response;
          } else {
            final url = Uri.parse(
              'https://api.groq.com/openai/v1/chat/completions',
            );
            final headers = {
              'Authorization':
                  'Bearer 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',
              'Content-Type': 'application/json',
            };
            final body = jsonEncode({
              'model': 'llama-3.1-8b-instant',
              'messages': apiMessages,
            });
            final response = await http.post(url, headers: headers, body: body);
            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              botResponse = data['choices'][0]['message']['content'];
              final cacheModel = ApiCacheModel(
                cacheKey: cacheKey,
                response: botResponse,
                timestamp: DateTime.now(),
              );
              cacheBox.add(cacheModel);
            } else {
              throw Exception(
                'Failed to get response: ${response.statusCode} ${response.body}',
              );
            }
          }
        } else {
          final cacheBox = Hive.box<ApiCacheModel>('cache');
          final cached = cacheBox.values.firstWhere(
            (c) => c.cacheKey == cacheKey,
            orElse: () => ApiCacheModel(
              cacheKey: '',
              response: '',
              timestamp: DateTime.now(),
            ),
          );
          if (cached.cacheKey.isNotEmpty) {
            final timeAgo = DateTime.now().difference(cached.timestamp);
            final hours = timeAgo.inHours;
            final minutes = timeAgo.inMinutes % 60;
            String timeStr = hours > 0 ? '$hours hours' : '$minutes minutes';
            // Clean the cached response
            final cleanedCache = TextCleaner.cleanOfflineText(cached.response);
            botResponse =
                "$cleanedCache\n\n*Offline mode: response from $timeStr ago*";
          } else {
            // Check if we should use Gemma even without explicit offline mode
            if (canUseGemma) {
              try {
                final responseStream = _gemma.getResponse(controller.text);
                String fullResponse = '';
                await for (final chunk in responseStream) {
                  fullResponse += chunk;
                }
                // Clean the response from Gemma
                botResponse = TextCleaner.cleanOfflineText(fullResponse);
                botResponse += "\n\n*Offline mode: Powered by local AI*";
              } catch (e) {
                botResponse =
                    "I'm offline right now, but I can answer this when you're back online.";
              }
            } else {
              botResponse =
                  "I'm offline right now, but I can answer this when you're back online.";
            }
          }
        }
      } else if (isRunyankore) {
        // Use Gemini API for Runyankole/Rukiga responses
        final lastUserInput = controller.text;

        if (kDebugMode) {
          print("🌟 Gemini API call for Runyankole: '$lastUserInput'");
        }

        try {
          if (isOnline) {
            final geminiUrl = Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-pro-preview:generateContent?key=AIzaSyBEA3lOGiMjuS1oYw4EmgN-Iy2WVjtu_6Q',
            );

            final geminiBody = jsonEncode({
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {
                      'text':
                          'You are Orunyankore, a Runyankole-Rukiga speaking assistant for teenage pregnancy prevention and maternal health education. ALWAYS respond ONLY in Runyankore-Rukiga. NEVER use English. Use simple language for teenagers. Topic: teenage pregnancy prevention. User: $lastUserInput',
                    },
                  ],
                },
              ],
              'generationConfig': {
                'temperature': 0.8,
                'topK': 40,
                'topP': 0.95,
                'maxOutputTokens': 1000,
              },
            });

            final geminiHeaders = {'Content-Type': 'application/json'};
            final geminiResponse = await http.post(
              geminiUrl,
              headers: geminiHeaders,
              body: geminiBody,
            );

            if (geminiResponse.statusCode == 200) {
              final geminiData = jsonDecode(geminiResponse.body);
              botResponse =
                  geminiData['candidates'][0]['content']['parts'][0]['text'];
            } else {
              throw Exception('Gemini API error: ${geminiResponse.statusCode}');
            }
          } else {
            // Fallback to dataset when offline
            botResponse = await RunyankoleMatcher.getResponse(lastUserInput);
            botResponse += "";
          }
        } catch (e) {
          // Fallback to dataset on any error
          botResponse = await RunyankoleMatcher.getResponse(lastUserInput);
          botResponse += "";
        }

        if (kDebugMode) {
          print(
            "✅ Gemini response: ${botResponse.substring(0, min(50, botResponse.length))}...",
          );
        }
      } else {
        if (isOnline) {
          final url = Uri.parse(
            'https://api.groq.com/openai/v1/chat/completions',
          );
          final headers = {
            'Authorization': 'Bearer $_groqApiKey',
            'Content-Type': 'application/json',
          };
          final body = jsonEncode({
            'model': 'llama-3.1-8b-instant',
            'messages': apiMessages,
          });
          final response = await http.post(url, headers: headers, body: body);
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            botResponse = data['choices'][0]['message']['content'];
          } else {
            throw Exception(
              'Failed to get response: ${response.statusCode} ${response.body}',
            );
          }
        } else {
          // Try Gemma for offline
          if (canUseGemma) {
            try {
              final responseStream = _gemma.getResponse(controller.text);
              String fullResponse = '';
              await for (final chunk in responseStream) {
                fullResponse += chunk;
              }
              // Clean the response from Gemma
              botResponse = TextCleaner.cleanOfflineText(fullResponse);
              botResponse += "\n\n*Offline mode: Powered by local AI*";
            } catch (e) {
              botResponse =
                  "I'm offline right now, but I can answer this when you're back online.";
            }
          } else {
            botResponse =
                "I'm offline right now, but I can answer this when you're back online.";
          }
        }
      }

      // Clean ALL bot responses for consistent formatting (MOVED UP)
      botResponse = TextCleaner.cleanOfflineText(botResponse);

      final botMsg = {
        "sender": "bot",
        "msg": botResponse,
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      };

      if (kDebugMode) {
        print("📤 Final bot response length: ${botResponse.length} chars");
      }

      setState(() {
        messages.insert(0, botMsg);
        _isLoading = false;
      });

      // 🔒 NULL-SAFE PERSISTENCE: CRASH FIX
      if (currentUser != null) {
        try {
          if (chatIndex != null && chatIndex! < currentUser!.chats.length) {
            currentUser!.chats[chatIndex!].messages = List.from(messages);
          } else {
            // New chat: create FIRST, then assign index
            final newChat = ChatModel(
              title: topic ?? controller.text,
              messages: List.from(messages),
            );
            currentUser!.chats.insert(0, newChat);
            chatIndex = 0;
          }
          await currentUser!.save();
          HomePage.recentChats = currentUser!.chats
              .map((c) => {'title': c.title, 'messages': c.messages})
              .toList();
        } catch (e) {
          debugPrint("💾 Persistence safe-fail: $e");
        }
      } else {
        debugPrint("⚠️ No currentUser for persistence");
      }
    } catch (e) {
      debugPrint("❌ API Error: ${e.toString()}");

      String errorMessage = "Sorry, unable to generate response right now.";
      if (e is SocketException ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Network is unreachable')) {
        errorMessage = "No internet connection. Please check your connection.";
      }

      if (language == 'Runyankole') {
        try {
          errorMessage = await RunyankoleMatcher.getResponse(
            "Translate to Runyankore: $errorMessage",
          );
        } catch (e) {
          if (errorMessage.contains("internet")) {
            errorMessage =
                "Tewali intaneet. Kyeroroka connection y'ekintu ky'okukola.";
          } else {
            errorMessage =
                "Nsonyi, nari kugira ikibazo ky'okukola ebitabo. "
                "Oryoza okwesibaata: \"Okurinda entwala kiki?\" "
                "oba \"Ebitabo ku okurinda entwala.\"";
          }
        }
      }
      final errorMsg = {
        "sender": "bot",
        "msg": errorMessage,
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      };
      setState(() {
        messages.insert(0, errorMsg);
        _isLoading = false;
      });

      // 🔒 NULL-SAFE ERROR HANDLER PERSISTENCE (same as success path)
      if (currentUser != null) {
        try {
          if (chatIndex != null && chatIndex! < currentUser!.chats.length) {
            currentUser!.chats[chatIndex!].messages = List.from(messages);
          } else {
            final newChat = ChatModel(
              title: topic ?? controller.text,
              messages: List.from(messages),
            );
            currentUser!.chats.insert(0, newChat);
            chatIndex = 0;
          }
          await currentUser!.save();
          HomePage.recentChats = currentUser!.chats
              .map((c) => {'title': c.title, 'messages': c.messages})
              .toList();
        } catch (e) {
          debugPrint("💾 Error handler persistence safe-fail: $e");
        }
      }
    }
    controller.clear();
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final base64 = base64Encode(bytes);
      pendingImageBase64 = base64;
      final imageMsg = {
        "sender": "user",
        "msg": "Image uploaded. Ask me a question about it.",
        "imageBase64": base64,
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      };
      setState(() {
        messages.insert(0, imageMsg);
      });
    }
  }

  /// REMOVED: No longer needed since we strip Markdown in cleanOfflineText()
  /// All text now displays as plain text without * bullet interpretation

  // REMOVED: _needsDataset no longer needed - RunyankoleMatcher handles all cases

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.chatTitle),
        actions: [
          if (returnToGame)
            IconButton(
              icon: const Icon(Icons.gamepad),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Back to Game',
            ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(localizations.chatHistory),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: HomePage.recentChats.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(Icons.chat_bubble_outline),
                          title: Text(HomePage.recentChats[index]['title']),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushReplacementNamed(
                              context,
                              '/chat',
                              arguments: {
                                'userEmail': userEmail,
                                'index': index,
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(localizations.close),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: () {
              Navigator.pushNamed(context, '/local_referrals');
            },
            tooltip: 'Local Referrals',
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            tooltip: 'New Chat',
          ),
        ],
      ),

      body: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ListView.builder(
                      reverse: true,
                      padding: EdgeInsets.only(
                        left: 15,
                        right: 15,
                        top: 15,
                        bottom: _isLoading ? 80 : 15,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];

                        final sender = message["sender"] as String;
                        bool isUser = sender == "user";
                        bool isSystem = sender == "system";
                        Widget content;
                        if (message.containsKey('imageBase64')) {
                          content = Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.memory(
                                base64Decode(message['imageBase64']!),
                                height: 200,
                                width: 200,
                                fit: BoxFit.cover,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                message["msg"]!,
                                style: TextStyle(
                                  color: isUser ? Colors.white : Colors.black,
                                  fontSize: 16,
                                ),
                                textAlign: isUser
                                    ? TextAlign.right
                                    : TextAlign.left,
                              ),
                            ],
                          );
                        } else {
                          final msgText = message["msg"]!;
                          content = Text(
                            msgText,
                            style: TextStyle(
                              color: isUser
                                  ? Colors.white
                                  : (isSystem
                                        ? Colors.grey[600]
                                        : Colors.black),
                              fontSize: isSystem ? 14 : 16,
                              fontWeight: isSystem
                                  ? FontWeight.w400
                                  : FontWeight.normal,
                              height: 1.4,
                            ),
                            textAlign: isUser
                                ? TextAlign.right
                                : TextAlign.left,
                          );
                        }
                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : (isSystem
                                    ? Alignment.center
                                    : Alignment.centerLeft),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? Colors.purple
                                  : (isSystem
                                        ? Colors.grey.shade200
                                        : Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            constraints: const BoxConstraints(maxWidth: 300),
                            child: content,
                          ),
                        );
                      },
                    ),
                    if (_isLoading)
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: SpinKitThreeBounce(
                            color: Colors.blueGrey,
                            size: 50.0,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              if (!_isLoading)
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.image),
                        onPressed: _pickImage,
                      ),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: localizations.typeMessage,
                            border: const OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onSubmitted: (_) => sendMessage(),
                          textInputAction: TextInputAction.send,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send, color: Colors.pink[200]),
                        onPressed: sendMessage,
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
