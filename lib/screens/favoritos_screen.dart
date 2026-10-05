import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../services/coincap_service.dart';
import '../services/favoritos_service.dart';
import '../utils/formatadores.dart';
import 'detalhes_ativo_screen.dart';

class FavoritosScreen extends StatefulWidget {
  final VoidCallback? onIrParaMercado;

  const FavoritosScreen({super.key, this.onIrParaMercado});

  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  List<Asset> _ativosFavoritos = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarFavoritos();
    FavoritosService.instance.favoritosNotifier.addListener(_aoMudarFavoritos);
  }

  @override
  void dispose() {
    FavoritosService.instance.favoritosNotifier.removeListener(_aoMudarFavoritos);
    super.dispose();
  }

  void _aoMudarFavoritos() {
    _carregarFavoritos();
  }

  Future<void> _carregarFavoritos() async {
    final slugs = FavoritosService.instance.favoritos.toList();
    if (slugs.isEmpty) {
      if (mounted) {
        setState(() {
          _ativosFavoritos = [];
          _carregando = false;
        });
      }
      return;
    }

    try {
      final ativos = await CoinCapService.buscarAtivos(slugs);
      if (mounted) {
        setState(() {
          _ativosFavoritos = ativos;
          _carregando = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
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

  Widget _cardFavorito(Asset ativo) {
    final subiu = (ativo.changePercent24Hr ?? 0) >= 0;
    final letra = ativo.symbol.isNotEmpty ? ativo.symbol[0] : 'F';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: corCartao,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: InkWell(
        onTap: () => _abrirDetalhes(ativo),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      ativo.symbol,
                      style: const TextStyle(
                        color: corTextoSuave,
                        fontSize: 13,
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
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  FavoritosService.instance.alternar(ativo.slug);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(seconds: 1),
                      backgroundColor: corPilula,
                      content: Text(
                        "${ativo.name} removido dos favoritos",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.star,
                    color: Color(0xFFFBBF24),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: corDestaque,
        backgroundColor: corCartao,
        onRefresh: _carregarFavoritos,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Favoritos",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: _carregando && _ativosFavoritos.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: corDestaque))
                    : _ativosFavoritos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.star_border,
                                  size: 64,
                                  color: corTextoSuave,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "Nenhum favorito ainda",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 32),
                                  child: Text(
                                    "Toque na estrela de qualquer ativo para adicioná-lo aos seus favoritos e acompanhar seus preços aqui.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: corTextoSuave,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                if (widget.onIrParaMercado != null)
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: corCartao,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: widget.onIrParaMercado,
                                    child: const Text("Explorar Mercado"),
                                  ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _ativosFavoritos.length,
                            itemBuilder: (context, i) => _cardFavorito(_ativosFavoritos[i]),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
