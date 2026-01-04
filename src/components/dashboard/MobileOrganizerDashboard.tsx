import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import {
  Home,
  CalendarDays,
  Mail,
  BarChart3,
  Search,
  Plus,
  Users,
  SlidersHorizontal,
  Briefcase,
  Bell
} from 'lucide-react';
import { useAuth } from '../../hooks/useAuth';
import { useCurrentOrganization } from '../organization/OrganizationContext';
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { useEventCreatePath } from '@/hooks/useEventCreatePath';

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
}

export function MobileOrganizerDashboard() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const organization = useCurrentOrganization();
  const [activeTab, setActiveTab] = useState<'home' | 'events' | 'email' | 'analytics' | 'search'>('home');
  const eventCreatePath = useEventCreatePath();

  // Fetch events
  const { data: events } = useQuery<Event[]>({
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
  const { data: workspaces } = useQuery<WorkspaceSummary[]>({
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
        .select('id, name, status, updated_at')
        .eq('organizer_id', user!.id)
        .in('event_id', orgEventIds)
        .order('updated_at', { ascending: false })
        .limit(5);
      
      if (error) throw error;
      return (data || []).map(ws => ({
        id: ws.id,
        name: ws.name,
        status: ws.status,
        updatedAt: ws.updated_at
      }));
    },
    enabled: !!user?.id
  });

  // Get user initials for avatar
  const getUserInitials = () => {
    if (user?.name) {
      return user.name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);
    }
    return 'U';
  };

  // Quick action grid items (2x2 layout like Attendflow)
  const quickActionCards = [
    { icon: CalendarDays, label: 'Events', path: `/${organization.slug}/eventmanagement` },
    { icon: SlidersHorizontal, label: 'Segments', path: `/${organization.slug}/analytics` },
    { icon: Briefcase, label: 'Workspaces', path: `/${organization.slug}/workspaces` },
    { icon: Users, label: 'Team', path: `/${organization.slug}/team` },
  ];

  const upcomingEvents = events?.filter(e => new Date(e.startDate) > new Date()).slice(0, 3) || [];

  return (
    <div className="min-h-screen w-full bg-background flex flex-col">
      {/* Mobile Header - Attendflow style */}
      <header className="fixed top-0 left-0 right-0 bg-card border-b border-border z-50">
        <div className="flex items-center justify-between px-4 py-3">
          {/* Left - Logo */}
          <div className="flex items-center gap-2">
            <div className="w-7 h-7 rounded bg-primary flex items-center justify-center">
              <span className="text-primary-foreground text-xs font-bold">T1</span>
            </div>
            <span className="text-base font-semibold text-foreground">Thittam1Hub</span>
          </div>

          {/* Right - Notification and Avatar */}
          <div className="flex items-center gap-2">
            <button className="p-2 rounded-full hover:bg-muted transition-colors relative">
              <Bell className="w-5 h-5 text-muted-foreground" />
            </button>
            <button className="w-8 h-8 rounded-full bg-primary flex items-center justify-center">
              <span className="text-primary-foreground text-sm font-medium">
                {getUserInitials()}
              </span>
            </button>
          </div>
        </div>
        
        {/* User email subtitle */}
        <div className="px-4 pb-2 -mt-1">
          <p className="text-xs text-muted-foreground truncate">
            {user?.email || organization.name}
          </p>
        </div>
      </header>

      {/* Main Content - Scrollable */}
      <div className="flex-1 overflow-y-auto pt-20 pb-24 px-4">
        {activeTab === 'home' && (
          <div className="space-y-6">
            {/* 2x2 Quick Action Grid */}
            <div className="grid grid-cols-2 gap-3">
              {quickActionCards.map((card, index) => (
                <Link
                  key={index}
                  to={card.path}
                  className="bg-card border border-border rounded-xl p-5 flex flex-col items-center justify-center gap-2 hover:bg-muted/50 active:scale-[0.98] transition-all"
                >
                  <card.icon className="w-6 h-6 text-primary" />
                  <span className="text-sm font-medium text-foreground">{card.label}</span>
                </Link>
              ))}
            </div>

            {/* Tasks Section */}
            <section className="space-y-3">
              <div className="flex items-center justify-between">
                <h2 className="text-lg font-semibold text-foreground">Tasks</h2>
                <Link to={`/${organization.slug}/workspaces`} className="text-sm font-medium text-primary hover:underline">
                  View all
                </Link>
              </div>
              <div className="py-6 text-center">
                <p className="text-muted-foreground">No tasks yet</p>
              </div>
            </section>

            {/* Upcoming Meetings Section */}
            <section className="space-y-3">
              <div className="flex items-center justify-between">
                <h2 className="text-lg font-semibold text-foreground">Upcoming Meetings</h2>
                <button className="text-sm font-medium text-primary hover:underline">
                  View all
                </button>
              </div>
              <div className="py-6 text-center">
                <p className="text-muted-foreground">No upcoming meetings</p>
              </div>
            </section>

            {/* Upcoming Events Section */}
            <section className="space-y-3">
              <div className="flex items-center justify-between">
                <h2 className="text-lg font-semibold text-foreground">Upcoming Events</h2>
                <Link to={`/${organization.slug}/eventmanagement`} className="text-sm font-medium text-primary hover:underline">
                  View all
                </Link>
              </div>
              {upcomingEvents.length > 0 ? (
                <div className="space-y-2">
                  {upcomingEvents.map(event => (
                    <Link
                      key={event.id}
                      to={`/events/${event.id}`}
                      className="block bg-card border border-border rounded-lg p-3 hover:bg-muted/50 transition-colors"
                    >
                      <p className="font-medium text-foreground text-sm">{event.name}</p>
                      <p className="text-xs text-muted-foreground mt-1">
                        {new Date(event.startDate).toLocaleDateString()}
                      </p>
                    </Link>
                  ))}
                </div>
              ) : (
                <div className="py-6 text-center">
                  <p className="text-muted-foreground">No upcoming events</p>
                </div>
              )}
            </section>

            {/* Recent Workspaces Section */}
            <section className="space-y-3">
              <div className="flex items-center justify-between">
                <h2 className="text-lg font-semibold text-foreground">Recent Workspaces</h2>
                <Link to={`/${organization.slug}/workspaces`} className="text-sm font-medium text-primary hover:underline">
                  View all
                </Link>
              </div>
              {workspaces && workspaces.length > 0 ? (
                <div className="space-y-2">
                  {workspaces.slice(0, 3).map(ws => (
                    <Link
                      key={ws.id}
                      to={`/${organization.slug}/workspaces/${ws.id}`}
                      className="block bg-card border border-border rounded-lg p-3 hover:bg-muted/50 transition-colors"
                    >
                      <p className="font-medium text-foreground text-sm">{ws.name}</p>
                      <p className="text-xs text-muted-foreground mt-1 capitalize">{ws.status.toLowerCase()}</p>
                    </Link>
                  ))}
                </div>
              ) : (
                <div className="py-6 text-center">
                  <p className="text-muted-foreground">No workspaces yet</p>
                </div>
              )}
            </section>
          </div>
        )}

        {activeTab === 'events' && (
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-semibold text-foreground">My Events</h2>
              <Link 
                to={eventCreatePath}
                className="text-sm font-medium text-primary hover:underline"
              >
                Create
              </Link>
            </div>
            {events && events.length > 0 ? (
              <div className="space-y-2">
                {events.map(event => (
                  <Link
                    key={event.id}
                    to={`/events/${event.id}`}
                    className="block bg-card border border-border rounded-lg p-4 hover:bg-muted/50 transition-colors"
                  >
                    <p className="font-medium text-foreground">{event.name}</p>
                    <div className="flex items-center gap-2 mt-2 text-xs text-muted-foreground">
                      <span>{new Date(event.startDate).toLocaleDateString()}</span>
                      <span className="capitalize px-2 py-0.5 bg-muted rounded-full">{event.status.toLowerCase()}</span>
                    </div>
                  </Link>
                ))}
              </div>
            ) : (
              <div className="py-8 text-center text-muted-foreground">
                No events created yet
              </div>
            )}
          </div>
        )}

        {activeTab === 'email' && (
          <div className="space-y-4">
            <h2 className="text-lg font-semibold text-foreground">Email</h2>
            <div className="py-8 text-center text-muted-foreground">
              No emails to display
            </div>
          </div>
        )}

        {activeTab === 'analytics' && (
          <div className="space-y-4">
            <h2 className="text-lg font-semibold text-foreground">Analytics</h2>
            <div className="grid grid-cols-2 gap-3">
              <div className="bg-card border border-border rounded-xl p-4">
                <p className="text-xs text-muted-foreground">Total Events</p>
                <p className="text-2xl font-bold text-foreground mt-1">{events?.length || 0}</p>
              </div>
              <div className="bg-card border border-border rounded-xl p-4">
                <p className="text-xs text-muted-foreground">Workspaces</p>
                <p className="text-2xl font-bold text-foreground mt-1">{workspaces?.length || 0}</p>
              </div>
            </div>
          </div>
        )}

        {activeTab === 'search' && (
          <div className="space-y-4">
            <h2 className="text-lg font-semibold text-foreground">Search</h2>
            <div className="py-8 text-center text-muted-foreground">
              Search functionality coming soon
            </div>
          </div>
        )}
      </div>

      {/* Floating Action Button */}
      <button
        onClick={() => navigate(eventCreatePath)}
        className="fixed bottom-24 right-4 w-14 h-14 rounded-full bg-gradient-to-br from-primary via-primary to-cyan-400 text-primary-foreground shadow-lg flex items-center justify-center hover:shadow-xl active:scale-95 transition-all z-40"
      >
        <Plus className="w-6 h-6" />
      </button>

      {/* Bottom Navigation - Attendflow style */}
      <div className="fixed bottom-0 left-0 right-0 bg-card border-t border-border z-50">
        <div className="flex justify-around items-center h-16 px-2 pb-safe">
          <button
            onClick={() => setActiveTab('home')}
            className={`flex flex-col items-center justify-center flex-1 py-2 transition-colors ${
              activeTab === 'home' ? 'text-primary' : 'text-muted-foreground'
            }`}
          >
            <Home className="w-5 h-5" />
            <span className="text-xs mt-1 font-medium">Home</span>
          </button>
          <button
            onClick={() => setActiveTab('events')}
            className={`flex flex-col items-center justify-center flex-1 py-2 transition-colors ${
              activeTab === 'events' ? 'text-primary' : 'text-muted-foreground'
            }`}
          >
            <CalendarDays className="w-5 h-5" />
            <span className="text-xs mt-1 font-medium">Events</span>
          </button>
          <button
            onClick={() => setActiveTab('email')}
            className={`flex flex-col items-center justify-center flex-1 py-2 transition-colors ${
              activeTab === 'email' ? 'text-primary' : 'text-muted-foreground'
            }`}
          >
            <Mail className="w-5 h-5" />
            <span className="text-xs mt-1 font-medium">Email</span>
          </button>
          <button
            onClick={() => setActiveTab('analytics')}
            className={`flex flex-col items-center justify-center flex-1 py-2 transition-colors ${
              activeTab === 'analytics' ? 'text-primary' : 'text-muted-foreground'
            }`}
          >
            <BarChart3 className="w-5 h-5" />
            <span className="text-xs mt-1 font-medium">Analytics</span>
          </button>
          <button
            onClick={() => setActiveTab('search')}
            className={`flex flex-col items-center justify-center flex-1 py-2 transition-colors ${
              activeTab === 'search' ? 'text-primary' : 'text-muted-foreground'
            }`}
          >
            <Search className="w-5 h-5" />
            <span className="text-xs mt-1 font-medium">Search</span>
          </button>
        </div>
      </div>
    </div>
  );
}
