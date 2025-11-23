import 'package:flutter/material.dart';

class SalaryView extends StatelessWidget {
  const SalaryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Salary')),
      body: const Center(
        child: Text(
          'Salary information will be displayed here.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
