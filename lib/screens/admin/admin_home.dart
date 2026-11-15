import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/service_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/common_widgets.dart';
import '../request_detail_screen.dart';
import 'analytics_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  RequestStatus? _filter;
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();
    final jobs = _filter == null
        ? data.requests
        : data.requests.where((r) => r.status == _filter).toList();
    final avgHours = data.avgResolutionHours;
    final avgText = avgHours <= 0
        ? '—'
        : avgHours < 24
            ? '${avgHours.toStringAsFixed(1)} hrs'
            : '${(avgHours / 24).toStringAsFixed(1)} days';

    return Scaffold(
      appBar: AppBar(
        title: const Text('ServiceTrail — Admin'),
        actions: [
          SyncBadgeButton(
            pendingCount: data.pendingSyncCount,
            onSync: () => _sync(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Switch role',
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: _tab == 0
          ? _buildDashboard(context, data, jobs, avgText)
          : const AnalyticsScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    DataProvider data,
    List<ServiceRequest> jobs,
    String avgText,
  ) {
    return RefreshIndicator(
      onRefresh: () => data.refresh(),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.55,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              StatCard(
                label: 'Open jobs',
                value: '${data.openJobs}',
                icon: Icons.build_circle_outlined,
                color: Colors.orange,
              ),
              StatCard(
                label: 'Resolved this month',
                value: '${data.resolvedThisMonth}',
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
              StatCard(
                label: 'Avg resolution',
                value: avgText,
                icon: Icons.timer_outlined,
                color: Colors.purple,
              ),
              StatCard(
                label: 'Technicians',
                value: '${data.technicians.length}',
                icon: Icons.engineering_outlined,
                color: Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Jobs (${jobs.length})',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                for (final s in RequestStatus.values)
                  _FilterChip(
                    label: s.label,
                    selected: _filter == s,
                    onTap: () => setState(() => _filter = s),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (jobs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No jobs match this filter.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            )
          else
            ...jobs.map((r) => _JobCard(request: r)),
        ],
      ),
    );
  }

  Future<void> _sync(BuildContext context) async {
    final data = context.read<DataProvider>();
    if (data.pendingSyncCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Everything is already synced.')),
      );
      return;
    }
    final count = await data.syncNow();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count change(s) synced to the server.')),
      );
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final ServiceRequest request;
  const _JobCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final eq = data.equipmentById(request.equipmentId);
    final customer = data.userById(request.customerId);
    final technician = request.assignedTechnicianId == null
        ? null
        : data.userById(request.assignedTechnicianId!);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(request.title),
            subtitle: Text(
              '${request.id} • ${customer?.name ?? ''} • '
              '${eq == null ? '' : '${eq.brand} ${eq.model} • '}'
              '${DateFormat('dd MMM yyyy').format(request.createdAt)}\n'
              'Technician: ${technician?.name ?? 'Unassigned'}',
            ),
            isThreeLine: true,
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusChip(status: request.status),
                const SizedBox(height: 4),
                PriorityChip(priority: request.priority),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RequestDetailScreen(requestId: request.id),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.person_add_alt_1, size: 18),
                label: Text(
                  technician == null ? 'Assign technician' : 'Reassign',
                ),
                onPressed: () => _showAssignDialog(context, data),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(BuildContext context, DataProvider data) {
    String? selected = request.assignedTechnicianId;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Assign technician — ${request.id}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final t in data.technicians)
                RadioListTile<String>(
                  title: Text(t.name),
                  subtitle: Text(
                      '${t.specialty ?? 'General'} • ${t.city ?? ''}'),
                  value: t.id,
                  groupValue: selected,
                  onChanged: (v) => setState(() => selected = v),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selected == null
                  ? null
                  : () async {
                      await data.assignTechnician(request, selected!);
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Technician assigned.')),
                        );
                      }
                    },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }
}
