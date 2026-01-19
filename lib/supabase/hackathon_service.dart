import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/hackathon_models.dart';

/// Service for hackathon-specific Zone features
class HackathonService {
  final SupabaseClient _supabase;

  HackathonService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // ==================== TEAMS ====================

  /// Get all teams for an event
  Future<List<HackathonTeam>> getEventTeams(String eventId) async {
    final response = await _supabase
        .from('hackathon_teams')
        .select('''
          *,
          hackathon_team_members(*)
        ''')
        .eq('event_id', eventId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => HackathonTeam.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get teams looking for members
  Future<List<HackathonTeam>> getTeamsLookingForMembers(String eventId) async {
    final response = await _supabase
        .from('hackathon_teams')
        .select('''
          *,
          hackathon_team_members(*)
        ''')
        .eq('event_id', eventId)
        .eq('is_looking_for_members', true)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => HackathonTeam.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get user's team for an event
  Future<HackathonTeam?> getUserTeam(String eventId) async {
    if (_currentUserId == null) return null;

    final memberResponse = await _supabase
        .from('hackathon_team_members')
        .select('team_id')
        .eq('user_id', _currentUserId!)
        .maybeSingle();

    if (memberResponse == null) return null;

    final teamResponse = await _supabase
        .from('hackathon_teams')
        .select('''
          *,
          hackathon_team_members(*)
        ''')
        .eq('id', memberResponse['team_id'])
        .eq('event_id', eventId)
        .maybeSingle();

    if (teamResponse == null) return null;
    return HackathonTeam.fromJson(teamResponse as Map<String, dynamic>);
  }

  /// Create a new team
  Future<HackathonTeam> createTeam({
    required String eventId,
    required String name,
    String? description,
    String? projectIdea,
    List<String>? techStack,
    List<String>? lookingForRoles,
    int maxMembers = 5,
  }) async {
    final response = await _supabase
        .from('hackathon_teams')
        .insert({
          'event_id': eventId,
          'name': name,
          'description': description,
          'project_idea': projectIdea,
          'tech_stack': techStack ?? [],
          'looking_for_roles': lookingForRoles ?? [],
          'max_members': maxMembers,
          'created_by': _currentUserId,
        })
        .select()
        .single();

    final team = HackathonTeam.fromJson(response as Map<String, dynamic>);

    // Add creator as team lead
    await _supabase.from('hackathon_team_members').insert({
      'team_id': team.id,
      'user_id': _currentUserId,
      'role': 'lead',
    });

    return team;
  }

  /// Join a team
  Future<void> joinTeam(String teamId, {List<String>? skills}) async {
    await _supabase.from('hackathon_team_members').insert({
      'team_id': teamId,
      'user_id': _currentUserId,
      'role': 'member',
      'skills': skills ?? [],
    });
  }

  /// Leave a team
  Future<void> leaveTeam(String teamId) async {
    await _supabase
        .from('hackathon_team_members')
        .delete()
        .eq('team_id', teamId)
        .eq('user_id', _currentUserId!);
  }

  // ==================== MENTOR SLOTS ====================

  /// Get available mentor slots for an event
  Future<List<MentorSlot>> getAvailableMentorSlots(String eventId) async {
    final response = await _supabase
        .from('mentor_slots')
        .select()
        .eq('event_id', eventId)
        .eq('status', 'available')
        .gte('slot_start', DateTime.now().toIso8601String())
        .order('slot_start');

    return (response as List)
        .map((json) => MentorSlot.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get all mentor slots (including booked) for an event
  Future<List<MentorSlot>> getAllMentorSlots(String eventId) async {
    final response = await _supabase
        .from('mentor_slots')
        .select()
        .eq('event_id', eventId)
        .order('slot_start');

    return (response as List)
        .map((json) => MentorSlot.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get team's booked mentor slots
  Future<List<MentorSlot>> getTeamMentorSlots(String teamId) async {
    final response = await _supabase
        .from('mentor_slots')
        .select()
        .eq('booked_by_team_id', teamId)
        .order('slot_start');

    return (response as List)
        .map((json) => MentorSlot.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Book a mentor slot
  Future<void> bookMentorSlot(String slotId, String teamId) async {
    await _supabase.from('mentor_slots').update({
      'booked_by_team_id': teamId,
      'booked_at': DateTime.now().toIso8601String(),
      'status': 'booked',
    }).eq('id', slotId);
  }

  /// Cancel a mentor slot booking
  Future<void> cancelMentorSlotBooking(String slotId) async {
    await _supabase.from('mentor_slots').update({
      'booked_by_team_id': null,
      'booked_at': null,
      'status': 'available',
    }).eq('id', slotId);
  }

  // ==================== SUBMISSIONS ====================

  /// Get team's submission
  Future<HackathonSubmission?> getTeamSubmission(
      String eventId, String teamId) async {
    final response = await _supabase
        .from('hackathon_submissions')
        .select()
        .eq('event_id', eventId)
        .eq('team_id', teamId)
        .maybeSingle();

    if (response == null) return null;
    return HackathonSubmission.fromJson(response as Map<String, dynamic>);
  }

  /// Create or update submission
  Future<HackathonSubmission> upsertSubmission({
    required String eventId,
    required String teamId,
    required String projectName,
    String? description,
    String? demoUrl,
    String? repoUrl,
    String? presentationUrl,
    String? videoUrl,
    List<String>? screenshots,
    List<String>? techStack,
    String? track,
    bool isDraft = true,
  }) async {
    final response = await _supabase
        .from('hackathon_submissions')
        .upsert({
          'event_id': eventId,
          'team_id': teamId,
          'project_name': projectName,
          'description': description,
          'demo_url': demoUrl,
          'repo_url': repoUrl,
          'presentation_url': presentationUrl,
          'video_url': videoUrl,
          'screenshots': screenshots ?? [],
          'tech_stack': techStack ?? [],
          'track': track,
          'is_draft': isDraft,
          'submitted_at': isDraft ? null : DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return HackathonSubmission.fromJson(response as Map<String, dynamic>);
  }

  /// Submit final submission
  Future<HackathonSubmission> submitFinal(String submissionId) async {
    final response = await _supabase
        .from('hackathon_submissions')
        .update({
          'is_draft': false,
          'submitted_at': DateTime.now().toIso8601String(),
        })
        .eq('id', submissionId)
        .select()
        .single();

    return HackathonSubmission.fromJson(response as Map<String, dynamic>);
  }

  // ==================== DEADLINES ====================

  /// Get event deadlines
  Future<List<HackathonDeadline>> getEventDeadlines(String eventId) async {
    final response = await _supabase
        .from('hackathon_deadlines')
        .select()
        .eq('event_id', eventId)
        .order('deadline_at');

    return (response as List)
        .map((json) => HackathonDeadline.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get next upcoming deadline
  Future<HackathonDeadline?> getNextDeadline(String eventId) async {
    final response = await _supabase
        .from('hackathon_deadlines')
        .select()
        .eq('event_id', eventId)
        .gte('deadline_at', DateTime.now().toIso8601String())
        .order('deadline_at')
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return HackathonDeadline.fromJson(response as Map<String, dynamic>);
  }
}
