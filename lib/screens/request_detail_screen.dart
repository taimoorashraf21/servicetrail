import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/equipment.dart';
import '../models/service_request.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;

  /// When false, renders only the detail body (no Scaffold/AppBar),
  /// so it can be embedded inside another screen.
  final bool showAppBar;

  const RequestDetailScreen({
    super.key,
    required this.requestId,
    this.showAppBar = true,
  });

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  final _noteCtrl = TextEditingController();
  bool _loadingNotes = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await context.read<DataProvider>().loadNotes(widget.requestId);
    if (mounted) setState(() => _loadingNotes = false);
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final request = data.requestById(widget.requestId);
    final notFound = Scaffold(
      appBar:
          widget.showAppBar ? AppBar(title: const Text('Request')) : null,
      body: const Center(child: Text('Request not found.')),
    );
    if (request == null) return notFound;
    final equipment = data.equipmentById(request.equipmentId);
    final customer = data.userById(request.customerId);
    final technician = request.assignedTechnicianId == null
        ? null
        : data.userById(request.assignedTechnicianId!);
    final notes = data.notesByRequest[request.id] ?? [];
    final user = context.watch<AuthProvider>().currentUser!;
    final isTechnician = user.role == UserRole.technician;
    final fmt = DateFormat('dd MMM yyyy, hh:mm a');

    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          request.title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            StatusChip(status: request.status),
            const SizedBox(width: 8),
            PriorityChip(priority: request.priority),
          ],
        ),
        const SizedBox(height: 16),
        _infoRow('Issue type', request.issueType),
        _infoRow(
          'Equipment',
          equipment == null
              ? '—'
              : '${equipment.brand} ${equipment.model} (${equipment.type.label})',
        ),
        _infoRow('Customer', customer?.name ?? '—'),
        _infoRow('Technician', technician?.name ?? 'Not assigned yet'),
        _infoRow('Created', fmt.format(request.createdAt)),
        if (request.resolvedAt != null)
          _infoRow('Resolved', fmt.format(request.resolvedAt!)),
        const SizedBox(height: 12),
        const Text(
          'Description',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(request.description),
        const SizedBox(height: 20),
        const Text(
          'Status timeline',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        _Timeline(request: request, fmt: fmt),
        const SizedBox(height: 20),
        const Text(
          'Site visits (GPS)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        _gpsRow(
          'Check-in',
          request.checkInAt,
          request.checkInLat,
          request.checkInLng,
          fmt,
        ),
        _gpsRow(
          'Check-out',
          request.checkOutAt,
          request.checkOutLat,
          request.checkOutLng,
          fmt,
        ),
        const SizedBox(height: 20),
        const Text(
          'Work notes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (_loadingNotes)
          const Center(child: CircularProgressIndicator())
        else if (notes.isEmpty)
          const Text(
            'No notes yet.',
            style: TextStyle(color: Colors.black54),
          )
        else
          ...notes.map(
            (n) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(n.authorName[0]),
                ),
                title: Text(n.authorName),
                subtitle: Text(n.text),
                trailing: Text(
                  DateFormat('dd MMM, hh:mm a').format(n.createdAt),
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
          ),
        if (isTechnician) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Add a work note',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              icon: const Icon(Icons.note_add_outlined),
              label: const Text('Add Note'),
              onPressed: () async {
                final text = _noteCtrl.text.trim();
                if (text.isEmpty) return;
                await data.addNote(request, user, text);
                _noteCtrl.clear();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Note added.')),
                  );
                }
              },
            ),
          ),
        ],
      ],
    );

    if (!widget.showAppBar) return body;

    return Scaffold(
      appBar: AppBar(
        title: Text(request.id),
        actions: [
          if (request.pendingSync == 1)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(
                child: Chip(
                  label: Text('Pending sync', style: TextStyle(fontSize: 11)),
                  backgroundColor: Colors.amber,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
        ],
      ),
      body: body,
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gpsRow(
    String label,
    DateTime? at,
    double? lat,
    double? lng,
    DateFormat fmt,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.location_on_outlined),
        title: Text(label),
        subtitle: Text(
          at == null
              ? 'Not recorded yet'
              : '${fmt.format(at)}'
                  '${lat != null && lng != null ? '\n${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}' : ' (no GPS — permission denied)'}',
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final ServiceRequest request;
  final DateFormat fmt;

  const _Timeline({required this.request, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final steps = <({RequestStatus status, String label, DateTime? at})>[
      (
        status: RequestStatus.submitted,
        label: 'Submitted',
        at: request.createdAt,
      ),
      (
        status: RequestStatus.assigned,
        label: 'Assigned',
        at: request.assignedTechnicianId == null
            ? null
            : request.createdAt,
      ),
      (
        status: RequestStatus.inProgress,
        label: 'In Progress',
        at: request.checkInAt,
      ),
      (
        status: RequestStatus.resolved,
        label: 'Resolved',
        at: request.resolvedAt,
      ),
    ];
    final currentIndex = RequestStatus.values.indexOf(request.status);

    return Column(
      children: [
        for (int i = 0; i < steps.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: i <= currentIndex
                        ? statusColor(steps[i].status)
                        : Colors.grey.shade300,
                    child: i < currentIndex || request.status == steps[i].status
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                  ),
                  if (i < steps.length - 1)
                    Container(
                      width: 2,
                      height: 26,
                      color: i < currentIndex
                          ? statusColor(steps[i].status)
                          : Colors.grey.shade300,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        steps[i].label,
                        style: TextStyle(
                          fontWeight: i <= currentIndex
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: i <= currentIndex
                              ? Colors.black87
                              : Colors.black38,
                        ),
                      ),
                      if (steps[i].at != null)
                        Text(
                          fmt.format(steps[i].at!),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
