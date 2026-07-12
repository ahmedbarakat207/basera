import 'package:basera/core/routes_manger/route_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:basera/core/utils/child_history_service.dart';
import 'package:basera/core/services/firebase_backend_service.dart';
import 'package:basera/core/services/basera_database.dart';
import 'package:basera/core/services/sync_service.dart';
import 'package:basera/core/services/firebase_messaging_service.dart';
import 'package:basera/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:basera/features/auth/presentation/bloc/auth_event.dart';
import 'package:basera/features/child/presentation/bloc/child_bloc.dart';
import 'package:basera/features/parent/presentation/bloc/parent_bloc.dart';
import 'package:basera/features/auth/presentation/pages/sign_up_screen.dart';
import 'package:basera/features/dashboard_wrapper_screen.dart';
import 'package:basera/core/resources/theme_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite Database
  try {
    await BaseraDatabase.instance.database;
  } catch (e) {
    debugPrint('SQLite database initialization failed: $e');
  }

  // Start background connection monitoring & sync service
  SyncService.instance.startListening();
  
  // Load local environment variables/secrets file
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Could not load .env file: $e. Fallback placeholder key will be used.');
  }

  try {
    await Firebase.initializeApp();
    await FirebaseMessagingService.instance.init();
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
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc()..add(AuthCheckRequested()),
        ),
        BlocProvider<ChildBloc>(
          create: (context) => ChildBloc(),
        ),
        BlocProvider<ParentBloc>(
          create: (context) => ParentBloc(),
        ),
        BlocProvider<ThemeCubit>(
          create: (context) => ThemeCubit(),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(430, 932),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => BlocBuilder<ThemeCubit, bool>(
          builder: (context, isDark) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                brightness: isDark ? Brightness.dark : Brightness.light,
                scaffoldBackgroundColor: isDark ? const Color(0xFF121214) : const Color(0xFFF8FAFC),
                primaryColor: const Color(0xFF6366F1),
                cardColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
              ),
              home: isLoggedIn ? const DashboardWrapperScreen() : const SignUpScreen(),
              onGenerateRoute: RouteGenerator.getRoute,
            );
          },
        ),
      ),
    );
  }
}
