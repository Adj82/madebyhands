import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';

class ProfileTab extends StatelessWidget {
  final UserEntity user;
  final VoidCallback onOrders;
  final VoidCallback onAddresses;
  final VoidCallback onSupport;
  final VoidCallback onLogout;

  const ProfileTab({
    super.key,
    required this.user,
    required this.onOrders,
    required this.onAddresses,
    required this.onSupport,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final initial = user.name.trim().isEmpty
        ? 'B'
        : user.name.trim()[0].toUpperCase();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Text(
          'Your profile',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 22),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFDDE5CA),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
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
                const Icon(Icons.edit_outlined),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _ProfileTile(
          icon: Icons.receipt_long_outlined,
          title: 'My orders',
          subtitle: 'Track, return or buy again',
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
          subtitle: 'FAQs and contact options',
          onTap: onSupport,
        ),
        const _ProfileTile(
          icon: Icons.info_outline,
          title: 'About MadeByHands',
          subtitle: 'Our mission and artisan community',
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            final shouldLogout =
                await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Log out?'),
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
                        child: const Text('Log out'),
                      ),
                    ],
                  ),
                ) ??
                false;
            if (shouldLogout) onLogout();
          },
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
        ),
      ],
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
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap:
          onTap ??
          () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title screen is coming next.')),
          ),
    ),
  );
}
