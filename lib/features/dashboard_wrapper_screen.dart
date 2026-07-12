import 'package:flutter/material.dart';
import 'package:basera/core/utils/child_history_service.dart';
import 'package:basera/features/child/presentation/pages/child_dashboard.dart';
import 'package:basera/features/parent/presentation/pages/parent_dashboard.dart';

class DashboardWrapperScreen extends StatelessWidget {
  const DashboardWrapperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: ChildHistoryService.instance.getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        final role = snapshot.data ?? 'parent';
        if (role == 'child') {
          return const ChildDashboard();
        } else {
          return const ParentDashboard();
        }
      },
    );
  }
}
