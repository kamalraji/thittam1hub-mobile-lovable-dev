import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:thittam1hub/supabase/gamification_service.dart';
import 'package:thittam1hub/utils/animations.dart';
import 'package:thittam1hub/widgets/glassmorphism_bottom_sheet.dart';
import 'package:thittam1hub/widgets/would_you_rather_card.dart';
import 'package:thittam1hub/widgets/compatibility_quiz.dart';
import 'package:thittam1hub/widgets/personality_game.dart';
import 'package:thittam1hub/widgets/icebreaker_card.dart';

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

  void _showVibeHistorySheet() {
    showGlassBottomSheet(
      context: context,
      title: 'Your Vibe History',
      child: const VibeHistoryContent(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        title: Text('🎮 Vibe Check',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _showVibeHistorySheet,
            style: TextButton.styleFrom(foregroundColor: cs.primary),
            child: const Text('Your Vibes'),
          )
        ],
      ),
      body: SafeArea(
        child: _loading
            ? ListView(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 16),
                children: List.generate(2, (_) => const VibeGameSkeleton()),
              )
            : BrandedRefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 16),
                  children: [
                    _buildSectionTitle('🔥 Live Now'),
                    if (_quick != null)
                      QuickMatchCard(
                        game: _quick!,
                        selectedIndex: _selectedQuick,
                        onOption: (i) async {
                          setState(() => _selectedQuick = i);
                          try {
                            await _svc.submitQuickMatch(
                                gameId: _quick!.id, optionIndex: i);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Answer submitted. Finding matches...')));
                          } catch (e) {
                            debugPrint('Quick match submit error: $e');
                            if (mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Failed to submit')));
                          }
                        },
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('No live quick match right now.',
                            style: textTheme.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      ),
                    _buildSectionTitle('🏆 Trivia Challenge'),
                    if (_trivia != null)
                      TriviaCard(
                        trivia: _trivia!,
                        selectedIndex: _selectedTrivia,
                        onOption: (i) async {
                          setState(() => _selectedTrivia = i);
                          try {
                            final correct = await _svc.submitTrivia(
                                trivia: _trivia!, optionIndex: i);
                            if (correct) {
                              await _svc.addImpactPoints(50);
                              await _svc.awardBadgeIfMissing('quiz_whiz');
                            }
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(correct
                                    ? 'Correct! +50 pts 🧠'
                                    : 'Nice try!')));
                          } catch (e) {
                            debugPrint('Trivia submit error: $e');
                            if (mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Failed to submit')));
                          }
                        },
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('No active trivia at the moment.',
                            style: textTheme.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      ),
                    _buildSectionTitle('🧊 Icebreaker of the Day'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: IcebreakerCard(
                        id: 'icebreaker_1',
                        question:
                            "What's the most underrated skill in your field?",
                        onSubmitAnswer: (answer) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Answer shared with the community!')),
                          );
                        },
                        onSeeAnswers: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => IcebreakerAnswersSheet(
                              question:
                                  "What's the most underrated skill in your field?",
                              answers: const [
                                IcebreakerAnswer(
                                    userName: 'Alex',
                                    userAvatar: null,
                                    answer: 'Communication skills',
                                    timestamp: 'Just now'),
                                IcebreakerAnswer(
                                    userName: 'Sam',
                                    userAvatar: null,
                                    answer: 'Time management',
                                    timestamp: '5m ago'),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('💭 Would You Rather'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: WouldYouRatherCard(
                        id: 'wyr_1',
                        optionA: 'Work remotely forever',
                        optionB: 'Work in office forever',
                        onVote: (choice) async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('You chose: $choice')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('🧠 Personality Quiz'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: PersonalityGameCard(
                        onTakeQuiz: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => PersonalityQuizPage(
                                onComplete: (type) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('You are: ${type.title}!')),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('💕 Compatibility Check'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: CompatibilityQuizCard(
                        partnerName: 'Find a partner',
                        onStart: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Select a connection to take the quiz with!')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(title,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
    );
  }
}

class QuickMatchCard extends StatelessWidget {
  final VibeGameItem game;
  final int? selectedIndex;
  final ValueChanged<int> onOption;

  const QuickMatchCard(
      {Key? key,
      required this.game,
      required this.selectedIndex,
      required this.onOption})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('⚡ QUICK MATCH',
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(game.question,
              style:
                  textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          for (int i = 0; i < game.options.length; i++)
            _buildOption(context, i, game.options[i]),
          const SizedBox(height: 12),
          Text('⏱️ ends soon • ${game.participantCount} playing',
              style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ]),
      ),
    );
  }

  Widget _buildOption(BuildContext context, int index, String text) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ElevatedButton(
        onPressed: () => onOption(index),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? cs.primary : cs.surfaceContainerHighest,
          foregroundColor: isSelected ? cs.onPrimary : cs.onSurface,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  const TriviaCard(
      {Key? key,
      required this.trivia,
      required this.selectedIndex,
      required this.onOption})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('🏆 TRIVIA',
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(trivia.question,
              style:
                  textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          for (int i = 0; i < trivia.options.length; i++)
            _buildOption(context, i, trivia.options[i]),
          const SizedBox(height: 12),
          Text(
              '⏱️ ${(trivia.expiresAt.difference(DateTime.now()).inMinutes).clamp(0, 59)} min left • ${trivia.participantCount} playing',
              style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ]),
      ),
    );
  }

  Widget _buildOption(BuildContext context, int index, String text) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ElevatedButton(
        onPressed: () => onOption(index),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? cs.primary : cs.surfaceContainerHighest,
          foregroundColor: isSelected ? cs.onPrimary : cs.onSurface,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          minimumSize: const Size(double.infinity, 40),
        ),
        child: Text(text),
      ),
    );
  }
}

/// Content for vibe history glassmorphism sheet
class VibeHistoryContent extends StatelessWidget {
  const VibeHistoryContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: 3,
            itemBuilder: (context, index) => ListTile(
              leading: Icon(Icons.history, color: cs.primary),
              title:
                  Text('Vibe game #${index + 1}', style: textTheme.bodyMedium),
              subtitle: Text('Played recently',
                  style: textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ),
          ),
        ),
      ],
    );
  }
}

class VibeGameSkeleton extends StatelessWidget {
  const VibeGameSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                height: 14, width: 100, color: cs.surfaceContainerHighest),
            const SizedBox(height: 12),
            Container(
                height: 18,
                width: double.infinity,
                color: cs.surfaceContainerHighest),
            const SizedBox(height: 16),
            ...List.generate(
                3,
                (_) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10))),
                    )),
          ],
        ),
      ),
    );
  }
}
