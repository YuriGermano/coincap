import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/asset.dart';
import 'auth_service.dart';

class FavoritosService {
  FavoritosService._();
  static final FavoritosService instance = FavoritosService._();

  // Inicia vazio — sem moedas pré-favoritadas por padrão
  final ValueNotifier<Set<String>> favoritosNotifier = ValueNotifier<Set<String>>({});

  // Cache em memória para os objetos Asset das moedas favoritadas
  final Map<String, Asset> _ativosCache = {};

  Set<String> get favoritos => favoritosNotifier.value;
  Map<String, Asset> get ativosCache => _ativosCache;

  void salvarAtivo(Asset asset) {
    _ativosCache[asset.slug.toLowerCase()] = asset;
  }

  bool isFavorito(String slug) {
    return favoritosNotifier.value.contains(slug.toLowerCase());
  }

  /// Carrega os favoritos salvos do banco de dados para o usuário informado
  Future<void> carregarFavoritosDoUsuario(int usuarioId) async {
    try {
      final db = await AuthService.banco;
      final registros = await db.query(
        'favoritos',
        columns: ['slug'],
        where: 'usuario_id = ?',
        whereArgs: [usuarioId],
        orderBy: 'id ASC',
      );

      final slugs = registros
          .map((r) => (r['slug'] as String).toLowerCase())
          .toSet();

      favoritosNotifier.value = slugs;
    } catch (_) {}
  }

  /// Recarrega os favoritos para o usuário atualmente logado
  Future<void> carregarFavoritos() async {
    final uid = AuthService.usuarioIdAtual;
    if (uid != null) {
      await carregarFavoritosDoUsuario(uid);
    }
  }

  /// Alterna o status de favorito de uma moeda (adiciona ou remove), persistindo no SQLite para o usuário atual
  Future<void> alternar(String slug, [Asset? asset]) async {
    final lower = slug.toLowerCase();
    if (asset != null) {
      _ativosCache[lower] = asset;
    }
    final novo = Set<String>.from(favoritosNotifier.value);
    final jaFavorito = novo.contains(lower);
    if (jaFavorito) {
      novo.remove(lower);
    } else {
      novo.add(lower);
    }
    favoritosNotifier.value = novo;

    final usuarioId = AuthService.usuarioIdAtual;
    if (usuarioId != null) {
      try {
        final db = await AuthService.banco;
        if (jaFavorito) {
          await db.delete(
            'favoritos',
            where: 'usuario_id = ? AND slug = ?',
            whereArgs: [usuarioId, lower],
          );
        } else {
          await db.insert(
            'favoritos',
            {
              'usuario_id': usuarioId,
              'slug': lower,
              'criado_em': DateTime.now().toIso8601String(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      } catch (_) {}
    }
  }

  /// Adiciona uma moeda aos favoritos e salva no SQLite para o usuário atual
  Future<void> adicionar(String slug, [Asset? asset]) async {
    final lower = slug.toLowerCase();
    if (asset != null) {
      _ativosCache[lower] = asset;
    }
    if (!favoritosNotifier.value.contains(lower)) {
      final novo = Set<String>.from(favoritosNotifier.value)..add(lower);
      favoritosNotifier.value = novo;

      final usuarioId = AuthService.usuarioIdAtual;
      if (usuarioId != null) {
        try {
          final db = await AuthService.banco;
          await db.insert(
            'favoritos',
            {
              'usuario_id': usuarioId,
              'slug': lower,
              'criado_em': DateTime.now().toIso8601String(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } catch (_) {}
      }
    }
  }

  /// Remove uma moeda dos favoritos e deleta do SQLite para o usuário atual
  Future<void> remover(String slug) async {
    final lower = slug.toLowerCase();
    if (favoritosNotifier.value.contains(lower)) {
      final novo = Set<String>.from(favoritosNotifier.value)..remove(lower);
      favoritosNotifier.value = novo;

      final usuarioId = AuthService.usuarioIdAtual;
      if (usuarioId != null) {
        try {
          final db = await AuthService.banco;
          await db.delete(
            'favoritos',
            where: 'usuario_id = ? AND slug = ?',
            whereArgs: [usuarioId, lower],
          );
        } catch (_) {}
      }
    }
  }

  /// Limpa os favoritos em memória (ex.: ao fazer logout)
  void limpar() {
    favoritosNotifier.value = {};
    _ativosCache.clear();
  }
}
