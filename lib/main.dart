import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/jobs_master_screen.dart';
import 'screens/user_dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Offset ERP',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthWrapper(),
    );
  }
}

/// Check if user is logged in
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Not logged in
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // Logged in → check role
        return RoleChecker(user: snapshot.data!);
      },
    );
  }
}

/// Fetch role from Firestore and navigate accordingly
class RoleChecker extends StatelessWidget {
  final User user;
  const RoleChecker({super.key, required this.user});

  Future<String> getUserRole() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return doc.data()?['role'] ?? 'user';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getUserRole(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        if (snapshot.data == 'admin') {
          return const AdminDashboard();
        } else {
          return const UserDashboardScreen();
        }
      },
    );
  }
}
