import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/formatadores.dart';

class GraficoLinha extends StatelessWidget {
  final List<double> pontos;
  final double largura;
  final double altura;

  const GraficoLinha({
    super.key,
    required this.pontos,
    this.largura = 64,
    this.altura = 20,
  });

  @override
  Widget build(BuildContext context) {
    final subiu = pontos.length < 2 || pontos.last >= pontos.first;

    return CustomPaint(
      size: Size(largura, altura),
      painter: _PintorLinha(pontos, subiu ? corVerde : corVermelha),
    );
  }
}

class _PintorLinha extends CustomPainter {
  final List<double> pontos;
  final Color cor;

  _PintorLinha(this.pontos, this.cor);

  @override
  void paint(Canvas canvas, Size size) {
    if (pontos.length < 2) return;

    final minimo = pontos.reduce(min);
    final maximo = pontos.reduce(max);
    final faixa = maximo - minimo == 0 ? 1.0 : maximo - minimo;

    final caminho = Path();
    for (var i = 0; i < pontos.length; i++) {
      final x = size.width * i / (pontos.length - 1);
      final y = size.height - (pontos[i] - minimo) / faixa * size.height;
      if (i == 0) {
        caminho.moveTo(x, y);
      } else {
        caminho.lineTo(x, y);
      }
    }

    final pincel = Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(caminho, pincel);
  }

  @override
  bool shouldRepaint(covariant _PintorLinha antigo) {
    return antigo.pontos != pontos || antigo.cor != cor;
  }
}