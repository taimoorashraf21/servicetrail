import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/equipment.dart';
import '../../models/service_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/common_widgets.dart';
import '../request_detail_screen.dart';
import 'equipment_form_screen.dart';
import 'request_form_screen.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();
    final user = auth.currentUser!;
    final myEquipment = data.equipmentFor(user.id);
    final myRequests = data.requestsForCustomer(user.id);
    final dateFmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${user.name.split(' ').first}'),
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
          ? _EquipmentTab(
              equipment: myEquipment,
              dateFmt: dateFmt,
              requests: myRequests,
            )
          : _RequestsTab(requests: myRequests, data: data),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.solar_power),
            label: 'My Equipment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build_circle_outlined),
            label: 'My Requests',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tab == 0) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const EquipmentFormScreen(),
              ),
            );
          } else {
            if (myEquipment.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Register equipment first, then raise a request.'),
                ),
              );
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const RequestFormScreen(),
              ),
            );
          }
        },
        icon: Icon(_tab == 0 ? Icons.add : Icons.report_problem_outlined),
        label: Text(_tab == 0 ? 'Add Equipment' : 'New Request'),
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

class _EquipmentTab extends StatelessWidget {
  final List<Equipment> equipment;
  final DateFormat dateFmt;
  final List<ServiceRequest> requests;

  const _EquipmentTab({
    required this.equipment,
    required this.dateFmt,
    required this.requests,
  });

  @override
  Widget build(BuildContext context) {
    if (equipment.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No equipment registered yet.\nTap "Add Equipment" to register your solar panel, inverter or battery.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: equipment.length,
      itemBuilder: (context, i) {
        final eq = equipment[i];
        final openCount = requests
            .where((r) =>
                r.equipmentId == eq.id &&
                r.status != RequestStatus.resolved)
            .length;
        final icon = switch (eq.type) {
          EquipmentType.solarPanel => Icons.solar_power,
          EquipmentType.inverter => Icons.electrical_services,
          EquipmentType.battery => Icons.battery_charging_full,
          EquipmentType.other => Icons.devices_other,
        };
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.12),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text('${eq.brand} ${eq.model}'),
            subtitle: Text(
              '${eq.type.label} • Installed ${dateFmt.format(eq.installDate)}\n'
              'Warranty till ${dateFmt.format(eq.warrantyExpiry)}'
              '${eq.isUnderWarranty ? '' : ' (expired)'}',
            ),
            isThreeLine: true,
            trailing: openCount > 0
                ? Chip(
                    label: Text('$openCount open'),
                    backgroundColor: Colors.orange.withOpacity(0.15),
                    labelStyle: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                    ),
                    visualDensity: VisualDensity.compact,
                  )
                : const Icon(Icons.check_circle, color: Colors.green),
            onTap: () {
              final history = requests
                  .where((r) => r.equipmentId == eq.id)
                  .toList();
              showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text('${eq.brand} ${eq.model}'),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Type: ${eq.type.label}'),
                        Text('Installed: ${dateFmt.format(eq.installDate)}'),
                        Text(
                            'Warranty: ${dateFmt.format(eq.warrantyExpiry)}'),
                        if (eq.location != null)
                          Text('Location: ${eq.location}'),
                        const SizedBox(height: 12),
                        Text(
                          'Maintenance history (${history.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        if (history.isEmpty)
                          const Text('No service requests yet.'),
                        for (final r in history)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                StatusChip(status: r.status),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${r.id} — ${r.title}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _RequestsTab extends StatelessWidget {
  final List<ServiceRequest> requests;
  final DataProvider data;

  const _RequestsTab({required this.requests, required this.data});

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No service requests yet.\nTap "New Request" to report an issue.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: requests.length,
      itemBuilder: (context, i) {
        final r = requests[i];
        final eq = data.equipmentById(r.equipmentId);
        return Card(
          child: ListTile(
            title: Text(r.title),
            subtitle: Text(
              '${r.id} • ${eq == null ? '' : '${eq.brand} ${eq.model} • '}'
              '${DateFormat('dd MMM yyyy, hh:mm a').format(r.createdAt)}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusChip(status: r.status),
                if (r.pendingSync == 1)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Pending sync',
                      style: TextStyle(fontSize: 11, color: Colors.amber),
                    ),
                  ),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RequestDetailScreen(requestId: r.id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
