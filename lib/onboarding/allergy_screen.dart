// lib/onboarding/allergy_screen.dart
import 'package:flutter/material.dart';
import 'dislike_food_screen.dart';

class AllergyScreen extends StatefulWidget {
  const AllergyScreen({super.key});

  @override
  State<AllergyScreen> createState() => _AllergyScreenState();
}

class _AllergyScreenState extends State<AllergyScreen> {
  final List<String> allergies = ["없음", "우유", "계란", "밀", "땅콩", "대두", "호두", "새우", "조개류"];
  final List<String> selected = [];

  void _toggle(String item) {
    setState(() {
      selected.contains(item) ? selected.remove(item) : selected.add(item);
    });
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
                    Text("당신의 알레르기를 알려주세요.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text("추천 루틴에서 자동으로 제외됩니다.", style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: allergies.map((a) {
                  final isSelected = selected.contains(a);
                  return ChoiceChip(
                    label: Text(a),
                    selected: isSelected,
                    onSelected: (_) => _toggle(a),
                  );
                }).toList(),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DislikeFoodScreen(allergies: selected)),
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
