import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

// ------------------ 1. 회원가입 ------------------
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final email = TextEditingController();
  final pass = TextEditingController();
  bool loading = false;

  Future<void> _signUp() async {
    setState(() => loading = true);
    try {

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.text.trim(),
          password: pass.text.trim(),
        );
        user = cred.user;
      }

      if (user != null) {
     
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email,
          'onboardingDone': false,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AllergyScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? '회원가입 실패')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("회원가입")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 8),
            TextField(controller: pass, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loading ? null : _signUp,
              child: Text(loading ? '처리 중...' : '회원가입'),
            ),
            const SizedBox(height: 8),
          
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AllergyScreen()));
              },
              child: const Text('나중에 하기(건너뛰기)'),
            ),
          ],
        ),
      ),
    );
  }
}


// ------------------ 2. 알레르기 선택 ------------------
class AllergyScreen extends StatefulWidget {
  const AllergyScreen({super.key});

  @override
  State<AllergyScreen> createState() => _AllergyScreenState();
}

class _AllergyScreenState extends State<AllergyScreen> {
  final List<String> allergies = ["없음", "우유", "계란", "밀", "땅콩", "대두", "호두", "새우", "조개류"];
  final List<String> selected = [];

  void _toggleSelection(String item) {
    setState(() {
      selected.contains(item) ? selected.remove(item) : selected.add(item);
    });
  }

  void _showAddDialog() {
    String newItem = "";
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("알레르기 추가"),
          content: TextField(
            autofocus: true,
            onChanged: (value) => newItem = value,
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (newItem.isNotEmpty) {
                  setState(() {
                    allergies.add(newItem);
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("추가"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("HF", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              const Center(
                child: Column(
                  children: [
                    Text("당신의 알레르기를 알려주세요.",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text("추천 루틴에서 자동으로 제외됩니다.",
                        style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: allergies.map((allergy) {
                  final isSelected = selected.contains(allergy);
                  return ChoiceChip(
                    label: Text(allergy),
                    selected: isSelected,
                    onSelected: (_) => _toggleSelection(allergy),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: _showAddDialog,
                child: const Text("+ 추가 입력"),
              ),
              const Spacer(),
             Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton(
                onPressed: () async {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid != null) {
                    await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .set(
                      {'allergies': selected},
                      SetOptions(merge: true),
                      );
                      }
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DislikeFoodScreen()),
                        );
                        },
                        mini: true,
                        child: const Icon(Icons.arrow_forward),
                        ),
                        ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------ 3. 싫어하는 식재료 ------------------
class DislikeFoodScreen extends StatefulWidget {
  const DislikeFoodScreen({super.key});

  @override
  State<DislikeFoodScreen> createState() => _DislikeFoodScreenState();
}

class _DislikeFoodScreenState extends State<DislikeFoodScreen> {
  // 1. 초기 식재료 목록과 선택된 목록을 위한 상태 변수 선언
  final List<String> foods = ["가지", "버섯", "생강", "고수"];
  final List<String> selectedFoods = [];

  // 2. 선택/해제를 처리하는 함수
  void _toggleSelection(String item) {
    setState(() {
      selectedFoods.contains(item)
          ? selectedFoods.remove(item)
          : selectedFoods.add(item);
    });
  }

  // 3. '추가' 다이얼로그를 보여주는 함수
  void _showAddDialog() {
    String newItem = "";
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("싫어하는 식재료 추가"), // 제목 변경
          content: TextField(
            autofocus: true,
            onChanged: (value) => newItem = value,
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (newItem.isNotEmpty) {
                  setState(() {
                    foods.add(newItem); // 'foods' 리스트에 추가
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("추가"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 4. AllergyScreen과 동일한 UI 구조 사용
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("HF",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              const Center(
                child: Column(
                  children: [
                    Text("싫어하는 식재료를 알려주세요.", // 텍스트 변경
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text("추천 루틴에서 자동으로 제외됩니다.",
                        style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                // ElevatedButton 대신 ChoiceChip 사용
                children: foods.map((food) {
                  final isSelected = selectedFoods.contains(food);
                  return ChoiceChip(
                    label: Text(food),
                    selected: isSelected,
                    onSelected: (_) => _toggleSelection(food),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              // '+ 추가 입력' 버튼 추가
              OutlinedButton(
                onPressed: _showAddDialog,
                child: const Text("+ 추가 입력"),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  onPressed: () async {
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid != null) {
                      await FirebaseFirestore.instance.collection('users').doc(uid).set({
                        'dislikes': selectedFoods,
                        }, SetOptions(merge: true));
                       }
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RoutineScreen()),
                          );
                          },
                  mini: true,
                  child: const Icon(Icons.arrow_forward),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------ 4. 건강 루틴 ------------------
class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  // 1. 초기 루틴 목록과 선택된 목록을 위한 상태 변수 선언
  final List<String> routines = ["다이어트", "벌크업", "이너디톡스", "피부건강"];
  final List<String> selectedRoutines = [];

  // 2. 선택/해제를 처리하는 함수
  void _toggleSelection(String item) {
    setState(() {
      selectedRoutines.contains(item)
          ? selectedRoutines.remove(item)
          : selectedRoutines.add(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 3. 다른 화면과 유사한 UI 구조 적용
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("HF",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              const Center(
                child: Column(
                  children: [
                    Text("관심있는 건강 루틴을 선택해주세요.", // 텍스트 변경
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text("하나 이상 선택할 수 있습니다.",
                        style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                // ElevatedButton 대신 ChoiceChip으로 변경
                children: routines.map((routine) {
                  final isSelected = selectedRoutines.contains(routine);
                  return ChoiceChip(
                    label: Text(routine),
                    selected: isSelected,
                    onSelected: (_) => _toggleSelection(routine),
                  );
                }).toList(),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  onPressed: () async {
                    try {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid != null) {
                        await FirebaseFirestore.instance.collection('users').doc(uid).set({
                          'routines': selectedRoutines, 
                          'onboardingDone': true}, 
                          SetOptions(merge: true));
                        }
                        } catch (e) {

                          }
                          if (context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                              );
                              }
                              },
                  mini: true,
                  child: const Icon(Icons.arrow_forward),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------ 5. 네비게이션바 ------------------
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const CategoryScreen(), 
    const InfluencerScreen(),
    const LikesScreen(),
    const MyPageScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "홈"),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: "카테고리"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "인플루언서"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "찜"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "마이페이지"),
        ],
      ),
    );
  }
}

// ------------------ 홈 화면 ------------------
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      {"title": "오늘의 인기 루틴"},
      {"title": "트렌드 변화 / 인기 인플루언서"},
      {"title": "개인화 추천 루틴"},
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("HF", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...menuItems.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    minimumSize: const Size(double.infinity, 60),
                  ),
                  onPressed: () {},
                  child: Text(item["title"]!, style: const TextStyle(color: Colors.black)),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

// ------------------ 카테고리 화면 ------------------
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  // 1. 상태 관리 변수들
  int _selectedMainCategoryIndex = 0; // 선택된 메인 카테고리 인덱스

  // 2. 카테고리 데이터
  final List<String> _mainCategories = ["다이어트", "벌크업", "피부 건강", "이너 디톡스"];

  final Map<String, List<Map<String, String>>> _subCategories = {
    "다이어트": [
      {"name": "주스"},
      {"name": "스무디"},
      {"name": "스킨 루틴"},
      {"name": "클렌징"}
    ],
    "벌크업": [
      {"name": "단백질 쉐이크"},
      {"name": "에너지바"},
      {"name": "보충제"}
    ],
    "피부 건강": [
      {"name": "콜라겐 음료"},
      {"name": "비타민C"},
      {"name": "마스크팩"}
    ],
    "이너 디톡스": [
      {"name": "클렌즈 주스"},
      {"name": "디톡스 티"},
      {"name": "건강즙"}
    ],
  };

  @override
  Widget build(BuildContext context) {
    // 선택된 메인 카테고리에 해당하는 서브 카테고리 목록
    final currentSubCategories =
        _subCategories[_mainCategories[_selectedMainCategoryIndex]] ?? [];

    return SafeArea(
      child: Column(
        children: [
          // --- 상단 검색창 ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("HF",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    hintText: "검색창",
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // --- 메인 컨텐츠 (좌: 메인 카테고리, 우: 서브 카테고리) ---
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Section 1: 왼쪽 메인 카테고리 목록 ---
                SizedBox(
                  width: 100,
                  child: ListView.builder(
                    itemCount: _mainCategories.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedMainCategoryIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMainCategoryIndex = index;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.grey[100],
                            border: Border(
                              left: BorderSide(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 4,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _mainCategories[index],
                              style: TextStyle(
                                fontWeight:
                                    isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // --- Section 2: 오른쪽 서브 카테고리 그리드 ---
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      // map 함수 안의 Column을 GestureDetector로 감싸줍니다.
                      children: currentSubCategories.map((item) {
                        return GestureDetector( // <-- 1. GestureDetector 추가
                          onTap: () { // <-- 2. onTap 이벤트 추가
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                // 3. InfluencerScreen으로 이동하며 카테고리 이름 전달
                                builder: (context) => InfluencerListScreen(
                                  categoryName: item["name"]!,
                                ),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(item["name"]!),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------ 인플루언서 목록 선택 ------------------
class InfluencerListScreen extends StatefulWidget {
  final String categoryName;

  const InfluencerListScreen({super.key, required this.categoryName});

  @override
  State<InfluencerListScreen> createState() => _InfluencerListScreenState();
}

class _InfluencerListScreenState extends State<InfluencerListScreen> {
  final List<Map<String, dynamic>> _influencers = [
    {"id": "@yuri", "followers": "1.2M", "videos": 120, "height": 1.4},
    {"id": "@health_king", "followers": "890K", "videos": 88, "height": 1.7},
    {"id": "@diet.note", "followers": "2.5M", "videos": 250, "height": 1.6},
    {"id": "@muscle_man", "followers": "500K", "videos": 55, "height": 1.5},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: Text(
          "'${widget.categoryName}' 관련 인플루언서",
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: _influencers
                      .where((e) => _influencers.indexOf(e) % 2 == 0)
                      .map((e) => _buildInfluencerCard(e))
                      .toList(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: _influencers
                      .where((e) => _influencers.indexOf(e) % 2 != 0)
                      .map((e) => _buildInfluencerCard(e))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfluencerCard(Map<String, dynamic> influencerData) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InfluencerDetailPage(
                influencerId: influencerData["id"],
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            color: Colors.grey[200],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                          radius: 20, backgroundColor: Colors.grey),
                      const SizedBox(height: 8),
                      Text(influencerData["id"],
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                          "팔로워 ${influencerData["followers"]} | 영상 ${influencerData["videos"]}개",
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 4),
                      const Text("[루틴 보러가기]",
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              decoration: TextDecoration.underline)),
                    ],
                  ),
                ),
                Container(
                  height: influencerData["height"] * 80,
                  color: Colors.grey[300],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// ------------------ 인플루언서 상세 페이지 ------------------
class InfluencerDetailPage extends StatelessWidget {
  final String influencerId;

  const InfluencerDetailPage({super.key, required this.influencerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // AppBar의 기본 그림자 효과 제거
        elevation: 0,
        // 배경을 투명하게 해서 body와 이어지게 함
        backgroundColor: Colors.transparent,
        // 아이콘 색상 조절 (기본값은 보통 테마에 따라 흰색 또는 검은색)
        foregroundColor: Colors.black,
        // HF 타이틀
        title: const Text(
          "HF",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 섹션 1: 인플루언서 프로필 ---
              _buildProfileCard(),
              const SizedBox(height: 20),

              // --- 섹션 2: 루틴 상세 정보 ---
              _buildRoutineCard(),
              const SizedBox(height: 30),

              // --- 섹션 3: 찜하기 버튼 ---
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // 인플루언서 프로필 카드 위젯
  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '인플루언서 프로필 ($influencerId)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '팔로워 1.2M | 영상 120개',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          const Text(
            'TikTok 바로가기 링크',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  // 루틴 상세 정보 카드 위젯
  Widget _buildRoutineCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '루틴명: 피부 염증 완화 주스',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            '루틴 요약: 레몬 케일 염증 완화 주스',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          SizedBox(height: 16),
          Text(
            '영상 속 단계:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('1. 준비물: 레몬, 케일, 사과, 물'),
          SizedBox(height: 4),
          Text('2. 블렌더에 넣고 30초 → 바로 음용'),
          SizedBox(height: 4),
          Text('3. 주의: 아침 공복에 음용'),
          SizedBox(height: 16),
          Text(
            '팁: 영상 속 주스 비율 1:1:2',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // 찜하기 버튼 위젯
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            child: const Text('루틴 찜하기'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            child: const Text('인플루언서 찜하기'),
          ),
        ),
      ],
    );
  }
}

// ------------------ 인플루언서 탭 화면 ------------------
class InfluencerScreen extends StatelessWidget {
  const InfluencerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 샘플 데이터
    final List<Map<String, String>> influencers = [
      {"name": "이름 (A)", "likes": "1.8M", "field": "다이어트"},
      {"name": "이름 (B)", "likes": "1.5M", "field": "벌크업"},
      {"name": "이름 (C)", "likes": "1.2M", "field": "피부 건강"},
      {"name": "이름 (D)", "likes": "980K", "field": "이너 디톡스"},
      {"name": "이름 (E)", "likes": "750K", "field": "다이어트"},
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 상단 HF 타이틀 및 검색창 ---
            const Text("HF", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                hintText: "검색창",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- 인플루언서 목록 ---
            Expanded(
              child: ListView.separated(
                itemCount: influencers.length,
                // 각 아이템을 만드는 빌더
                itemBuilder: (context, index) {
                  final influencer = influencers[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InfluencerProfilePage(
                            influencerData: influencer,
                          ),
                        ),
                      );
                    },
                    // Row 위젯 안에 내용을 채워줍니다.
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(influencer["name"]!, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text("좋아요 수: ${influencer["likes"]}"),
                              const SizedBox(height: 4),
                              Text("분야: ${influencer["field"]}"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                // separatorBuilder는 itemBuilder와 같은 레벨에 위치해야 합니다.
                separatorBuilder: (context, index) => const SizedBox(height: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------ 인플루언서 프로필 상세 페이지 ------------------
class InfluencerProfilePage extends StatelessWidget {
  // 이전 화면에서 전달받은 인플루언서 데이터
  final Map<String, String> influencerData;

  const InfluencerProfilePage({super.key, required this.influencerData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(influencerData['name']!),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // --- 프로필 정보 섹션 ---
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              influencerData['name']!,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn("팔로잉", "150"),
                _buildStatColumn("팔로워", influencerData['likes'] ?? '0'),
                _buildStatColumn("좋아요", "3.2M"),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black,
                elevation: 0,
              ),
              child: const Text('인플루언서 찜'),
            ),
            const SizedBox(height: 20),
            const Divider(), // 구분선

            // --- 게시물 그리드 섹션 ---
            GridView.builder(
              // GridView를 스크롤 가능한 Column 내부에 넣을 때 필수 설정
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),

              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 3열
                crossAxisSpacing: 8, // 가로 간격
                mainAxisSpacing: 8, // 세로 간격
              ),
              itemCount: 9, // 게시물 갯수 (임시)
              itemBuilder: (context, index) {
                // 각 게시물 아이템을 GestureDetector로 감싸서 클릭 가능하게 만듭니다.
                return GestureDetector(
                  onTap: () {
                    // 새로운 RoutineDetailPage로 이동합니다.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RoutineDetailPage(),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 팔로워, 팔로잉 등을 표시하기 위한 작은 위젯
  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

// ------------------ 루틴 상세 페이지 ------------------
class RoutineDetailPage extends StatelessWidget {
  const RoutineDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: const Text(
          "HF",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            // Column이 전체 높이를 차지하지 않도록 크기 조절
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '루틴명: 피부 염증 완화 주스',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '루틴 요약: 레몬 케일 염증 완화 주스',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              SizedBox(height: 24),
              Text(
                '영상 속 단계:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('1. 준비물: 레몬, 케일, 사과, 물'),
              SizedBox(height: 8),
              Text('2. 블렌더에 넣고 30초 → 바로 음용'),
              SizedBox(height: 8),
              Text('3. 주의: 아침 공복에 음용'),
              SizedBox(height: 24),
              Text(
                '팁: 영상 속 주스 비율 1:1:2',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------ 찜하기 화면 ------------------
class LikesScreen extends StatefulWidget {
  const LikesScreen({super.key});

  @override
  State<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> {
  // 필터 상태 관리를 위한 변수
  final List<String> _filters = ["전체", "다이어트", "벌크업", "피부", "이너"];
  String _selectedFilter = "전체";

  @override
  Widget build(BuildContext context) {
    // 탭 컨트롤러를 사용하여 탭 상태를 관리합니다.
    return DefaultTabController(
      length: 2, // 탭 갯수 (루틴, 인플루언서)
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text("HF",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          // AppBar 아래에 탭 바를 추가합니다.
          bottom: const TabBar(
            tabs: [
              Tab(text: "루틴"),
              Tab(text: "인플루언서"),
            ],
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
          ),
        ),
        body: Column(
          children: [
            // --- 필터 칩 ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: SizedBox(
                height: 35,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = _selectedFilter == filter;
                    return ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        }
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: Colors.black,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                      shape: StadiumBorder(),
                      side: BorderSide(color: Colors.transparent),
                    );
                  },
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                ),
              ),
            ),
            // --- 탭 컨텐츠 ---
            Expanded(
              child: TabBarView(
                children: [
                  // "루틴" 탭에 표시될 컨텐츠
                  _buildRoutinesGrid(),
                  // "인플루언서" 탭에 표시될 컨텐츠 (임시)
                  _buildLikedInfluencersList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 찜한 루틴들을 보여주는 그리드 위젯
  Widget _buildRoutinesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2열
        crossAxisSpacing: 16, // 가로 간격
        mainAxisSpacing: 16, // 세로 간격
        childAspectRatio: 0.8, // 아이템의 가로세로 비율
      ),
      itemCount: 8, // 찜한 루틴 갯수 (임시)
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }
  // 찜한 인플루언서들을 보여주는 리스트 위젯
  Widget _buildLikedInfluencersList() {
    // 샘플 데이터 (실제로는 찜한 데이터만 가져와야 합니다)
    final List<Map<String, String>> likedInfluencers = [
      {"name": "이름 (A)", "likes": "1.8M", "field": "다이어트"},
      {"name": "이름 (B)", "likes": "1.5M", "field": "벌크업"},
      {"name": "이름 (C)", "likes": "1.2M", "field": "피부 건강"},
      {"name": "이름 (D)", "likes": "980K", "field": "이너 디톡스"},
      {"name": "이름 (E)", "likes": "750K", "field": "다이어트"},
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: likedInfluencers.length,
      itemBuilder: (context, index) {
        final influencer = likedInfluencers[index];
        return GestureDetector(
          onTap: () {
            // 인플루언서 상세 페이지로 이동합니다.
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InfluencerProfilePage(
                  influencerData: influencer,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  influencer["name"]!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 12),
    );
  }
}

// ------------------ 마이페이지 화면 ------------------
class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 상단 HF 타이틀 및 설정 아이콘 ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("HF",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () {
                    // 설정 페이지로 이동하는 로직 (나중에 구현)
                  },
                  icon: const Icon(Icons.settings, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- '마이페이지' 타이틀 ---
            const Text(
              "마이페이지",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // --- 프로필 섹션 ---
            InkWell(
              onTap: () {
                // 이 부분을 추가하여 ProfileEditScreen으로 이동합니다.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileEditScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey,
                      child: Text("프로필"),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        "사용자 ID",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------ 프로필 수정 화면 ------------------
class ProfileEditScreen extends StatelessWidget {
  const ProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 수정'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- 프로필 이미지 ---
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 60,
              backgroundColor: Color(0xFFD9D9D9), // 이미지와 비슷한 회색
            ),
            const SizedBox(height: 40),

            // --- 정보 입력 필드 ---
            _buildTextField(label: "닉네임"),
            const SizedBox(height: 16),
            _buildTextField(label: "휴대폰 번호"),
            const SizedBox(height: 16),
            _buildTextField(label: "생년월일"),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTextField(label: "키")),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(label: "몸무게")),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 반복되는 텍스트 필드 UI를 위한 헬퍼 메서드
  Widget _buildTextField({required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFD9D9D9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
