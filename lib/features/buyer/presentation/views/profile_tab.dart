import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/buyer/presentation/pages/about_madebyhands_page.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_background.dart';

class ProfileTab extends StatelessWidget {
  final UserEntity user;
  final VoidCallback onOrders;
  final VoidCallback onAddresses;
  final VoidCallback onSupport;
  final VoidCallback onAccount;
  final VoidCallback onLogout;

  const ProfileTab({
    super.key,
    required this.user,
    required this.onOrders,
    required this.onAddresses,
    required this.onSupport,
    required this.onAccount,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final initial = user.name.trim().isEmpty
        ? 'B'
        : user.name.trim()[0].toUpperCase();

    return BuyerBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Text(
            'Your profile',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF8B261D),
                ),
          ),
          const SizedBox(height: 22),
          Card(
            elevation: 1,
            color: const Color(0xFFFAF6EE).withValues(alpha: 0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(
                color: Color(0xFF8B261D),
                width: 1.0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFFF2DEDD),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF8B261D),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name.isEmpty ? 'Buyer' : user.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF8B261D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: const TextStyle(color: AppColors.mutedText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _ProfileTile(
            icon: Icons.manage_accounts_outlined,
            title: 'Account settings',
            subtitle: 'Update your name, phone or delete your account',
            onTap: onAccount,
          ),
          _ProfileTile(
            icon: Icons.receipt_long_outlined,
            title: 'My orders',
            subtitle: 'Track your orders and refunds',
            onTap: onOrders,
          ),
          _ProfileTile(
            icon: Icons.location_on_outlined,
            title: 'Saved addresses',
            subtitle: 'Manage delivery locations',
            onTap: onAddresses,
          ),
          _ProfileTile(
            icon: Icons.support_agent_outlined,
            title: 'Help & support',
            subtitle: 'Raise a ticket and chat with our team',
            onTap: onSupport,
          ),
          _ProfileTile(
            icon: Icons.info_outline,
            title: 'About MadeByHands',
            subtitle: 'Our mission, terms & privacy policy',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AboutMadeByHandsPage(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final shouldLogout =
                  await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      backgroundColor: const Color(0xFFFAF6EE),
                      title: const Text(
                        'Log out?',
                        style: TextStyle(color: Color(0xFF8B261D)),
                      ),
                      content: const Text(
                        'You can sign back in with your Google account.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF8B261D),
                          ),
                          child: const Text('Log out'),
                        ),
                      ],
                    ),
                  ) ??
                  false;
              if (shouldLogout) onLogout();
            },
            icon: const Icon(Icons.logout, color: Color(0xFF8B261D)),
            label: const Text(
              'Log out',
              style: TextStyle(color: Color(0xFF8B261D)),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF8B261D)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        color: const Color(0xFFFAF6EE).withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFF8B261D).withValues(alpha: 0.3),
          ),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          leading: Icon(icon, color: const Color(0xFF8B261D)),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF8B261D),
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: AppColors.mutedText),
          ),
          trailing: const Icon(Icons.chevron_right, color: Color(0xFF8B261D)),
          onTap: onTap,
        ),
      );
}
