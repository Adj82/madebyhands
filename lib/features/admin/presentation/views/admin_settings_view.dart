import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';

class AdminSettingsView extends StatefulWidget {
  const AdminSettingsView({super.key});

  @override
  State<AdminSettingsView> createState() => _AdminSettingsViewState();
}

class _AdminSettingsViewState extends State<AdminSettingsView> {
  bool _maintenanceMode = false;
  bool _emailNotifications = true;
  final double _flatFee = 50.0;
  final double _percentFee = 5.0;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _SettingsSection(title: 'Platform Economics'),
        _buildConfigTile(
          'Flat Platform Fee',
          'Currently ₹$_flatFee charged per sale',
          Icons.payments_outlined,
          trailing: TextButton(onPressed: () {}, child: const Text('Change')),
        ),
        _buildConfigTile(
          'Transaction Fee (%)',
          'Currently $_percentFee% for orders > ₹999',
          Icons.percent,
          trailing: TextButton(onPressed: () {}, child: const Text('Change')),
        ),
        const SizedBox(height: 20),
        const _SettingsSection(title: 'System Control'),
        SwitchListTile(
          title: const Text('Maintenance Mode', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Block all user access while performing updates'),
          value: _maintenanceMode,
          activeTrackColor: AppColors.primary,
          onChanged: (val) => setState(() => _maintenanceMode = val),
        ),
        SwitchListTile(
          title: const Text('Admin Email Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Get notified about new creator applications'),
          value: _emailNotifications,
          activeTrackColor: AppColors.primary,
          onChanged: (val) => setState(() => _emailNotifications = val),
        ),
        const SizedBox(height: 20),
        const _SettingsSection(title: 'Security'),
        _buildConfigTile(
          'Authorized Admins',
          '1 active admin account',
          Icons.admin_panel_settings_outlined,
          trailing: const Icon(Icons.chevron_right),
        ),
        _buildConfigTile(
          'API Configuration',
          'Manage Firebase & Google keys',
          Icons.key_outlined,
          trailing: const Icon(Icons.chevron_right),
        ),
        const SizedBox(height: 40),
        FilledButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings saved successfully')),
          ),
          child: const Text('Save Global Changes'),
        ),
      ],
    );
  }

  Widget _buildConfigTile(String title, String subtitle, IconData icon, {Widget? trailing}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: trailing,
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  const _SettingsSection({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(title.toUpperCase(),
          style: const TextStyle(
              color: AppColors.mutedText, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
    );
  }
}
