import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/service_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/common_widgets.dart';
import 'job_detail_screen.dart';

class TechnicianHome extends StatefulWidget {
  const TechnicianHome({super.key});

  @override
  State<TechnicianHome> createState() => _TechnicianHomeState();
}

class _TechnicianHomeState extends State<TechnicianHome> {
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();
    final user = auth.currentUser!;
    final myJobs = data.requestsForTechnician(user.id);
    final active =
        myJobs.where((r) => r.status != RequestStatus.resolved).toList();
    final done =
        myJobs.where((r) => r.status == RequestStatus.resolved).toList();
    final shown = _showCompleted ? done : active;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Tasks — ${user.name.split(' ').first}'),
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
      body: RefreshIndicator(
        onRefresh: () => data.refresh(),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Active tasks',
                    value: '${active.length}',
                    icon: Icons.assignment_outlined,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    label: 'Completed',
                    value: '${done.length}',
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Active')),
                ButtonSegment(value: true, label: Text('Completed')),
              ],
              selected: {_showCompleted},
              onSelectionChanged: (s) =>
                  setState(() => _showCompleted = s.first),
            ),
            const SizedBox(height: 12),
            if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _showCompleted
                      ? 'No completed tasks yet.'
                      : 'No active tasks. New assignments will appear here.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
              )
            else
              ...shown.map((r) => _TaskCard(request: r)),
          ],
        ),
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

class _TaskCard extends StatelessWidget {
  final ServiceRequest request;
  const _TaskCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final eq = data.equipmentById(request.equipmentId);
    final customer = data.userById(request.customerId);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              statusColor(request.status).withOpacity(0.15),
          child: Icon(
            Icons.build,
            color: statusColor(request.status),
          ),
        ),
        title: Text(request.title),
        subtitle: Text(
          '${request.id} • ${customer?.name ?? ''} • '
          '${eq == null ? '' : '${eq.brand} ${eq.model} • '}'
          '${DateFormat('dd MMM yyyy').format(request.createdAt)}'
          '${request.checkInAt != null ? '\nChecked in ${DateFormat('hh:mm a').format(request.checkInAt!)}' : ''}',
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
              builder: (_) => JobDetailScreen(requestId: request.id),
            ),
          );
        },
      ),
    );
  }
}
