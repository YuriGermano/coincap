import 'package:flutter_test/flutter_test.dart';
import 'package:coincap/models/candlestick.dart';
import 'package:coincap/models/compact_history.dart';
import 'package:coincap/services/coincap_service.dart';

void main() {
  group('Testes de Modelos e Serviços CoinCap', () {
    test('Modelo Candlestick parsing', () {
      final json = {
        'time': 1672531199000,
        'open': '85000.5',
        'high': 86000.0,
        'low': 84000.0,
        'close': '85500.2',
      };
      final candle = Candlestick.fromJson(json);
      expect(candle.open, 85000.5);
      expect(candle.high, 86000.0);
      expect(candle.low, 84000.0);
      expect(candle.close, 85500.2);
      expect(candle.time.millisecondsSinceEpoch, 1672531199000);
    });

    test('Modelo CompactHistory parsing com CSV', () {
      final json = {
        'data': {
          'slug': 'bitcoin',
          'startTime': 1672500000000,
          'endTime': 1672600000000,
          'intervalMinutes': 60,
          'dataPoints': 2,
          'history': '1672500000000,85000.0\n1672503600000,85500.0',
        }
      };
      final history = CompactHistory.fromJson(json);
      expect(history.slug, 'bitcoin');
      expect(history.intervalMinutes, 60);
      expect(history.points.length, 2);
      expect(history.points[0].price, 85000.0);
      expect(history.points[1].price, 85500.0);
    });

    test('buscarTaxaIndividual e buscarTaxa retornam objeto Rate válido', () async {
      final taxa = await CoinCapService.buscarTaxaIndividual('bitcoin');
      expect(taxa.id, 'bitcoin');
      expect(taxa.symbol, 'BTC');
      expect(taxa.rateUsd, greaterThan(0));

      final taxaAlias = await CoinCapService.buscarTaxa('bitcoin');
      expect(taxaAlias.symbol, 'BTC');
    });

    test('buscarMercadosComFiltro filtra por pares e abreviações (ex.: BTC/USDT)', () async {
      final mercados = await CoinCapService.buscarMercadosComFiltro(
        baseSymbol: 'BTC',
        quoteSymbol: 'USDT',
      );
      expect(mercados, isNotEmpty);
      for (final m in mercados) {
        expect(m.baseSymbol.toUpperCase(), 'BTC');
        expect(m.quoteSymbol.toUpperCase(), 'USDT');
      }
    });

    test('buscarVelas e buscarCandlesticks retornam velas válidas', () async {
      final velas = await CoinCapService.buscarVelas('bitcoin');
      expect(velas, isNotEmpty);
      expect(velas.first.high, greaterThanOrEqualTo(velas.first.low));

      final velasAlias = await CoinCapService.buscarCandlesticks('bitcoin');
      expect(velasAlias, isNotEmpty);
    });
  });
}
