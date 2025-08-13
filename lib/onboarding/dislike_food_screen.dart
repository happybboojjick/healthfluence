// lib/onboarding/dislike_food_screen.dart
import 'package:flutter/material.dart';
import 'routine_interest_screen.dart';

class DislikeFoodScreen extends StatefulWidget {
  final List<String> allergies;
  const DislikeFoodScreen({super.key, required this.allergies});

  @override
  State<DislikeFoodScreen> createState() => _DislikeFoodScreenState();
}

class _DislikeFoodScreenState extends State<DislikeFoodScreen> {
  final List<String> foods = ["가지", "버섯", "생강", "고수"];
  final List<String> selectedFoods = [];

  void _toggle(String item) {
    setState(() {
      selectedFoods.contains(item) ? selectedFoods.remove(item) : selectedFoods.add(item);
    });
  }

  void _addDialog() {
    String val = "";
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("싫어하는 식재료 추가"),
        content: TextField(onChanged: (v) => val = v, autofocus: true),
        actions: [
          TextButton(
            onPressed: () {
              if (val.isNotEmpty) setState(() => foods.add(val));
              Navigator.pop(context);
            },
            child: const Text("추가"),
          ),
        ],
      ),
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
                    Text("싫어하는 식재료를 알려주세요.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                children: foods.map((f) {
                  final isSelected = selectedFoods.contains(f);
                  return ChoiceChip(label: Text(f), selected: isSelected, onSelected: (_) => _toggle(f));
                }).toList(),
              ),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _addDialog, child: const Text("+ 추가 입력")),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RoutineInterestScreen(
                          allergies: widget.allergies,
                          dislikes: selectedFoods,
                        ),
                      ),
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
