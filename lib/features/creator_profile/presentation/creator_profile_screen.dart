import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reelboost_ai/core/constants/profile_niches.dart';
import 'package:reelboost_ai/core/providers/app_providers.dart';
import 'package:reelboost_ai/core/theme/app_theme.dart';
import 'package:reelboost_ai/core/utils/api_error_message.dart';
import 'package:reelboost_ai/features/creator_profile/domain/creator_profile.dart';
import 'package:reelboost_ai/widgets/app_card.dart';
import 'package:reelboost_ai/widgets/app_loading_indicator.dart';
import 'package:reelboost_ai/features/creator_profile/presentation/profile_settings_card.dart';
import 'package:reelboost_ai/widgets/gradient_button.dart';

class CreatorProfileScreen extends ConsumerStatefulWidget {
  const CreatorProfileScreen({super.key});

  @override
  ConsumerState<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends ConsumerState<CreatorProfileScreen> {
  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _instagram = TextEditingController();
  final _facebook = TextEditingController();

  String _nicheValue = '';
  int _formSeed = 0;
  bool _loading = true;
  bool _saving = false;
  bool _editing = false;
  String? _loadError;
  String _accountEmail = '';

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _instagram.dispose();
    _facebook.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  List<String> _nicheChoices() {
    if (_nicheValue.isNotEmpty && !kProfileNiches.contains(_nicheValue)) {
      return [...kProfileNiches, _nicheValue];
    }
    return kProfileNiches;
  }

  void _applyProfileToFields(CreatorProfile p) {
    _name.text = p.name;
    _bio.text = p.bio;
    _instagram.text = p.instagramLink;
    _facebook.text = p.facebookLink;
    _nicheValue = p.niche;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final repo = ref.read(creatorProfileRepositoryProvider);
    final authUser = ref.read(authControllerProvider).asData?.value;
    try {
      final profile = await repo.load();
      if (!mounted) return;
      final empty = profile.name.isEmpty &&
          profile.bio.isEmpty &&
          profile.instagramLink.isEmpty &&
          profile.facebookLink.isEmpty &&
          profile.niche.isEmpty;
      setState(() {
        _formSeed++;
        _applyProfileToFields(profile);
        _accountEmail = authUser?.email ?? '';
        _editing = empty;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancelEdit() async {
    setState(() => _editing = false);
    await _load();
  }

  Future<void> _save() async {
    if (_nicheValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a niche')),
      );
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(creatorProfileRepositoryProvider);
    final draft = CreatorProfile(
      name: _name.text.trim(),
      niche: _nicheValue,
      bio: _bio.text.trim(),
      instagramLink: _instagram.text.trim(),
      facebookLink: _facebook.text.trim(),
    );
    try {
      final updated = await repo.save(draft);
      final prev = ref.read(authControllerProvider).asData?.value;
      final merged = prev == null
          ? updated
          : updated.withPostAnalyzeUsage(
              isPremium: updated.isPremium,
              postAnalyzeLimit: updated.postAnalyzeLimit ?? prev.postAnalyzeLimit,
              postAnalyzeRemaining: updated.postAnalyzeRemaining ?? prev.postAnalyzeRemaining,
              postAnalyzeAdRewardsRemaining:
                  updated.postAnalyzeAdRewardsRemaining ?? prev.postAnalyzeAdRewardsRemaining,
            );
      ref.read(authControllerProvider.notifier).applyUser(merged);
      if (!mounted) return;
      setState(() {
        _formSeed++;
        _applyProfileToFields(CreatorProfile.fromUserModel(updated));
        _editing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_loading && _loadError == null && !_editing)
            IconButton(
              tooltip: 'Edit profile',
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_rounded),
            ),
          if (!_loading && _loadError == null && _editing)
            IconButton(
              tooltip: 'Cancel',
              onPressed: _saving ? null : _cancelEdit,
              icon: const Icon(Icons.close_rounded),
            ),
          IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.scaffoldGradient(context)),
        child: SafeArea(
          child: _loading
              ? const Center(child: AppLoadingIndicator(size: 40, message: 'Loading profile…'))
              : _loadError != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_loadError!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _load,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppCard(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    gradient: AppTheme.primaryGradient,
                                    boxShadow: AppTheme.buttonShadow,
                                  ),
                                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Your profile',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Keep this up to date — it powers smarter suggestions across the app.',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          fontSize: 12,
                                          height: 1.35,
                                        ),
                                      ),
                                      if (_accountEmail.isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        Text(
                                          _accountEmail,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.45),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (!_editing) ...[
                            _SectionCard(
                              icon: Icons.badge_outlined,
                              title: 'Details',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _ReadOnlyField(label: 'Name', value: _name.text),
                                  _ReadOnlyField(label: 'Niche', value: _nicheValue.isEmpty ? '—' : _nicheValue),
                                  _ReadOnlyField(label: 'Bio', value: _bio.text.isEmpty ? '—' : _bio.text),
                                  _ReadOnlyField(
                                    label: 'Instagram',
                                    value: _instagram.text.isEmpty ? '—' : _instagram.text,
                                  ),
                                  _ReadOnlyField(
                                    label: 'Facebook',
                                    value: _facebook.text.isEmpty ? '—' : _facebook.text,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            GradientButton(
                              label: 'Edit profile',
                              loading: false,
                              onPressed: () => setState(() => _editing = true),
                              icon: Icons.edit_rounded,
                            ),
                          ] else ...[
                            _SectionCard(
                              icon: Icons.badge_outlined,
                              title: 'Edit',
                              child: Column(
                                children: [
                                  TextField(
                                    controller: _name,
                                    decoration: const InputDecoration(labelText: 'Name'),
                                    textCapitalization: TextCapitalization.words,
                                  ),
                                  const SizedBox(height: 14),
                                  DropdownButtonFormField<String>(
                                    key: ValueKey(_formSeed),
                                    initialValue: _nicheValue.isEmpty ? null : _nicheValue,
                                    decoration: const InputDecoration(labelText: 'Niche'),
                                    hint: const Text('Select niche'),
                                    items: _nicheChoices()
                                        .map(
                                          (n) => DropdownMenuItem<String>(
                                            value: n,
                                            child: Text(n, overflow: TextOverflow.ellipsis),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) => setState(() => _nicheValue = v ?? ''),
                                  ),
                                  const SizedBox(height: 14),
                                  TextField(
                                    controller: _bio,
                                    maxLines: 4,
                                    maxLength: 500,
                                    decoration: const InputDecoration(
                                      labelText: 'Bio',
                                      alignLabelWithHint: true,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _instagram,
                                    decoration: const InputDecoration(
                                      labelText: 'Instagram link',
                                      hintText: 'URL or @handle',
                                    ),
                                    keyboardType: TextInputType.url,
                                  ),
                                  const SizedBox(height: 14),
                                  TextField(
                                    controller: _facebook,
                                    decoration: const InputDecoration(
                                      labelText: 'Facebook link',
                                      hintText: 'https://…',
                                    ),
                                    keyboardType: TextInputType.url,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _saving ? null : _cancelEdit,
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: GradientButton(
                                    label: 'Save profile',
                                    loading: _saving,
                                    onPressed: _saving ? null : _save,
                                    icon: Icons.save_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 20),
                          const ProfileSettingsCard(),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.onCardSecondary(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.35,
                  color: AppTheme.onCardPrimary(context),
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: AppTheme.accent2.withValues(alpha: 0.95)),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
