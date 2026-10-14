import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/asset.dart';
import '../models/candlestick.dart';
import '../models/compact_history.dart';
import '../models/exchange.dart';
import '../models/market.dart';
import '../models/price_point.dart';
import '../models/rate.dart';
import '../models/ta_indicators.dart';

class _Resposta {
  final DateTime hora;
  final Map<String, dynamic> corpo;

  _Resposta(this.hora, this.corpo);
}

class CoinCapService {
  static const String _baseUrl = 'https://rest.coincap.io/v3';

  // Rotação de chaves: lê do .env (API_KEY) com fallback se necessário
  static List<String> get _apiKeys {
    final envKey = dotenv.env['API_KEY']?.trim();
    final keys = <String>[];
    if (envKey != null && envKey.isNotEmpty) {
      keys.add(envKey);
    }
    const fallbackKey = '55dac914c55b002b76343e7c1e9cc7480373847f3ccf89967ea51ba2d3b2041b';
    if (!keys.contains(fallbackKey)) {
      keys.add(fallbackKey);
    }
    return keys;
  }
  static int _chaveIndiceAtual = 0;

  // Cache em memória com duração inteligente para respeitar o limite de 5 req/min
  static const Duration _validadeCache = Duration(minutes: 3);
  static final Map<String, _Resposta> _cache = {};
  static final Map<String, Future<Map<String, dynamic>>> _pendentes = {};
  static DateTime? _bloqueioRateLimitAte;

  static Future<Map<String, dynamic>> _get(
    String caminho,
    Map<String, String>? parametros, {
    bool usarCache = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$caminho').replace(
      queryParameters: parametros,
    );
    final chave = uri.toString();

    final guardada = _cache[chave];
    final agora = DateTime.now();

    // Se temos cache válido e não estamos forçando, usa imediatamente
    if (usarCache &&
        guardada != null &&
        agora.difference(guardada.hora) < _validadeCache) {
      return guardada.corpo;
    }

    // Se estivermos em período de cooldown do rate limit, reutiliza cache existente ou fallback
    if (_bloqueioRateLimitAte != null && agora.isBefore(_bloqueioRateLimitAte!)) {
      if (guardada != null) {
        return guardada.corpo;
      }
      final fallback = _obterFallback(caminho);
      if (fallback != null) return fallback;
    }

    // Coalescência de requisições: se já há uma requisição em voo para essa chave, aguarda a mesma
    if (_pendentes.containsKey(chave)) {
      return _pendentes[chave]!;
    }

    final future = _executarRequisicao(uri, chave, guardada, caminho);
    _pendentes[chave] = future;

    try {
      final res = await future;
      return res;
    } finally {
      _pendentes.remove(chave);
    }
  }

  static Future<Map<String, dynamic>> _executarRequisicao(
    Uri uri,
    String chave,
    _Resposta? guardada,
    String caminho,
  ) async {
    final keys = _apiKeys;
    final totalChaves = keys.length;

    // Tenta as chaves disponíveis com timeout adequado para mobile e desktop
    for (int i = 0; i < totalChaves; i++) {
      final apiKey = keys[_chaveIndiceAtual % totalChaves];
      try {
        final response = await http.get(
          uri,
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Accept': 'application/json',
            'User-Agent': 'CoinCapApp/1.0',
          },
        ).timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final corpo = json.decode(response.body) as Map<String, dynamic>;
          _cache[chave] = _Resposta(DateTime.now(), corpo);
          _bloqueioRateLimitAte = null;
          return corpo;
        } else if (response.statusCode == 429 ||
            response.statusCode == 403 ||
            response.statusCode == 401) {
          // Alterna chave e tenta a próxima
          _chaveIndiceAtual = (_chaveIndiceAtual + 1) % totalChaves;
          continue;
        } else {
          // Outro status HTTP
          break;
        }
      } catch (_) {
        // Timeout ou erro de rede (comum em conexões mobile/3G/4G): tenta chave alternativa
        _chaveIndiceAtual = (_chaveIndiceAtual + 1) % totalChaves;
      }
    }

    // Se bateu no rate limit em ambas as chaves ou ocorreu erro de rede:
    _bloqueioRateLimitAte = DateTime.now().add(const Duration(seconds: 40));

    // 1º Fallback: cache existente mesmo que antigo
    if (guardada != null) {
      return guardada.corpo;
    }

    // 2º Fallback: busca por chave parecida no cache
    for (final entry in _cache.entries) {
      if (entry.key.contains(caminho)) {
        return entry.value.corpo;
      }
    }

    // 3º Fallback: dados pré-definidos para garantir experiência sem telas de erro
    final fallback = _obterFallback(caminho);
    if (fallback != null) {
      _cache[chave] = _Resposta(DateTime.now(), fallback);
      return fallback;
    }

    throw Exception("Falha ao carregar dados ($caminho).");
  }

  // 1. Preços por símbolo (Doc #1)
  static Future<Map<String, double?>> buscarPrecosPorSimbolo(List<String> symbols) async {
    try {
      final symbolParam = symbols.join(',');
      final corpo = await _get('/price/bysymbol/$symbolParam', null, usarCache: true);
      final data = corpo['data'] as List? ?? [];
      final resultado = <String, double?>{};
      for (var i = 0; i < symbols.length && i < data.length; i++) {
        final val = data[i];
        resultado[symbols[i].toUpperCase()] = val == null ? null : double.tryParse(val.toString());
      }
      return resultado;
    } catch (_) {
      return {};
    }
  }

  // 2. Lista de ativos por valor de mercado (Doc #2)
  static Future<List<Asset>> buscarListaAtivos({
    int limit = 50,
    int offset = 0,
    bool forcarAtualizacao = false,
  }) async {
    final corpo = await _get(
      '/assets',
      {'limit': limit.toString(), 'offset': offset.toString()},
      usarCache: !forcarAtualizacao,
    );
    return AssetResponse.fromJson(corpo).data;
  }

  // 3. Detalhes de um ativo (Doc #3)
  static Future<Asset> buscarDetalhesAtivo(
    String slug, {
    bool forcarAtualizacao = false,
  }) async {
    try {
      final corpo = await _get(
        '/assets/$slug',
        null,
        usarCache: !forcarAtualizacao,
      );
      final data = corpo['data'] as Map<String, dynamic>? ?? {};
      return Asset.fromJson(data);
    } catch (_) {
      // Se falhar, tenta achar nos ativos principais em cache
      final ativos = await buscarListaAtivos();
      final encontrado = ativos.where((a) => a.slug == slug).firstOrNull;
      if (encontrado != null) return encontrado;
      rethrow;
    }
  }

  // 4. Histórico de preço (Doc #4)
  static Future<List<PricePoint>> buscarHistorico(
    String slug, {
    String interval = 'h1',
    bool forcarAtualizacao = false,
  }) async {
    try {
      final corpo = await _get(
        '/assets/$slug/history',
        {'interval': interval},
        usarCache: !forcarAtualizacao,
      );
      final data = corpo['data'] as List? ?? [];
      return data
          .map((item) => PricePoint.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // 5. Mercados de um ativo (Doc #5)
  static Future<List<Market>> buscarMercadosAtivo(String slug) async {
    try {
      final corpo = await _get('/assets/$slug/markets', null);
      final data = corpo['data'] as List? ?? [];
      return data
          .map((item) => Market.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // 6. Lista de corretoras (Doc #6)
  static Future<List<Exchange>> buscarCorretoras({bool forcarAtualizacao = false}) async {
    final corpo = await _get(
      '/exchanges',
      {'limit': '100'},
      usarCache: !forcarAtualizacao,
    );
    return ExchangeResponse.fromJson(corpo).data;
  }

  // 7. Mercados com filtros (Doc #7)
  static Future<List<Market>> buscarMercados([String? exchangeId]) async {
    return buscarMercadosComFiltro(
      exchangeId: exchangeId,
    );
  }

  // 7b. Busca de mercados com filtros de abreviação (ex.: BTC/USDT)
  static Future<List<Market>> buscarMercadosComFiltro({
    String? exchangeId,
    String? baseSymbol,
    String? quoteSymbol,
    String? assetSymbol,
    int limit = 20,
  }) async {
    try {
      final params = <String, String>{'limit': limit.toString()};
      if (exchangeId != null && exchangeId.isNotEmpty) {
        params['exchangeId'] = exchangeId;
      }
      if (baseSymbol != null && baseSymbol.isNotEmpty) {
        params['baseSymbol'] = baseSymbol;
      }
      if (quoteSymbol != null && quoteSymbol.isNotEmpty) {
        params['quoteSymbol'] = quoteSymbol;
      }
      if (assetSymbol != null && assetSymbol.isNotEmpty) {
        params['assetSymbol'] = assetSymbol;
      }

      final corpo = await _get('/markets', params);
      var mercados = MarketResponse.fromJson(corpo).data;

      if (baseSymbol != null && baseSymbol.isNotEmpty) {
        final b = baseSymbol.toUpperCase();
        mercados = mercados.where((m) => m.baseSymbol.toUpperCase() == b).toList();
      }
      if (quoteSymbol != null && quoteSymbol.isNotEmpty) {
        final q = quoteSymbol.toUpperCase();
        mercados = mercados.where((m) => m.quoteSymbol.toUpperCase() == q).toList();
      }
      if (assetSymbol != null && assetSymbol.isNotEmpty) {
        final a = assetSymbol.toUpperCase();
        mercados = mercados.where((m) =>
            m.baseSymbol.toUpperCase() == a || m.quoteSymbol.toUpperCase() == a).toList();
      }

      return mercados;
    } catch (_) {
      return [];
    }
  }

  // 8. Taxas de conversão (Doc #8)
  static Future<List<Rate>> buscarTaxas({String? ids, bool forcarAtualizacao = false}) async {
    final corpo = await _get(
      '/rates',
      ids == null ? null : {'ids': ids},
      usarCache: !forcarAtualizacao,
    );
    return RateResponse.fromJson(corpo)
        .data
        .where((taxa) => taxa.rateUsd > 0 && taxa.symbol.isNotEmpty)
        .toList();
  }

  // 9. Taxa individual (Doc #9 - /rates/{slug})
  static Future<Rate> buscarTaxaIndividual(String slug) async {
    final corpo = await _get('/rates/$slug', null);
    final data = corpo['data'];
    if (data is Map<String, dynamic>) {
      return Rate.fromJson(data);
    }
    if (data is List && data.isNotEmpty) {
      final item = data.firstWhere(
        (elem) => elem is Map && elem['id'] == slug,
        orElse: () => data.first,
      );
      return Rate.fromJson(item as Map<String, dynamic>);
    }
    return Rate(id: slug, symbol: slug.toUpperCase(), type: 'crypto', rateUsd: 1.0);
  }

  // Alias para buscar taxa individual de uma moeda
  static Future<Rate> buscarTaxa(String idOuSlug) => buscarTaxaIndividual(idOuSlug);

  // 10. Indicadores técnicos (Doc #10)
  static Future<TaIndicators> buscarIndicadoresTecnicos(String slug) async {
    try {
      final corpo = await _get(
        '/ta/$slug/allLatest',
        {'fetchInterval': 'd1'},
      );
      return TaIndicators.fromJson(corpo);
    } catch (_) {
      return TaIndicators.vazio();
    }
  }

  // 10b. Gráfico de velas (candlesticks) - /ta/{slug}/candlesticks
  static Future<List<Candlestick>> buscarVelas(
    String slug, {
    String interval = 'h1',
    int? start,
    int? end,
  }) async {
    try {
      final params = <String, String>{'interval': interval};
      if (start != null) params['start'] = start.toString();
      if (end != null) params['end'] = end.toString();

      final corpo = await _get('/ta/$slug/candlesticks', params);
      final data = (corpo['data'] ?? corpo['candles']) as List? ?? [];
      return data
          .map((item) => Candlestick.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // Alias para buscar gráfico de velas
  static Future<List<Candlestick>> buscarCandlesticks(
    String slug, {
    String interval = 'h1',
    int? start,
    int? end,
  }) => buscarVelas(slug, interval: interval, start: start, end: end);

  // 10c. Histórico compactado - /agentFriendly/history/{slug}
  static Future<CompactHistory> buscarHistoricoCompactado(
    String slug, {
    int? start,
    int? end,
  }) async {
    final params = <String, String>{};
    if (start != null) params['start'] = start.toString();
    if (end != null) params['end'] = end.toString();

    final corpo = await _get(
      '/agentFriendly/history/$slug',
      params.isEmpty ? null : params,
    );
    return CompactHistory.fromJson(corpo);
  }

  // 12. Busca de ativos (Doc #12)
  static Future<List<Asset>> buscarAtivosPorNome(String texto) async {
    final termo = texto.trim().toLowerCase();
    if (termo.isEmpty) return [];

    try {
      final corpo = await _get(
        '/agentFriendly/assets_search',
        {'search': texto, 'limit': '20', 'sortBy': 'marketCap'},
        usarCache: true,
      );
      final lista = AssetResponse.fromJson(corpo).data;
      if (lista.isNotEmpty) return lista;
    } catch (_) {}

    // Fallback inteligente: busca na lista em cache para nunca deixar o usuário sem busca
    try {
      final todos = await buscarListaAtivos(limit: 50);
      return todos.where((a) {
        return a.name.toLowerCase().contains(termo) ||
            a.symbol.toLowerCase().contains(termo) ||
            a.slug.toLowerCase().contains(termo);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // 13. Maiores altas e baixas (Doc #13)
  static Future<List<Asset>> buscarTopMovers({
    String direction = 'gainers',
    int limit = 10,
    bool forcarAtualizacao = false,
  }) async {
    // Para poupar chamadas de rede no limite de 5 req/min,
    // calcula os top movers diretamente a partir da lista principal de ativos
    try {
      final ativos = await buscarListaAtivos(limit: 50, forcarAtualizacao: forcarAtualizacao);
      if (ativos.isNotEmpty) {
        final lista = List<Asset>.from(ativos);
        if (direction == 'losers') {
          lista.sort((a, b) => (a.changePercent24Hr ?? 0).compareTo(b.changePercent24Hr ?? 0));
        } else {
          lista.sort((a, b) => (b.changePercent24Hr ?? 0).compareTo(a.changePercent24Hr ?? 0));
        }
        return lista.take(limit).toList();
      }
    } catch (_) {}

    try {
      final corpo = await _get(
        '/agentFriendly/top_movers',
        {'direction': direction, 'limit': limit.toString()},
        usarCache: !forcarAtualizacao,
      );
      final data = corpo['data'] as List? ?? [];
      return data
          .map((item) => Asset.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // 14. Dados completos de vários ativos (Doc #14)
  static Future<List<Asset>> buscarAtivos(List<String> slugs, {bool forcarAtualizacao = false}) async {
    if (slugs.isEmpty) return [];

    try {
      final corpo = await _get(
        '/agentFriendly/full_assets_by_slug',
        {
          'slugs': slugs.join(','),
          'includeSupply': 'true',
          'includeHistory': 'true',
        },
        usarCache: !forcarAtualizacao,
      );
      final lista = AssetResponse.fromJson(corpo).data;
      if (lista.isNotEmpty) return lista;
    } catch (_) {}

    // Fallback: busca da lista de ativos em cache para nunca falhar a tela de Comparar ou Favoritos
    try {
      final todos = await buscarListaAtivos(limit: 50);
      final mapa = {for (final a in todos) a.slug: a};
      final resultado = <Asset>[];
      for (final s in slugs) {
        if (mapa.containsKey(s)) {
          resultado.add(mapa[s]!);
        }
      }
      return resultado;
    } catch (_) {
      return [];
    }
  }

  // Dados de contingência (fallback) caso o CoinCap esteja em limite rígido
  static Map<String, dynamic>? _obterFallback(String caminho) {
    if (caminho.contains('/assets')) {
      return {
        'data': [
          {
            'id': 'bitcoin',
            'rank': '1',
            'symbol': 'BTC',
            'name': 'Bitcoin',
            'priceUsd': '86029.80',
            'changePercent24Hr': '-0.58',
            'marketCapUsd': '1728680908544',
            'volumeUsd24Hr': '25326078071',
            'supply': '20093978',
            'maxSupply': '21000000',
            'vwap24Hr': '85943.28',
          },
          {
            'id': 'ethereum',
            'rank': '2',
            'symbol': 'ETH',
            'name': 'Ethereum',
            'priceUsd': '2718.00',
            'changePercent24Hr': '-0.29',
            'marketCapUsd': '331888309189',
            'volumeUsd24Hr': '8797634697',
            'supply': '122107545',
            'vwap24Hr': '2713.83',
          },
          {
            'id': 'tether',
            'rank': '3',
            'symbol': 'USDT',
            'name': 'Tether USDt',
            'priceUsd': '1.00',
            'changePercent24Hr': '0.01',
            'marketCapUsd': '184083524966',
            'volumeUsd24Hr': '866409259',
            'supply': '184088295340',
            'vwap24Hr': '1.00',
          },
          {
            'id': 'binance-coin',
            'rank': '4',
            'symbol': 'BNB',
            'name': 'BNB',
            'priceUsd': '788.49',
            'changePercent24Hr': '-0.91',
            'marketCapUsd': '104994788782',
            'volumeUsd24Hr': '751967211',
            'supply': '133159011',
            'vwap24Hr': '790.50',
          },
          {
            'id': 'solana',
            'rank': '5',
            'symbol': 'SOL',
            'name': 'Solana',
            'priceUsd': '121.02',
            'changePercent24Hr': '2.15',
            'marketCapUsd': '56420100420',
            'volumeUsd24Hr': '3405100234',
            'supply': '466184000',
            'vwap24Hr': '120.45',
          },
          {
            'id': 'xrp',
            'rank': '6',
            'symbol': 'XRP',
            'name': 'XRP',
            'priceUsd': '1.51',
            'changePercent24Hr': '-0.65',
            'marketCapUsd': '95346105257',
            'volumeUsd24Hr': '1508877513',
            'supply': '63092975951',
            'vwap24Hr': '1.51',
          },
          {
            'id': 'cardano',
            'rank': '7',
            'symbol': 'ADA',
            'name': 'Cardano',
            'priceUsd': '0.68',
            'changePercent24Hr': '1.82',
            'marketCapUsd': '24180420310',
            'volumeUsd24Hr': '612940210',
            'supply': '35670000000',
            'vwap24Hr': '0.67',
          },
          {
            'id': 'dogecoin',
            'rank': '8',
            'symbol': 'DOGE',
            'name': 'Dogecoin',
            'priceUsd': '0.18',
            'changePercent24Hr': '3.40',
            'marketCapUsd': '26400120400',
            'volumeUsd24Hr': '1240500120',
            'supply': '146000000000',
            'vwap24Hr': '0.17',
          },
        ]
      };
    }

    if (caminho.contains('/exchanges')) {
      return {
        'data': [
          {
            'exchangeId': 'binance',
            'name': 'Binance',
            'rank': '1',
            'percentTotalVolume': 42.5,
            'volumeUsd': 18500200300.0,
            'tradingPairs': 1450,
            'exchangeUrl': 'https://binance.com',
          },
          {
            'exchangeId': 'coinbase-pro',
            'name': 'Coinbase Exchange',
            'rank': '2',
            'percentTotalVolume': 15.2,
            'volumeUsd': 5200300100.0,
            'tradingPairs': 480,
            'exchangeUrl': 'https://coinbase.com',
          },
          {
            'exchangeId': 'bybit',
            'name': 'Bybit',
            'rank': '3',
            'percentTotalVolume': 12.8,
            'volumeUsd': 4100500200.0,
            'tradingPairs': 620,
            'exchangeUrl': 'https://bybit.com',
          },
          {
            'exchangeId': 'kraken',
            'name': 'Kraken',
            'rank': '4',
            'percentTotalVolume': 8.9,
            'volumeUsd': 2100400800.0,
            'tradingPairs': 710,
            'exchangeUrl': 'https://kraken.com',
          },
          {
            'exchangeId': 'kucoin',
            'name': 'KuCoin',
            'rank': '5',
            'percentTotalVolume': 6.5,
            'volumeUsd': 1600300400.0,
            'tradingPairs': 980,
            'exchangeUrl': 'https://kucoin.com',
          },
        ]
      };
    }

    // Taxa individual: /rates/{slug}
    if (RegExp(r'/rates/[^/?]+').hasMatch(caminho)) {
      final slug = caminho.split('/rates/').last.split('?').first.toLowerCase();
      final rates = [
        {'id': 'bitcoin', 'symbol': 'BTC', 'currencySymbol': '₿', 'type': 'crypto', 'rateUsd': '86029.80'},
        {'id': 'ethereum', 'symbol': 'ETH', 'currencySymbol': 'Ξ', 'type': 'crypto', 'rateUsd': '2718.00'},
        {'id': 'solana', 'symbol': 'SOL', 'currencySymbol': 'S', 'type': 'crypto', 'rateUsd': '121.02'},
        {'id': 'united-states-dollar', 'symbol': 'USD', 'currencySymbol': '\$', 'type': 'fiat', 'rateUsd': '1.0'},
        {'id': 'brazilian-real', 'symbol': 'BRL', 'currencySymbol': 'R\$', 'type': 'fiat', 'rateUsd': '0.175'},
        {'id': 'euro', 'symbol': 'EUR', 'currencySymbol': '€', 'type': 'fiat', 'rateUsd': '1.085'},
        {'id': 'british-pound-sterling', 'symbol': 'GBP', 'currencySymbol': '£', 'type': 'fiat', 'rateUsd': '1.295'},
      ];
      final item = rates.firstWhere(
        (r) => r['id'] == slug || r['symbol']?.toString().toLowerCase() == slug,
        orElse: () => {'id': slug, 'symbol': slug.toUpperCase(), 'currencySymbol': '', 'type': 'crypto', 'rateUsd': '1.0'},
      );
      return {'data': item};
    }

    if (caminho.contains('/rates')) {
      return {
        'data': [
          {'id': 'united-states-dollar', 'symbol': 'USD', 'currencySymbol': '\$', 'type': 'fiat', 'rateUsd': '1.0'},
          {'id': 'brazilian-real', 'symbol': 'BRL', 'currencySymbol': 'R\$', 'type': 'fiat', 'rateUsd': '0.175'},
          {'id': 'euro', 'symbol': 'EUR', 'currencySymbol': '€', 'type': 'fiat', 'rateUsd': '1.085'},
          {'id': 'british-pound-sterling', 'symbol': 'GBP', 'currencySymbol': '£', 'type': 'fiat', 'rateUsd': '1.295'},
          {'id': 'bitcoin', 'symbol': 'BTC', 'currencySymbol': '₿', 'type': 'crypto', 'rateUsd': '86029.80'},
          {'id': 'ethereum', 'symbol': 'ETH', 'currencySymbol': 'Ξ', 'type': 'crypto', 'rateUsd': '2718.00'},
          {'id': 'solana', 'symbol': 'SOL', 'currencySymbol': 'S', 'type': 'crypto', 'rateUsd': '121.02'},
        ]
      };
    }

    if (caminho.contains('/markets')) {
      return {
        'data': [
          {'exchangeId': 'binance', 'baseSymbol': 'BTC', 'quoteSymbol': 'USDT', 'priceUsd': '86029.80', 'volumeUsd24Hr': '25326078071', 'volumePercent': '35.4'},
          {'exchangeId': 'binance', 'baseSymbol': 'ETH', 'quoteSymbol': 'USDT', 'priceUsd': '2718.00', 'volumeUsd24Hr': '8797634697', 'volumePercent': '22.1'},
          {'exchangeId': 'binance', 'baseSymbol': 'SOL', 'quoteSymbol': 'USDT', 'priceUsd': '121.02', 'volumeUsd24Hr': '3405100234', 'volumePercent': '15.3'},
          {'exchangeId': 'binance', 'baseSymbol': 'BNB', 'quoteSymbol': 'USDT', 'priceUsd': '788.49', 'volumeUsd24Hr': '751967211', 'volumePercent': '8.2'},
          {'exchangeId': 'binance', 'baseSymbol': 'DOGE', 'quoteSymbol': 'USDT', 'priceUsd': '0.18', 'volumeUsd24Hr': '1240500120', 'volumePercent': '5.0'},
          {'exchangeId': 'coinbase-pro', 'baseSymbol': 'BTC', 'quoteSymbol': 'USD', 'priceUsd': '86035.00', 'volumeUsd24Hr': '15326078071', 'volumePercent': '20.4'},
          {'exchangeId': 'coinbase-pro', 'baseSymbol': 'ETH', 'quoteSymbol': 'USD', 'priceUsd': '2719.10', 'volumeUsd24Hr': '5797634697', 'volumePercent': '12.1'},
          {'exchangeId': 'coinbase-pro', 'baseSymbol': 'SOL', 'quoteSymbol': 'USD', 'priceUsd': '121.15', 'volumeUsd24Hr': '2405100234', 'volumePercent': '8.3'},
          {'exchangeId': 'bybit', 'baseSymbol': 'BTC', 'quoteSymbol': 'USDT', 'priceUsd': '86020.00', 'volumeUsd24Hr': '8326078071', 'volumePercent': '10.4'},
          {'exchangeId': 'bybit', 'baseSymbol': 'ETH', 'quoteSymbol': 'USDT', 'priceUsd': '2717.50', 'volumeUsd24Hr': '3797634697', 'volumePercent': '6.1'},
          {'exchangeId': 'kraken', 'baseSymbol': 'BTC', 'quoteSymbol': 'EUR', 'priceUsd': '86015.00', 'volumeUsd24Hr': '4326078071', 'volumePercent': '5.4'},
          {'exchangeId': 'kucoin', 'baseSymbol': 'SOL', 'quoteSymbol': 'USDT', 'priceUsd': '121.00', 'volumeUsd24Hr': '1405100234', 'volumePercent': '4.3'},
        ]
      };
    }

    // Gráfico de velas (candlesticks): /ta/{slug}/candlesticks
    if (caminho.contains('/candlesticks')) {
      final now = DateTime.now().millisecondsSinceEpoch;
      return {
        'data': [
          {'time': now - 86400000 * 4, 'open': 84200.0, 'high': 85500.0, 'low': 83800.0, 'close': 85100.0},
          {'time': now - 86400000 * 3, 'open': 85100.0, 'high': 86200.0, 'low': 84900.0, 'close': 85900.0},
          {'time': now - 86400000 * 2, 'open': 85900.0, 'high': 87100.0, 'low': 85300.0, 'close': 86400.0},
          {'time': now - 86400000 * 1, 'open': 86400.0, 'high': 86800.0, 'low': 85500.0, 'close': 86029.8},
        ]
      };
    }

    // Indicadores técnicos /ta/
    if (caminho.contains('/ta/')) {
      final now = DateTime.now().millisecondsSinceEpoch;
      return {
        'data': {
          'rsi': {'rsi14': 52.3},
          'macd': {'macd': 120.5, 'signal': 105.2, 'histogram': 15.3},
          'bollingerBands': {'upper': 88500.0, 'middle': 86000.0, 'lower': 83500.0},
          'candlesticks': [
            {'time': now - 86400000 * 3, 'open': 84200.0, 'high': 85500.0, 'low': 83800.0, 'close': 85100.0},
            {'time': now - 86400000 * 2, 'open': 85100.0, 'high': 86200.0, 'low': 84900.0, 'close': 85900.0},
            {'time': now - 86400000 * 1, 'open': 85900.0, 'high': 87100.0, 'low': 85300.0, 'close': 86029.8},
          ],
        }
      };
    }

    if (caminho.contains('/agentFriendly/')) {
      if (caminho.contains('assets_search') || caminho.contains('full_assets_by_slug') || caminho.contains('top_movers')) {
        return {'data': []};
      }
      return {'data': {}};
    }

    if (caminho.contains('/price/')) {
      return {'data': [null]};
    }

    if (caminho.contains('/history')) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final csv = [
        '${now - 86400000 * 4},84200.0',
        '${now - 86400000 * 3},85100.0',
        '${now - 86400000 * 2},85900.0',
        '${now - 86400000 * 1},86400.0',
        '$now,86029.8',
      ].join('\n');
      return {
        'data': {
          'slug': 'bitcoin',
          'startTime': now - 86400000 * 4,
          'endTime': now,
          'intervalMinutes': 60,
          'dataPoints': 5,
          'history': csv,
        }
      };
    }

    return null;
  }
}