import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.solar_power,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'ServiceTrail',
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Smart service & maintenance for solar companies',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                'Demo mode — pick a role to continue. No password needed.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black45, fontSize: 13),
              ),
              const SizedBox(height: 28),
              if (data.loading)
                const Center(child: CircularProgressIndicator())
              else ...[
                _RoleCard(
                  icon: Icons.person_outline,
                  title: 'Customer',
                  subtitle:
                      'Register equipment, raise service requests, track repairs',
                  color: Colors.green,
                  accounts: data.customers,
                ),
                const SizedBox(height: 14),
                _RoleCard(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Admin',
                  subtitle: 'Manage jobs, assign technicians, view analytics',
                  color: Colors.indigo,
                  accounts: const [],
                  singleAccount: const AppUser(
                    id: 'admin-1',
                    name: 'ServiceTrail Admin',
                    email: 'admin@servicetrail.com',
                    phone: '+92 300 1112223',
                    role: UserRole.admin,
                    city: 'Lahore',
                  ),
                ),
                const SizedBox(height: 14),
                _RoleCard(
                  icon: Icons.engineering_outlined,
                  title: 'Technician',
                  subtitle:
                      'My tasks, GPS check-in / check-out, work notes',
                  color: Colors.amber.shade800,
                  accounts: data.technicians,
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Works offline — changes are saved locally and marked pending sync.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black45, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final List<AppUser> accounts;
  final AppUser? singleAccount;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.accounts,
    this.singleAccount,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final allAccounts =
        singleAccount != null ? [singleAccount!] : accounts;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (allAccounts.isEmpty)
              const Text(
                'Loading demo accounts…',
                style: TextStyle(color: Colors.black45),
              )
            else
              ...allAccounts.map(
                (u) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.login, size: 18),
                      label: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          singleAccount != null
                              ? 'Continue as Admin'
                              : '${u.name} • ${u.city ?? ''}',
                        ),
                      ),
                      onPressed: () => auth.loginAs(u),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
