class Employee {
  final String id;
  final String name;
  final String phone;
  final String faceImageUrl;

  Employee({
    required this.id,
    required this.name,
    required this.phone,
    required this.faceImageUrl,
  });

  factory Employee.fromFirestore(String id, Map<String, dynamic> data) {
    return Employee(
      id: id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      faceImageUrl: data['faceImageUrl'] ?? '',
    );
  }
}
