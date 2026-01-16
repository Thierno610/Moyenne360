import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:moyenne_auto/models/student_grade.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart'; // For sharing/printing
import 'package:share_plus/share_plus.dart';

class ExportService {
  
  /// Generates a PDF file with the class list, grades, and average, then opens the share dialog.
  Future<void> exportToPdf(List<StudentGrade> students, String className, double? classAverage) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Moyennes360', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Classe: $className', style: pw.TextStyle(fontSize: 18)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              context: context,
              headers: ['Rang', 'Nom', 'Nombre de notes', 'Moyenne'],
              data: students.map((student) {
                return [
                  '${student.rank}',
                  student.name,
                  '${student.grades.length}',
                  student.average?.toStringAsFixed(2) ?? '--',
                ];
              }).toList(),
            ),
             pw.SizedBox(height: 20),
             pw.Divider(),
             pw.Align(
               alignment: pw.Alignment.centerRight,
               child: pw.Text(
                 'Moyenne Générale Classe: ${classAverage?.toStringAsFixed(2) ?? '--'}',
                 style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
               ),
             ),
          ];
        },
      ),
    );
    
    // Save/Share
    final bytes = await pdf.save();
    final fileName = 'resultats_${className.replaceAll(' ', '_')}.pdf';

    // Using printing package to share easily (works on mobile/desktop)
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  /// Generates an Excel file and shares it.
  Future<void> exportToExcel(List<StudentGrade> students, String className, double? classAverage) async {
    var excel = Excel.createExcel();
    // Rename default sheet
    String sheetName = 'Resultats';
    excel.rename('Sheet1', sheetName);
    
    Sheet sheet = excel[sheetName];
    
    // Header
    sheet.appendRow([
      TextCellValue('Rang'), 
      TextCellValue('Nom Prénom'), 
      TextCellValue('Moyenne'),
      TextCellValue('Détails Notes')
    ]);
    
    // Rows
    for (var student in students) {
      // Build details string (e.g. "Maths: 15, Philo: 12")
      String details = student.grades.entries.map((e) => '${e.key}: ${e.value}').join(', ');
      
      sheet.appendRow([
        IntCellValue(student.rank),
        TextCellValue(student.name),
        DoubleCellValue(student.average ?? 0.0),
        TextCellValue(details),
      ]);
    }
    
    // Footer
    sheet.appendRow([TextCellValue(''), TextCellValue(''), TextCellValue(''), TextCellValue('')]);
    sheet.appendRow([
      TextCellValue(''), 
      TextCellValue('MOYENNE CLASSE'), 
      DoubleCellValue(classAverage ?? 0.0),
      TextCellValue('')
    ]);
    
    var fileBytes = excel.save();
    if (fileBytes == null) return;
    
    // Save to temp file and share
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/resultats_${className.replaceAll(' ', '_')}.xlsx');
    await file.writeAsBytes(fileBytes);
    
    await Share.shareXFiles(
      [XFile(file.path)], 
      text: 'Résultats classe $className',
    );
  }
}
