import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/group_chat_service.dart';
import '../../widgets/styled_button.dart';
import '../../theme.dart';

class AddGroupMembersPage extends StatefulWidget {
  final String groupId;

  const AddGroupMembersPage({super.key, required this.groupId});

  @override
  State<AddGroupMembersPage> createState() => _AddGroupMembersPageState();
}

class _AddGroupMembersPageState extends State<AddGroupMembersPage> {
  final _supabase = Supabase.instance.client;
  final _groupService = GroupChatService();
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _connections = [];
  Set<String> _existingMemberIds = {};
  Set<String> _selectedIds = {};
  bool _isLoading = true;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Get existing group members
      final members = await _groupService.getGroupMembers(widget.groupId);
      _existingMemberIds = members.map((m) => m.userId).toSet();

      // Get user's connections (accepted)
      final connections = await _supabase
          .from('connections')
          .select('''
            *,
            requester:impact_profiles!connections_requester_id_fkey (
              user_id, full_name, avatar_url, is_online
            ),
            receiver:impact_profiles!connections_receiver_id_fkey (
              user_id, full_name, avatar_url, is_online
            )
          ''')
          .eq('status', 'ACCEPTED')
          .or('requester_id.eq.$userId,receiver_id.eq.$userId');

      // Map to list of potential members (excluding self and existing members)
      final List<Map<String, dynamic>> potentialMembers = [];
      for (final conn in connections) {
        final requester = conn['requester'] as Map<String, dynamic>?;
        final receiver = conn['receiver'] as Map<String, dynamic>?;

        if (requester != null && requester['user_id'] != userId) {
          if (!_existingMemberIds.contains(requester['user_id'])) {
            potentialMembers.add(requester);
          }
        }
        if (receiver != null && receiver['user_id'] != userId) {
          if (!_existingMemberIds.contains(receiver['user_id'])) {
            potentialMembers.add(receiver);
          }
        }
      }

      // Remove duplicates
      final seen = <String>{};
      _connections = potentialMembers.where((m) {
        final id = m['user_id'] as String;
        if (seen.contains(id)) return false;
        seen.add(id);
        return true;
      }).toList();

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load connections: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredConnections {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _connections;

    return _connections.where((c) {
      final name = (c['full_name'] as String? ?? '').toLowerCase();
      return name.contains(query);
    }).toList();
  }

  Future<void> _addMembers() async {
    if (_selectedIds.isEmpty) return;

    setState(() => _isAdding = true);

    try {
      await _groupService.addMembers(widget.groupId, _selectedIds.toList());

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${_selectedIds.length} member(s)'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add members: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Members'),
        actions: [
          if (_selectedIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_selectedIds.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search connections...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
            ),
          ),

          // Selected Members Preview
          if (_selectedIds.isNotEmpty)
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _selectedIds.length,
                itemBuilder: (context, index) {
                  final id = _selectedIds.elementAt(index);
                  final member = _connections.firstWhere(
                    (c) => c['user_id'] == id,
                    orElse: () => {'full_name': 'Unknown'},
                  );
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: member['avatar_url'] != null
                                  ? NetworkImage(member['avatar_url'])
                                  : null,
                              child: member['avatar_url'] == null
                                  ? Text(
                                      (member['full_name'] as String? ?? 'U')[0]
                                          .toUpperCase(),
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: -4,
                              top: -4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _selectedIds.remove(id));
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 60,
                          child: Text(
                            member['full_name'] as String? ?? 'Unknown',
                            style: const TextStyle(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          if (_selectedIds.isNotEmpty) const Divider(),

          // Connections List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredConnections.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _connections.isEmpty
                                  ? 'No connections to add'
                                  : 'No matching connections',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredConnections.length,
                        itemBuilder: (context, index) {
                          final member = _filteredConnections[index];
                          final userId = member['user_id'] as String;
                          final isSelected = _selectedIds.contains(userId);

                          return ListTile(
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  backgroundImage: member['avatar_url'] != null
                                      ? NetworkImage(member['avatar_url'])
                                      : null,
                                  child: member['avatar_url'] == null
                                      ? Text(
                                          (member['full_name'] as String? ??
                                                  'U')[0]
                                              .toUpperCase(),
                                        )
                                      : null,
                                ),
                                if (member['is_online'] == true)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .scaffoldBackgroundColor,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title:
                                Text(member['full_name'] as String? ?? 'Unknown'),
                            trailing: Checkbox(
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedIds.add(userId);
                                  } else {
                                    _selectedIds.remove(userId);
                                  }
                                });
                              },
                              activeColor: AppColors.primary,
                            ),
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedIds.remove(userId);
                                } else {
                                  _selectedIds.add(userId);
                                }
                              });
                            },
                          );
                        },
                      ),
          ),

          // Add Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StyledButton(
                onPressed:
                    _selectedIds.isEmpty || _isAdding ? null : _addMembers,
                label: _isAdding
                    ? 'Adding...'
                    : 'Add ${_selectedIds.length} Member${_selectedIds.length == 1 ? '' : 's'}',
                icon: Icons.person_add,
                isLoading: _isAdding,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
