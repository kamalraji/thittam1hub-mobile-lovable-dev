import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/looseClient';
import { EventStatusActions } from '@/components/events/publish/EventStatusActions';
import { WorkspacePublishSettings } from '@/components/workspace/settings/WorkspacePublishSettings';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Calendar, MapPin, Users, Globe, Lock, Loader2 } from 'lucide-react';
import { format } from 'date-fns';

interface EventOverviewPanelProps {
  eventId: string;
  workspaceId: string;
  isRootOwner: boolean;
}

export const EventOverviewPanel: React.FC<EventOverviewPanelProps> = ({
  eventId,
  workspaceId,
  isRootOwner,
}) => {
  const { data: event, isLoading, refetch } = useQuery({
    queryKey: ['event-overview', eventId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('events')
        .select('id, name, status, start_date, end_date, mode, visibility, capacity, description')
        .eq('id', eventId)
        .single();

      if (error) throw error;
      return data;
    },
  });

  const { data: registrationStats } = useQuery({
    queryKey: ['event-registration-stats', eventId],
    queryFn: async () => {
      const { count, error } = await supabase
        .from('registrations')
        .select('*', { count: 'exact', head: true })
        .eq('event_id', eventId)
        .eq('status', 'CONFIRMED');

      if (error) throw error;
      return { confirmedCount: count || 0 };
    },
  });

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-12">
        <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
      </div>
    );
  }

  if (!event) {
    return (
      <div className="text-center py-12 text-muted-foreground">
        Event not found
      </div>
    );
  }

  const getModeLabel = (mode: string) => {
    switch (mode) {
      case 'IN_PERSON': return 'In Person';
      case 'VIRTUAL': return 'Virtual';
      case 'HYBRID': return 'Hybrid';
      default: return mode;
    }
  };

  return (
    <div className="space-y-6">
      {/* Event Status & Actions Card */}
      <Card>
        <CardHeader className="pb-3">
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <div>
              <CardTitle className="text-xl">{event.name}</CardTitle>
              <p className="text-sm text-muted-foreground mt-1">
                Event lifecycle and publishing controls
              </p>
            </div>
            <EventStatusActions
              eventId={eventId}
              currentStatus={event.status}
              canManage={isRootOwner}
              onStatusChange={() => refetch()}
            />
          </div>
        </CardHeader>
      </Card>

      {/* Event Quick Info Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Dates */}
        <Card>
          <CardContent className="pt-4">
            <div className="flex items-start gap-3">
              <div className="p-2 rounded-lg bg-primary/10">
                <Calendar className="h-4 w-4 text-primary" />
              </div>
              <div className="min-w-0">
                <p className="text-xs text-muted-foreground font-medium">Event Dates</p>
                <p className="text-sm font-medium truncate">
                  {format(new Date(event.start_date), 'MMM d')} - {format(new Date(event.end_date), 'MMM d, yyyy')}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Mode */}
        <Card>
          <CardContent className="pt-4">
            <div className="flex items-start gap-3">
              <div className="p-2 rounded-lg bg-blue-500/10">
                <MapPin className="h-4 w-4 text-blue-500" />
              </div>
              <div className="min-w-0">
                <p className="text-xs text-muted-foreground font-medium">Event Mode</p>
                <p className="text-sm font-medium">{getModeLabel(event.mode)}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Visibility */}
        <Card>
          <CardContent className="pt-4">
            <div className="flex items-start gap-3">
              <div className="p-2 rounded-lg bg-amber-500/10">
                {event.visibility === 'PUBLIC' ? (
                  <Globe className="h-4 w-4 text-amber-500" />
                ) : (
                  <Lock className="h-4 w-4 text-amber-500" />
                )}
              </div>
              <div className="min-w-0">
                <p className="text-xs text-muted-foreground font-medium">Visibility</p>
                <p className="text-sm font-medium capitalize">{event.visibility?.toLowerCase()}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Registrations */}
        <Card>
          <CardContent className="pt-4">
            <div className="flex items-start gap-3">
              <div className="p-2 rounded-lg bg-green-500/10">
                <Users className="h-4 w-4 text-green-500" />
              </div>
              <div className="min-w-0">
                <p className="text-xs text-muted-foreground font-medium">Registrations</p>
                <p className="text-sm font-medium">
                  {registrationStats?.confirmedCount || 0}
                  {event.capacity && <span className="text-muted-foreground"> / {event.capacity}</span>}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Workspace Publish Settings - ROOT only */}
      {isRootOwner && (
        <WorkspacePublishSettings workspaceId={workspaceId} />
      )}
    </div>
  );
};
