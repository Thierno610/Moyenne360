import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:moyenne_auto/models/student_grade.dart';

/// Service de gestion de la base de données SQLite locale
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'moyennes.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Table des niveaux (Primaire, Secondaire, etc.)
    await db.execute('''
      CREATE TABLE levels (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL
      )
    ''');

    // Table des matières
    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        level_id INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (level_id) REFERENCES levels(id) ON DELETE CASCADE
      )
    ''');

    // Table des classes/sessions (pour gérer plusieurs classes par niveau)
    await db.execute('''
      CREATE TABLE classes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        level_id INTEGER NOT NULL,
        academic_year TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (level_id) REFERENCES levels(id) ON DELETE CASCADE
      )
    ''');

    // Table des étudiants
    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        class_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE
      )
    ''');

    // Table des notes
    await db.execute('''
      CREATE TABLE grades (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        subject_id INTEGER NOT NULL,
        value REAL NOT NULL,
        exam_type TEXT,
        exam_date TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
        FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE
      )
    ''');

    // Index pour améliorer les performances
    await db.execute('CREATE INDEX idx_student_class ON students(class_id)');
    await db.execute('CREATE INDEX idx_grade_student ON grades(student_id)');
    await db.execute('CREATE INDEX idx_grade_subject ON grades(subject_id)');
    await db.execute('CREATE INDEX idx_subject_level ON subjects(level_id)');

    // Table d'historique des imports
    await db.execute('''
      CREATE TABLE imported_files (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        path TEXT NOT NULL,
        level TEXT NOT NULL,
        student_count INTEGER NOT NULL,
        imported_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Gérer les migrations futures ici
    if (oldVersion < 2) {
       await db.execute('''
        CREATE TABLE IF NOT EXISTS imported_files (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          path TEXT NOT NULL,
          level TEXT NOT NULL,
          student_count INTEGER NOT NULL,
          imported_at TEXT NOT NULL
        )
      ''');
    }
  }

  // ========== CRUD pour l'Historique des Imports ==========
  Future<int> insertImportFile({
    required String name, 
    required String path, 
    required String level, 
    required int count,
  }) async {
    final db = await database;
    return await db.insert('imported_files', {
      'name': name,
      'path': path,
      'level': level,
      'student_count': count,
      'imported_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getImportFiles() async {
    final db = await database;
    return await db.query('imported_files', orderBy: 'imported_at DESC');
  }

  Future<void> deleteImportFile(int id) async {
    final db = await database;
    await db.delete('imported_files', where: 'id = ?', whereArgs: [id]);
  }

  // ========== CRUD pour les Niveaux ==========
  Future<int> insertLevel(String name) async {
    final db = await database;
    return await db.insert(
      'levels',
      {
        'name': name,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllLevels() async {
    final db = await database;
    return await db.query('levels', orderBy: 'name');
  }

  // ========== CRUD pour les Matières ==========
  Future<int> insertSubject(String name, int? levelId) async {
    final db = await database;
    return await db.insert(
      'subjects',
      {
        'name': name,
        'level_id': levelId,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getSubjectsByLevel(int levelId) async {
    final db = await database;
    return await db.query(
      'subjects',
      where: 'level_id = ?',
      whereArgs: [levelId],
      orderBy: 'name',
    );
  }

  // ========== CRUD pour les Classes ==========
  Future<int> insertClass(String name, int levelId, {String? academicYear}) async {
    final db = await database;
    return await db.insert(
      'classes',
      {
        'name': name,
        'level_id': levelId,
        'academic_year': academicYear ?? DateTime.now().year.toString(),
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getClassesByLevel(int levelId) async {
    final db = await database;
    return await db.query(
      'classes',
      where: 'level_id = ?',
      whereArgs: [levelId],
      orderBy: 'name',
    );
  }

  // ========== CRUD pour les Étudiants ==========
  Future<int> insertStudent(String name, int classId) async {
    final db = await database;
    return await db.insert(
      'students',
      {
        'name': name,
        'class_id': classId,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getStudentsByClass(int classId) async {
    final db = await database;
    return await db.query(
      'students',
      where: 'class_id = ?',
      whereArgs: [classId],
      orderBy: 'name',
    );
  }

  // ========== CRUD pour les Notes ==========
  Future<int> insertGrade({
    required int studentId,
    required int subjectId,
    required double value,
    String? examType,
    DateTime? examDate,
  }) async {
    final db = await database;
    return await db.insert(
      'grades',
      {
        'student_id': studentId,
        'subject_id': subjectId,
        'value': value,
        'exam_type': examType,
        'exam_date': examDate?.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getGradesByStudent(int studentId) async {
    final db = await database;
    return await db.query(
      'grades',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'created_at DESC',
    );
  }

  // ========== Requêtes complexes ==========
  
  /// Récupère tous les étudiants avec leurs moyennes pour une classe
  Future<List<StudentGrade>> getStudentsWithAverages(int classId) async {
    final db = await database;
    
    // 1. Récupérer tous les étudiants de la classe
    final studentsData = await db.query(
      'students',
      where: 'class_id = ?',
      whereArgs: [classId],
      orderBy: 'name',
    );

    if (studentsData.isEmpty) return [];

    // 2. Récupérer toutes les notes de la classe en une seule requête
    final gradesData = await db.rawQuery('''
      SELECT g.student_id, s.name as subject_name, g.value
      FROM grades g
      JOIN subjects s ON g.subject_id = s.id
      JOIN students st ON g.student_id = st.id
      WHERE st.class_id = ?
    ''', [classId]);

    // Groupement des notes par étudiant
    final Map<int, Map<String, double>> gradesByStudent = {};
    for (var row in gradesData) {
      final studentId = row['student_id'] as int;
      final subjectName = row['subject_name'] as String;
      final value = row['value'] as double;
      
      gradesByStudent.putIfAbsent(studentId, () => {})[subjectName] = value;
    }

    final List<StudentGrade> result = [];

    for (var studentRow in studentsData) {
      final studentId = studentRow['id'] as int;
      final studentName = studentRow['name'] as String;
      final gradesMap = gradesByStudent[studentId] ?? {};

      final studentGrade = StudentGrade(
        name: studentName,
        grades: gradesMap,
      );

      // Calculer la moyenne
      if (gradesMap.isNotEmpty) {
        final sum = gradesMap.values.reduce((a, b) => a + b);
        studentGrade.average = double.parse((sum / gradesMap.length).toStringAsFixed(2));
      } else {
        studentGrade.average = 0.0;
      }

      result.add(studentGrade);
    }

    // Classer les étudiants
    result.sort((a, b) => (b.average ?? 0).compareTo(a.average ?? 0));
    for (int i = 0; i < result.length; i++) {
      result[i].rank = i + 1;
    }

    return result;
  }

  /// Calcule la moyenne d'une classe
  Future<double> getClassAverage(int classId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT AVG(g.value) as avg
      FROM grades g
      JOIN students s ON g.student_id = s.id
      WHERE s.class_id = ?
    ''', [classId]);

    return (result.first['avg'] as num?)?.toDouble() ?? 0.0;
  }

  /// Sauvegarde une liste d'étudiants avec leurs notes
  Future<void> saveClassGrades(int classId, List<StudentGrade> students) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // 1. Récupérer les infos de la classe et les matières une seule fois
      final classData = await txn.query(
        'classes',
        where: 'id = ?',
        whereArgs: [classId],
      );
      if (classData.isEmpty) return;

      final levelId = classData.first['level_id'] as int;
      final subjects = await txn.query(
        'subjects',
        where: 'level_id = ?',
        whereArgs: [levelId],
      );

      // Créer une map pour un accès rapide aux IDs des matières par nom
      final subjectMap = <String, int>{};
      for (var s in subjects) {
        subjectMap[s['name'] as String] = s['id'] as int;
      }

      for (var student in students) {
        // 2. Insérer ou récupérer l'étudiant
        final existingStudent = await txn.query(
          'students',
          where: 'name = ? AND class_id = ?',
          whereArgs: [student.name, classId],
        );

        int studentId;
        if (existingStudent.isEmpty) {
          studentId = await txn.insert(
            'students',
            {
              'name': student.name,
              'class_id': classId,
              'created_at': DateTime.now().toIso8601String(),
            },
          );
        } else {
          studentId = existingStudent.first['id'] as int;
        }

        // 3. Supprimer les anciennes notes de l'étudiant pour ces matières
        await txn.delete(
          'grades',
          where: 'student_id = ?',
          whereArgs: [studentId],
        );

        // 4. Insérer les nouvelles notes
        for (var entry in student.grades.entries) {
          final subjectId = subjectMap[entry.key];
          if (subjectId != null) {
            await txn.insert(
              'grades',
              {
                'student_id': studentId,
                'subject_id': subjectId,
                'value': entry.value,
                'created_at': DateTime.now().toIso8601String(),
              },
            );
          }
        }
      }
    });
  }

  // ========== Utilitaires ==========
  Future<void> deleteClass(int classId) async {
    final db = await database;
    await db.delete('classes', where: 'id = ?', whereArgs: [classId]);
  }

  Future<void> deleteStudent(int studentId) async {
    final db = await database;
    await db.delete('students', where: 'id = ?', whereArgs: [studentId]);
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('grades');
    await db.delete('students');
    await db.delete('classes');
    await db.delete('subjects');
    await db.delete('levels');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

