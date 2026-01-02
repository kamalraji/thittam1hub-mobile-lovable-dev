import { useEffect, useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/looseClient';

export type DashboardEventRow = {
  id: string;
  name: string;
  status: string;
  start_date: string | null;
};

export type EventManagementMetrics = {
  totalEvents: number;
  activeEvents: number;
  draftEvents: number;
  totalRegistrations: number;
  upcomingEvents: number;
};

/**
 * Shared data hook for Event Management dashboards.
 *
 * - Fetches recent events (optionally scoped by organization)
 * - Aggregates registrations per event
 * - Exposes summary metrics for tiles / widgets
 */
export const useEventManagementMetrics = (organizationId?: string) => {
  // Prefetch recent events
  const { data: events } = useQuery<DashboardEventRow[]>({
    queryKey: ['event-service-dashboard-events', organizationId ?? 'all'],
    queryFn: async () => {
      let query = supabase
        .from('events')
        .select('id, name, status, start_date, organization_id')
        .order('start_date', { ascending: false })
        .limit(10);

      if (organizationId) {
        query = query.eq('organization_id', organizationId);
      }

      const { data, error } = await query;
      if (error) throw error;
      // Cast away organization_id which we only use for filtering
      return (data ?? []).map((row: any) => ({
        id: row.id,
        name: row.name,
        status: row.status,
        start_date: row.start_date,
      })) as DashboardEventRow[];
    },
  });

  // Registrations grouped by event
  const { data: registrationsByEvent } = useQuery<Record<string, number>>({
    queryKey: [
      'event-service-dashboard-registrations',
      organizationId ?? 'all',
      (events ?? []).map((e) => e.id),
    ],
    enabled: !!events && events.length > 0,
    queryFn: async () => {
      const eventIds = (events ?? []).map((e) => e.id);
      const { data, error } = await supabase
        .from('registrations')
        .select('id, event_id')
        .in('event_id', eventIds);

      if (error) throw error;

      const counts: Record<string, number> = {};
      (data as { id: string; event_id: string }[]).forEach((row) => {
        counts[row.event_id] = (counts[row.event_id] ?? 0) + 1;
      });
      return counts;
    },
  });

  const metrics: EventManagementMetrics = useMemo(() => {
    const allEvents = events ?? [];
    const totalEvents = allEvents.length;
    const activeEvents = allEvents.filter((evt) =>
      ['PUBLISHED', 'ONGOING'].includes(evt.status),
    ).length;
    const draftEvents = allEvents.filter((evt) => evt.status === 'DRAFT').length;
    const upcomingEvents = allEvents.filter((evt) => {
      if (!evt.start_date) return false;
      return new Date(evt.start_date).getTime() > Date.now();
    }).length;

    const totalRegistrations = Object.values(registrationsByEvent ?? {}).reduce(
      (sum, value) => sum + value,
      0,
    );

    return {
      totalEvents,
      activeEvents,
      draftEvents,
      totalRegistrations,
      upcomingEvents,
    };
  }, [events, registrationsByEvent]);

  // Ensure document title stays consistent for runtimes that rely on this hook
  useEffect(() => {
    // No-op: the individual pages still control SEO/title; this hook is data-only.
  }, []);

  return { events, registrationsByEvent, metrics };
};
