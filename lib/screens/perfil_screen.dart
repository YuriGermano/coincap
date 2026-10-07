import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/formatadores.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _usuario;
  bool _carregando = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _carregarUsuario();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _carregarUsuario() async {
    final usuario = await AuthService.usuarioAtual();
    if (mounted) {
      setState(() {
        _usuario = usuario;
        _carregando = false;
      });
      _animController.forward();
    }
  }

  String _formatarData(String? iso) {
    if (iso == null) return '-';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return '-';
    }
  }

  String _iniciais(String? nome) {
    if (nome == null || nome.isEmpty) return '?';
    final partes = nome.trim().split(' ');
    if (partes.length == 1) return partes[0][0].toUpperCase();
    return '${partes[0][0]}${partes.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0014),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF26003F), Color(0xFF0A0014)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Perfil',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _carregando
                    ? const Center(
                        child: CircularProgressIndicator(color: corDestaque))
                    : FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                            child: Column(
                              children: [
                                _avatar(),
                                const SizedBox(height: 16),
                                Text(
                                  _usuario?['nome'] ?? '-',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _usuario?['email'] ?? '-',
                                  style: const TextStyle(
                                    color: corTextoSuave,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                _secaoInfo(),
                                const SizedBox(height: 32),
                                _botaoSair(),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar() {
    final iniciais = _iniciais(_usuario?['nome']);
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: corDestaque,
      ),
      child: Center(
        child: Text(
          iniciais,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _secaoInfo() {
    return Container(
      decoration: BoxDecoration(
        color: corCartao,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _linhaInfo(
            icone: Icons.person_outline,
            titulo: 'Nome',
            valor: _usuario?['nome'] ?? '-',
          ),
          Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
          _linhaInfo(
            icone: Icons.email_outlined,
            titulo: 'E-mail',
            valor: _usuario?['email'] ?? '-',
          ),
          Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
          _linhaInfo(
            icone: Icons.calendar_today_outlined,
            titulo: 'Membro desde',
            valor: _formatarData(_usuario?['criado_em']),
          ),
        ],
      ),
    );
  }

  Widget _linhaInfo({
    required IconData icone,
    required String titulo,
    required String valor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: corPilula,
            child: Icon(icone, color: corDestaque, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: corTextoSuave,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _botaoSair() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Container(
        decoration: BoxDecoration(
          color: corCartao,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: corVermelha.withValues(alpha: 0.35),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              AuthService.logout();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.logout, color: corVermelha, size: 20),
                SizedBox(width: 10),
                Text(
                  'Sair da conta',
                  style: TextStyle(
                    color: corVermelha,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
