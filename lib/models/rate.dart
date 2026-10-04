class Rate {
  String id;
  String symbol;
  String? currencySymbol;
  String type;
  double rateUsd;

  Rate({
    required this.id,
    required this.symbol,
    this.currencySymbol,
    required this.type,
    required this.rateUsd,
  });

  factory Rate.fromJson(Map<String, dynamic> json) => Rate(
        id: json["id"] ?? '',
        symbol: json["symbol"] ?? '',
        currencySymbol: json["currencySymbol"],
        type: json["type"] ?? '',
        rateUsd: double.tryParse('${json["rateUsd"]}') ?? 0,
      );
}

class RateResponse {
  List<Rate> data;

  RateResponse({required this.data});

  factory RateResponse.fromJson(Map<String, dynamic> json) => RateResponse(
        data: List<Rate>.from(json["data"].map((x) => Rate.fromJson(x))),
      );
}