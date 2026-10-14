class Candlestick {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;

  Candlestick({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  factory Candlestick.fromJson(Map<String, dynamic> json) {
    DateTime parseTime(dynamic v) {
      if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
      if (v is String) {
        final n = int.tryParse(v);
        if (n != null) return DateTime.fromMillisecondsSinceEpoch(n);
        final dt = DateTime.tryParse(v);
        if (dt != null) return dt;
      }
      return DateTime.now();
    }

    double parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v == null) return 0.0;
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return Candlestick(
      time: parseTime(json['time'] ?? json['timestamp'] ?? json['date']),
      open: parseDouble(json['open']),
      high: parseDouble(json['high']),
      low: parseDouble(json['low']),
      close: parseDouble(json['close']),
    );
  }
}

class CandlestickResponse {
  final List<Candlestick> data;

  CandlestickResponse({required this.data});

  factory CandlestickResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] ?? json['candles']) as List? ?? [];
    return CandlestickResponse(
      data: list
          .map((item) => Candlestick.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

