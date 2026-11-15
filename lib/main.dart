import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'screens/admin/admin_home.dart';
import 'screens/customer/customer_home.dart';
import 'screens/role_select_screen.dart';
import 'screens/technician/technician_home.dart';
import 'models/user.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ServiceTrailApp());
}

class ServiceTrailApp extends StatelessWidget {
  const ServiceTrailApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => DataProvider()..loadAll()),
      ],
      child: MaterialApp(
        title: 'ServiceTrail',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E7D32),
            primary: const Color(0xFF2E7D32),
            secondary: const Color(0xFFFFB300),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF2E7D32),
            foregroundColor: Colors.white,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFFFFB300),
            foregroundColor: Colors.black87,
          ),
        ),
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final user = auth.currentUser;
    if (user == null) return const RoleSelectScreen();
    switch (user.role) {
      case UserRole.customer:
        return const CustomerHome();
      case UserRole.admin:
        return const AdminHome();
      case UserRole.technician:
        return const TechnicianHome();
    }
  }
}
