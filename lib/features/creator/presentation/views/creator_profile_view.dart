import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';

class CreatorProfileView extends StatefulWidget {
  final CreatorProfile profile;
  const CreatorProfileView({super.key, required this.profile});

  @override
  State<CreatorProfileView> createState() => _CreatorProfileViewState();
}

class _CreatorProfileViewState extends State<CreatorProfileView> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      final bloc = context.read<CreatorBloc>();
      bloc.add(CreatorCheckProfileExists(widget.profile.uid));
      bloc.add(CreatorFetchCreatorProducts(widget.profile.uid));
      bloc.add(CreatorFetchOrders(widget.profile.uid));
      await Future.delayed(const Duration(milliseconds: 600));
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
            backgroundImage: widget.profile.profileImage.isNotEmpty
                ? NetworkImage(widget.profile.profileImage)
                : null,
            child: widget.profile.profileImage.isEmpty
                ? const Icon(Icons.person, size: 50, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 15),
          Text(
            widget.profile.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            widget.profile.category,
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
