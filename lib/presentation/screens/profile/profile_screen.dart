import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../auth/login_screen.dart';
import '../ticket/my_tickets_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().loadLoyaltyWallet();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final bookingProvider = context.watch<BookingProvider>();
    final user = authProvider.currentUser;
    final wallet = bookingProvider.loyaltyWallet;

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
                    backgroundImage: user.avatarUrl != null
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null
                        ? const Icon(Icons.person,
                            size: 50, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.fullName,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.email,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  ListTile(
                    leading: const Icon(Icons.confirmation_number,
                        color: AppColors.primary),
                    title: const Text('My Tickets'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyTicketsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.star, color: Colors.amber),
                    title: const Text('Loyalty Points'),
                    subtitle: const Text('Available for checkout discounts'),
                    trailing: Text(
                      '${wallet?.points ?? user.loyaltyPoints} pts',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (wallet != null && wallet.transactions.isNotEmpty)
                    _PointHistory(provider: bookingProvider),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.error),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: AppColors.error),
                    ),
                    onTap: () {
                      authProvider.logout();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class _PointHistory extends StatelessWidget {
  const _PointHistory({required this.provider});

  final BookingProvider provider;

  @override
  Widget build(BuildContext context) {
    final transactions = provider.loyaltyWallet!.transactions.take(5).toList();
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent point history',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...transactions.map((transaction) {
            final isPositive = transaction.points >= 0;
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                transaction.description.isEmpty
                    ? transaction.type
                    : transaction.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text('Balance ${transaction.balanceAfter} pts'),
              trailing: Text(
                '${isPositive ? '+' : ''}${transaction.points}',
                style: TextStyle(
                  color: isPositive ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
