import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/rate.dart';

class CoinCapService {
  static const String _baseUrl = 'https://rest.coincap.io/v3';
  static const String _apiKey = '9dcd68c96ba0f7835834d843d5177ada774c360b9a923444b7581723def24114';

  static Future<List<Rate>> buscarTaxas({String? ids}) async {
    final uri = Uri.parse('$_baseUrl/rates').replace(
      queryParameters: ids == null ? null : {'ids': ids},
    );

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $_apiKey'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return RateResponse.fromJson(data)
          .data
          .where((taxa) => taxa.rateUsd > 0 && taxa.symbol.isNotEmpty)
          .toList();
    } else {
      throw Exception(
        "Falha ao Carregar Dados. Código: ${response.statusCode}",
      );
    }
  }
}