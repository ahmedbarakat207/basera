import 'package:flutter/material.dart';
import 'package:basera/core/routes_manger/routes.dart';
import 'package:basera/features/auth/presentation/pages/sign_up_screen.dart';
import 'package:basera/features/auth/presentation/pages/sign_in_screen.dart';
import 'package:basera/features/dashboard_wrapper_screen.dart';

class RouteGenerator {
  static Route<dynamic> getRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.signUpRoute:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case Routes.signInRoute:
        return MaterialPageRoute(builder: (_) => const SignInScreen());
      case Routes.mainRoute:
        return MaterialPageRoute(builder: (_) => const DashboardWrapperScreen());
      default:
        return unDefinedRoute();
    }
  }

  static Route<dynamic> unDefinedRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('No Route Found')),
        body: const Center(child: Text('No Route Found')),
      ),
    );
  }
}
