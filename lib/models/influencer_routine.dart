// lib/models/influencer_routine.dart
class RoutineElement {
  final String id;
  final String name;
  final double qty;
  final String unit;
  final String note;

  RoutineElement({
    required this.id,
    required this.name,
    required this.qty,
    required this.unit,
    required this.note,
  });

  factory RoutineElement.fromJson(Map<String, dynamic> json) {
    return RoutineElement(
      id: (json['eid'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      qty: _toDouble(json['qty'], 0.0),
      unit: (json['unit'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
    );
  }

  static double _toDouble(dynamic v, double fallback) {
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    final s = v.toString().trim();
    return double.tryParse(s) ?? fallback;
  }
}

class InfluencerRoutine {
  final String id;
  final String title;
  final String categories;
  final int costKrw;
  final int timeMin;
  final int difficulty;
  final String influencerId;
  final int popularityScore;
  final String videoUrl;
  final String thumbnailUrl;
  final String provider;
  final List<String> tags;
  final String createdAt;
  final List<RoutineElement> elements;

  InfluencerRoutine({
    required this.id,
    required this.title,
    required this.categories,
    required this.costKrw,
    required this.timeMin,
    required this.difficulty,
    required this.influencerId,
    required this.popularityScore,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.provider,
    required this.tags,
    required this.createdAt,
    required this.elements,
  });

  factory InfluencerRoutine.fromJson(Map<String, dynamic> json) {
    final rawTags = (json['tags'] ?? '').toString();
    final tagList = rawTags.split(RegExp(r'[,;]+')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    final elementsJson = (json['elements'] ?? []) as List? ?? [];
    final elements = elementsJson.map((e) => RoutineElement.fromJson(Map<String, dynamic>.from(e as Map))).toList();

    return InfluencerRoutine(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      categories: (json['categories'] ?? '').toString(),
      costKrw: _toInt(json['cost_krw'], 0),
      timeMin: _toInt(json['time_min'], 0),
      difficulty: _toInt(json['difficulty'], 1),
      influencerId: (json['influencer_id'] ?? '').toString(),
      popularityScore: _toInt(json['popularity_score'], 0),
      videoUrl: (json['video_url'] ?? '').toString(),
      thumbnailUrl: (json['thumbnail_url'] ?? '').toString(),
      provider: (json['provider'] ?? '').toString(),
      tags: tagList,
      createdAt: (json['created_at'] ?? '').toString(),
      elements: elements,
    );
  }

  static int _toInt(dynamic v, int fallback) {
    if (v == null) return fallback;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? fallback;
  }
}
