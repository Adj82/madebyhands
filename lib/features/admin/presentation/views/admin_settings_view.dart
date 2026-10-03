import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:madebyhands/features/admin/presentation/pages/details/admin_management_page.dart';
import 'package:madebyhands/features/admin/presentation/pages/details/api_config_page.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';

class AdminSettingsView extends StatelessWidget {
  const AdminSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = context.select<AuthBloc, bool>((bloc) {
      final state = bloc.state;
      return state is AuthSuccess && state.user.isSuperAdmin;
    });

    return BlocBuilder<AdminBloc, AdminState>(
      buildWhen: (previous, current) =>
          previous.flatFee != current.flatFee ||
          previous.percentFee != current.percentFee ||
          previous.commissionThreshold != current.commissionThreshold,
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const _SettingsSection(title: 'Platform economics'),
            _ConfigTile(
              title: 'Flat platform fee',
              subtitle: '₹${state.flatFee.round()} added per creator in each checkout',
              icon: Icons.payments_outlined,
              trailing: isSuperAdmin
                  ? TextButton(
                      onPressed: () =>
                          _showUpdateFeeDialog(context, field: _FeeField.flat),
                      child: const Text('Change'),
                    )
                  : const Icon(Icons.lock_outline, size: 20),
            ),
            _ConfigTile(
              title: 'Commission',
              subtitle:
                  '${_formatPercent(state.percentFee)}% of the creator subtotal on orders above ₹${state.commissionThreshold.round()}',
              icon: Icons.percent,
              trailing: isSuperAdmin
                  ? TextButton(
                      onPressed: () =>
                          _showUpdateFeeDialog(context, field: _FeeField.percent),
                      child: const Text('Change'),
                    )
                  : const Icon(Icons.lock_outline, size: 20),
            ),
            _ConfigTile(
              title: 'Commission threshold',
              subtitle:
                  'Commission only applies when the creator subtotal is above ₹${state.commissionThreshold.round()}',
              icon: Icons.trending_up,
              trailing: isSuperAdmin
                  ? TextButton(
                      onPressed: () => _showUpdateFeeDialog(
                        context,
                        field: _FeeField.threshold,
                      ),
                      child: const Text('Change'),
                    )
                  : const Icon(Icons.lock_outline, size: 20),
            ),
            if (!isSuperAdmin)
              const Padding(
                padding: EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  'Only super admins can change platform fees.',
                  style: TextStyle(fontSize: 12, color: AppColors.mutedText),
                ),
              ),
            const SizedBox(height: 20),
            const _SettingsSection(title: 'Access'),
            _ConfigTile(
              title: 'Admins & managers',
              subtitle: 'See who has admin access',
              icon: Icons.admin_panel_settings_outlined,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminManagementPage()),
              ),
            ),
            _ConfigTile(
              title: 'API configuration',
              subtitle: 'Firebase & Google keys',
              icon: Icons.key_outlined,
              trailing: Icon(
                isSuperAdmin ? Icons.chevron_right : Icons.lock_outline,
                size: isSuperAdmin ? null : 20,
              ),
              onTap: isSuperAdmin
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ApiConfigPage()),
                    )
                  : () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('API configuration requires super admin access.'),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  static String _formatPercent(double value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);

  Future<void> _showUpdateFeeDialog(
    BuildContext context, {
    required _FeeField field,
  }) async {
    final adminBloc = context.read<AdminBloc>();
    final current = switch (field) {
      _FeeField.flat => adminBloc.state.flatFee,
      _FeeField.percent => adminBloc.state.percentFee,
      _FeeField.threshold => adminBloc.state.commissionThreshold,
    };
    final isDecimal = field == _FeeField.percent;
    final controller = TextEditingController(
      text: isDecimal ? _formatPercent(current) : current.round().toString(),
    );
    final formKey = GlobalKey<FormState>();

    final value = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(switch (field) {
          _FeeField.flat => 'Flat platform fee',
          _FeeField.percent => 'Commission',
          _FeeField.threshold => 'Commission threshold',
        }),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(isDecimal ? r'[0-9.]' : r'[0-9]'),
              ),
            ],
            decoration: InputDecoration(
              prefixText: field == _FeeField.percent ? null : '₹ ',
              suffixText: field == _FeeField.percent ? '%' : null,
              helperText: switch (field) {
                _FeeField.flat => 'Whole rupees, 0 – 1000',
                _FeeField.percent => '0 – 50',
                _FeeField.threshold => 'Whole rupees, 0 – 100000',
              },
            ),
            validator: (text) {
              final parsed = double.tryParse(text?.trim() ?? '');
              if (parsed == null) return 'Enter a number.';
              switch (field) {
                case _FeeField.flat:
                  if (parsed < 0 || parsed > 1000) return 'Enter 0 – 1000.';
                case _FeeField.percent:
                  if (parsed < 0 || parsed > 50) return 'Enter 0 – 50.';
                case _FeeField.threshold:
                  if (parsed < 0 || parsed > 100000) {
                    return 'Enter 0 – 100000.';
                  }
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(dialogContext, double.parse(controller.text.trim()));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value == null) return;
    adminBloc.add(
      AdminUpdateSettingsRequested(
        flatFee: field == _FeeField.flat
            ? value.roundToDouble()
            : adminBloc.state.flatFee,
        percentFee: field == _FeeField.percent
            ? value
            : adminBloc.state.percentFee,
        commissionThreshold: field == _FeeField.threshold
            ? value.roundToDouble()
            : adminBloc.state.commissionThreshold,
      ),
    );
  }
}

enum _FeeField { flat, percent, threshold }

class _ConfigTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ConfigTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.mutedText,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

