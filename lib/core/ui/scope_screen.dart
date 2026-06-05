import 'package:flutter/material.dart';
import '../di/service_locator.dart';

class ScopeScreen extends StatefulWidget {
  final void Function(ScopedServiceLocator scope) onInit;
  final Widget Function(BuildContext context) builder;
  final void Function(ScopedServiceLocator scope)? onDispose;
  final String? scopeName;

  const ScopeScreen({
    super.key,
    required this.onInit,
    required this.builder,
    this.onDispose,
    this.scopeName,
  });

  @override
  State<ScopeScreen> createState() => _ScopeScreenState();
}

class _ScopeScreenState extends State<ScopeScreen> {
  late final ScopedServiceLocator _scope;

  @override
  void initState() {
    super.initState();
    _scope = locator.createScope(name: widget.scopeName);
    widget.onInit(_scope);
  }

  @override
  void dispose() {
    widget.onDispose?.call(_scope);
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
