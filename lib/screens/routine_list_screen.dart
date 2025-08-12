import 'package:flutter/material.dart';
import '../models/influencer_routine.dart';
import '../services/data_service.dart';
import 'routine_detail_screen.dart';

class RoutineListScreen extends StatefulWidget {
  final String subCategoryId;
  final String subCategoryName;

  const RoutineListScreen({
    super.key,
    required this.subCategoryId,
    required this.subCategoryName,
  });

  @override
  State<RoutineListScreen> createState() => _RoutineListScreenState();
}

class _RoutineListScreenState extends State<RoutineListScreen> {
  final DataService _dataService = DataService();
  late Future<List<InfluencerRoutine>> _routinesFuture;

  @override
  void initState() {
    super.initState();
    _routinesFuture = _dataService.getRoutinesForSubCategory(widget.subCategoryId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.subCategoryName)),
      body: FutureBuilder<List<InfluencerRoutine>>(
        future: _routinesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("오류가 발생했습니다: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("${widget.subCategoryName} 관련 루틴이 없습니다."));
          }

          final routines = snapshot.data!;
          return ListView.builder(
            itemCount: routines.length,
            itemBuilder: (context, index) {
              final routine = routines[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(routine.profileImageUrl),
                  ),
                  title: Text(routine.routineTitle),
                  subtitle: Text(routine.influencerName),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoutineDetailScreen(routineId: routine.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}