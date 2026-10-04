import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/asset.dart';
import '../models/exchange.dart';
import '../models/market.dart';
import '../models/rate.dart';

class _Resposta {
  final DateTime hora;
  final Map<String, dynamic> corpo;

  _Resposta(this.hora, this.corpo);
}

class CoinCapService {
  static const String _baseUrl = 'https://rest.coincap.io/v3';
  static const String _apiKey = '9dcd68c96ba0f7835834d843d5177ada774c360b9a923444b7581723def24114';
  static const Duration _validadeCache = Duration(minutes: 10);

  static final Map<String, _Resposta> _cache = {};

  static Future<Map<String, dynamic>> _get(
    String caminho,
    Map<String, String>? parametros, {
    bool usarCache = false,
  }) async {
    final uri = Uri.parse('$_baseUrl$caminho').replace(
      queryParameters: parametros,
    );
    final chave = uri.toString();

    final guardada = _cache[chave];
    if (usarCache &&
        guardada != null &&
        DateTime.now().difference(guardada.hora) < _validadeCache) {
      return guardada.corpo;
    }

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $_apiKey'},
    );

    if (response.statusCode == 200) {
      final corpo = json.decode(response.body) as Map<String, dynamic>;
      if (usarCache) {
        _cache[chave] = _Resposta(DateTime.now(), corpo);
      }
      return corpo;
    } else {
      throw Exception(
        "Falha ao Carregar Dados. Código: ${response.statusCode}",
      );
    }
  }

  static Future<List<Rate>> buscarTaxas({String? ids}) async {
    final corpo = await _get('/rates', ids == null ? null : {'ids': ids});

    return RateResponse.fromJson(corpo)
        .data
        .where((taxa) => taxa.rateUsd > 0 && taxa.symbol.isNotEmpty)
        .toList();
  }

  static Future<List<Exchange>> buscarCorretoras() async {
    final corpo = await _get(
      '/exchanges',
      {'limit': '200'},
      usarCache: true,
    );
    return ExchangeResponse.fromJson(corpo).data;
  }

  static Future<List<Market>> buscarMercados(String exchangeId) async {
    final corpo = await _get(
      '/markets',
      {'exchangeId': exchangeId, 'limit': '20'},
      usarCache: true,
    );
    return MarketResponse.fromJson(corpo).data;
  }

  static Future<List<Asset>> buscarAtivos(List<String> slugs) async {
    final corpo = await _get(
      '/agentFriendly/full_assets_by_slug',
      {
        'slugs': slugs.join(','),
        'includeSupply': 'true',
        'includeHistory': 'true',
      },
      usarCache: true,
    );
    return AssetResponse.fromJson(corpo).data;
  }

  static Future<List<Asset>> buscarAtivosPorNome(String texto) async {
    final corpo = await _get(
      '/agentFriendly/assets_search',
      {'search': texto, 'limit': '10', 'sortBy': 'marketCap'},
      usarCache: true,
    );
    return AssetResponse.fromJson(corpo).data;
  }
}