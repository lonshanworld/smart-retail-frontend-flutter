import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StaffSalaryView extends StatelessWidget {
  const StaffSalaryView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Salary'),
      ),
      body: const Center(
        child: Text('Staff Salary Page'),
      ),
    );
  }
}
