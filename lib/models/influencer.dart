// lib/models/influencer.dart
class Influencer {
  final String id;
  final String name;
  final String platform;
  final String handle;
  final String channelUrl;
  final int followers;

  Influencer({
    required this.id,
    required this.name,
    required this.platform,
    required this.handle,
    required this.channelUrl,
    required this.followers,
  });

  factory Influencer.fromJson(Map<String, dynamic> json) {
    return Influencer(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      platform: (json['platform'] ?? '').toString(),
      handle: (json['handle'] ?? '').toString(),
      channelUrl: (json['channel_url'] ?? '').toString(),
      followers: (json['followers'] ?? 0) is int
          ? json['followers'] as int
          : int.tryParse((json['followers'] ?? '0').toString()) ?? 0,
    );
  }
}
