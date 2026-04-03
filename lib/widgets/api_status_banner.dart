import 'package:flutter/material.dart';

import 'package:reelboost_ai/core/config/api_config.dart';
import 'package:reelboost_ai/services/api_bootstrap.dart';
import 'package:reelboost_ai/services/api_runtime.dart';
import 'package:reelboost_ai/services/api_service.dart';

/// Shown when `/health` failed at startup or after Retry still failing.
class ApiStatusBanner extends StatefulWidget {
  const ApiStatusBanner({super.key});

  @override
  State<ApiStatusBanner> createState() => _ApiStatusBannerState();
}

class _ApiStatusBannerState extends State<ApiStatusBanner> {
  bool _busy = false;
  late final TextEditingController _serverCtrl;

  @override
  void initState() {
    super.initState();
    _serverCtrl = TextEditingController(text: _initialServerText());
  }

  String _initialServerText() {
    final m = ApiRuntime.stickyManualApiBase;
    if (m != null && m.isNotEmpty) {
      return ApiService.originFromApiBase(m);
    }
    return ApiService.originFromApiBase(ApiService.baseUrl);
  }

  @override
  void dispose() {
    _serverCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveServerUrl(BuildContext context) async {
    final raw = _serverCtrl.text.trim();
    if (raw.isEmpty) {
      setState(() => _busy = true);
      try {
        await ApiBootstrap.clearManualApiBaseAndReinitialize();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed saved PC address')),
          );
        }
        if (mounted) setState(() {});
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }
    setState(() => _busy = true);
    try {
      await ApiBootstrap.saveManualApiBaseAndReinitialize(raw);
      if (!context.mounted) return;
      if (ApiRuntime.healthCheckOk) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connected to server')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiRuntime.bootstrapDetail ??
                  'Still cannot reach the server. Check connection and Railway.',
            ),
          ),
        );
      }
      setState(() {});
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ApiRuntime.healthCheckOk) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: const Color(0x33FF9800),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.wifi_off_rounded, color: Colors.orange.shade200, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Backend unreachable',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.orange.shade100,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SelectableText(
                ApiService.baseUrl,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
              ),
              if (ApiService.usesCompileTimeDefaultApiBase) ...[
                const SizedBox(height: 6),
                Text(
                  'Tip: default API is production (HTTPS on Railway). Check internet. To use another server, set the URL below or build with --dart-define=API_BASE_URL=<your-https-url>/api',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, height: 1.3),
                ),
              ],
              if (ApiRuntime.bootstrapDetail != null) ...[
                const SizedBox(height: 6),
                Text(
                  ApiRuntime.bootstrapDetail!,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12, height: 1.35),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'API server URL',
                style: TextStyle(
                  color: Colors.orange.shade100,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _serverCtrl,
                enabled: !_busy,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: ApiConfig.apiOrigin,
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.25),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _busy ? null : () => _saveServerUrl(context),
                    icon: _busy
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange.shade900),
                          )
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(_busy ? 'Saving…' : 'Save & connect'),
                  ),
                  TextButton.icon(
                    onPressed: _busy
                        ? null
                        : () async {
                            setState(() => _busy = true);
                            await ApiBootstrap.recheckHealth();
                            if (mounted) setState(() => _busy = false);
                          },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry'),
                  ),
                  TextButton.icon(
                    onPressed: _busy
                        ? null
                        : () async {
                            setState(() => _busy = true);
                            await ApiBootstrap.clearCachedApiBaseAndReinitialize();
                            if (mounted) setState(() => _busy = false);
                          },
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Clear auto server'),
                  ),
                  TextButton.icon(
                    onPressed: _busy
                        ? null
                        : () async {
                            setState(() => _busy = true);
                            await ApiBootstrap.clearManualApiBaseAndReinitialize();
                            _serverCtrl.clear();
                            if (mounted) setState(() => _busy = false);
                          },
                    icon: const Icon(Icons.link_off_rounded, size: 18),
                    label: const Text('Clear saved IP'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
