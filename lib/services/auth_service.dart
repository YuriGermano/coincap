import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AuthService {
  static Database? _db;

  static String? _emailSessao;

  static String? get emailAtual => _emailSessao;

  static Future<Database> get _banco async {
    if (_db != null) return _db!;
    final caminho = join(await getDatabasesPath(), 'coincap_auth.db');
    _db = await openDatabase(
      caminho,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE usuarios (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            senha_hash TEXT NOT NULL,
            criado_em TEXT NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  static String _hash(String senha) {
    final bytes = utf8.encode(senha);
    return sha256.convert(bytes).toString();
  }

  static Future<Map<String, dynamic>?> usuarioAtual() async {
    if (_emailSessao == null) return null;
    final db = await _banco;
    final res = await db.query(
      'usuarios',
      where: 'email = ?',
      whereArgs: [_emailSessao],
      limit: 1,
    );
    return res.isNotEmpty ? res.first : null;
  }

  static void logout() {
    _emailSessao = null;
  }

  static Future<String?> cadastrar({
    required String nome,
    required String email,
    required String senha,
  }) async {
    final db = await _banco;
    final emailLower = email.trim().toLowerCase();

    final existente = await db.query(
      'usuarios',
      where: 'email = ?',
      whereArgs: [emailLower],
      limit: 1,
    );

    if (existente.isNotEmpty) {
      return 'Este e-mail já está cadastrado';
    }

    await db.insert('usuarios', {
      'nome': nome.trim(),
      'email': emailLower,
      'senha_hash': _hash(senha),
      'criado_em': DateTime.now().toIso8601String(),
    });

    _emailSessao = emailLower;
    return null;
  }

  static Future<String?> login({
    required String email,
    required String senha,
  }) async {
    final db = await _banco;
    final emailLower = email.trim().toLowerCase();

    final resultado = await db.query(
      'usuarios',
      where: 'email = ? AND senha_hash = ?',
      whereArgs: [emailLower, _hash(senha)],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return 'E-mail ou senha incorretos';
    }

    _emailSessao = emailLower;
    return null;
  }
}
