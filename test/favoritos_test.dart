import 'package:flutter_test/flutter_test.dart';
import 'package:coincap/models/asset.dart';
import 'package:coincap/services/favoritos_service.dart';

void main() {
  group('FavoritosService Testes', () {
    setUp(() {
      FavoritosService.instance.limpar();
    });

    test('Inicia com conjunto de favoritos vazio', () {
      expect(FavoritosService.instance.favoritos, isEmpty);
      expect(FavoritosService.instance.isFavorito('bitcoin'), isFalse);
    });

    test('Adiciona ativo aos favoritos com reatividade no ValueNotifier', () {
      final btc = Asset(
        slug: 'bitcoin',
        symbol: 'BTC',
        name: 'Bitcoin',
        price: 90000.0,
        historico: [],
      );

      FavoritosService.instance.adicionar('bitcoin', btc);

      expect(FavoritosService.instance.isFavorito('bitcoin'), isTrue);
      expect(FavoritosService.instance.favoritos.contains('bitcoin'), isTrue);
      expect(FavoritosService.instance.ativosCache['bitcoin'], isNotNull);
      expect(FavoritosService.instance.ativosCache['bitcoin']!.name, 'Bitcoin');
    });

    test('Alternar (toggle) adiciona e remove ativo', () {
      expect(FavoritosService.instance.isFavorito('ethereum'), isFalse);

      FavoritosService.instance.alternar('ethereum');
      expect(FavoritosService.instance.isFavorito('ethereum'), isTrue);

      FavoritosService.instance.alternar('ethereum');
      expect(FavoritosService.instance.isFavorito('ethereum'), isFalse);
    });

    test('Remover exclui ativo dos favoritos', () {
      FavoritosService.instance.adicionar('solana');
      expect(FavoritosService.instance.isFavorito('solana'), isTrue);

      FavoritosService.instance.remover('solana');
      expect(FavoritosService.instance.isFavorito('solana'), isFalse);
    });

    test('Limpar remove todos os favoritos e limpa cache de ativos', () {
      FavoritosService.instance.adicionar('bitcoin');
      FavoritosService.instance.adicionar('cardano');
      expect(FavoritosService.instance.favoritos.length, 2);

      FavoritosService.instance.limpar();
      expect(FavoritosService.instance.favoritos, isEmpty);
      expect(FavoritosService.instance.ativosCache, isEmpty);
    });
  });
}
