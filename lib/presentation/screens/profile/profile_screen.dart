import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../ticket/my_tickets_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary,
                    backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                    child: user.avatarUrl == null ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
                  ),
                  const SizedBox(height: 16),
                  Text(user.fullName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(user.email, style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 32),
                  
                  // Menu Items
                  ListTile(
                    leading: const Icon(Icons.confirmation_number, color: AppColors.primary),
                    title: const Text('My Tickets'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const MyTicketsScreen()));
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.star, color: Colors.amber),
                    title: const Text('Loyalty Points'),
                    trailing: Text('${user.loyaltyPoints} pts', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.error),
                    title: const Text('Logout', style: TextStyle(color: AppColors.error)),
                    onTap: () {
                      // Call logout and navigate back to login
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
