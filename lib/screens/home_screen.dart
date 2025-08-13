// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../models/influencer_routine.dart';
import 'routine_detail_screen.dart';
import '../ui/ui_bundle.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = DataService();
  late Future<List<InfluencerRoutine>> _popular;

  @override
  void initState() {
    super.initState();
    _popular = _api.fetchRoutines(limit: 20, order: 'popular');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('오늘의 인기 루틴', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          FutureBuilder<List<InfluencerRoutine>>(
            future: _popular,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ));
              }
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('에러: ${snap.error}'),
                );
              }
              final items = snap.data ?? [];
              return Column(
                children: items.map((r) => RoutineCard(
                  routine: r,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => RoutineDetailScreen(routineId: r.id)));
                  },
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
