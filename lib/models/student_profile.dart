class StudentProfile {
  final int? id;
  final String fullName;
  final String studentId;
  final String school;
  final String course;
  final String company;
  final String supervisor;
  final int requiredHours;
  final String startDate;

  StudentProfile({
    this.id,
    required this.fullName,
    required this.studentId,
    required this.school,
    required this.course,
    required this.company,
    required this.supervisor,
    required this.requiredHours,
    required this.startDate,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'fullName': fullName,
    'studentId': studentId,
    'school': school,
    'course': course,
    'company': company,
    'supervisor': supervisor,
    'requiredHours': requiredHours,
    'startDate': startDate,
  };

  factory StudentProfile.fromMap(Map<String, dynamic> map) => StudentProfile(
    id: map['id'],
    fullName: map['fullName'],
    studentId: map['studentId'],
    school: map['school'],
    course: map['course'],
    company: map['company'],
    supervisor: map['supervisor'],
    requiredHours: map['requiredHours'],
    startDate: map['startDate'],
  );

  StudentProfile copyWith({
    int? id, String? fullName, String? studentId, String? school,
    String? course, String? company, String? supervisor,
    int? requiredHours, String? startDate,
  }) => StudentProfile(
    id: id ?? this.id,
    fullName: fullName ?? this.fullName,
    studentId: studentId ?? this.studentId,
    school: school ?? this.school,
    course: course ?? this.course,
    company: company ?? this.company,
    supervisor: supervisor ?? this.supervisor,
    requiredHours: requiredHours ?? this.requiredHours,
    startDate: startDate ?? this.startDate,
  );
}
