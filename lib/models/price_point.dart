class PricePoint {
  final DateTime time;
  final double price;

  PricePoint(this.time, this.price);

  factory PricePoint.fromJson(Map<String, dynamic> json) {
    DateTime dataHora;
    if (json['date'] != null) {
      dataHora = DateTime.tryParse(json['date'].toString()) ?? DateTime.now();
    } else if (json['time'] != null) {
      final millis = int.tryParse(json['time'].toString()) ?? 0;
      dataHora = DateTime.fromMillisecondsSinceEpoch(millis);
    } else {
      dataHora = DateTime.now();
    }

    final preco = double.tryParse(json['priceUsd']?.toString() ?? json['price']?.toString() ?? '0') ?? 0.0;
    return PricePoint(dataHora, preco);
  }
}
