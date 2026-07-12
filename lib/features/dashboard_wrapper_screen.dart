import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:basera/core/routes_manger/routes.dart';
import 'package:basera/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:basera/features/auth/presentation/bloc/auth_state.dart';
import 'package:basera/features/child/presentation/pages/child_dashboard.dart';
import 'package:basera/features/parent/presentation/pages/parent_dashboard.dart';

/// Reacts to [AuthBloc] state so role switches are instant — no stale
/// SharedPreferences read via FutureBuilder.
class DashboardWrapperScreen extends StatelessWidget {
  const DashboardWrapperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // When user logs out from within a dashboard, redirect immediately
        if (state is Unauthenticated) {
          Navigator.pushReplacementNamed(context, Routes.signUpRoute);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            if (state.role == 'child') {
              return const ChildDashboard();
            } else {
              return const ParentDashboard();
            }
          }
          // Spinner while auth state resolves on startup
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
