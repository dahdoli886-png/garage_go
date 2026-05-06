class Vehicle {
  final String id;
  final String make;
  final String model;
  final int year;
  final String plateNumber;
  final String ownerId;

  Vehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.plateNumber,
    required this.ownerId,
  });

  // هاد الجزء بنحتاجه لاحقاً لما نجيب بيانات من قاعدة البيانات (JSON)
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      make: json['make'],
      model: json['model'],
      year: json['year'],
      plateNumber: json['plateNumber'],
      ownerId: json['ownerId'],
    );
  }
}