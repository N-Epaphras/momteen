import 'package:hive/hive.dart';
import 'chat_model.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  String email;

  @HiveField(1)
  String username;

  @HiveField(2)
  String password;

  @HiveField(3)
  List<ChatModel> chats;

  UserModel({
    required this.email,
    required this.username,
    required this.password,
    List<ChatModel>? chats,
  }) : chats = chats ?? [];
}
