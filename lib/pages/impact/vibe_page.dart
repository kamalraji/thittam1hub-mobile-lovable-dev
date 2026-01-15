import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:thittam1hub/supabase/gamification_service.dart';

class VibePage extends StatefulWidget {
  const VibePage({Key? key}) : super(key: key);

  @override
  State<VibePage> createState() => _VibePageState();
}

class _VibePageState extends State<VibePage> {
  final _svc = GamificationService();
  VibeGameItem? _quick;
  VibeGameItem? _trivia;
  bool _loading = true;
  int? _selectedQuick;
  int? _selectedTrivia;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _svc.getActiveQuickMatch(),
        _svc.getActiveTrivia(),
      ]);
      if (!mounted) return;
      setState(() {
        _quick = results[0] as VibeGameItem?;
        _trivia = results[1] as VibeGameItem?;
        _loading = false;
      });
    } catch (e) {
      debugPrint('VibePage load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('🎮 Vibe Check', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (context) => const _MyVibesSheet(),
              );
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF8B5CF6)),
            child: const Text('Your Vibes'),
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSectionTitle('🔥 Live Now'),
                if (_quick != null)
                  QuickMatchCard(
                    game: _quick!,
                    selectedIndex: _selectedQuick,
                    onOption: (i) async {
                      setState(() => _selectedQuick = i);
                      try {
                        await _svc.submitQuickMatch(gameId: _quick!.id, optionIndex: i);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Answer submitted. Finding matches...')));
                      } catch (e) {
                        debugPrint('Quick match submit error: $e');
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to submit')));
                      }
                    },
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No live quick match right now.'),
                  ),
                _buildSectionTitle('🏆 Trivia Challenge'),
                if (_trivia != null)
                  TriviaCard(
                    trivia: _trivia!,
                    selectedIndex: _selectedTrivia,
                    onOption: (i) async {
                      setState(() => _selectedTrivia = i);
                      try {
                        final correct = await _svc.submitTrivia(trivia: _trivia!, optionIndex: i);
                        if (correct) {
                          await _svc.addImpactPoints(50);
                          await _svc.awardBadgeIfMissing('quiz_whiz');
                        }
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(correct ? 'Correct! +50 pts 🧠' : 'Nice try!')));
                      } catch (e) {
                        debugPrint('Trivia submit error: $e');
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to submit')));
                      }
                    },
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No active trivia at the moment.'),
                  ),
                _buildSectionTitle('🧊 Icebreaker of the Day'),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Come back soon for a new icebreaker!'),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );
}

class QuickMatchCard extends StatelessWidget {
  final VibeGameItem game;
  final int? selectedIndex;
  final ValueChanged<int> onOption;

  const QuickMatchCard({Key? key, required this.game, required this.selectedIndex, required this.onOption}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('⚡ QUICK MATCH', style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(game.question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          for (int i = 0; i < game.options.length; i++) _buildOption(context, i, game.options[i]),
          const SizedBox(height: 12),
          Text('⏱️ ends soon • ${game.participantCount} playing', style: TextStyle(color: Colors.grey[600])),
        ]),
      ),
    );
  }

  Widget _buildOption(BuildContext context, int index, String text) {
    final isSelected = selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ElevatedButton(
        onPressed: () => onOption(index),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFF8B5CF6) : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          minimumSize: const Size(double.infinity, 40),
        ),
        child: Text(text),
      ),
    );
  }
}

class TriviaCard extends StatelessWidget {
  final VibeGameItem trivia; // type TRIVIA
  final int? selectedIndex;
  final ValueChanged<int> onOption;

  const TriviaCard({Key? key, required this.trivia, required this.selectedIndex, required this.onOption}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('🏆 TRIVIA', style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(trivia.question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          for (int i = 0; i < trivia.options.length; i++) _buildOption(context, i, trivia.options[i]),
          const SizedBox(height: 12),
          Text('⏱️ ${(trivia.expiresAt.difference(DateTime.now()).inMinutes).clamp(0, 59)} min left • ${trivia.participantCount} playing', style: TextStyle(color: Colors.grey[600])),
        ]),
      ),
    );
  }

  Widget _buildOption(BuildContext context, int index, String text) {
    final isSelected = selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ElevatedButton(
        onPressed: () => onOption(index),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFF8B5CF6) : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          minimumSize: const Size(double.infinity, 40),
        ),
        child: Text(text),
      ),
    );
  }
}

class _MyVibesSheet extends StatelessWidget {
  const _MyVibesSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (context, scrollController) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Your Vibe History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: 3,
                itemBuilder: (context, index) => ListTile(
                  leading: const Icon(Icons.history),
                  title: Text('Vibe game #${index + 1}'),
                  subtitle: const Text('Played recently'),
                ),
              ),
            )
          ]),
        ),
      ),
    );
  }
}
