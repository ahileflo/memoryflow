import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../widgets/brand_button.dart';
import '../../widgets/common.dart';
import '../../widgets/provider_tile.dart';

/// Step 1: link a photo source. The CTA stays disabled until at least one
/// source is selected. In mock mode "Continue" runs the scan animation. In
/// backend mode it kicks off a real read-only import (Edge Function) and the
/// scanning screen reflects live progress.
class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  bool _starting = false;
  String? _error;

  Future<void> _continue(Set<String> selected) async {
    if (!AppConfig.backendEnabled) {
      context.go(Routes.scanning);
      return;
    }
    // Backend mode: start a real import for the first selected provider.
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final provider = selected.first;
      final job = await ref
          .read(repositoryProvider)
          .startImport(provider: provider, mode: 'sample');
      ref.read(currentImportJobIdProvider.notifier).state = job.id;
      if (mounted) context.go(Routes.scanning);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Could not start import: $e');
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final selected = ref.watch(connectSelectionProvider);
    final selection = ref.read(connectSelectionProvider.notifier);
    final count = selected.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
                children: [
                  const Eyebrow('Step 1 of 2'),
                  const SizedBox(height: 10),
                  Text('Connect your photos',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                    'Link one account to start. We never delete or move your originals — we only read them to organize.',
                    style: TextStyle(color: BrandColors.muted, fontSize: 14.5, height: 1.5),
                  ),
                  if (AppConfig.backendEnabled) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: BrandColors.panel,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '🧪 Demo import: selecting a source runs a small sample import into your real database. Real Google sign-in needs OAuth configured (see docs).',
                        style: TextStyle(
                            fontSize: 12, color: BrandColors.violetDark, height: 1.4),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  accountsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Text('Could not load sources: $e'),
                    data: (accounts) => Column(
                      children: [
                        for (final a in accounts) ...[
                          ProviderTile(
                            account: a,
                            selected: selection.isOn(a.id),
                            onTap: () => selection.toggle(a.id),
                          ),
                          const SizedBox(height: 11),
                        ],
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!,
                        style: const TextStyle(color: BrandColors.coral, fontSize: 13)),
                  ],
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: BrandColors.line)),
              ),
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
              child: Column(
                children: [
                  if (_starting)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    BrandButton(
                      label: count > 0
                          ? 'Continue ($count connected) →'
                          : 'Connect a source to continue',
                      onPressed: count > 0 ? () => _continue(selected) : null,
                    ),
                  const SizedBox(height: 10),
                  const Text(
                    '🔒 GDPR-compliant · revoke access anytime',
                    style: TextStyle(fontSize: 11.5, color: BrandColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
