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
  final Map<String, Asset> _cacheAtivos = {};
  bool _carregando = false;
  Set<String> _ultimosSlugsCarregados = {};

  @override
  void initState() {
    super.initState();
    _sincronizarFavoritos(FavoritosService.instance.favoritos);
  }

  Future<void> _sincronizarFavoritos(Set<String> slugs, {bool forcar = false}) async {
    _ultimosSlugsCarregados = Set.from(slugs);

    if (slugs.isEmpty) {
      if (mounted) setState(() => _carregando = false);
      return;
    }

    // Copia ativos que já estão no cache central do FavoritosService
    for (final s in slugs) {
      final emMemoria = FavoritosService.instance.ativosCache[s];
      if (emMemoria != null) {
        _cacheAtivos[s] = emMemoria;
      }
    }

    final faltando = slugs.where((s) => !_cacheAtivos.containsKey(s)).toList();
    if (faltando.isEmpty && !forcar) {
      if (mounted) setState(() => _carregando = false);
      return;
    }

    setState(() => _carregando = true);

    try {
      final ativos = await CoinCapService.buscarAtivos(
        slugs.toList(),
        forcarAtualizacao: forcar,
      );
      if (mounted) {
        setState(() {
          for (final a in ativos) {
            final key = a.slug.toLowerCase();
            _cacheAtivos[key] = a;
            FavoritosService.instance.salvarAtivo(a);
          }
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
    FavoritosService.instance.salvarAtivo(ativo);
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

  Widget _cardFavorito(Asset ativo, bool isFavorito) {
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
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  FavoritosService.instance.alternar(ativo.slug, ativo);
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(seconds: 2),
                      backgroundColor: corCartao,
                      content: Text(
                        isFavorito
                            ? "${ativo.name} removido dos favoritos"
                            : "${ativo.name} adicionado aos favoritos!",
                        style: const TextStyle(color: Colors.white),
                      ),
                      action: isFavorito
                          ? SnackBarAction(
                              label: "Desfazer",
                              textColor: corDestaque,
                              onPressed: () {
                                FavoritosService.instance.adicionar(ativo.slug, ativo);
                              },
                            )
                          : null,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    isFavorito ? Icons.star : Icons.star_border,
                    color: isFavorito ? const Color(0xFFFBBF24) : Colors.white38,
                    size: 24,
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

            // ValueListenableBuilder atualiza a tela instantaneamente ao favoritar/desfavoritar
            Expanded(
              child: ValueListenableBuilder<Set<String>>(
                valueListenable: FavoritosService.instance.favoritosNotifier,
                builder: (context, favoritosSlugs, _) {
                  // Se houver novos slugs que ainda não foram sincronizados
                  final novos = favoritosSlugs.difference(_ultimosSlugsCarregados);
                  if (novos.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _sincronizarFavoritos(favoritosSlugs);
                    });
                  }

                  if (favoritosSlugs.isEmpty) {
                    return Center(
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
                    );
                  }

                  // Monta a lista com os ativos favoritados
                  final ativosFav = <Asset>[];
                  for (final slug in favoritosSlugs) {
                    final ativo = _cacheAtivos[slug] ?? FavoritosService.instance.ativosCache[slug];
                    if (ativo != null) {
                      ativosFav.add(ativo);
                    }
                  }

                  if (_carregando && ativosFav.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: corDestaque),
                    );
                  }

                  return RefreshIndicator(
                    color: corDestaque,
                    backgroundColor: corCartao,
                    onRefresh: () => _sincronizarFavoritos(favoritosSlugs, forcar: true),
                    child: ListView.builder(
                      itemCount: ativosFav.length,
                      itemBuilder: (context, i) {
                        final ativo = ativosFav[i];
                        final isFav = favoritosSlugs.contains(ativo.slug.toLowerCase());
                        return _cardFavorito(ativo, isFav);
                      },
                    ),
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
