import 'package:flutter/material.dart';

import '../application/app_controller.dart';
import '../core/theme.dart';
import 'widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _login() {
    if (_form.currentState!.validate()) {
      widget.controller.login(_username.text, _password.text);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Brand(),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: ChifaColors.red,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Pill(
                                'HECHO PARA ATENDER',
                                color: Color(0xFFFFDFA8),
                              ),
                              const SizedBox(height: 15),
                              const Text(
                                'Buen servicio.\nBuenos momentos.',
                                style: TextStyle(
                                  fontSize: 26,
                                  height: 1.15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -.7,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'El sabor de siempre,\na un pedido de distancia.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: .78),
                                  height: 1.5,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DishArt(
                          size: MediaQuery.sizeOf(context).width < 360
                              ? 70
                              : 106,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Bienvenido al equipo',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ingresa para comenzar a atender tus mesas.',
                    style: TextStyle(color: ChifaColors.muted),
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _form,
                    child: AutofillGroup(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _username,
                            enabled: !widget.controller.busy,
                            autofillHints: const [AutofillHints.username],
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Usuario',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Ingresa tu usuario'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _password,
                            enabled: !widget.controller.busy,
                            obscureText: _obscure,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _login(),
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                tooltip: _obscure
                                    ? 'Mostrar contraseña'
                                    : 'Ocultar contraseña',
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Ingresa tu contraseña'
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.controller.error != null)
                    ErrorNotice(widget.controller.error!),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: widget.controller.busy ? null : _login,
                      icon: widget.controller.busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_forward_rounded),
                      label: Text(
                        widget.controller.busy
                            ? 'Ingresando…'
                            : 'Comenzar mi turno',
                      ),
                    ),
                  ),
                  if (widget.controller.isDemo) ...[
                    const SizedBox(height: 22),
                    Paper(
                      color: const Color(0xFFF0E9DD),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.science_outlined,
                                size: 18,
                                color: ChifaColors.gold,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'MODO DEMOSTRACIÓN',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Usuario: mozo o lucia · Contraseña: 123456\nClave de administrador: 2468',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.7,
                              color: ChifaColors.muted,
                            ),
                          ),
                          TextButton(
                            onPressed: widget.controller.busy
                                ? null
                                : () {
                                    _username.text = 'mozo';
                                    _password.text = '123456';
                                  },
                            child: const Text('Usar acceso de prueba'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 26),
                  const Center(
                    child: Text(
                      'CHIFA CENTRO  ·  PEDIDOS CON TRADICIÓN',
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.5,
                        color: ChifaColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
