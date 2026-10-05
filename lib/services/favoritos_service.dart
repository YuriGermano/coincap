import 'package:flutter/foundation.dart';

class FavoritosService {
  FavoritosService._();
  static final FavoritosService instance = FavoritosService._();

  // Conjunto inicial com moedas populares para já abrir a tela de Favoritos preenchida conforme o wireframe
  final ValueNotifier<Set<String>> favoritosNotifier = ValueNotifier<Set<String>>({
    'bitcoin',
    'ethereum',
    'solana',
    'dogecoin',
  });

  Set<String> get favoritos => favoritosNotifier.value;

  bool isFavorito(String slug) {
    return favoritosNotifier.value.contains(slug.toLowerCase());
  }

  void alternar(String slug) {
    final lower = slug.toLowerCase();
    final novo = Set<String>.from(favoritosNotifier.value);
    if (novo.contains(lower)) {
      novo.remove(lower);
    } else {
      novo.add(lower);
    }
    favoritosNotifier.value = novo;
  }

  void adicionar(String slug) {
    final lower = slug.toLowerCase();
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
}
