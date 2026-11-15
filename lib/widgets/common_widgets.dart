import 'package:flutter/material.dart';

import '../models/service_request.dart';

Color statusColor(RequestStatus status) {
  switch (status) {
    case RequestStatus.submitted:
      return Colors.blue;
    case RequestStatus.assigned:
      return Colors.orange;
    case RequestStatus.inProgress:
      return Colors.purple;
    case RequestStatus.resolved:
      return Colors.green;
  }
}

Color priorityColor(Priority priority) {
  switch (priority) {
    case Priority.low:
      return Colors.teal;
    case Priority.medium:
      return Colors.blue;
    case Priority.high:
      return Colors.orange;
    case Priority.urgent:
      return Colors.red;
  }
}

class StatusChip extends StatelessWidget {
  final RequestStatus status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Chip(
      label: Text(
        status.label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      backgroundColor: color.withOpacity(0.15),
      side: BorderSide(color: color.withOpacity(0.4)),
      labelStyle: TextStyle(color: color),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class PriorityChip extends StatelessWidget {
  final Priority priority;
  const PriorityChip({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = priorityColor(priority);
    return Chip(
      label: Text(
        priority.label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      backgroundColor: color.withOpacity(0.15),
      side: BorderSide(color: color.withOpacity(0.4)),
      labelStyle: TextStyle(color: color),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class SyncBadgeButton extends StatelessWidget {
  final int pendingCount;
  final VoidCallback onSync;

  const SyncBadgeButton({
    super.key,
    required this.pendingCount,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.cloud_upload_outlined),
          tooltip: pendingCount > 0
              ? '$pendingCount change(s) pending sync'
              : 'All changes synced',
          onPressed: onSync,
        ),
        if (pendingCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                '$pendingCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
