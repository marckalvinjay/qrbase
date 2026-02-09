class Student {
  int? id;
  String name;
  String qrCode;

  Student({this.id, required this.name, required this.qrCode});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'qrCode': qrCode};
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      name: map['name'],
      qrCode: map['qrCode'],
    );
  }
}
