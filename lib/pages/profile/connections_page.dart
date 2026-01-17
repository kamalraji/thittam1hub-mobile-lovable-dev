import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:thittam1hub/models/connection.dart';
import 'package:thittam1hub/models/impact_profile.dart';
import 'package:thittam1hub/services/connections_service.dart';
import 'package:thittam1hub/supabase/impact_service.dart';
import 'package:thittam1hub/theme.dart';
import 'package:thittam1hub/widgets/connection_card.dart';
import 'package:thittam1hub/utils/animations.dart';

/// Connections page with tabs for mutual, pending, and suggestions
class ConnectionsPage extends StatefulWidget {
  const ConnectionsPage({super.key});

  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> with SingleTickerProviderStateMixin {
  final _connectionsService = ConnectionsService();
  final _impactService = ImpactService();
  
  late TabController _tabController;
  
  List<Connection> _mutualConnections = [];
  List<Connection> _pendingRequests = [];
  List<ImpactProfile> _suggestions = [];
  
  bool _isLoading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTab = _tabController.index);
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _connectionsService.getAcceptedConnections(),
        _connectionsService.getIncomingPendingRequests(),
        _connectionsService.getSuggestedConnections(limit: 15),
      ]);

      if (mounted) {
        setState(() {
          _mutualConnections = results[0] as List<Connection>;
          _pendingRequests = results[1] as List<Connection>;
          _suggestions = results[2] as List<ImpactProfile>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Load connections error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptRequest(Connection connection) async {
    final success = await _connectionsService.acceptRequest(connection.id);
    if (success) {
      HapticFeedback.mediumImpact();
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected with ${connection.otherUserName}!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _declineRequest(Connection connection) async {
    final success = await _connectionsService.declineRequest(connection.id);
    if (success) {
      HapticFeedback.lightImpact();
      _loadData();
    }
  }

  Future<void> _sendRequest(ImpactProfile profile) async {
    final success = await _connectionsService.sendRequest(profile.userId);
    if (success) {
      HapticFeedback.mediumImpact();
      setState(() {
        _suggestions.removeWhere((p) => p.userId == profile.userId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request sent to ${profile.fullName}!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _navigateToProfile(String userId) {
    context.push('/impact/profile/$userId');
  }

  void _startChat(Connection connection) {
    context.push('/chat/${connection.otherUserId}', extra: {
      'dmUserId': connection.otherUserId,
      'dmUserName': connection.otherUserName,
      'dmUserAvatar': connection.otherUserAvatar,
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connections'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Mutual (${_mutualConnections.length})'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pending'),
                  if (_pendingRequests.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_pendingRequests.length}',
                        style: context.textStyles.labelSmall?.copyWith(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Suggestions'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMutualTab(),
                _buildPendingTab(),
                _buildSuggestionsTab(),
              ],
            ),
    );
  }

  Widget _buildMutualTab() {
    if (_mutualConnections.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        title: 'No connections yet',
        subtitle: 'Connect with others to grow your network',
        actionLabel: 'Find People',
        onAction: () => _tabController.animateTo(2),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _mutualConnections.length,
        itemBuilder: (context, index) {
          final connection = _mutualConnections[index];
          return FadeSlideTransition(
            delay: staggerDelay(index),
            child: ConnectionCard(
              connection: connection,
              onTap: () => _navigateToProfile(connection.otherUserId),
              onMessage: () => _startChat(connection),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_pendingRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.hourglass_empty,
        title: 'No pending requests',
        subtitle: 'When someone wants to connect, you\'ll see them here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingRequests.length,
        itemBuilder: (context, index) {
          final connection = _pendingRequests[index];
          return FadeSlideTransition(
            delay: staggerDelay(index),
            child: ConnectionCard(
              connection: connection,
              onTap: () => _navigateToProfile(connection.otherUserId),
              onAccept: () => _acceptRequest(connection),
              onDecline: () => _declineRequest(connection),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuggestionsTab() {
    if (_suggestions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_search,
        title: 'No suggestions available',
        subtitle: 'Check back later for new connection suggestions',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final profile = _suggestions[index];
          // Calculate match score
          int matchScore = 0;
          String? matchReason;
          
          return FutureBuilder<ImpactProfile?>(
            future: _impactService.getMyImpactProfile(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                final result = _impactService.calculateMatchInsights(snapshot.data!, profile);
                matchScore = result.totalScore;
                matchReason = result.summaryText;
              }
              
              return FadeSlideTransition(
                delay: staggerDelay(index),
                child: SuggestionCard(
                  profile: profile,
                  matchScore: matchScore,
                  matchReason: matchReason,
                  onTap: () => _navigateToProfile(profile.userId),
                  onConnect: () => _sendRequest(profile),
                  onSkip: () {
                    setState(() {
                      _suggestions.removeAt(index);
                    });
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: context.textStyles.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: context.textStyles.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
