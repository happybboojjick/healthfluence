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

// lib/screens/likes_screen.dart 파일의 _LikesContentState 클래스

class _LikesContentState extends State<_LikesContent> {
  final _user = UserService();
  final _api = DataService();

  // Future.wait를 사용해 여러 루틴 정보를 동시에 요청
  Future<List<InfluencerRoutine>> _fetchDetails(List<String> ids) {
    // DataService에 있는 함수 이름이 fetchRoutineDetail이라고 가정합니다.
    // 만약 다르다면 그에 맞게 수정해주세요. (예: getRoutineById)
    final futures = ids.map((id) => _api.fetchRoutineDetail(id)).toList();
    
    return Future.wait(futures)
        .then((routines) => routines.whereType<InfluencerRoutine>().toList());
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
            
            // 2열 그리드 UI 적용
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                return _buildRoutineCard(items[i]);
              },
            );
          },
        );
      },
    );
  }

  // 카드 UI를 만드는 함수
  Widget _buildRoutineCard(InfluencerRoutine routine) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RoutineDetailScreen(routineId: routine.id),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              // --- 수정된 부분 1 ---
              // profileImageUrl -> thumbnailUrl
              child: Image.network(
                routine.thumbnailUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.grey[200]),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // --- 수정된 부분 2 ---
          // routineTitle -> title
          Text(
            routine.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // --- 수정된 부분 3 ---
          // influencerName -> influencerId (또는 인플루언서 이름을 가져오는 다른 로직 필요)
          Text(
            routine.influencerId, 
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}