// lib/onboarding/routine_interest_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../screens/main_navigation_screen.dart';

class RoutineInterestScreen extends StatefulWidget {
  final List<String> allergies;
  final List<String> dislikes;
  const RoutineInterestScreen({super.key, required this.allergies, required this.dislikes});

  @override
  State<RoutineInterestScreen> createState() => _RoutineInterestScreenState();
}

class _RoutineInterestScreenState extends State<RoutineInterestScreen> {
  final List<String> routines = ["다이어트", "벌크업", "이너디톡스", "피부건강"];
  final List<String> selected = [];

  void _toggle(String item) {
    setState(() {
      selected.contains(item) ? selected.remove(item) : selected.add(item);
    });
  }

  Future<void> _complete() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await UserService().saveOnboarding(
      uid: uid,
      allergies: widget.allergies,
      dislikes: widget.dislikes,
      interests: selected,
    );
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
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
                    Text("관심있는 건강 루틴을 선택해주세요.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text("하나 이상 선택할 수 있습니다.", style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: routines.map((r) {
                  final isSelected = selected.contains(r);
                  return ChoiceChip(label: Text(r), selected: isSelected, onSelected: (_) => _toggle(r));
                }).toList(),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  onPressed: _complete,
                  mini: true,
                  child: const Icon(Icons.check),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
