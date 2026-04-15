import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'models/settings_model.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'l10n/app_localizations.dart';
import 'utils/gemma_api.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool offlineModeEnabled = false;
  bool modelDownloaded = false;
  bool notificationsEnabled = true;
  bool isDownloading = false;
  double downloadProgress = 0.0;

  final GemmaAPI _gemma = GemmaAPI();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkGemmaStatus();
  }

  Future<void> _checkGemmaStatus() async {
    await _gemma.initialize();
    final bool downloaded = _gemma.isModelDownloaded;
    setState(() {
      modelDownloaded = downloaded;
    });
  }

  Future<void> _loadSettings() async {
    final settingsBox = Hive.box<SettingsModel>('settings');
    if (settingsBox.isNotEmpty) {
      final settings = settingsBox.getAt(0);
      if (settings != null) {
        setState(() {
          offlineModeEnabled = settings.offlineModeEnabled;
          modelDownloaded = settings.modelDownloaded;
          notificationsEnabled = settings.notifications;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    final settingsBox = Hive.box<SettingsModel>('settings');
    if (settingsBox.isNotEmpty) {
      final settings = settingsBox.getAt(0);
      if (settings != null) {
        settings.offlineModeEnabled = offlineModeEnabled;
        settings.modelDownloaded = modelDownloaded;
        settings.notifications = notificationsEnabled;
        await settings.save();
      }
    }
  }

  Future<void> _downloadModel() async {
    setState(() {
      isDownloading = true;
      downloadProgress = 0.0;
    });

    try {
      await for (final progress in _gemma.downloadModel()) {
        setState(() {
          downloadProgress = progress;
        });
      }

      setState(() {
        modelDownloaded = true;
        isDownloading = false;
      });

      _saveSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Model downloaded successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        isDownloading = false;
        downloadProgress = 0.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to download model: $e')));
      }
    }
  }

  Future<void> _deleteModel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Offline Model'),
        content: const Text(
          'This will delete the downloaded offline AI model (~1.5GB). '
          'You can re-download it later. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _gemma.deleteModel();
      setState(() {
        modelDownloaded = false;
        offlineModeEnabled = false;
      });
      _saveSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Model deleted successfully!')),
        );
      }
    }
  }

  void _showDeviceRequirements() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device Requirements'),
        content: const SingleChildScrollView(
          child: Text(
            'Offline AI Model Requirements:\n\n'
            'The offline AI model requires:\n\n'
            '📱 Android:\n'
            '• Modern phone (Snapdragon 8 Gen 1+ / Pixel 7+)\n'
            '• At least 4GB of free RAM\n'
            '• 2GB of free storage space\n\n'
            '🍎 iOS:\n'
            '• iPhone 13 or newer\n'
            '• At least 4GB of free RAM\n'
            '• 2GB of free storage space\n\n'
            '⚠️ Note: Running an AI model offline is resource-intensive. '
            'Your device may get warm and battery may drain faster in offline mode.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          const SizedBox(height: 20),
          Text(localizations.settings),
          const SizedBox(height: 20),
          SwitchListTile(
            title: Text(localizations.darkMode),
            value: themeProvider.isDarkMode,
            onChanged: (bool value) {
              themeProvider.toggleTheme(value);
            },
          ),
          ListTile(
            title: Text(localizations.language),
            subtitle: Text(
              localeProvider.languageString == 'English'
                  ? localizations.english
                  : 'Runyankole',
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => SimpleDialog(
                  title: Text(localizations.language),
                  children: [
                    SimpleDialogOption(
                      onPressed: () {
                        Navigator.pop(context);
                        localeProvider.setLocale('English');
                      },
                      child: Text(localizations.english),
                    ),
                    SimpleDialogOption(
                      onPressed: () {
                        Navigator.pop(context);
                        localeProvider.setLocale('Runyankole');
                      },
                      child: Text('Runyankole'),
                    ),
                  ],
                ),
              );
            },
          ),

          // Offline Mode Section
          const Divider(height: 40),
          const Text(
            'Offline AI Mode',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Enable offline AI to get answers even without internet. '
            'This requires downloading a large AI model (~1.5GB).',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 10),

          // Device Requirements Info
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Device Requirements'),
            subtitle: const Text('Check if your device can run offline AI'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showDeviceRequirements,
          ),

          // Enable Offline Mode Switch
          SwitchListTile(
            title: const Text('Enable Offline Mode'),
            subtitle: Text(
              modelDownloaded
                  ? 'Offline AI is ready to use'
                  : 'Model needs to be downloaded first',
            ),
            value: offlineModeEnabled && modelDownloaded,
            onChanged: modelDownloaded
                ? (bool value) {
                    setState(() {
                      offlineModeEnabled = value;
                    });
                    _saveSettings();
                  }
                : null,
          ),

          // Download Model Button
          if (!modelDownloaded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isDownloading) ...[
                    const Text('Downloading model...'),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: downloadProgress),
                    const SizedBox(height: 4),
                    Text(
                      '${(downloadProgress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      onPressed: _downloadModel,
                      icon: const Icon(Icons.download),
                      label: const Text('Download Offline Brain'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '⚠️ This will download approximately 1.5GB',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),

          // Delete Model Button (only if downloaded)
          if (modelDownloaded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: _deleteModel,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Offline Model'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  foregroundColor: Colors.red,
                ),
              ),
            ),

          const Divider(height: 40),
          ListTile(
            title: Text(localizations.privacyPolicy),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(localizations.privacyPolicy),
                  content: SingleChildScrollView(
                    child: const Text(
                      'Privacy Policy\n\nWe are committed to protecting your privacy. This app collects minimal personal information necessary for functionality, such as user email for account management. We do not share your data with third parties without your consent. All data is stored securely using local storage. For questions, contact us at support@momteen.com.\n\nDetailed Privacy Policy:\n\n1. Information We Collect:\n- User email for account creation.\n- Chat history and messages stored locally.\n- API responses cached for offline use.\n\n2. How We Use Information:\n- To provide personalized chat responses.\n- To enable offline functionality through caching.\n- To improve app performance.\n\n3. Data Sharing:\n- We do not sell or share personal data.\n- Data is stored locally on your device.\n\n4. Security:\n- All data is encrypted and stored securely.\n- We use Hive for local storage.\n\n5. Contact Us:\n- For any privacy concerns, email epaphrasnasasira21@gmail.com. or \n evelynkyomugisha12@gmail.com',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            title: Text(localizations.termsOfService),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(localizations.termsOfService),
                  content: SingleChildScrollView(
                    child: const Text(
                      'Terms of Service\n\nBy using this app, you agree to these terms. The app is for maternal health advice, not medical advice. Use at your own risk. We are not liable for any damages. Contact support for issues.\n\nDetailed Terms of Service:\n\n1. Acceptance of Terms:\n- By downloading and using the app, you accept these terms.\n\n2. Use of Service:\n- The app provides general advice on pregnancy and maternal health.\n- Not a substitute for professional medical advice.\n\n3. User Responsibilities:\n- Provide accurate information.\n- Use the app responsibly.\n\n4. Limitation of Liability:\n- We are not responsible for any harm from using the app.\n\n5. Changes to Terms:\n- We may update terms, continued use implies acceptance.\n\n6. Contact:\n- For questions, email epaphrasnasasira21@gmail.com.or \n evelynkyomugisha12@gmail.com. ',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            title: Text(localizations.about),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(localizations.about),
                  content: const Text(
                    'MomTeen App\nVersion 1.0.0\nA helpful app for maternal health and pregnancy advice, providing chat support and local referrals.\n\nOffline AI powered by Google Gemma.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          SwitchListTile(
            title: const Text('Notifications'),
            value: notificationsEnabled,
            onChanged: (value) {
              setState(() {
                notificationsEnabled = value;
              });
              _saveSettings();
            },
          ),
          const Divider(height: 20),
          ListTile(
            title: Text(localizations.share),
            onTap: () {
              SharePlus.instance.share(
                ShareParams(
                  text:
                      'Check out the MomTeen App: A helpful app for maternal health and pregnancy advice. Download it now!',
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
