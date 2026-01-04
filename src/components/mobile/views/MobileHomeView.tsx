import React, { useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { Calendar, Users, Briefcase, BarChart3, ChevronRight, Clock } from 'lucide-react';
import { supabase } from '@/integrations/supabase/client';
import { format } from 'date-fns';
import { PullToRefresh } from '../shared/PullToRefresh';
import { ListSkeleton } from '../shared/MobileSkeleton';

interface MobileHomeViewProps {
  organization: {
    id: string;
    name: string;
    slug: string;
  };
  user: {
    id: string;
    name?: string;
  };
}

interface Event {
  id: string;
  name: string;
  start_date: string;
  status: string;
}

interface Workspace {
  id: string;
  name: string;
  status: string;
  updated_at: string;
  event_id: string;
}

export const MobileHomeView: React.FC<MobileHomeViewProps> = ({ organization, user }) => {
  const navigate = useNavigate();

  // Fetch recent events
  const { data: events, isLoading: eventsLoading, refetch: refetchEvents } = useQuery<Event[]>({
    queryKey: ['mobile-events', organization.id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('events')
        .select('id, name, start_date, status')
        .eq('organization_id', organization.id)
        .order('start_date', { ascending: false })
        .limit(3);
      if (error) throw error;
      return data || [];
    },
  });

  // Fetch recent workspaces
  const { data: workspaces, isLoading: workspacesLoading, refetch: refetchWorkspaces } = useQuery<Workspace[]>({
    queryKey: ['mobile-workspaces', organization.id, user.id],
    queryFn: async () => {
      const { data: orgEvents } = await supabase
        .from('events')
        .select('id')
        .eq('organization_id', organization.id);
      
      const eventIds = (orgEvents || []).map(e => e.id);
      if (eventIds.length === 0) return [];

      const { data, error } = await supabase
        .from('workspaces')
        .select('id, name, status, updated_at, event_id')
        .eq('organizer_id', user.id)
        .in('event_id', eventIds)
        .order('updated_at', { ascending: false })
        .limit(3);
      if (error) throw error;
      return data || [];
    },
    enabled: !!user.id,
  });

  const handleRefresh = useCallback(async () => {
    await Promise.all([refetchEvents(), refetchWorkspaces()]);
  }, [refetchEvents, refetchWorkspaces]);

  const quickNavItems = [
    { 
      id: 'events', 
      label: 'Events', 
      icon: Calendar, 
      color: 'bg-blue-500/10 text-blue-600',
      path: `/${organization.slug}/eventmanagement` 
    },
    { 
      id: 'workspaces', 
      label: 'Workspaces', 
      icon: Briefcase, 
      color: 'bg-green-500/10 text-green-600',
      path: `/${organization.slug}/workspaces` 
    },
    { 
      id: 'team', 
      label: 'Team', 
      icon: Users, 
      color: 'bg-purple-500/10 text-purple-600',
      path: `/${organization.slug}/team` 
    },
    { 
      id: 'analytics', 
      label: 'Analytics', 
      icon: BarChart3, 
      color: 'bg-orange-500/10 text-orange-600',
      path: `/${organization.slug}/analytics` 
    },
  ];

  return (
    <PullToRefresh onRefresh={handleRefresh} className="h-full">
      <div className="px-4 py-4 space-y-6">
        {/* Welcome Section */}
        <div>
          <h1 className="text-2xl font-bold text-foreground">
            Welcome{user.name ? `, ${user.name.split(' ')[0]}` : ''}!
          </h1>
          <p className="text-sm text-muted-foreground mt-1">
            Here's what's happening in {organization.name}
          </p>
        </div>

        {/* 2x2 Quick Navigation Grid */}
        <div className="grid grid-cols-2 gap-3">
          {quickNavItems.map((item) => {
            const Icon = item.icon;
            return (
              <button
                key={item.id}
                onClick={() => navigate(item.path)}
                className="flex flex-col items-center justify-center gap-2 p-5 rounded-2xl bg-card border border-border hover:bg-muted/50 transition-colors shadow-sm active:scale-[0.98]"
              >
                <div className={`p-3 rounded-xl ${item.color}`}>
                  <Icon className="h-6 w-6" />
                </div>
                <span className="text-sm font-medium text-foreground">
                  {item.label}
                </span>
              </button>
            );
          })}
        </div>

        {/* Tasks Section */}
        <section>
          <div className="flex items-center justify-between mb-3">
            <h2 className="text-base font-semibold text-foreground">Tasks</h2>
            <button className="text-xs font-medium text-primary flex items-center gap-1">
              View all <ChevronRight className="h-3 w-3" />
            </button>
          </div>
          <div className="bg-card border border-border rounded-xl p-4">
            <p className="text-sm text-muted-foreground text-center py-4">
              No pending tasks
            </p>
          </div>
        </section>

        {/* Upcoming Meetings Section */}
        <section>
          <div className="flex items-center justify-between mb-3">
            <h2 className="text-base font-semibold text-foreground">Upcoming Meetings</h2>
            <button className="text-xs font-medium text-primary flex items-center gap-1">
              View all <ChevronRight className="h-3 w-3" />
            </button>
          </div>
          <div className="bg-card border border-border rounded-xl p-4">
            <p className="text-sm text-muted-foreground text-center py-4">
              No upcoming meetings
            </p>
          </div>
        </section>

        {/* Upcoming Events Section */}
        <section>
          <div className="flex items-center justify-between mb-3">
            <h2 className="text-base font-semibold text-foreground">Upcoming Events</h2>
            <button 
              onClick={() => navigate(`/${organization.slug}/eventmanagement`)}
              className="text-xs font-medium text-primary flex items-center gap-1"
            >
              View all <ChevronRight className="h-3 w-3" />
            </button>
          </div>
          {eventsLoading ? (
            <ListSkeleton count={2} />
          ) : (
            <div className="space-y-2">
              {events && events.length > 0 ? (
                events.map((event) => (
                  <button
                    key={event.id}
                    onClick={() => navigate(`/${organization.slug}/eventmanagement/${event.id}`)}
                    className="w-full flex items-center gap-3 p-3 bg-card border border-border rounded-xl hover:bg-muted/50 transition-colors active:scale-[0.98]"
                  >
                    <div className="p-2 rounded-lg bg-primary/10">
                      <Calendar className="h-5 w-5 text-primary" />
                    </div>
                    <div className="flex-1 text-left">
                      <p className="text-sm font-medium text-foreground truncate">{event.name}</p>
                      <p className="text-xs text-muted-foreground flex items-center gap-1">
                        <Clock className="h-3 w-3" />
                        {format(new Date(event.start_date), 'MMM d, yyyy')}
                      </p>
                    </div>
                    <ChevronRight className="h-4 w-4 text-muted-foreground" />
                  </button>
                ))
              ) : (
                <div className="bg-card border border-border rounded-xl p-4">
                  <p className="text-sm text-muted-foreground text-center py-2">
                    No upcoming events
                  </p>
                </div>
              )}
            </div>
          )}
        </section>

        {/* Recent Workspaces Section */}
        <section>
          <div className="flex items-center justify-between mb-3">
            <h2 className="text-base font-semibold text-foreground">Recent Workspaces</h2>
            <button 
              onClick={() => navigate(`/${organization.slug}/workspaces`)}
              className="text-xs font-medium text-primary flex items-center gap-1"
            >
              View all <ChevronRight className="h-3 w-3" />
            </button>
          </div>
          {workspacesLoading ? (
            <ListSkeleton count={2} />
          ) : (
            <div className="space-y-2">
              {workspaces && workspaces.length > 0 ? (
                workspaces.map((ws) => (
                  <button
                    key={ws.id}
                    onClick={() => navigate(`/${organization.slug}/workspaces/${ws.event_id}/${ws.id}`)}
                    className="w-full flex items-center gap-3 p-3 bg-card border border-border rounded-xl hover:bg-muted/50 transition-colors active:scale-[0.98]"
                  >
                    <div className="p-2 rounded-lg bg-green-500/10">
                      <Briefcase className="h-5 w-5 text-green-600" />
                    </div>
                    <div className="flex-1 text-left">
                      <p className="text-sm font-medium text-foreground truncate">{ws.name}</p>
                      <p className="text-xs text-muted-foreground">
                        Updated {format(new Date(ws.updated_at), 'MMM d')}
                      </p>
                    </div>
                    <span className={`text-xs px-2 py-0.5 rounded-full ${
                      ws.status === 'active' 
                        ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400' 
                        : 'bg-muted text-muted-foreground'
                    }`}>
                      {ws.status}
                    </span>
                  </button>
                ))
              ) : (
                <div className="bg-card border border-border rounded-xl p-4">
                  <p className="text-sm text-muted-foreground text-center py-2">
                    No workspaces yet
                  </p>
                </div>
              )}
            </div>
          )}
        </section>
      </div>
    </PullToRefresh>
  );
};
