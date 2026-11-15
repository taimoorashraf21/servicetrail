import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/equipment.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';

class EquipmentFormScreen extends StatefulWidget {
  const EquipmentFormScreen({super.key});

  @override
  State<EquipmentFormScreen> createState() => _EquipmentFormScreenState();
}

class _EquipmentFormScreenState extends State<EquipmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  EquipmentType _type = EquipmentType.solarPanel;
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  DateTime _installDate = DateTime.now();
  DateTime _warrantyDate = DateTime.now().add(const Duration(days: 365 * 5));
  bool _saving = false;

  @override
  void dispose() {
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool install}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: install ? _installDate : _warrantyDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2045),
    );
    if (picked != null) {
      setState(() {
        if (install) {
          _installDate = picked;
        } else {
          _warrantyDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final user = context.read<AuthProvider>().currentUser!;
    final equipment = Equipment(
      id: 'eq_${DateTime.now().microsecondsSinceEpoch}',
      customerId: user.id,
      type: _type,
      brand: _brandCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
      installDate: _installDate,
      warrantyExpiry: _warrantyDate,
      location: _locationCtrl.text.trim().isEmpty
          ? null
          : _locationCtrl.text.trim(),
    );
    await context.read<DataProvider>().addEquipment(equipment);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Equipment registered.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    return Scaffold(
      appBar: AppBar(title: const Text('Register Equipment')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<EquipmentType>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Equipment type',
                border: OutlineInputBorder(),
              ),
              items: EquipmentType.values
                  .map(
                    (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _brandCtrl,
              decoration: const InputDecoration(
                labelText: 'Brand (e.g. Jinko Solar)',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Brand is required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _modelCtrl,
              decoration: const InputDecoration(
                labelText: 'Model (e.g. JKM-550M)',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Model is required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                labelText: 'Location (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Install date'),
              subtitle: Text(fmt.format(_installDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(install: true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Warranty expiry'),
              subtitle: Text(fmt.format(_warrantyDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(install: false),
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
                  : const Text('Register Equipment'),
            ),
          ],
        ),
      ),
    );
  }
}
