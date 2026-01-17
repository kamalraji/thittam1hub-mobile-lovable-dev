import 'package:flutter/foundation.dart';
import 'package:thittam1hub/models/work_experience.dart';
import 'package:thittam1hub/models/portfolio_project.dart';
import 'package:thittam1hub/models/skill_endorsement.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';

class ProfessionalService {
  final _supabase = SupabaseConfig.client;

  // ==================== Work Experience ====================

  Future<List<WorkExperience>> getWorkExperience(String userId) async {
    try {
      final rows = await _supabase
          .from('work_experience')
          .select('*')
          .eq('user_id', userId)
          .order('is_current', ascending: false)
          .order('start_date', ascending: false);
      
      return (rows as List)
          .map((e) => WorkExperience.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching work experience: $e');
      return [];
    }
  }

  // Backwards-compatible alias
  Future<List<WorkExperience>> getWorkExperiences(String userId) => getWorkExperience(userId);

  Future<WorkExperience?> addWorkExperience({
    required String title,
    required String company,
    String? companyLogoUrl,
    String? location,
    required DateTime startDate,
    DateTime? endDate,
    required bool isCurrent,
    String? description,
  }) async {
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) throw Exception('Not authenticated');

      final data = {
        'user_id': uid,
        'title': title,
        'company': company,
        'company_logo_url': companyLogoUrl,
        'location': location,
        'start_date': startDate.toIso8601String().split('T').first,
        'end_date': endDate?.toIso8601String().split('T').first,
        'is_current': isCurrent,
        'description': description,
      };

      final result = await _supabase
          .from('work_experience')
          .insert(data)
          .select()
          .single();

      return WorkExperience.fromMap(result);
    } catch (e) {
      debugPrint('Error adding work experience: $e');
      rethrow;
    }
  }

  Future<void> updateWorkExperience(WorkExperience experience) async {
    try {
      await _supabase
          .from('work_experience')
          .update(experience.toMap())
          .eq('id', experience.id);
    } catch (e) {
      debugPrint('Error updating work experience: $e');
      rethrow;
    }
  }

  Future<void> deleteWorkExperience(String id) async {
    try {
      await _supabase.from('work_experience').delete().eq('id', id);
    } catch (e) {
      debugPrint('Error deleting work experience: $e');
      rethrow;
    }
  }

  // ==================== Portfolio Projects ====================

  Future<List<PortfolioProject>> getPortfolioProjects(String userId) async {
    try {
      final rows = await _supabase
          .from('portfolio_projects')
          .select('*')
          .eq('user_id', userId)
          .order('project_date', ascending: false);
      
      return (rows as List)
          .map((e) => PortfolioProject.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching portfolio projects: $e');
      return [];
    }
  }

  Future<PortfolioProject?> addProject({
    required String title,
    String? description,
    String? imageUrl,
    String? projectUrl,
    required List<String> skills,
    DateTime? projectDate,
  }) async {
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) throw Exception('Not authenticated');

      final data = {
        'user_id': uid,
        'title': title,
        'description': description,
        'image_url': imageUrl,
        'project_url': projectUrl,
        'skills': skills,
        'project_date': projectDate?.toIso8601String().split('T').first,
      };

      final result = await _supabase
          .from('portfolio_projects')
          .insert(data)
          .select()
          .single();

      return PortfolioProject.fromMap(result);
    } catch (e) {
      debugPrint('Error adding project: $e');
      rethrow;
    }
  }

  Future<void> updateProject(PortfolioProject project) async {
    try {
      await _supabase
          .from('portfolio_projects')
          .update(project.toMap())
          .eq('id', project.id);
    } catch (e) {
      debugPrint('Error updating project: $e');
      rethrow;
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      await _supabase.from('portfolio_projects').delete().eq('id', id);
    } catch (e) {
      debugPrint('Error deleting project: $e');
      rethrow;
    }
  }

  // ==================== Skill Endorsements ====================

  Future<Map<String, SkillEndorsementSummary>> getEndorsements(String userId) async {
    try {
      final rows = await _supabase
          .from('skill_endorsements')
          .select('*, impact_profiles!endorser_user_id(full_name, avatar_url)')
          .eq('endorsed_user_id', userId)
          .order('created_at', ascending: false);
      
      final Map<String, List<SkillEndorsement>> grouped = {};
      final Map<String, List<EndorserInfo>> endorsers = {};

      for (final row in rows as List) {
        final skill = row['skill'] as String;
        final endorsement = SkillEndorsement(
          id: row['id'] as String,
          endorsedUserId: row['endorsed_user_id'] as String,
          endorserUserId: row['endorser_user_id'] as String,
          skill: skill,
          createdAt: DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
          endorserName: row['impact_profiles']?['full_name'] as String?,
          endorserAvatarUrl: row['impact_profiles']?['avatar_url'] as String?,
        );

        grouped.putIfAbsent(skill, () => []).add(endorsement);
        endorsers.putIfAbsent(skill, () => []).add(EndorserInfo(
          userId: endorsement.endorserUserId,
          name: endorsement.endorserName ?? 'User',
          avatarUrl: endorsement.endorserAvatarUrl,
        ));
      }

      return grouped.map((skill, list) => MapEntry(
        skill,
        SkillEndorsementSummary(
          skill: skill,
          count: list.length,
          topEndorsers: endorsers[skill]?.take(3).toList() ?? [],
        ),
      ));
    } catch (e) {
      debugPrint('Error fetching endorsements: $e');
      return {};
    }
  }

  Future<void> endorseSkill(String userId, String skill) async {
    try {
      final myId = _supabase.auth.currentUser?.id;
      if (myId == null) throw Exception('Not authenticated');
      if (myId == userId) throw Exception('Cannot endorse your own skill');

      await _supabase.from('skill_endorsements').insert({
        'endorsed_user_id': userId,
        'endorser_user_id': myId,
        'skill': skill,
      });
      
      debugPrint('✅ Endorsed $skill for user $userId');
    } catch (e) {
      debugPrint('Error endorsing skill: $e');
      rethrow;
    }
  }

  Future<void> removeEndorsement(String userId, String skill) async {
    try {
      final myId = _supabase.auth.currentUser?.id;
      if (myId == null) throw Exception('Not authenticated');

      await _supabase
          .from('skill_endorsements')
          .delete()
          .eq('endorsed_user_id', userId)
          .eq('endorser_user_id', myId)
          .eq('skill', skill);
      
      debugPrint('❌ Removed endorsement for $skill');
    } catch (e) {
      debugPrint('Error removing endorsement: $e');
      rethrow;
    }
  }

  Future<bool> hasEndorsed(String userId, String skill) async {
    try {
      final myId = _supabase.auth.currentUser?.id;
      if (myId == null) return false;

      final result = await _supabase
          .from('skill_endorsements')
          .select('id')
          .eq('endorsed_user_id', userId)
          .eq('endorser_user_id', myId)
          .eq('skill', skill)
          .maybeSingle();

      return result != null;
    } catch (e) {
      return false;
    }
  }
}
