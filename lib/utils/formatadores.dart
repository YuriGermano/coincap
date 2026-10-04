import 'package:flutter/material.dart';

const Color corCartao = Color(0xFF420D5E);
const Color corPilula = Color(0xFF2A0A40);
const Color corDestaque = Color(0xFFA78BFA);
const Color corTextoSuave = Color(0xFFB79AD6);
const Color corVerde = Color(0xFF4ADE80);
const Color corVermelha = Color(0xFFF87171);

Color corVariacao(double? valor) {
  if (valor == null) return corTextoSuave;
  return valor >= 0 ? corVerde : corVermelha;
}

String _agrupar(String inteiro) {
  return inteiro.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => '.',
  );
}

String formatarInteiro(num valor) {
  return _agrupar(valor.round().toString());
}

String formatarPreco(double? valor, {String prefixo = '', int? casas}) {
  if (valor == null || !valor.isFinite) return '-';

  final decimais = casas ?? (valor.abs() >= 1 ? 2 : 6);
  var texto = valor.toStringAsFixed(decimais);

  if (casas == null && decimais == 6) {
    texto = texto.replaceAll(RegExp(r'0+$'), '');
    if (texto.endsWith('.')) {
      texto = texto.substring(0, texto.length - 1);
    }
  }

  final partes = texto.split('.');
  final inteiro = _agrupar(partes[0]);
  final decimal = partes.length > 1 ? ',${partes[1]}' : '';
  return '$prefixo$inteiro$decimal';
}

String formatarCompacto(double? valor, {String prefixo = ''}) {
  if (valor == null || !valor.isFinite) return '-';

  final absoluto = valor.abs();
  if (absoluto >= 1e12) {
    return '$prefixo${(valor / 1e12).toStringAsFixed(2).replaceAll('.', ',')}T';
  }
  if (absoluto >= 1e9) {
    return '$prefixo${(valor / 1e9).toStringAsFixed(1).replaceAll('.', ',')}B';
  }
  if (absoluto >= 1e6) {
    return '$prefixo${(valor / 1e6).toStringAsFixed(1).replaceAll('.', ',')}M';
  }
  return formatarPreco(valor, prefixo: prefixo);
}

String formatarPercentual(double? valor, {bool sinal = true}) {
  if (valor == null || !valor.isFinite) return '-';

  final prefixo = sinal && valor > 0 ? '+' : '';
  return '$prefixo${valor.toStringAsFixed(1).replaceAll('.', ',')}%';
}