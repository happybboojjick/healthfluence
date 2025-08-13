// lib/screens/likes_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../services/data_service.dart';
import '../models/influencer_routine.dart';
import 'routine_detail_screen.dart';

class LikesScreen extends StatelessWidget {
  const LikesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('로그인을 해주세요.'));
    }
    return _LikesContent(uid: uid);
  }
}

class _LikesContent extends StatefulWidget {
  final String uid;
  const _LikesContent({required this.uid});

  @override
  State<_LikesContent> createState() => _LikesContentState();
}

class _LikesContentState extends State<_LikesContent> {
  final _user = UserService();
  final _api = DataService();

  Future<List<InfluencerRoutine>> _fetchDetails(List<String> ids) async {
    final results = <InfluencerRoutine>[];
    for (final id in ids) {
      try {
        final r = await _api.fetchRoutineDetail(id);
        results.add(r);
      } catch (_) {}
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: _user.favoriteRoutineIds(widget.uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final ids = snap.data ?? [];
        if (ids.isEmpty) return const Center(child: Text('찜한 루틴이 없습니다.'));

        return FutureBuilder<List<InfluencerRoutine>>(
          future: _fetchDetails(ids),
          builder: (context, s2) {
            if (s2.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = s2.data ?? [];
            if (items.isEmpty) return const Center(child: Text('표시할 루틴이 없습니다.'));
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) {
                final r = items[i];
                return ListTile(
                  leading: r.thumbnailUrl.isNotEmpty
                      ? Image.network(r.thumbnailUrl, width: 60, height: 60, fit: BoxFit.cover)
                      : const Icon(Icons.local_drink),
                  title: Text(r.title),
                  subtitle: Text(r.categories),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => RoutineDetailScreen(routineId: r.id)));
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
