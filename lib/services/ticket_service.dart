import 'package:flutter/foundation.dart';
import 'package:thittam1hub/models/user_ticket.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';

/// Service for fetching user tickets with event details
class TicketService {
  /// Get all tickets for the current user with full event details
  Future<List<UserTicket>> getUserTickets(String userId) async {
    try {
      final data = await SupabaseConfig.client
          .from('registrations')
          .select('''
            id,
            event_id,
            ticket_tier_id,
            status,
            quantity,
            total_amount,
            created_at,
            events!inner(
              name,
              start_date,
              end_date,
              mode,
              branding,
              organization:organizations(
                name,
                logo_url
              )
            ),
            ticket_tier:ticket_tiers(
              name,
              price,
              currency
            )
          ''')
          .eq('user_id', userId)
          .neq('status', 'CANCELLED')
          .order('created_at', ascending: false);

      final tickets = <UserTicket>[];
      for (final item in data as List) {
        try {
          // Flatten the nested structure
          final flat = <String, dynamic>{
            'id': item['id'],
            'event_id': item['event_id'],
            'status': item['status'],
            'quantity': item['quantity'],
            'total_amount': item['total_amount'],
            'created_at': item['created_at'],
          };

          // Add event details
          final event = item['events'];
          if (event is Map) {
            flat['event_name'] = event['name'];
            flat['start_date'] = event['start_date'];
            flat['end_date'] = event['end_date'];
            flat['mode'] = event['mode'];
            flat['branding'] = event['branding'];
            flat['organization'] = event['organization'];
          }

          // Add tier details
          flat['ticket_tier'] = item['ticket_tier'];

          tickets.add(UserTicket.fromJson(flat));
        } catch (e) {
          debugPrint('⚠️ Failed to parse ticket: $e');
        }
      }

      return tickets;
    } catch (e) {
      debugPrint('❌ Get user tickets error: $e');
      return [];
    }
  }

  /// Get upcoming tickets only
  Future<List<UserTicket>> getUpcomingTickets(String userId) async {
    final tickets = await getUserTickets(userId);
    return tickets.where((t) => t.isUpcoming || t.isOngoing).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  /// Get past tickets only
  Future<List<UserTicket>> getPastTickets(String userId) async {
    final tickets = await getUserTickets(userId);
    return tickets.where((t) => t.isPast).toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  /// Get a specific ticket by registration ID
  Future<UserTicket?> getTicketById(String registrationId) async {
    try {
      final data = await SupabaseConfig.client
          .from('registrations')
          .select('''
            id,
            event_id,
            user_id,
            ticket_tier_id,
            status,
            quantity,
            total_amount,
            created_at,
            events!inner(
              name,
              start_date,
              end_date,
              mode,
              branding,
              organization:organizations(
                name,
                logo_url
              )
            ),
            ticket_tier:ticket_tiers(
              name,
              price,
              currency
            )
          ''')
          .eq('id', registrationId)
          .maybeSingle();

      if (data == null) return null;

      // Flatten the nested structure
      final flat = <String, dynamic>{
        'id': data['id'],
        'event_id': data['event_id'],
        'status': data['status'],
        'quantity': data['quantity'],
        'total_amount': data['total_amount'],
        'created_at': data['created_at'],
      };

      // Add event details
      final event = data['events'];
      if (event is Map) {
        flat['event_name'] = event['name'];
        flat['start_date'] = event['start_date'];
        flat['end_date'] = event['end_date'];
        flat['mode'] = event['mode'];
        flat['branding'] = event['branding'];
        flat['organization'] = event['organization'];
      }

      // Add tier details
      flat['ticket_tier'] = data['ticket_tier'];

      return UserTicket.fromJson(flat);
    } catch (e) {
      debugPrint('❌ Get ticket by ID error: $e');
      return null;
    }
  }
}
