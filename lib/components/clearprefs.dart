import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClearPrefsTile extends StatelessWidget {
  const ClearPrefsTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text("Clear history & data"),
      onTap: () {
        _clearAllPreferences(context);
      },
    );
  }

  void _clearAllPreferences(context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("History & data cleared"),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint("Error clearing preferences: $e");
    }
  }
}
