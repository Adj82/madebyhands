import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'Overview',
    'Creator Verifications',
    'Product Approvals',
    'Categories',
    'Orders',
    'User Management',
    'Support Tickets',
    'Moderation',
    'Payouts & Finance',
    'Admin Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () {
              // Simulate refresh
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Refreshing data...')));
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.background,
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.admin_panel_settings,
                        size: 50, color: Colors.white),
                    const SizedBox(height: 10),
                    const Text('MADEBYHANDS ADMIN',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerTile(0, Icons.dashboard_outlined, Icons.dashboard, 'Overview'),
                  _buildDrawerTile(1, Icons.verified_user_outlined, Icons.verified_user, 'Verifications'),
                  _buildDrawerTile(2, Icons.shopping_bag_outlined, Icons.shopping_bag, 'Products'),
                  _buildDrawerTile(3, Icons.category_outlined, Icons.category, 'Categories'),
                  _buildDrawerTile(4, Icons.receipt_long_outlined, Icons.receipt_long, 'Orders'),
                  _buildDrawerTile(5, Icons.people_outline, Icons.people, 'Users'),
                  _buildDrawerTile(6, Icons.support_agent_outlined, Icons.support_agent, 'Support'),
                  _buildDrawerTile(7, Icons.gavel_outlined, Icons.gavel, 'Moderation'),
                  _buildDrawerTile(8, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'Payouts'),
                  _buildDrawerTile(9, Icons.settings_outlined, Icons.settings, 'Settings'),
                ],
              ),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Version 1.0.0', style: TextStyle(color: AppColors.mutedText, fontSize: 12)),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _OverviewView(),
          _VerificationView(),
          _ProductApprovalView(),
          _CategoryManagementView(),
          _OrderManagementView(),
          _UserManagementView(),
          _SupportTicketsView(),
          _ModerationView(),
          _FinanceView(),
          _AdminSettingsView(),
        ],
      ),
    );
  }

  Widget _buildDrawerTile(int index, IconData icon, IconData selectedIcon, String title) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(isSelected ? selectedIcon : icon, color: isSelected ? AppColors.primary : AppColors.mutedText),
      title: Text(title, style: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.primary : AppColors.text,
      )),
      selected: isSelected,
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }
}

class _OverviewView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Platform Status', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.5,
            children: [
              _StatCard(title: 'Total Users', value: '1,284', icon: Icons.people, color: Colors.blue),
              _StatCard(title: 'Active Creators', value: '142', icon: Icons.palette, color: AppColors.primary),
              _StatCard(title: 'Pending Approvals', value: '28', icon: Icons.hourglass_empty, color: AppColors.accent),
              _StatCard(title: 'Total Revenue', value: '₹42,500', icon: Icons.payments, color: Colors.green),
            ],
          ),
          const SizedBox(height: 30),
          const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              return ListTile(
                leading: const CircleAvatar(backgroundColor: AppColors.outline, child: Icon(Icons.notifications_none, size: 20)),
                title: Text('New creator application from "Artisan $index"'),
                subtitle: const Text('2 hours ago'),
                trailing: TextButton(onPressed: () {}, child: const Text('Review')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _VerificationView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 15),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(radius: 25, backgroundColor: AppColors.primary, child: Icon(Icons.person, color: Colors.white)),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Artisan Name $index', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Text('Pottery & Ceramics', style: TextStyle(color: AppColors.mutedText)),
                        ],
                      ),
                    ),
                    const Chip(label: Text('Pending'), backgroundColor: Color(0xFFFFF3E0)),
                  ],
                ),
                const SizedBox(height: 15),
                const Text('Bio: "Passionate ceramicist with 10 years of experience crafting handmade vases and dinnerware."', maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => _showDocumentReview(context, index), 
                      child: const Text('View Documents')
                    ),
                    const SizedBox(width: 10),
                    FilledButton(onPressed: () {}, style: FilledButton.styleFrom(backgroundColor: AppColors.primary), child: const Text('Verify')),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDocumentReview(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Verification Documents', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text('Artisan ID: MBH-CRT-00$index', style: const TextStyle(color: AppColors.mutedText)),
            const SizedBox(height: 25),
            Expanded(
              child: ListView(
                children: [
                  _DocItem(title: 'Identity Proof (PAN/Aadhar)', subtitle: 'Uploaded on 12 Sep 2026'),
                  const SizedBox(height: 15),
                  _DocItem(title: 'Address Proof', subtitle: 'Utility Bill / Bank Statement'),
                  const SizedBox(height: 15),
                  _DocItem(title: 'Portfolio Link', subtitle: 'https://behance.net/artisan$index', isLink: true),
                ],
              ),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Reject Application'))),
                const SizedBox(width: 15),
                Expanded(child: FilledButton(onPressed: () => Navigator.pop(context), style: FilledButton.styleFrom(backgroundColor: AppColors.primary), child: const Text('Approve Creator'))),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _DocItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isLink;
  const _DocItem({required this.title, required this.subtitle, this.isLink = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.outline)),
      child: Row(
        children: [
          Icon(isLink ? Icons.link : Icons.description, color: AppColors.primary),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
              ],
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.open_in_new, size: 20)),
        ],
      ),
    );
  }
}

class _CategoryManagementView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final categories = ['Pottery', 'Jewellery', 'Home Decor', 'Textiles', 'Gifts', 'Paintings', 'Digital Art'];
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('New Category'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: AppColors.outline, child: Icon(Icons.category, size: 20)),
              title: Text(categories[index]),
              subtitle: Text('${index * 12 + 5} products listed'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined)),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.delete_outline, color: Colors.redAccent)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrderManagementView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 15),
          child: ExpansionTile(
            title: Text('Order #MBH-102$index', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Status: ${index % 2 == 0 ? 'Processing' : 'Shipped'} • Total: ₹2,450'),
            children: [
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Order Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    const Text('• Blue Ceramic Vase x 1'),
                    const Text('• Handmade Soap Set x 2'),
                    const Divider(),
                    const Text('Timeline:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Text('18 Sep: Order Confirmed'),
                    if (index % 2 != 0) const Text('19 Sep: Shipped by Creator'),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        const Spacer(),
                        OutlinedButton(onPressed: () {}, child: const Text('Contact Buyer')),
                        const SizedBox(width: 10),
                        OutlinedButton(onPressed: () {}, child: const Text('Contact Creator')),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

class _SupportTicketsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: 6,
      itemBuilder: (context, index) {
        final isOpen = index < 3;
        return Card(
          child: ListTile(
            leading: Icon(Icons.help_center, color: isOpen ? Colors.orange : Colors.green),
            title: Text('Support Ticket #78$index'),
            subtitle: Text('Issue: ${index % 2 == 0 ? 'Payment failed' : 'Product damaged'}'),
            trailing: Chip(
              label: Text(isOpen ? 'Open' : 'Resolved', style: const TextStyle(fontSize: 10)),
              backgroundColor: isOpen ? Colors.orange.withAlpha(50) : Colors.green.withAlpha(50),
            ),
            onTap: () {},
          ),
        );
      },
    );
  }
}

class _FinanceView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Financial Summary', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(25),
            width: double.infinity,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(25)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Platform Balance', style: TextStyle(color: Colors.white70)),
                const Text('₹1,42,850.00', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _SmallStat(label: 'Total Fees', value: '₹12,400'),
                    const SizedBox(width: 40),
                    _SmallStat(label: 'Pending Payouts', value: '₹5,200'),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text('Pending Creator Payouts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Card(
                child: ListTile(
                  title: Text('Artisan $index'),
                  subtitle: const Text('Request Date: 17 Sep 2026'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('₹4,500', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextButton(onPressed: () {}, style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero), child: const Text('Release Payout', style: TextStyle(fontSize: 12))),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AdminSettingsView extends StatefulWidget {
  @override
  State<_AdminSettingsView> createState() => _AdminSettingsViewState();
}

class _AdminSettingsViewState extends State<_AdminSettingsView> {
  bool _maintenanceMode = false;
  bool _emailNotifications = true;
  double _flatFee = 50.0;
  double _percentFee = 5.0;

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
        style: const TextStyle(color: AppColors.mutedText, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
    );
  }
}

class _SmallStat extends StatelessWidget {
  final String label;
  final String value;
  const _SmallStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _ProductApprovalView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.7,
      ),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: AppColors.outline,
                  child: const Icon(Icons.image, size: 50, color: Colors.grey),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Handmade Vase $index', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('by Creator $index', style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                    const SizedBox(height: 5),
                    const Text('₹1,200', style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(padding: EdgeInsets.zero), child: const Text('Reject'))),
                        const SizedBox(width: 5),
                        Expanded(child: FilledButton(onPressed: () {}, style: FilledButton.styleFrom(padding: EdgeInsets.zero, backgroundColor: AppColors.primary), child: const Text('Approve'))),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

class _UserManagementView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 20,
      itemBuilder: (context, index) {
        final isCreator = index % 3 == 0;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isCreator ? AppColors.primary.withAlpha(50) : AppColors.outline,
              child: Icon(isCreator ? Icons.palette : Icons.person, size: 20, color: isCreator ? AppColors.primary : AppColors.mutedText),
            ),
            title: Text('User $index', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('user$index@gmail.com • ${isCreator ? 'Creator' : 'Buyer'}'),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'view', child: Text('View Profile')),
                const PopupMenuItem(value: 'suspend', child: Text('Suspend User', style: TextStyle(color: Colors.redAccent))),
                const PopupMenuItem(value: 'role', child: Text('Change Role')),
              ],
              onSelected: (val) {},
            ),
          ),
        );
      },
    );
  }
}

class _ModerationView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            leading: const Icon(Icons.report_problem, color: Colors.red),
            title: Text('Report #$index: Contact Info Exchange'),
            subtitle: const Text('Reported by System on Conversation #CRT-BYR-102'),
            trailing: TextButton(
              onPressed: () => _showChatModeration(context, index),
              child: const Text('Review Chat'),
            ),
          ),
        );
      },
    );
  }

  void _showChatModeration(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Moderation Review', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('System flagged potential contact sharing in this chat:', 
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    _ChatMessage(sender: 'Artisan', message: 'Hello! Thanks for your order.', isFlagged: false),
                    _ChatMessage(sender: 'Buyer', message: 'Can we talk on WhatsApp? 9876543210', isFlagged: true),
                    _ChatMessage(sender: 'Artisan', message: 'I am not sure if that is allowed here.', isFlagged: false),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ignore')),
          FilledButton(
            onPressed: () => Navigator.pop(context), 
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Warn User'),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage extends StatelessWidget {
  final String sender;
  final String message;
  final bool isFlagged;
  const _ChatMessage({required this.sender, required this.message, required this.isFlagged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$sender: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Expanded(
            child: Text(message, 
              style: TextStyle(
                fontSize: 12, 
                color: isFlagged ? Colors.red : Colors.black,
                backgroundColor: isFlagged ? Colors.red.withAlpha(20) : null,
              )
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
        ],
      ),
    );
  }
}
