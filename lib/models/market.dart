class Market {
  String exchangeId;
  String baseSymbol;
  String quoteSymbol;
  double? priceUsd;
  double? volumeUsd24Hr;

  Market({
    required this.exchangeId,
    required this.baseSymbol,
    required this.quoteSymbol,
    this.priceUsd,
    this.volumeUsd24Hr,
  });

  factory Market.fromJson(Map<String, dynamic> json) => Market(
        exchangeId: json["exchangeId"] ?? '',
        baseSymbol: json["baseSymbol"] ?? '',
        quoteSymbol: json["quoteSymbol"] ?? '',
        priceUsd: double.tryParse('${json["priceUsd"]}'),
        volumeUsd24Hr: double.tryParse('${json["volumeUsd24Hr"]}'),
      );
}

class MarketResponse {
  List<Market> data;

  MarketResponse({required this.data});

  factory MarketResponse.fromJson(Map<String, dynamic> json) => MarketResponse(
        data: List<Market>.from(json["data"].map((x) => Market.fromJson(x))),
      );
}