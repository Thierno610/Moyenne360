import 'package:flutter_test/flutter_test.dart';
import 'package:moyenne_auto/models/student_grade.dart';
import 'package:moyenne_auto/services/grade_service.dart';

void main() {
  group('GradeService Tests', () {
    final service = GradeService();

    test('calculateAverages computes correct average', () {
      final student = StudentGrade(
        name: 'Test Student',
        grades: {'Math': 10.0, 'Phys': 20.0},
      );
      
      service.calculateAverages([student]);
      
      expect(student.average, 15.0);
    });

    test('rankStudents grades correctly', () {
      final s1 = StudentGrade(name: 'S1', grades: {}, average: 10.0);
      final s2 = StudentGrade(name: 'S2', grades: {}, average: 15.0);
      final s3 = StudentGrade(name: 'S3', grades: {}, average: 12.0);

      final students = [s1, s2, s3];
      service.rankStudents(students);

      expect(students[0].name, 'S2'); // 15.0
      expect(students[1].name, 'S3'); // 12.0
      expect(students[2].name, 'S1'); // 10.0
      
      expect(students[0].rank, 1);
      expect(students[1].rank, 2);
      expect(students[2].rank, 3);
    });

    test('calculateClassAverage computes global average', () {
      final s1 = StudentGrade(name: 'S1', grades: {}, average: 10.0);
      final s2 = StudentGrade(name: 'S2', grades: {}, average: 20.0);

      final avg = service.calculateClassAverage([s1, s2]);
      expect(avg, 15.0);
    });
  });
}
