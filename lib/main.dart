import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/customer/customer_home.dart';
import 'screens/rider/rider_home.dart';
import 'screens/admin/admin_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const RyanivaApp());
}

class RyanivaApp extends StatelessWidget {
  const RyanivaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadFromStorage()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: MaterialApp(
        title: 'Ryaniva',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1A3A8F),
            primary: const Color(0xFF1A3A8F),
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
        ),
        home: const AppRouter(),
      ),
    );
  }
}

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A3A8F),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'RYANIVA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'BUSINESS SERVICES',
                style: TextStyle(
                  color: Color(0xFFE85C1A),
                  fontSize: 12,
                  letterSpacing: 3,
                ),
              ),
              SizedBox(height: 40),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      );
    }

    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) return const WelcomeScreen();

    switch (auth.user?.role) {
      case 'CUSTOMER':
        return const CustomerHome();
      case 'RIDER':
        return const RiderHome();
      case 'ADMIN':
        return const AdminHome();
      default:
        return const WelcomeScreen();
    }
  }
}