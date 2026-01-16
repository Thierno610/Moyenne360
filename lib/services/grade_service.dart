import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:moyenne_auto/models/student_grade.dart';

class GradeService {
  Future<List<StudentGrade>> parseFile(File file) async {
    final extension = file.path.split('.').last.toLowerCase();

    try {
      if (extension == 'csv') {
        return _parseCsv(file);
      } else if (extension == 'xlsx' || extension == 'xls') {
        return _parseExcel(file);
      } else {
        throw Exception('Format de fichier non supporté. Utilisez CSV ou Excel.');
      }
    } catch (e) {
      throw Exception('Erreur lors de la lecture du fichier: $e');
    }
  }

  Future<List<StudentGrade>> _parseCsv(File file) async {
    final input = await file.readAsString();
    
    // Try semicolon first, then comma
    List<List<dynamic>> rows = const CsvToListConverter().convert(input, fieldDelimiter: ';');
    if (rows.isEmpty || (rows.length == 1 && rows.first.length == 1)) {
       // Only one field? might be comma separated
       rows = const CsvToListConverter().convert(input, fieldDelimiter: ',');
    }

    if (rows.isEmpty) return [];

    // Headers: Name, Subj1, Subj2...
    final headers = rows.first.map((e) => e.toString().trim()).toList();
    final List<StudentGrade> students = [];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      // Safe access
      String name = row.isNotEmpty ? row[0].toString() : 'Inconnu';
      Map<String, double> grades = {};

      for (int j = 1; j < row.length; j++) {
        if (j < headers.length) {
          final rawVal = row[j].toString().replaceAll(',', '.').trim();
          double? grade = double.tryParse(rawVal);
          if (grade != null) {
            grades[headers[j]] = grade;
          }
        }
      }

      if (name.isNotEmpty) {
        students.add(StudentGrade(name: name, grades: grades));
      }
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

      // Parse Headers
      final headers = <String>[];
      final firstRow = sheet.rows.first;
      for (var cell in firstRow) {
        headers.add(_getCellValueAsString(cell));
      }

      // Parse Data
      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty) continue;

        String name = _getCellValueAsString(row[0]);
        if (name.isEmpty) continue;

        Map<String, double> grades = {};

        for (int j = 1; j < row.length; j++) {
          if (j < headers.length) {
             double? grade = _getCellValueAsDouble(row[j]);
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
  
  String _getCellValueAsString(dynamic cell) {
    if (cell == null) return '';
    dynamic val;
    try {
      val = cell.value;
    } catch (_) {
      val = cell;
    }
    
    if (val == null) return '';

    if (val is TextCellValue) {
      return val.value.toString(); // Ensure String
    } else if (val is IntCellValue) {
      return val.value.toString();
    } else if (val is DoubleCellValue) {
      return val.value.toString();
    } else if (val is DateCellValue) {
        return val.asDateTimeLocal().toString();
    }
    
    return val.toString();
  }

  double? _getCellValueAsDouble(dynamic cell) {
    if (cell == null) return null;
    dynamic val;
    try {
       val = cell.value;
    } catch (_) {
       val = cell;
    }
    
    if (val == null) return null;

    if (val is DoubleCellValue) {
      return val.value;
    } else if (val is IntCellValue) {
      return val.value.toDouble();
    } else if (val is TextCellValue) {
       return double.tryParse(val.value.toString().replaceAll(',', '.').trim());
    } 
    
    return double.tryParse(val.toString().replaceAll(',', '.').trim());
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
