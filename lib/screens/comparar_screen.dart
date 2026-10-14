import 'dart:async';
import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../services/coincap_service.dart';
import '../utils/formatadores.dart';
import '../widgets/grafico_linha.dart';
import '../widgets/tela_base.dart';

class CompararScreen extends StatefulWidget {
  const CompararScreen({super.key});

  @override
  State<CompararScreen> createState() => _CompararScreenState();
}

class _CompararScreenState extends State<CompararScreen> {
  static const List<String> _slugsIniciais = ['bitcoin', 'ethereum', 'solana'];
  static const int _maximo = 10;

  List<Asset> _ativos = [];
  bool _carregando = true;
  bool _erro = false;
  bool _adicionando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = false;
    });

    List<Asset> ativos = [];
    try {
      ativos = await CoinCapService.buscarAtivos(_slugsIniciais);
    } catch (e) {
      ativos = [];
    }

    if (!mounted) return;

    setState(() {
      _ativos = ativos;
      _carregando = false;
      _erro = ativos.isEmpty;
    });
  }

  void _aviso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  Future<void> _adicionar() async {
    if (_ativos.length >= _maximo) {
      _aviso("Você já está comparando $_maximo ativos");
      return;
    }

    final selecionado = await showModalBottomSheet<Asset>(
      context: context,
      isScrollControlled: true,
      backgroundColor: corCartao,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _BuscaAtivo(),
    );

    if (selecionado == null || !mounted) return;
    if (_ativos.any((a) => a.slug.toLowerCase() == selecionado.slug.toLowerCase())) {
      _aviso("Este ativo já está na lista");
      return;
    }

    setState(() {
      _adicionando = true;
    });

    List<Asset> novos = [];
    try {
      novos = await CoinCapService.buscarAtivos([selecionado.slug]);
    } catch (_) {
      novos = [];
    }

    if (novos.isEmpty) {
      try {
        final detalhe = await CoinCapService.buscarDetalhesAtivo(selecionado.slug);
        novos = [detalhe];
      } catch (_) {
        novos = [selecionado];
      }
    }

    if (!mounted) return;

    setState(() {
      _adicionando = false;
      _ativos.addAll(novos);
    });

    if (novos.isEmpty) {
      _aviso("Não foi possível adicionar o ativo");
    }
  }

  Widget _botaoAdicionar() {
    return GestureDetector(
      onTap: _adicionar,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: corPilula,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            Icon(Icons.add, size: 18, color: corDestaque),
            SizedBox(width: 4),
            Text(
              "Adicionar",
              style: TextStyle(
                color: corDestaque,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _valor(String texto) {
    return Text(
      texto,
      style: const TextStyle(color: Colors.white, fontSize: 13),
    );
  }

  Widget _cabecalhoAtivo(Asset ativo) {
    final inicial = ativo.symbol.isEmpty ? '?' : ativo.symbol[0].toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _ativos.remove(ativo);
              });
            },
            child: const Icon(Icons.close, size: 16, color: corTextoSuave),
          ),
          const SizedBox(height: 4),
          CircleAvatar(
            radius: 14,
            backgroundColor: corPilula,
            child: Text(
              inicial,
              style: const TextStyle(
                color: corDestaque,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            ativo.symbol,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          GraficoLinha(pontos: ativo.historico, largura: 56, altura: 18),
        ],
      ),
    );
  }

  TableRow _linha(String rotulo, Widget Function(Asset) celula) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 4, 14),
          child: Text(
            rotulo,
            style: const TextStyle(color: corTextoSuave, fontSize: 11),
          ),
        ),
        ..._ativos.map(
          (ativo) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(child: celula(ativo)),
          ),
        ),
      ],
    );
  }

  Widget _tabela(double larguraRotulo, double larguraColuna) {
    return Table(
      columnWidths: {
        0: FixedColumnWidth(larguraRotulo),
        for (var i = 1; i <= _ativos.length; i++)
          i: FixedColumnWidth(larguraColuna),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: const TableBorder(
        horizontalInside: BorderSide(color: Color(0xFF5A2380), width: 0.5),
      ),
      children: [
        TableRow(
          children: [
            const SizedBox.shrink(),
            ..._ativos.map(_cabecalhoAtivo),
          ],
        ),
        _linha(
          "Preço",
          (a) => _valor(
            formatarPreco(
              a.price,
              prefixo: '\$',
              casas: a.price >= 1000 ? 0 : null,
            ),
          ),
        ),
        _linha(
          "Variação 24h",
          (a) => Text(
            formatarPercentual(a.changePercent24Hr),
            style: TextStyle(
              color: corVariacao(a.changePercent24Hr),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _linha(
          "Mercado",
          (a) => _valor(formatarCompacto(a.marketCap, prefixo: '\$')),
        ),
        _linha(
          "Volume 24h",
          (a) => _valor(formatarCompacto(a.volume, prefixo: '\$')),
        ),
        _linha("Fornecimento", (a) => _valor(formatarCompacto(a.supply))),
      ],
    );
  }

  Widget _cartaoTabela() {
    return Card(
      color: corCartao,
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: LayoutBuilder(
        builder: (context, restricoes) {
          const larguraRotulo = 88.0;
          final larguraColuna = _ativos.length <= 3
              ? (restricoes.maxWidth - larguraRotulo) / _ativos.length
              : 96.0;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _tabela(larguraRotulo, larguraColuna),
          );
        },
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
              "Não foi possível carregar os ativos",
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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Compare até 10 ativos lado a lado — preço, mercado, volume e tendência recente.",
            style: TextStyle(color: corTextoSuave, fontSize: 14),
          ),
          const SizedBox(height: 16),
          if (_adicionando)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(
                color: corDestaque,
                backgroundColor: corPilula,
              ),
            ),
          if (_ativos.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  "Toque em Adicionar para escolher ativos",
                  style: TextStyle(color: corTextoSuave),
                ),
              ),
            )
          else
            _cartaoTabela(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      titulo: "Comparar",
      acao: _botaoAdicionar(),
      child: _conteudo(),
    );
  }
}

class _BuscaAtivo extends StatefulWidget {
  const _BuscaAtivo();

  @override
  State<_BuscaAtivo> createState() => _BuscaAtivoState();
}

class _BuscaAtivoState extends State<_BuscaAtivo> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<Asset> _sugestoes = [];
  List<Asset> _resultados = [];
  bool _buscando = false;
  bool _carregandoSugestoes = true;
  String _termo = '';

  @override
  void initState() {
    super.initState();
    _carregarSugestoes();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _carregarSugestoes() async {
    try {
      final lista = await CoinCapService.buscarListaAtivos(limit: 30);
      if (mounted) {
        setState(() {
          _sugestoes = lista;
          _carregandoSugestoes = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _carregandoSugestoes = false);
      }
    }
  }

  void _aoDigitar(String valor) {
    _debounce?.cancel();
    final texto = valor.trim();

    if (texto.isEmpty) {
      setState(() {
        _termo = '';
        _resultados = [];
        _buscando = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _executarBusca(texto);
    });
  }

  Future<void> _executarBusca(String texto) async {
    if (!mounted) return;
    setState(() {
      _buscando = true;
      _termo = texto;
    });

    List<Asset> res = [];
    try {
      res = await CoinCapService.buscarAtivosPorNome(texto);
    } catch (_) {
      res = [];
    }

    if (res.isEmpty) {
      final lower = texto.toLowerCase();
      res = _sugestoes
          .where((a) =>
              a.name.toLowerCase().contains(lower) ||
              a.symbol.toLowerCase().contains(lower) ||
              a.slug.toLowerCase().contains(lower))
          .toList();
    }

    if (!mounted) return;
    setState(() {
      _resultados = res;
      _buscando = false;
    });
  }

  Widget _corpo() {
    if (_buscando || (_termo.isEmpty && _carregandoSugestoes)) {
      return const Center(
        child: CircularProgressIndicator(color: corDestaque),
      );
    }

    final lista = _termo.isEmpty ? _sugestoes : _resultados;

    if (lista.isEmpty) {
      return const Center(
        child: Text(
          "Nenhum ativo encontrado",
          style: TextStyle(color: corTextoSuave),
        ),
      );
    }

    return ListView.separated(
      itemCount: lista.length,
      separatorBuilder: (_, _) => const Divider(
        color: Color(0xFF5A2380),
        height: 1,
      ),
      itemBuilder: (context, indice) {
        final ativo = lista[indice];
        final inicial = ativo.symbol.isNotEmpty ? ativo.symbol[0].toUpperCase() : '?';

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          onTap: () {
            Navigator.pop(context, ativo);
          },
          leading: CircleAvatar(
            backgroundColor: corPilula,
            child: Text(
              inicial,
              style: const TextStyle(
                color: corDestaque,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            ativo.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            ativo.symbol,
            style: const TextStyle(
              color: corTextoSuave,
              fontSize: 12,
            ),
          ),
          trailing: Text(
            formatarPreco(ativo.price, prefixo: '\$'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: corTextoSuave.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                TextField(
                  controller: _controller,
                  onChanged: _aoDigitar,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (val) {
                    _debounce?.cancel();
                    _executarBusca(val.trim());
                  },
                  style: const TextStyle(color: Colors.white),
                  cursorColor: corDestaque,
                  decoration: InputDecoration(
                    hintText: "Buscar ativo (ex.: Bitcoin, SOL)",
                    hintStyle: const TextStyle(color: corTextoSuave),
                    prefixIcon: const Icon(Icons.search, color: corTextoSuave),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, color: corTextoSuave, size: 20),
                            onPressed: () {
                              _controller.clear();
                              _aoDigitar('');
                            },
                          )
                        : IconButton(
                            icon: const Icon(Icons.arrow_forward, color: corDestaque),
                            onPressed: () {
                              _debounce?.cancel();
                              _executarBusca(_controller.text.trim());
                            },
                          ),
                    filled: true,
                    fillColor: corPilula,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    _termo.isEmpty ? "POPULARES" : "RESULTADOS",
                    style: const TextStyle(
                      color: corTextoSuave,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(child: _corpo()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}