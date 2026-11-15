import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/equipment.dart';
import '../../models/service_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';

const _issueTypes = [
  'Inverter Fault',
  'Battery Fault',
  'Low Generation',
  'Wiring Fault',
  'Maintenance',
  'Other',
];

class RequestFormScreen extends StatefulWidget {
  const RequestFormScreen({super.key});

  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends State<RequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _equipmentId;
  String _issueType = _issueTypes.first;
  Priority _priority = Priority.medium;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_equipmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick an equipment.')),
      );
      return;
    }
    setState(() => _saving = true);
    final user = context.read<AuthProvider>().currentUser!;
    final data = context.read<DataProvider>();
    final request = ServiceRequest(
      id: 'SR-${DateTime.now().millisecondsSinceEpoch % 100000}',
      equipmentId: _equipmentId!,
      customerId: user.id,
      title: _titleCtrl.text.trim(),
      issueType: _issueType,
      description: _descCtrl.text.trim(),
      priority: _priority,
      status: RequestStatus.submitted,
      createdAt: DateTime.now(),
    );
    await data.addRequest(request);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Request ${request.id} submitted.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser!;
    final myEquipment =
        context.watch<DataProvider>().equipmentFor(user.id);
    _equipmentId ??= myEquipment.isNotEmpty ? myEquipment.first.id : null;

    return Scaffold(
      appBar: AppBar(title: const Text('New Service Request')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: _equipmentId,
              decoration: const InputDecoration(
                labelText: 'Equipment',
                border: OutlineInputBorder(),
              ),
              items: myEquipment
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.id,
                      child: Text('${e.brand} ${e.model} (${e.type.label})'),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _equipmentId = v),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _issueType,
              decoration: const InputDecoration(
                labelText: 'Issue type',
                border: OutlineInputBorder(),
              ),
              items: _issueTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _issueType = v!),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title (e.g. Inverter not turning on)',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Describe the problem',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Description is required'
                  : null,
            ),
            const SizedBox(height: 14),
            const Text('Priority', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            SegmentedButton<Priority>(
              segments: Priority.values
                  .map(
                    (p) => ButtonSegment(value: p, label: Text(p.label)),
                  )
                  .toList(),
              selected: {_priority},
              onSelectionChanged: (s) => setState(() => _priority = s.first),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }
}
