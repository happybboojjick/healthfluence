// lib/screens/explore_screen.dart
import 'package:flutter/material.dart';
import '../services/data_service.dart';
import 'routine_list_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _api = DataService();
  late Future<List<Map<String, dynamic>>> _trends;

  @override
  void initState() {
    super.initState();
    _trends = _api.fetchTrends(limit: 200);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _trends,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          }
          final tags = snapshot.data ?? [];
          if (tags.isEmpty) return const Center(child: Text("표시할 태그가 없습니다."));

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8, runSpacing: 8,
              children: tags.map((t) {
                return ActionChip(
                  label: Text('#${t['tag']} (${t['count']})'),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => RoutineListScreen(tag: t['tag'].toString()),
                    ));
                  },
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
