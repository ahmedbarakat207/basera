import 'package:basera/core/routes_manger/route_generator.dart';
import 'package:basera/core/routes_manger/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:basera/core/utils/child_history_service.dart';
import 'package:basera/core/services/firebase_backend_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load local environment variables/secrets file
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Could not load .env file: $e. Fallback placeholder key will be used.');
  }

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e. Using local storage fallback.');
  }

  // Determine initial login status
  bool isLoggedIn = false;
  try {
    isLoggedIn = await ChildHistoryService.instance.getIsLoggedIn();
    if (FirebaseBackendService.instance.isFirebaseAvailable) {
      isLoggedIn = FirebaseBackendService.instance.currentUser != null;
    }
  } catch (_) {}

  runApp(BasseraApp(isLoggedIn: isLoggedIn));
}

class BasseraApp extends StatelessWidget {
  final bool isLoggedIn;
  const BasseraApp({super.key, this.isLoggedIn = false});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: child,
        onGenerateRoute: RouteGenerator.getRoute,
        initialRoute: isLoggedIn ? Routes.mainRoute : Routes.signUpRoute,
      ),
    );
  }
}
