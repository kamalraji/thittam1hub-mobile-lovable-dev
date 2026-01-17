import 'package:flutter/material.dart';
import 'package:thittam1hub/models/circle.dart';

class CircleDiscoveryCard extends StatelessWidget {
  final Circle circle;
  final int matchScore;
  final List<String> insights;
  final VoidCallback onJoin;
  final VoidCallback onTap;

  const CircleDiscoveryCard({
    Key? key,
    required this.circle,
    required this.matchScore,
    required this.insights,
    required this.onJoin,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(circle.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(circle.description ?? ''),
              const SizedBox(height: 8),
              Text('Match Score: $matchScore'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: onJoin,
                child: const Text('Join'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
