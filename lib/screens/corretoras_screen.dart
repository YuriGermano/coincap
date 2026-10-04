import 'package:flutter/material.dart';
import '../models/exchange.dart';
import '../models/market.dart';
import '../services/coincap_service.dart';
import '../utils/formatadores.dart';
import '../widgets/tela_base.dart';

class CorretorasScreen extends StatefulWidget {
  const CorretorasScreen({super.key});

  @override
  State<CorretorasScreen> createState() => _CorretorasScreenState();
}

class _CorretorasScreenState extends State<CorretorasScreen> {
  final TextEditingController _busca = TextEditingController();
  List<Exchange> _corretoras = [];
  bool _carregando = true;
  bool _erro = false;
  String _ordem = 'Volume';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = false;
    });

    List<Exchange> corretoras = [];
    try {
      corretoras = await CoinCapService.buscarCorretoras();
    } catch (e) {
      corretoras = [];
    }

    if (!mounted) return;

    setState(() {
      _corretoras = corretoras;
      _carregando = false;
      _erro = corretoras.isEmpty;
    });
  }

  List<Exchange> get _filtradas {
    final texto = _busca.text.trim().toLowerCase();
    final lista = _corretoras
        .where((c) => c.name.toLowerCase().contains(texto))
        .toList();

    if (_ordem == 'Pares') {
      lista.sort((a, b) => b.tradingPairs.compareTo(a.tradingPairs));
    } else if (_ordem == 'Nome') {
      lista.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else {
      lista.sort((a, b) => (b.volumeUsd ?? 0).compareTo(a.volumeUsd ?? 0));
    }
    return lista;
  }

  void _mostrarPares(Exchange corretora) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: corCartao,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FolhaPares(corretora: corretora),
    );
  }

  Widget _resumo(String rotulo, String valor) {
    return Card(
      color: corCartao,
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rotulo,
              style: const TextStyle(color: corTextoSuave, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              valor,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String rotulo) {
    final selecionado = _ordem == rotulo;

    return ChoiceChip(
      label: Text(rotulo),
      selected: selecionado,
      showCheckmark: false,
      selectedColor: corDestaque,
      backgroundColor: corPilula,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      labelStyle: TextStyle(
        color: selecionado ? const Color(0xFF1A0530) : corTextoSuave,
        fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) {
        setState(() {
          _ordem = rotulo;
        });
      },
    );
  }

  Widget _topo() {
    final total = _corretoras.fold<double>(
      0,
      (soma, c) => soma + (c.volumeUsd ?? 0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Onde suas criptomoedas favoritas são negociadas — toque em uma corretora para ver os pares disponíveis.",
          style: TextStyle(color: corTextoSuave, fontSize: 14),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _resumo(
                "Volume total (24h)",
                formatarCompacto(total, prefixo: '\$'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _resumo(
                "Corretoras listadas",
                formatarInteiro(_corretoras.length),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _busca,
          onChanged: (_) {
            setState(() {});
          },
          style: const TextStyle(color: Colors.white),
          cursorColor: corDestaque,
          decoration: InputDecoration(
            hintText: "Buscar corretora",
            hintStyle: const TextStyle(color: corTextoSuave),
            prefixIcon: const Icon(Icons.search, color: corTextoSuave),
            filled: true,
            fillColor: corPilula,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _chip('Volume'),
            const SizedBox(width: 8),
            _chip('Pares'),
            const SizedBox(width: 8),
            _chip('Nome'),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _linha(Exchange corretora, double maximo) {
    final proporcao = maximo > 0 ? (corretora.volumeUsd ?? 0) / maximo : 0.0;
    final inicial =
        corretora.name.isEmpty ? '?' : corretora.name[0].toUpperCase();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _mostrarPares(corretora);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: corPilula,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                corretora.rank,
                style: const TextStyle(
                  color: corTextoSuave,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 20,
              backgroundColor: corCartao,
              child: Text(
                inicial,
                style: const TextStyle(
                  color: corDestaque,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    corretora.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    "${formatarInteiro(corretora.tradingPairs)} pares",
                    style: const TextStyle(color: corTextoSuave, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: proporcao,
                    minHeight: 4,
                    color: corDestaque,
                    backgroundColor: corPilula,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatarCompacto(corretora.volumeUsd, prefixo: '\$'),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                Text(
                  formatarPercentual(corretora.percentTotalVolume, sinal: false),
                  style: const TextStyle(color: corTextoSuave, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.open_in_new, size: 18, color: corTextoSuave),
          ],
        ),
      ),
    );
  }

  Widget _conteudo() {
    if (_carregando) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_erro) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Não foi possível carregar as corretoras",
              style: TextStyle(color: Colors.white),
            ),
            TextButton(
              onPressed: _carregar,
              child: const Text("Tentar novamente"),
            ),
          ],
        ),
      );
    }

    final lista = _filtradas;
    final maximo = _corretoras.fold<double>(
      0,
      (maior, c) => (c.volumeUsd ?? 0) > maior ? (c.volumeUsd ?? 0) : maior,
    );

    return ListView.builder(
      itemCount: lista.length + 1,
      itemBuilder: (context, indice) {
        if (indice == 0) return _topo();
        return _linha(lista[indice - 1], maximo);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(titulo: "Corretoras", child: _conteudo());
  }
}

class _FolhaPares extends StatefulWidget {
  final Exchange corretora;

  const _FolhaPares({required this.corretora});

  @override
  State<_FolhaPares> createState() => _FolhaParesState();
}

class _FolhaParesState extends State<_FolhaPares> {
  late final Future<List<Market>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = CoinCapService.buscarMercados(widget.corretora.exchangeId);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.corretora.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<Market>>(
                future: _futuro,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        "Não foi possível carregar os pares",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final mercados = snapshot.data ?? [];
                  if (mercados.isEmpty) {
                    return const Center(
                      child: Text(
                        "Nenhum par encontrado",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: mercados.length,
                    itemBuilder: (context, indice) {
                      final mercado = mercados[indice];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                "${mercado.baseSymbol}/${mercado.quoteSymbol}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formatarPreco(mercado.priceUsd, prefixo: '\$'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  formatarCompacto(
                                    mercado.volumeUsd24Hr,
                                    prefixo: '\$',
                                  ),
                                  style: const TextStyle(
                                    color: corTextoSuave,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}