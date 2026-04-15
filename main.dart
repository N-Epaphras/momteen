import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'models/user_model.dart';
import 'models/chat_model.dart';
import 'models/settings_model.dart';
import 'models/api_cache_model.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'l10n/app_localizations.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'home_page.dart';
import 'chat_page.dart';
import 'local_referrals_page.dart';
import 'settings_page.dart';
import 'image_generation_page.dart';
import 'game_page.dart';
import 'note_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  // Register adapters
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(ChatModelAdapter());
  Hive.registerAdapter(SettingsModelAdapter());
  Hive.registerAdapter(ApiCacheModelAdapter());

  // Open boxes
  await Hive.openBox<UserModel>('users');
  await Hive.openBox('chats');
  await Hive.openBox<SettingsModel>('settings');
  await Hive.openBox('cache');

  // Initialize notifications
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );

  runApp(const MomTeenApp());
}

class MomTeenApp extends StatefulWidget {
  const MomTeenApp({super.key});

  @override
  State<MomTeenApp> createState() => _MomTeenAppState();
}

class _MomTeenAppState extends State<MomTeenApp> {
  late final Box<SettingsModel> settingsBox;

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box<SettingsModel>('settings');
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(settingsBox)),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, child) {
          return MaterialApp(
            key: const ValueKey(
              'momteen_app',
            ), // ✅ Stable key - prevents rebuild crash on locale change
            debugShowCheckedModeBanner: false,
            title: "MomTeen",
            theme: themeProvider.themeData.copyWith(
              textTheme: themeProvider.themeData.textTheme.apply(
                fontFamily: 'NotoSans',
              ),
            ),
            locale: localeProvider.locale, // ✅ Dynamic locale from provider
            localeResolutionCallback: (locale, supportedLocales) {
              // 🔥 WEB FIX: 'nyn' unsupported by Material/Cupertino on Chrome
              // Force fallback to 'en' for MaterialLocalizations, keep 'nyn' for app only
              if (locale?.languageCode == 'nyn') {
                return const Locale('en'); // Material/Cupertino need 'en'
              }
              if (locale != null && supportedLocales.contains(locale)) {
                return locale;
              }
              return const Locale('en');
            },
            localizationsDelegates: [
              // Standard Material localizations FIRST
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              // Custom app localizations LAST
              AppLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            initialRoute: '/welcome',
            routes: {
              '/login': (context) => const LoginPage(),
              '/register': (context) => const RegisterPage(),
              '/welcome': (context) => const HomePage(),
              '/home': (context) => const HomePage(),
              '/game': (context) => const GamePage(),
              '/chat': (context) => const ChatPage(),
              '/local_referrals': (context) => const LocalReferralsPage(),
              '/settings': (context) => const SettingsPage(),
              '/image_generation': (context) => const ImageGenerationPage(),
              '/note': (context) => const NotePage(),
            },
          );
        },
      ),
    );
  }
}
