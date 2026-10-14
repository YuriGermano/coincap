import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'favoritos_service.dart';

class AuthService {
  static Database? _db;

  static String? _emailSessao;
  static int? _usuarioIdSessao;

  static String? get emailAtual => _emailSessao;
  static int? get usuarioIdAtual => _usuarioIdSessao;

  static Future<Database> get banco => _banco;

  static Future<Database> get _banco async {
    if (_db != null) return _db!;
    final caminho = join(await getDatabasesPath(), 'coincap_auth.db');
    _db = await openDatabase(
      caminho,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
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
        await db.execute('''
          CREATE TABLE favoritos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            usuario_id INTEGER NOT NULL,
            slug TEXT NOT NULL,
            criado_em TEXT NOT NULL,
            FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE,
            UNIQUE(usuario_id, slug)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS favoritos (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              usuario_id INTEGER NOT NULL,
              slug TEXT NOT NULL,
              criado_em TEXT NOT NULL,
              FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE,
              UNIQUE(usuario_id, slug)
            )
          ''');
        }
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
    if (res.isNotEmpty) {
      _usuarioIdSessao = res.first['id'] as int?;
      return res.first;
    }
    return null;
  }

  static void logout() {
    _emailSessao = null;
    _usuarioIdSessao = null;
    FavoritosService.instance.limpar();
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

    final id = await db.insert('usuarios', {
      'nome': nome.trim(),
      'email': emailLower,
      'senha_hash': _hash(senha),
      'criado_em': DateTime.now().toIso8601String(),
    });

    _emailSessao = emailLower;
    _usuarioIdSessao = id;
    await FavoritosService.instance.carregarFavoritosDoUsuario(id);
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
    _usuarioIdSessao = resultado.first['id'] as int?;
    if (_usuarioIdSessao != null) {
      await FavoritosService.instance.carregarFavoritosDoUsuario(_usuarioIdSessao!);
    }
    return null;
  }

  /// Método utilitário para testes automatizados
  static void definirSessaoTeste({required int id, required String email}) {
    _usuarioIdSessao = id;
    _emailSessao = email.trim().toLowerCase();
  }
}
