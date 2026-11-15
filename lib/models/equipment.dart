enum EquipmentType { solarPanel, inverter, battery, other }

extension EquipmentTypeX on EquipmentType {
  String get label {
    switch (this) {
      case EquipmentType.solarPanel:
        return 'Solar Panel';
      case EquipmentType.inverter:
        return 'Inverter';
      case EquipmentType.battery:
        return 'Battery';
      case EquipmentType.other:
        return 'Other';
    }
  }

  static EquipmentType fromString(String value) {
    return EquipmentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EquipmentType.other,
    );
  }
}

class Equipment {
  final String id;
  final String customerId;
  final EquipmentType type;
  final String brand;
  final String model;
  final DateTime installDate;
  final DateTime warrantyExpiry;
  final String? location;

  const Equipment({
    required this.id,
    required this.customerId,
    required this.type,
    required this.brand,
    required this.model,
    required this.installDate,
    required this.warrantyExpiry,
    this.location,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'customerId': customerId,
        'type': type.name,
        'brand': brand,
        'model': model,
        'installDate': installDate.toIso8601String(),
        'warrantyExpiry': warrantyExpiry.toIso8601String(),
        'location': location,
      };

  factory Equipment.fromMap(Map<String, dynamic> map) => Equipment(
        id: map['id'] as String,
        customerId: map['customerId'] as String,
        type: EquipmentTypeX.fromString(map['type'] as String),
        brand: map['brand'] as String,
        model: map['model'] as String,
        installDate: DateTime.parse(map['installDate'] as String),
        warrantyExpiry: DateTime.parse(map['warrantyExpiry'] as String),
        location: map['location'] as String?,
      );

  bool get isUnderWarranty => DateTime.now().isBefore(warrantyExpiry);
}
