import 'package:moyenne_auto/services/database_service.dart';
import 'package:moyenne_auto/models/student_grade.dart';

/// Exemple d'utilisation de la base de données
/// Ce fichier montre comment utiliser DatabaseService dans votre application
class DatabaseExample {
  final _db = DatabaseService();

  /// Exemple: Initialiser la base de données avec des données de base
  Future<void> initializeDatabase() async {
    // Créer des niveaux
    await _db.insertLevel('Primaire');
    await _db.insertLevel('Secondaire');
    await _db.insertLevel('Lycée');

    // Récupérer l'ID du niveau Primaire
    final levels = await _db.getAllLevels();
    final primaryLevelId = levels.firstWhere((l) => l['name'] == 'Primaire')['id'] as int;

    // Créer des matières pour le Primaire
    await _db.insertSubject('Mathématiques', primaryLevelId);
    await _db.insertSubject('Français', primaryLevelId);
    await _db.insertSubject('Sciences', primaryLevelId);

    // Créer une classe
    final classId = await _db.insertClass('6ème A', primaryLevelId, academicYear: '2024-2025');

    print('Base de données initialisée avec succès!');
  }

  /// Exemple: Sauvegarder des notes d'étudiants
  Future<void> saveStudentGrades() async {
    // Récupérer une classe (exemple)
    final levels = await _db.getAllLevels();
    final primaryLevelId = levels.firstWhere((l) => l['name'] == 'Primaire')['id'] as int;
    final classes = await _db.getClassesByLevel(primaryLevelId);
    
    if (classes.isEmpty) {
      print('Aucune classe trouvée. Créez d\'abord une classe.');
      return;
    }

    final classId = classes.first['id'] as int;

    // Créer des étudiants avec leurs notes
    final students = [
      StudentGrade(
        name: 'Jean Dupont',
        grades: {
          'Mathématiques': 15.5,
          'Français': 12.0,
          'Sciences': 14.0,
        },
      ),
      StudentGrade(
        name: 'Marie Martin',
        grades: {
          'Mathématiques': 18.0,
          'Français': 16.5,
          'Sciences': 17.0,
        },
      ),
    ];

    // Sauvegarder dans la base de données
    await _db.saveClassGrades(classId, students);
    print('${students.length} étudiants sauvegardés avec succès!');
  }

  /// Exemple: Récupérer les étudiants avec leurs moyennes
  Future<void> loadStudentGrades() async {
    final levels = await _db.getAllLevels();
    final primaryLevelId = levels.firstWhere((l) => l['name'] == 'Primaire')['id'] as int;
    final classes = await _db.getClassesByLevel(primaryLevelId);
    
    if (classes.isEmpty) return;

    final classId = classes.first['id'] as int;

    // Récupérer les étudiants avec leurs moyennes
    final students = await _db.getStudentsWithAverages(classId);

    print('Étudiants récupérés:');
    for (var student in students) {
      print('${student.rank}. ${student.name} - Moyenne: ${student.average}');
      print('   Notes: ${student.grades}');
    }

    // Calculer la moyenne de la classe
    final classAverage = await _db.getClassAverage(classId);
    print('Moyenne de la classe: $classAverage');
  }

  /// Exemple: Recherche et filtrage
  Future<void> searchExamples() async {
    final db = await _db.database;

    // Rechercher les étudiants avec une moyenne supérieure à 15
    final topStudents = await db.rawQuery('''
      SELECT s.name, AVG(g.value) as avg
      FROM students s
      JOIN grades g ON s.id = g.student_id
      GROUP BY s.id
      HAVING avg > 15
      ORDER BY avg DESC
    ''');

    print('Étudiants avec moyenne > 15:');
    for (var student in topStudents) {
      print('${student['name']}: ${student['avg']}');
    }
  }
}

