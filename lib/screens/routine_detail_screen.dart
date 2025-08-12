// lib/screens/routine_detail_screen.dart

import 'package:flutter/material.dart';
import '../models/influencer_routine.dart';
import '../services/data_service.dart';

class RoutineDetailScreen extends StatefulWidget {
  final String routineId;

  const RoutineDetailScreen({super.key, required this.routineId});

  @override
  State<RoutineDetailScreen> createState() => _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends State<RoutineDetailScreen> {
  final DataService _dataService = DataService();
  late Future<InfluencerRoutine?> _routineFuture;

  @override
  void initState() {
    super.initState();
    _routineFuture = _dataService.getRoutineById(widget.routineId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("루틴 상세정보")),
      body: FutureBuilder<InfluencerRoutine?>(
        future: _routineFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("루틴 정보를 불러올 수 없습니다."));
          }

          final routine = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(routine.profileImageUrl),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      routine.influencerName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  routine.routineTitle,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 32),
                Text(
                  routine.description,
                  style: const TextStyle(fontSize: 16, height: 1.5), // 이 부분이 완성되었습니다.
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}