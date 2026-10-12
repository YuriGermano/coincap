import 'package:flutter/foundation.dart';
import '../models/asset.dart';

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

  void alternar(String slug, [Asset? asset]) {
    final lower = slug.toLowerCase();
    if (asset != null) {
      _ativosCache[lower] = asset;
    }
    final novo = Set<String>.from(favoritosNotifier.value);
    if (novo.contains(lower)) {
      novo.remove(lower);
    } else {
      novo.add(lower);
    }
    favoritosNotifier.value = novo;
  }

  void adicionar(String slug, [Asset? asset]) {
    final lower = slug.toLowerCase();
    if (asset != null) {
      _ativosCache[lower] = asset;
    }
    if (!favoritosNotifier.value.contains(lower)) {
      final novo = Set<String>.from(favoritosNotifier.value)..add(lower);
      favoritosNotifier.value = novo;
    }
  }

  void remover(String slug) {
    final lower = slug.toLowerCase();
    if (favoritosNotifier.value.contains(lower)) {
      final novo = Set<String>.from(favoritosNotifier.value)..remove(lower);
      favoritosNotifier.value = novo;
    }
  }

  void limpar() {
    favoritosNotifier.value = {};
    _ativosCache.clear();
  }
}
