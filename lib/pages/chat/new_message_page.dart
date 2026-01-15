import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thittam1hub/models/models.dart';
import 'package:thittam1hub/services/chat_service.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';
import 'package:thittam1hub/theme.dart';

class NewMessagePage extends StatefulWidget {
  const NewMessagePage({super.key});
  @override
  State<NewMessagePage> createState() => _NewMessagePageState();
}

class _NewMessagePageState extends State<NewMessagePage> {
  final TextEditingController _search = TextEditingController();
  bool _loading = false;
  List<UserProfile> _results = [];

  @override
  void initState() {
    super.initState();
    _runSearch();
  }

  Future<void> _runSearch() async {
    setState(() => _loading = true);
    try {
      final list = await ChatService.searchParticipants(_search.text);
      if (mounted) setState(() => _results = list);
    } catch (e) {
      debugPrint('NewMessagePage search error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openDM(UserProfile user) {
    final me = SupabaseConfig.auth.currentUser?.id;
    if (me == null) return;
    final channelId = ChatService.dmChannelIdFor(me, user.id);
    context.push('/chat/$channelId', extra: {
      'dmUserId': user.id,
      'dmUserName': user.fullName?.isNotEmpty == true ? user.fullName : user.email,
      'dmUserAvatar': user.avatarUrl,
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 10, AppSpacing.md, 10),
          child: Row(children: [
            IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
            const SizedBox(width: 8),
            Text('New Message', style: context.textStyles.titleLarge),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: _SearchField(controller: _search, onChanged: (_) => _runSearch()),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: _results.length,
                  itemBuilder: (context, index) => _UserTile(user: _results[index], onTap: _openDM),
                ),
        ),
      ]),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.controller, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        const Icon(Icons.search, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: const InputDecoration(
              hintText: 'Search participants by name or email...',
              border: InputBorder.none,
            ),
          ),
        ),
      ]),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserProfile user;
  final void Function(UserProfile) onTap;
  const _UserTile({required this.user, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final name = user.fullName?.isNotEmpty == true ? user.fullName! : user.email;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => onTap(user),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6)),
        ),
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) ? NetworkImage(user.avatarUrl!) : null,
            child: (user.avatarUrl == null || user.avatarUrl!.isEmpty) ? const Icon(Icons.person, color: AppColors.textPrimary) : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: context.textStyles.titleMedium?.semiBold, overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }
}
