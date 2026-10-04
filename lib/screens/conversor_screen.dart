import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/rate.dart';
import '../services/coincap_service.dart';

const Color _corCartao = Color(0xFF420D5E);
const Color _corPilula = Color(0xFF2A0A40);
const Color _corDestaque = Color(0xFFA78BFA);
const Color _corTextoSuave = Color(0xFFB79AD6);

String _formatarNumero(double valor) {
  if (!valor.isFinite) return '0';

  final casas = valor.abs() >= 1 ? 2 : 8;
  var texto = valor.toStringAsFixed(casas);

  if (casas == 8) {
    texto = texto.replaceAll(RegExp(r'0+$'), '');
    if (texto.endsWith('.')) {
      texto = texto.substring(0, texto.length - 1);
    }
  }

  final partes = texto.split('.');
  final inteiro = partes[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => '.',
  );

  if (partes.length == 1) return inteiro;
  return '$inteiro,${partes[1]}';
}

String _formatarMoeda(Rate taxa, double valor) {
  final texto = _formatarNumero(valor);
  if (taxa.type == 'fiat' && taxa.currencySymbol != null) {
    return '${taxa.currencySymbol}$texto';
  }
  return '$texto ${taxa.symbol}';
}

class ConversorScreen extends StatefulWidget {
  const ConversorScreen({super.key});

  @override
  State<ConversorScreen> createState() => _ConversorScreenState();
}

class _ConversorScreenState extends State<ConversorScreen> {
  final TextEditingController _controller = TextEditingController(text: '1');
  List<Rate> _taxas = [];
  String? _deId;
  String? _paraId;
  bool _atualizando = false;
  bool _erro = false;
  DateTime? _ultimaAtualizacao;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _carregarTaxas();

    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _carregarTaxas() async {
    setState(() {
      _atualizando = true;
      _erro = false;
    });

    List<Rate> taxas = [];
    try {
      taxas = await CoinCapService.buscarTaxas();
    } catch (e) {
      taxas = [];
    }

    if (!mounted) return;

    setState(() {
      _atualizando = false;
      if (taxas.length < 2) {
        _erro = _taxas.isEmpty;
      } else {
        _taxas = taxas;
        _deId = taxas.any((t) => t.id == _deId)
            ? _deId
            : (_idPorSimbolo(taxas, 'BTC') ?? taxas[0].id);
        _paraId = taxas.any((t) => t.id == _paraId)
            ? _paraId
            : (_idPorSimbolo(taxas, 'DOGE') ?? taxas[1].id);
        _ultimaAtualizacao = DateTime.now();
      }
    });
  }

  String? _idPorSimbolo(List<Rate> taxas, String simbolo) {
    for (final taxa in taxas) {
      if (taxa.symbol == simbolo) return taxa.id;
    }
    return null;
  }

  Rate? _taxa(String? id) {
    for (final taxa in _taxas) {
      if (taxa.id == id) return taxa;
    }
    return null;
  }

  Rate? _taxaPorSimbolo(String simbolo) {
    for (final taxa in _taxas) {
      if (taxa.symbol == simbolo) return taxa;
    }
    return null;
  }

  double get _valor =>
      double.tryParse(_controller.text.replaceAll(',', '.')) ?? 0;

  double _converter(double valor, Rate de, Rate para) {
    return valor * de.rateUsd / para.rateUsd;
  }

  String get _textoAtualizacao {
    final ultima = _ultimaAtualizacao;
    if (ultima == null) return '';
    final minutos = DateTime.now().difference(ultima).inMinutes;
    return minutos < 1 ? 'agora' : '$minutos min atrás';
  }

  void _inverter() {
    setState(() {
      final temporario = _deId;
      _deId = _paraId;
      _paraId = temporario;
    });
  }

  Widget _cabecalho() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Conversor",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        GestureDetector(
          onTap: _atualizando ? null : _carregarTaxas,
          child: Row(
            children: [
              _atualizando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _corTextoSuave,
                      ),
                    )
                  : const Icon(Icons.refresh, size: 18, color: _corTextoSuave),
              const SizedBox(width: 4),
              Text(
                _textoAtualizacao,
                style: const TextStyle(color: _corTextoSuave, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cartao(String rotulo, Widget conteudo) {
    return Card(
      color: _corCartao,
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rotulo,
              style: const TextStyle(color: _corTextoSuave, fontSize: 13),
            ),
            const SizedBox(height: 8),
            conteudo,
          ],
        ),
      ),
    );
  }

  Widget _seletor(String? idAtual, ValueChanged<String?> aoMudar) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _corPilula,
        borderRadius: BorderRadius.circular(24),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: idAtual,
          dropdownColor: _corCartao,
          iconEnabledColor: Colors.white,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          onChanged: aoMudar,
          items: _taxas
              .map(
                (taxa) => DropdownMenuItem<String>(
                  value: taxa.id,
                  child: Text(taxa.symbol),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _cartaoOutraMoeda(String simbolo, Rate de, double valor) {
    final taxa = _taxaPorSimbolo(simbolo);
    if (taxa == null) return const SizedBox.shrink();

    return _cartao(
      taxa.symbol,
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          _formatarMoeda(taxa, _converter(valor, de, taxa)),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _conteudo() {
    final de = _taxa(_deId);
    final para = _taxa(_paraId);

    if (de == null || para == null) {
      if (_erro) {
        return Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Center(
            child: Column(
              children: [
                const Text(
                  "Não foi possível carregar as taxas",
                  style: TextStyle(color: Colors.white),
                ),
                TextButton(
                  onPressed: _carregarTaxas,
                  child: const Text("Tentar novamente"),
                ),
              ],
            ),
          ),
        );
      }
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final valor = _valor;
    final resultado = _converter(valor, de, para);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _cartao(
                  "De",
                  SizedBox(
                    height: 52,
                    child: Row(
                      children: [
                        _seletor(_deId, (id) {
                          setState(() {
                            _deId = id;
                          });
                        }),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            textAlign: TextAlign.right,
                            cursorColor: _corDestaque,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*[,.]?\d*'),
                              ),
                            ],
                            onChanged: (_) {
                              setState(() {});
                            },
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                                borderSide: BorderSide(
                                  color: Colors.transparent,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                                borderSide: BorderSide(
                                  color: _corDestaque,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _cartao(
                  "Para",
                  SizedBox(
                    height: 52,
                    child: Row(
                      children: [
                        _seletor(_paraId, (id) {
                          setState(() {
                            _paraId = id;
                          });
                        }),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                _formatarNumero(resultado),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: _inverter,
              child: const CircleAvatar(
                radius: 25,
                backgroundColor: Color(0xFF0A0014),
                child: CircleAvatar(
                  radius: 21,
                  backgroundColor: _corDestaque,
                  child: Icon(Icons.swap_horiz, color: Color(0xFF1A0530)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _corPilula,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "1 ${de.symbol} = ${_formatarNumero(_converter(1, de, para))} ${para.symbol}",
              style: const TextStyle(color: _corTextoSuave, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          "O MESMO VALOR EM OUTRAS MOEDAS",
          style: TextStyle(
            color: _corTextoSuave,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.9,
          children: ['USD', 'BRL', 'EUR', 'ETH']
              .map((simbolo) => _cartaoOutraMoeda(simbolo, de, valor))
              .toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _cabecalho(),
            const SizedBox(height: 16),
            _conteudo(),
          ],
        ),
      ),
    );
  }
}