import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'jobs_master_screen.dart'; // Import the JobsMasterScreen

class UserDashboardScreen extends StatelessWidget {
  const UserDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('User Info'),
                  content: Text(
                      'Email: ${user?.email ?? ''}\nUID: ${user?.uid ?? ''}'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: const JobsMasterScreen(isAdmin: false), // ✅ Embed JobsMasterScreen read-only
    );
  }
}
