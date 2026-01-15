import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';
import 'package:thittam1hub/models/models.dart';

class RegistrationService {
  /// Get all registrations for a user
  Future<List<Registration>> getUserRegistrations(String userId) async {
    try {
      final data = await SupabaseConfig.client
          .from('registrations')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (data as List).map((json) => Registration.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Get user registrations error: $e');
      return [];
    }
  }

  /// Get registration by ID
  Future<Registration?> getRegistrationById(String registrationId) async {
    try {
      final data = await SupabaseConfig.client
          .from('registrations')
          .select()
          .eq('id', registrationId)
          .maybeSingle();

      if (data == null) return null;
      return Registration.fromJson(data);
    } catch (e) {
      debugPrint('❌ Get registration by ID error: $e');
      return null;
    }
  }

  /// Check if user is registered for an event
  Future<bool> isUserRegistered(String userId, String eventId) async {
    try {
      final data = await SupabaseConfig.client
          .from('registrations')
          .select('id')
          .eq('user_id', userId)
          .eq('event_id', eventId)
          .maybeSingle();

      return data != null;
    } catch (e) {
      debugPrint('❌ Check registration error: $e');
      return false;
    }
  }

  /// Get user's registration for a specific event
  Future<Registration?> getUserEventRegistration(
    String userId,
    String eventId,
  ) async {
    try {
      final data = await SupabaseConfig.client
          .from('registrations')
          .select()
          .eq('user_id', userId)
          .eq('event_id', eventId)
          .maybeSingle();

      if (data == null) return null;
      return Registration.fromJson(data);
    } catch (e) {
      debugPrint('❌ Get user event registration error: $e');
      return null;
    }
  }

  /// Create a new registration
  Future<Registration?> createRegistration({
    required String eventId,
    required String userId,
    String? ticketTierId,
    int quantity = 1,
    Map<String, dynamic>? formResponses,
    double? subtotal,
    double? discountAmount,
    double? totalAmount,
  }) async {
    try {
      final registration = Registration(
        id: const Uuid().v4(),
        eventId: eventId,
        userId: userId,
        ticketTierId: ticketTierId,
        status: RegistrationStatus.CONFIRMED,
        quantity: quantity,
        formResponses: formResponses ?? {},
        subtotal: subtotal ?? 0,
        discountAmount: discountAmount ?? 0,
        totalAmount: totalAmount ?? 0,
        promoCodeId: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final data = await SupabaseConfig.client
          .from('registrations')
          .insert(registration.toJson())
          .select()
          .single();

      // Update ticket tier sold count
      if (ticketTierId != null) {
        await _incrementTicketSoldCount(ticketTierId, quantity);
      }

      return Registration.fromJson(data);
    } catch (e) {
      debugPrint('❌ Create registration error: $e');
      return null;
    }
  }

  /// Update registration status
  Future<bool> updateRegistrationStatus(
    String registrationId,
    RegistrationStatus status,
  ) async {
    try {
      await SupabaseConfig.client
          .from('registrations')
          .update({'status': status.name})
          .eq('id', registrationId);

      return true;
    } catch (e) {
      debugPrint('❌ Update registration status error: $e');
      return false;
    }
  }

  /// Cancel a registration
  Future<bool> cancelRegistration(String registrationId) async {
    try {
      final registration = await getRegistrationById(registrationId);
      if (registration == null) return false;

      await SupabaseConfig.client
          .from('registrations')
          .update({'status': RegistrationStatus.CANCELLED.name})
          .eq('id', registrationId);

      // Decrement ticket tier sold count
      if (registration.ticketTierId != null) {
        await _decrementTicketSoldCount(
          registration.ticketTierId!,
          registration.quantity,
        );
      }

      return true;
    } catch (e) {
      debugPrint('❌ Cancel registration error: $e');
      return false;
    }
  }

  /// Delete a registration
  Future<bool> deleteRegistration(String registrationId) async {
    try {
      final registration = await getRegistrationById(registrationId);
      if (registration == null) return false;

      await SupabaseConfig.client
          .from('registrations')
          .delete()
          .eq('id', registrationId);

      // Decrement ticket tier sold count
      if (registration.ticketTierId != null) {
        await _decrementTicketSoldCount(
          registration.ticketTierId!,
          registration.quantity,
        );
      }

      return true;
    } catch (e) {
      debugPrint('❌ Delete registration error: $e');
      return false;
    }
  }

  /// Get event registration count
  Future<int> getEventRegistrationCount(String eventId) async {
    try {
      final data = await SupabaseConfig.client
          .from('registrations')
          .select('quantity')
          .eq('event_id', eventId)
          .neq('status', RegistrationStatus.CANCELLED.name);

      if (data.isEmpty) return 0;

      return (data as List).fold<int>(
        0,
        (sum, item) => sum + (item['quantity'] as int),
      );
    } catch (e) {
      debugPrint('❌ Get event registration count error: $e');
      return 0;
    }
  }

  Future<void> _incrementTicketSoldCount(String ticketTierId, int quantity) async {
    try {
      await SupabaseConfig.client.rpc('increment_ticket_sold_count', params: {
        'ticket_id': ticketTierId,
        'quantity': quantity,
      });
    } catch (e) {
      debugPrint('⚠️ Increment ticket sold count error: $e');
    }
  }

  Future<void> _decrementTicketSoldCount(String ticketTierId, int quantity) async {
    try {
      await SupabaseConfig.client.rpc('decrement_ticket_sold_count', params: {
        'ticket_id': ticketTierId,
        'quantity': quantity,
      });
    } catch (e) {
      debugPrint('⚠️ Decrement ticket sold count error: $e');
    }
  }
}
