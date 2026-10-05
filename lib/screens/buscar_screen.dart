import 'dart:async';
import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../services/coincap_service.dart';
import '../utils/formatadores.dart';
import 'detalhes_ativo_screen.dart';

class BuscarScreen extends StatefulWidget {
  const BuscarScreen({super.key});

  @override
  State<BuscarScreen> createState() => _BuscarScreenState();
}

class _BuscarScreenState extends State<BuscarScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<Asset> _resultados = [];
  bool _buscando = false;
  String _termoBuscado = '';

  // Ativos sugeridos quando o campo estiver vazio
  List<Asset> _sugestoes = [];
  bool _carregandoSugestoes = true;

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
        _termoBuscado = '';
        _resultados = [];
        _buscando = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() {
        _buscando = true;
        _termoBuscado = texto;
      });

      try {
        final resultados = await CoinCapService.buscarAtivosPorNome(texto);
        if (mounted) {
          setState(() {
            _resultados = resultados;
            _buscando = false;
          });
        }
      } catch (_) {
        if (mounted) {
          final filtrados = _sugestoes
              .where((a) =>
                  a.name.toLowerCase().contains(texto.toLowerCase()) ||
                  a.symbol.toLowerCase().contains(texto.toLowerCase()))
              .toList();
          setState(() {
            _resultados = filtrados;
            _buscando = false;
          });
        }
      }
    });
  }

  void _abrirDetalhes(Asset ativo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalhesAtivoScreen(
          slug: ativo.slug,
          assetInicial: ativo,
        ),
      ),
    );
  }

  Widget _itemResultado(Asset ativo) {
    final subiu = (ativo.changePercent24Hr ?? 0) >= 0;
    final letra = ativo.symbol.isNotEmpty ? ativo.symbol[0] : 'A';

    return InkWell(
      onTap: () => _abrirDetalhes(ativo),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: corPilula,
              child: Text(
                letra,
                style: const TextStyle(
                  color: corDestaque,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ativo.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "#${ativo.rank ?? '-'} · ${ativo.symbol}",
                    style: const TextStyle(
                      color: corTextoSuave,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatarPreco(ativo.price, prefixo: '\$'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatarPercentual(ativo.changePercent24Hr),
                  style: TextStyle(
                    color: subiu ? corVerde : corVermelha,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listaAtual = _termoBuscado.isEmpty ? _sugestoes : _resultados;
    final tituloSecao = _termoBuscado.isEmpty ? "POPULARES" : "RESULTADOS";

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Buscar",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Barra de Busca
            Container(
              decoration: BoxDecoration(
                color: corPilula,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: TextField(
                controller: _controller,
                onChanged: _aoDigitar,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                cursorColor: corDestaque,
                decoration: InputDecoration(
                  hintText: "Buscar por nome ou símbolo (ex: sol)",
                  hintStyle: const TextStyle(color: corTextoSuave, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: corTextoSuave),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: corTextoSuave, size: 20),
                          onPressed: () {
                            _controller.clear();
                            _aoDigitar('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Título da Seção
            Text(
              tituloSecao,
              style: const TextStyle(
                color: corTextoSuave,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),

            // Conteúdo
            Expanded(
              child: _buscando
                  ? const Center(child: CircularProgressIndicator(color: corDestaque))
                  : _termoBuscado.isNotEmpty && _resultados.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off, size: 48, color: corTextoSuave),
                              const SizedBox(height: 12),
                              Text(
                                "Nenhum resultado para '$_termoBuscado'",
                                style: const TextStyle(color: corTextoSuave, fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      : _termoBuscado.isEmpty && _carregandoSugestoes
                          ? const Center(child: CircularProgressIndicator(color: corDestaque))
                          : ListView.separated(
                              itemCount: listaAtual.length,
                              separatorBuilder: (_, _) => Divider(
                                color: Colors.white.withValues(alpha: 0.04),
                                height: 1,
                              ),
                              itemBuilder: (context, i) => _itemResultado(listaAtual[i]),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
