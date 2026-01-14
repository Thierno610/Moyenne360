import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:moyenne_auto/models/student_grade.dart';

class GradeService {
  Future<List<StudentGrade>> parseFile(File file) async {
    final extension = file.path.split('.').last.toLowerCase();

    if (extension == 'csv') {
      return _parseCsv(file);
    } else if (extension == 'xlsx' || extension == 'xls') {
      return _parseExcel(file);
    } else {
      throw Exception('Format de fichier non supporté. Utilisez CSV ou Excel.');
    }
  }

  Future<List<StudentGrade>> _parseCsv(File file) async {
    final input = await file.readAsString();
    final rows = const CsvToListConverter().convert(input, fieldDelimiter: ';');

    if (rows.isEmpty) return [];

    // Assume generic format: Name, Subject1, Subject2, ...
    final headers = rows.first.map((e) => e.toString()).toList();
    final List<StudentGrade> students = [];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      String name = row[0].toString();
      Map<String, double> grades = {};

      for (int j = 1; j < row.length; j++) {
        if (j < headers.length) {
          double? grade = double.tryParse(row[j].toString().replaceAll(',', '.'));
          if (grade != null) {
            grades[headers[j]] = grade;
          }
        }
      }

      students.add(StudentGrade(name: name, grades: grades));
    }

    return students;
  }

  Future<List<StudentGrade>> _parseExcel(File file) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final List<StudentGrade> students = [];

    for (var table in excel.tables.keys) {
      final sheet = excel.tables[table];
      if (sheet == null) continue;

      if (sheet.maxRows == 0) continue;

      // Assume first row is header
      final headers = sheet.rows.first.map((e) => e?.value.toString() ?? '').toList();

      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
         if (row.isEmpty) continue;

        String name = row[0]?.value.toString() ?? 'Inconnu';
        Map<String, double> grades = {};

        for (int j = 1; j < row.length; j++) {
          if (j < headers.length) {
             final cellValue = row[j]?.value;
             double? grade;
             
             if (cellValue != null) {
               // Safely try to extract the value from the CellValue wrapper
               dynamic val = cellValue;
               try {
                 // Try to access .value property (common in excel package versions)
                 val = (cellValue as dynamic).value;
               } catch (_) {
                 // Fallback if .value doesn't exist
                 val = cellValue;
               }
               
               if (val is double) {
                 grade = val;
               } else if (val is int) {
                 grade = val.toDouble();
               } else {
                 final s = val.toString();
                 grade = double.tryParse(s.replaceAll(',', '.'));
               }
             }

            if (grade != null) {
              grades[headers[j]] = grade;
            }
          }
        }
        students.add(StudentGrade(name: name, grades: grades));
      }
    }
    return students;
  }

  void calculateAverages(List<StudentGrade> students) {
    for (var student in students) {
      if (student.grades.isNotEmpty) {
        double sum = student.grades.values.reduce((a, b) => a + b);
        student.average = double.parse((sum / student.grades.length).toStringAsFixed(2));
      } else {
        student.average = 0.0;
      }
    }
  }

  void rankStudents(List<StudentGrade> students) {
    students.sort((a, b) => (b.average ?? 0).compareTo(a.average ?? 0));
    for (int i = 0; i < students.length; i++) {
      students[i].rank = i + 1;
    }
  }

  double calculateClassAverage(List<StudentGrade> students) {
    if (students.isEmpty) return 0.0;
    
    double totalSum = 0.0;
    int count = 0;

    for (var student in students) {
      if (student.average != null) {
        totalSum += student.average!;
        count++;
      }
    }

    return count > 0 ? double.parse((totalSum / count).toStringAsFixed(2)) : 0.0;
  }
}
