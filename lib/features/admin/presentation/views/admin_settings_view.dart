import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:madebyhands/features/admin/presentation/pages/details/api_config_page.dart';
import 'package:madebyhands/features/admin/presentation/pages/details/admin_management_page.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';

class AdminSettingsView extends StatefulWidget {
  const AdminSettingsView({super.key});

  @override
  State<AdminSettingsView> createState() => _AdminSettingsViewState();
}

class _AdminSettingsViewState extends State<AdminSettingsView> {
  bool _maintenanceMode = false;
  bool _emailNotifications = true;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final currentUser = authState is AuthSuccess ? authState.user : null;
    final isSuperAdmin = currentUser?.isSuperAdmin ?? true;

    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const _SettingsSection(title: 'Platform Economics'),
            _buildConfigTile(
              'Flat Platform Fee',
              'Currently ₹${state.flatFee} charged per sale',
              Icons.payments_outlined,
              trailing: TextButton(
                onPressed: () => _showUpdateFeeDialog(context, true, isSuperAdmin),
                child: Text(isSuperAdmin ? 'Change' : 'Locked 🔒'),
              ),
            ),
            _buildConfigTile(
              'Transaction Fee (%)',
              'Currently ${state.percentFee}% for orders > ₹999',
              Icons.percent,
              trailing: TextButton(
                onPressed: () => _showUpdateFeeDialog(context, false, isSuperAdmin),
                child: Text(isSuperAdmin ? 'Change' : 'Locked 🔒'),
              ),
            ),
            const SizedBox(height: 20),
            const _SettingsSection(title: 'System Control'),
            SwitchListTile(
              title: const Text('Maintenance Mode', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Block all user access while performing updates'),
              value: _maintenanceMode,
              activeTrackColor: AppColors.primary,
              onChanged: isSuperAdmin
                  ? (val) => setState(() => _maintenanceMode = val)
                  : (val) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Only Super Admins can toggle maintenance mode.')),
                      );
                    },
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
              'Authorized Admins & Roles',
              'Manage Super Admin & Manager access',
              Icons.admin_panel_settings_outlined,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminManagementPage())),
              trailing: const Icon(Icons.chevron_right),
            ),
            _buildConfigTile(
              'API Configuration',
              'Manage Firebase & Google keys',
              Icons.key_outlined,
              onTap: () {
                if (!isSuperAdmin) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('API Configuration requires Super Admin access.')),
                  );
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ApiConfigPage()));
                }
              },
              trailing: Icon(isSuperAdmin ? Icons.chevron_right : Icons.lock_outline, size: 20),
            ),
            const SizedBox(height: 40),
            FilledButton(
              onPressed: () {
                if (!isSuperAdmin) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Access Restricted: Operational Managers cannot modify global settings.')),
                  );
                  return;
                }
                context.read<AdminBloc>().add(AdminUpdateSettingsRequested(
                  flatFee: state.flatFee,
                  percentFee: state.percentFee,
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings saved successfully')),
                );
              },
              child: const Text('Save Global Changes'),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateFeeDialog(BuildContext context, bool isFlat, bool isSuperAdmin) {
    if (!isSuperAdmin) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.orange),
              SizedBox(width: 8),
              Text('Access Restricted'),
            ],
          ),
          content: const Text(
            'Operational Managers cannot update platform fee parameters.\n\nOnly Super Admins have permission to modify platform economics.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final controller = TextEditingController();
    final adminBloc = context.read<AdminBloc>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isFlat ? 'Update Flat Fee' : 'Update Percentage Fee'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: isFlat ? 'Enter amount (₹)' : 'Enter percentage (%)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) {
                adminBloc.add(AdminUpdateSettingsRequested(
                  flatFee: isFlat ? val : adminBloc.state.flatFee,
                  percentFee: isFlat ? adminBloc.state.percentFee : val,
                ));
                Navigator.pop(context);
              }
            }, 
            child: const Text('Update')
          ),
        ],
      ),
    );
  }

  Widget _buildConfigTile(String title, String subtitle, IconData icon, {Widget? trailing, VoidCallback? onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
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
