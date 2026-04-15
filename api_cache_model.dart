import 'package:hive/hive.dart';

part 'api_cache_model.g.dart';

@HiveType(typeId: 3)
class ApiCacheModel extends HiveObject {
  @HiveField(0)
  String cacheKey;

  @HiveField(1)
  String response;

  @HiveField(2)
  DateTime timestamp;

  ApiCacheModel({
    required this.cacheKey,
    required this.response,
    required this.timestamp,
  });
}
