import 'package:hive/hive.dart';

part 'chat_model.g.dart';

@HiveType(typeId: 1)
class ChatModel extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  List<Map<String, dynamic>> messages;

  ChatModel({required this.title, required this.messages});
}
