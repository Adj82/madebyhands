import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';

class CreatorProfileView extends StatelessWidget {
  final CreatorProfile profile;
  const CreatorProfileView({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildProfileCard(),
          const SizedBox(height: 30),
          _buildActionItem(
            icon: Icons.edit_outlined,
            title: 'Edit Creator Profile',
            subtitle: 'Update bio, craft category, and links',
            onTap: () {},
          ),
          _buildActionItem(
            icon: Icons.collections_outlined,
            title: 'Manage Portfolio',
            subtitle: 'Add or remove showcase images',
            onTap: () {},
          ),
          _buildActionItem(
            icon: Icons.share_outlined,
            title: 'Share Storefront',
            subtitle: 'Let others discover your work',
            onTap: () {},
          ),
          _buildActionItem(
            icon: Icons.settings_outlined,
            title: 'Store Settings',
            subtitle: 'Payment and shipping preferences',
            onTap: () {},
          ),
          const SizedBox(height: 40),
          OutlinedButton.icon(
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Logout', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.outline,
            backgroundImage: profile.profileImage.isNotEmpty
                ? NetworkImage(profile.profileImage)
                : null,
            child: profile.profileImage.isEmpty
                ? const Icon(Icons.person, size: 50, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 15),
          Text(
            profile.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            profile.category,
            style: const TextStyle(color: AppColors.mutedText, fontSize: 14),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('Products', '0'),
              _buildStat('Rating', '5.0'),
              _buildStat('Join Date', 'Sep 2026'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }
}
