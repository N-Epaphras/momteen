import 'package:hive/hive.dart';

part 'settings_model.g.dart';

@HiveType(typeId: 2)
class SettingsModel extends HiveObject {
  @HiveField(0)
  bool darkMode;

  @HiveField(1)
  bool notifications;

  @HiveField(2)
  String language;

  @HiveField(3)
  bool offlineModeEnabled;

  @HiveField(4)
  bool modelDownloaded;

  SettingsModel({
    required this.darkMode,
    required this.notifications,
    required this.language,
    this.offlineModeEnabled = false,
    this.modelDownloaded = false,
  });
}
