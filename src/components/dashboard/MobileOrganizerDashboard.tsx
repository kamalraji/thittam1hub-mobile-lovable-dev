import { Link } from 'react-router-dom';
import {
  CalendarDays,
  SlidersHorizontal,
  Briefcase,
  Users,
  ChevronRight,
  Clock
} from 'lucide-react';
import { useAuth } from '../../hooks/useAuth';
import { useCurrentOrganization } from '../organization/OrganizationContext';
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { format } from 'date-fns';

interface Event {
  id: string;
  name: string;
  startDate: string;
  status: string;
}

interface WorkspaceSummary {
  id: string;
  name: string;
  status: string;
  updatedAt: string;
  eventId: string;
}

/**
 * Mobile-optimized home view for the Organizer Dashboard.
 * This component is displayed inside the MobileAppShell which provides
 * the header, bottom navigation, and FAB. It only renders the content area.
 */
export function MobileOrganizerDashboard() {
  const { user } = useAuth();
  const organization = useCurrentOrganization();

  // Fetch events
  const { data: events, isLoading: eventsLoading } = useQuery<Event[]>({
    queryKey: ['mobile-organizer-events', organization.id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('events')
        .select('id, name, start_date, status')
        .eq('organization_id', organization.id)
        .order('start_date', { ascending: false })
        .limit(5);
      
      if (error) throw error;
      return (data || []).map(e => ({
        id: e.id,
        name: e.name,
        startDate: e.start_date,
        status: e.status
      }));
    }
  });

  // Fetch workspaces
  const { data: workspaces, isLoading: workspacesLoading } = useQuery<WorkspaceSummary[]>({
    queryKey: ['mobile-organizer-workspaces', organization.id, user?.id],
    queryFn: async () => {
      const { data: orgEvents } = await supabase
        .from('events')
        .select('id')
        .eq('organization_id', organization.id);
      
      const orgEventIds = (orgEvents || []).map(e => e.id);
      if (orgEventIds.length === 0) return [];

      const { data, error } = await supabase
        .from('workspaces')
        .select('id, name, status, updated_at, event_id')
        .eq('organizer_id', user!.id)
        .in('event_id', orgEventIds)
        .order('updated_at', { ascending: false })
        .limit(5);
      
      if (error) throw error;
      return (data || []).map(ws => ({
        id: ws.id,
        name: ws.name,
        status: ws.status,
        updatedAt: ws.updated_at,
        eventId: ws.event_id
      }));
    },
    enabled: !!user?.id
  });

  // Quick action grid items (2x2 layout)
  const quickActionCards = [
    { 
      icon: CalendarDays, 
      label: 'Events', 
      path: `/${organization.slug}/eventmanagement`,
      color: 'bg-blue-500/10 text-blue-600'
    },
    { 
      icon: SlidersHorizontal, 
      label: 'Analytics', 
      path: `/${organization.slug}/analytics`,
      color: 'bg-orange-500/10 text-orange-600'
    },
    { 
      icon: Briefcase, 
      label: 'Workspaces', 
      path: `/${organization.slug}/workspaces`,
      color: 'bg-green-500/10 text-green-600'
    },
    { 
      icon: Users, 
      label: 'Team', 
      path: `/${organization.slug}/team`,
      color: 'bg-purple-500/10 text-purple-600'
    },
  ];

  const upcomingEvents = events?.filter(e => new Date(e.startDate) > new Date()).slice(0, 3) || [];

  // Skeleton component
  const CardSkeleton = () => (
    <div className="bg-card border border-border rounded-xl p-4 animate-pulse">
      <div className="flex items-center gap-3">
        <div className="w-10 h-10 rounded-lg bg-muted" />
        <div className="flex-1 space-y-2">
          <div className="h-4 bg-muted rounded w-3/4" />
          <div className="h-3 bg-muted rounded w-1/2" />
        </div>
      </div>
    </div>
  );

  return (
    <div className="px-4 py-4 space-y-6">
      {/* Welcome Section */}
      <div>
        <h1 className="text-2xl font-bold text-foreground">
          Welcome{user?.name ? `, ${user.name.split(' ')[0]}` : ''}!
        </h1>
        <p className="text-sm text-muted-foreground mt-1">
          Here's what's happening in {organization.name}
        </p>
      </div>

      {/* 2x2 Quick Action Grid */}
      <div className="grid grid-cols-2 gap-3">
        {quickActionCards.map((card, index) => (
          <Link
            key={index}
            to={card.path}
            className="flex flex-col items-center justify-center gap-2 p-5 rounded-2xl bg-card border border-border hover:bg-muted/50 active:scale-[0.98] transition-all shadow-sm"
          >
            <div className={`p-3 rounded-xl ${card.color}`}>
              <card.icon className="w-6 h-6" />
            </div>
            <span className="text-sm font-medium text-foreground">{card.label}</span>
          </Link>
        ))}
      </div>

      {/* Tasks Section */}
      <section className="space-y-3">
        <div className="flex items-center justify-between">
          <h2 className="text-base font-semibold text-foreground">Tasks</h2>
          <Link to={`/${organization.slug}/workspaces`} className="text-xs font-medium text-primary flex items-center gap-1">
            View all <ChevronRight className="h-3 w-3" />
          </Link>
        </div>
        <div className="bg-card border border-border rounded-xl p-4">
          <p className="text-sm text-muted-foreground text-center py-2">No pending tasks</p>
        </div>
      </section>

      {/* Upcoming Events Section */}
      <section className="space-y-3">
        <div className="flex items-center justify-between">
          <h2 className="text-base font-semibold text-foreground">Upcoming Events</h2>
          <Link to={`/${organization.slug}/eventmanagement`} className="text-xs font-medium text-primary flex items-center gap-1">
            View all <ChevronRight className="h-3 w-3" />
          </Link>
        </div>
        
        {eventsLoading ? (
          <div className="space-y-2">
            <CardSkeleton />
            <CardSkeleton />
          </div>
        ) : upcomingEvents.length > 0 ? (
          <div className="space-y-2">
            {upcomingEvents.map(event => (
              <Link
                key={event.id}
                to={`/${organization.slug}/eventmanagement/${event.id}`}
                className="flex items-center gap-3 p-3 bg-card border border-border rounded-xl hover:bg-muted/50 active:scale-[0.98] transition-all"
              >
                <div className="p-2 rounded-lg bg-primary/10">
                  <CalendarDays className="h-5 w-5 text-primary" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-foreground truncate">{event.name}</p>
                  <p className="text-xs text-muted-foreground flex items-center gap-1">
                    <Clock className="h-3 w-3" />
                    {format(new Date(event.startDate), 'MMM d, yyyy')}
                  </p>
                </div>
                <ChevronRight className="h-4 w-4 text-muted-foreground" />
              </Link>
            ))}
          </div>
        ) : (
          <div className="bg-card border border-border rounded-xl p-4">
            <p className="text-sm text-muted-foreground text-center py-2">No upcoming events</p>
          </div>
        )}
      </section>

      {/* Recent Workspaces Section */}
      <section className="space-y-3">
        <div className="flex items-center justify-between">
          <h2 className="text-base font-semibold text-foreground">Recent Workspaces</h2>
          <Link to={`/${organization.slug}/workspaces`} className="text-xs font-medium text-primary flex items-center gap-1">
            View all <ChevronRight className="h-3 w-3" />
          </Link>
        </div>
        
        {workspacesLoading ? (
          <div className="space-y-2">
            <CardSkeleton />
            <CardSkeleton />
          </div>
        ) : workspaces && workspaces.length > 0 ? (
          <div className="space-y-2">
            {workspaces.slice(0, 3).map(ws => (
              <Link
                key={ws.id}
                to={`/${organization.slug}/workspaces/${ws.eventId}/${ws.id}`}
                className="flex items-center gap-3 p-3 bg-card border border-border rounded-xl hover:bg-muted/50 active:scale-[0.98] transition-all"
              >
                <div className="p-2 rounded-lg bg-green-500/10">
                  <Briefcase className="h-5 w-5 text-green-600" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-foreground truncate">{ws.name}</p>
                  <p className="text-xs text-muted-foreground">
                    Updated {format(new Date(ws.updatedAt), 'MMM d')}
                  </p>
                </div>
                <span className={`text-xs px-2 py-0.5 rounded-full ${
                  ws.status === 'active' 
                    ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400' 
                    : 'bg-muted text-muted-foreground'
                }`}>
                  {ws.status}
                </span>
              </Link>
            ))}
          </div>
        ) : (
          <div className="bg-card border border-border rounded-xl p-4">
            <p className="text-sm text-muted-foreground text-center py-2">No workspaces yet</p>
          </div>
        )}
      </section>
    </div>
  );
}
