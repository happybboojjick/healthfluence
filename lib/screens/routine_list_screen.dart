// lib/screens/routine_list_screen.dart
import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../models/influencer_routine.dart';
import 'routine_detail_screen.dart';
import '../ui/ui_bundle.dart';

class RoutineListScreen extends StatefulWidget {
  final String? category;
  final String? tag;
  final String? influencerId;
  const RoutineListScreen({super.key, this.category, this.tag, this.influencerId});

  @override
  State<RoutineListScreen> createState() => _RoutineListScreenState();
}

class _RoutineListScreenState extends State<RoutineListScreen> {
  final _api = DataService();
  late Future<List<InfluencerRoutine>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchRoutines(
      category: widget.category,
      tag: widget.tag,
      influencerId: widget.influencerId,
      limit: 50,
      order: 'popular',
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.influencerId != null
        ? "인플루언서 루틴"
        : (widget.tag != null ? "#${widget.tag}" : (widget.category ?? "루틴"));

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<List<InfluencerRoutine>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('오류: ${snap.error}'));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) return const Center(child: Text('루틴이 없습니다.'));
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final r = items[i];
              return RoutineCard(
                routine: r,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RoutineDetailScreen(routineId: r.id)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
