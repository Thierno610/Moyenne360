class StudentGrade {
  final String name;
  final Map<String, double> grades; // Key: Subject, Value: Grade
  double? average;
  int rank;

  StudentGrade({
    required this.name,
    required this.grades,
    this.average,
    this.rank = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'grades': grades,
      'average': average,
      'rank': rank,
    };
  }

  factory StudentGrade.fromJson(Map<String, dynamic> json) {
    return StudentGrade(
      name: json['name'],
      grades: Map<String, double>.from(json['grades']),
      average: json['average'],
      rank: json['rank'] ?? 0,
    );
  }
}
