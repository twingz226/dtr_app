class DtrRecord {
  final int? id;
  final String date;
  final String? timeIn;
  final String? timeOut;
  final double? hoursWorked;
  final String? remarks;
  final String status; // 'present', 'absent', 'half-day', 'leave'

  DtrRecord({
    this.id,
    required this.date,
    this.timeIn,
    this.timeOut,
    this.hoursWorked,
    this.remarks,
    this.status = 'present',
  });

  bool get isComplete => timeIn != null && timeOut != null;
  bool get isClockedIn => timeIn != null && timeOut == null;

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date,
    'timeIn': timeIn,
    'timeOut': timeOut,
    'hoursWorked': hoursWorked,
    'remarks': remarks,
    'status': status,
  };

  factory DtrRecord.fromMap(Map<String, dynamic> map) => DtrRecord(
    id: map['id'],
    date: map['date'],
    timeIn: map['timeIn'],
    timeOut: map['timeOut'],
    hoursWorked: map['hoursWorked'],
    remarks: map['remarks'],
    status: map['status'] ?? 'present',
  );

  DtrRecord copyWith({
    int? id, String? date, String? timeIn, String? timeOut,
    double? hoursWorked, String? remarks, String? status,
  }) => DtrRecord(
    id: id ?? this.id,
    date: date ?? this.date,
    timeIn: timeIn ?? this.timeIn,
    timeOut: timeOut ?? this.timeOut,
    hoursWorked: hoursWorked ?? this.hoursWorked,
    remarks: remarks ?? this.remarks,
    status: status ?? this.status,
  );
}
