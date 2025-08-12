// lib/services/data_service.dart

import '../models/category.dart';
import '../models/influencer_routine.dart';

class DataService {
  // --- 가짜 데이터베이스 ---

  final List<Category> _categories = [
    Category(id: 'diet', name: '다이어트', subCategories: [SubCategory(id: 'juice', name: '주스'), SubCategory(id: 'salad', name: '샐러드')]),
    Category(id: 'bulk_up', name: '벌크업', subCategories: [SubCategory(id: 'protein', name: '고단백'), SubCategory(id: 'supplements', name: '보충제')]),
    Category(id: 'skin', name: '피부건강', subCategories: [SubCategory(id: 'collagen', name: '콜라겐'), SubCategory(id: 'vitamins', name: '비타민')]),
    Category(id: 'detox', name: '이너디톡스', subCategories: [SubCategory(id: 'tea', name: '차'), SubCategory(id: 'cleanse', name: '클렌즈')]),
  ];

  // 모든 인플루언서 루틴 정보
  // 수정된 점: 각 루틴에 subCategoryId를 추가하여 소속을 명확히 함
  final List<InfluencerRoutine> _allRoutines = [
    InfluencerRoutine(id: 'r1', influencerName: '제인', profileImageUrl: 'https://picsum.photos/id/237/100', routineTitle: '아침 ABC 주스 루틴', description: '매일 아침 사과, 비트, 당근으로...', subCategoryId: 'juice'),
    InfluencerRoutine(id: 'r2', influencerName: '핏블리', profileImageUrl: 'https://picsum.photos/id/238/100', routineTitle: '운동 후 클렌즈 주스', description: '운동 효과를 극대화하는...', subCategoryId: 'juice'),
    InfluencerRoutine(id: 'r3', influencerName: '안젤라', profileImageUrl: 'https://picsum.photos/id/239/100', routineTitle: '저칼로리 닭가슴살 샐러드', description: '맛있고 배부른 다이어트 샐러드', subCategoryId: 'salad'),
    InfluencerRoutine(id: 'r4', influencerName: '김계란', profileImageUrl: 'https://picsum.photos/id/240/100', routineTitle: '벌크업을 위한 소고기 식단', description: '근성장에 필수적인...', subCategoryId: 'protein'),
    InfluencerRoutine(id: 'r5', influencerName: '닥터프렌즈', profileImageUrl: 'https://picsum.photos/id/241/100', routineTitle: '피부를 위한 비타민C 섭취', description: '매일 비타민C로 환한 피부를...', subCategoryId: 'vitamins'),
  ];

  // --- 데이터 제공 함수 ---

  Future<List<Category>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _categories;
  }

  // 수정된 점: if/else 대신 동적인 필터링으로 변경
  Future<List<InfluencerRoutine>> getRoutinesForSubCategory(String subCategoryId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // 전체 루틴 목록에서 subCategoryId가 일치하는 것만 찾아서 반환
    return _allRoutines.where((routine) => routine.subCategoryId == subCategoryId).toList();
  }

  // 추가된 점: ID로 특정 루틴 하나의 정보를 반환하는 함수
  Future<InfluencerRoutine?> getRoutineById(String routineId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _allRoutines.firstWhere((routine) => routine.id == routineId);
    } catch (e) {
      return null; // ID에 해당하는 루틴이 없을 경우 null 반환
    }
  }
}