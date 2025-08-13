// lib/services/data_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/influencer.dart';
import '../models/influencer_routine.dart';

class DataService {
  static const String baseUrl = "https://healthfluence-api.healthfluence-yuri.workers.dev";

  Uri _buildUri(String path, Map<String, String?> params) {
    final qp = <String, String>{};
    params.forEach((k, v) {
      if (v != null && v.isNotEmpty) qp[k] = v;
    });
    return Uri.parse("$baseUrl$path").replace(queryParameters: qp.isEmpty ? null : qp);
  }

  T _decode<T>(http.Response res) {
    final body = json.decode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body as T;
    }
    throw Exception("HTTP ${res.statusCode}: ${body is Map && body['error'] != null ? body['error'] : res.body}");
  }

  // Influencers
  Future<List<Influencer>> fetchInfluencers({int limit = 100, int offset = 0}) async {
    final uri = _buildUri("/influencers", {'limit': '$limit', 'offset': '$offset'});
    final res = await http.get(uri);
    final map = _decode<Map<String, dynamic>>(res);
    final List items = (map['items'] ?? []) as List;
    return items.map((e) => Influencer.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  // Routines
  Future<List<InfluencerRoutine>> fetchRoutines({
    String? provider,
    String? category,
    String? tag,
    String? influencerId,
    int limit = 20,
    int offset = 0,
    String order = 'popular',
  }) async {
    final uri = _buildUri("/routines", {
      'provider': provider,
      'category': category,
      'tag': tag,
      'influencer_id': influencerId,
      'limit': '$limit',
      'offset': '$offset',
      'order': order,
    });
    final res = await http.get(uri);
    final map = _decode<Map<String, dynamic>>(res);
    final List items = (map['items'] ?? []) as List;
    return items.map((e) => InfluencerRoutine.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<InfluencerRoutine> fetchRoutineDetail(String id) async {
    final uri = _buildUri("/routines/$id", {});
    final res = await http.get(uri);
    final map = _decode<Map<String, dynamic>>(res);
    return InfluencerRoutine.fromJson(map);
  }

  Future<List<Map<String, dynamic>>> fetchTrends({int limit = 200}) async {
    final uri = _buildUri("/trends", {'limit': '$limit'});
    final res = await http.get(uri);
    final map = _decode<Map<String, dynamic>>(res);
    final List tags = (map['tags'] ?? []) as List;
    return tags.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
