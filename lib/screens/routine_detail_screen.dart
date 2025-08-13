// lib/screens/routine_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/data_service.dart';
import '../services/user_service.dart';
import '../models/influencer_routine.dart';

class RoutineDetailScreen extends StatefulWidget {
  final String routineId;
  const RoutineDetailScreen({super.key, required this.routineId});

  @override
  State<RoutineDetailScreen> createState() => _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends State<RoutineDetailScreen> {
  final _api = DataService();
  late Future<InfluencerRoutine> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchRoutineDetail(widget.routineId);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('루틴 상세')),
      body: FutureBuilder<InfluencerRoutine>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('오류: ${snap.error}'));
          }
          final r = snap.data;
          if (r == null) return const SizedBox.shrink();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(r.categories),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(label: Text('시간 ${r.timeMin}분')),
                    Chip(label: Text('난이도 ${r.difficulty}')),
                    if (r.provider.isNotEmpty) Chip(label: Text(r.provider)),
                  ],
                ),
                const SizedBox(height: 16),
                if (r.tags.isNotEmpty)
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: r.tags.map((t) => Chip(label: Text('#$t'))).toList(),
                  ),
                const SizedBox(height: 16),
                Text('구성 요소', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (r.elements.isEmpty) const Text('요소 정보가 없습니다.'),
                ...r.elements.map((e) {
                  final parts = <String>[];
                  if (e.qty > 0) parts.add(e.qty.toString());
                  if (e.unit.isNotEmpty) parts.add(e.unit);
                  if (e.note.isNotEmpty) parts.add('- ${e.note}');
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(e.name.isNotEmpty ? e.name : '이름 미지정'),
                    subtitle: parts.isEmpty ? null : Text(parts.join(' ')),
                  );
                }),
                const SizedBox(height: 24),
                if (uid != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await UserService().toggleFavoriteRoutine(uid, r.id, true);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('찜에 추가됨')));
                      },
                      icon: const Icon(Icons.favorite),
                      label: const Text('찜하기'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
