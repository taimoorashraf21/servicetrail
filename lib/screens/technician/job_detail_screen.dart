import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/service_request.dart';
import '../../providers/data_provider.dart';
import '../request_detail_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final String requestId;
  const JobDetailScreen({super.key, required this.requestId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final request = data.requestById(widget.requestId);
    if (request == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job')),
        body: const Center(child: Text('Job not found.')),
      );
    }
    final isResolved = request.status == RequestStatus.resolved;
    final checkedIn = request.checkInAt != null;
    final checkedOut = request.checkOutAt != null;

    return Scaffold(
      appBar: AppBar(title: Text('Job ${request.id}')),
      body: Column(
        children: [
          Expanded(
            child: RequestDetailScreen(
              requestId: request.id,
              showAppBar: false,
            ),
          ),
          if (!isResolved)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.login),
                          label: Text(
                            checkedIn ? 'Checked in ✓' : 'GPS Check-in',
                          ),
                          onPressed:
                              (checkedIn || _busy) ? null : () => _checkInOut(true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.logout),
                          label: Text(
                            checkedOut ? 'Checked out ✓' : 'GPS Check-out',
                          ),
                          onPressed: (!checkedIn || checkedOut || _busy)
                              ? null
                              : () => _checkInOut(false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy ||
                                  request.status == RequestStatus.inProgress
                              ? null
                              : () => _setStatus(RequestStatus.inProgress),
                          child: const Text('Start Work'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: _busy
                              ? null
                              : () => _setStatus(RequestStatus.resolved),
                          child: const Text('Mark Complete'),
                        ),
                      ),
                    ],
                  ),
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _checkInOut(bool checkIn) async {
    setState(() => _busy = true);
    final data = context.read<DataProvider>();
    final request = data.requestById(widget.requestId);
    if (request == null) {
      setState(() => _busy = false);
      return;
    }
    final error = checkIn
        ? await data.checkIn(request)
        : await data.checkOut(request);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? checkIn
                  ? 'Checked in with GPS location.'
                  : 'Checked out with GPS location.'
              : checkIn
                  ? 'Checked in without GPS — $error'
                  : 'Checked out without GPS — $error',
        ),
      ),
    );
  }

  Future<void> _setStatus(RequestStatus status) async {
    setState(() => _busy = true);
    final data = context.read<DataProvider>();
    final request = data.requestById(widget.requestId);
    if (request == null) {
      setState(() => _busy = false);
      return;
    }
    await data.updateStatus(request, status);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == RequestStatus.resolved
              ? 'Job marked complete.'
              : 'Job moved to In Progress.',
        ),
      ),
    );
  }
}
