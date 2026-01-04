import React from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { Calendar, Plus, Clock, MapPin, Users } from 'lucide-react';
import { supabase } from '@/integrations/supabase/client';
import { Button } from '@/components/ui/button';
import { format } from 'date-fns';

interface MobileEventsViewProps {
  organization: {
    id: string;
    slug: string;
  };
}

interface Event {
  id: string;
  name: string;
  description: string | null;
  start_date: string;
  end_date: string;
  status: string;
  mode: string;
  capacity: number | null;
}

export const MobileEventsView: React.FC<MobileEventsViewProps> = ({ organization }) => {
  const navigate = useNavigate();

  const { data: events, isLoading } = useQuery<Event[]>({
    queryKey: ['mobile-all-events', organization.id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('events')
        .select('id, name, description, start_date, end_date, status, mode, capacity')
        .eq('organization_id', organization.id)
        .order('start_date', { ascending: false });
      if (error) throw error;
      return data || [];
    },
  });

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'PUBLISHED':
        return 'bg-green-100 text-green-700';
      case 'DRAFT':
        return 'bg-yellow-100 text-yellow-700';
      case 'ONGOING':
        return 'bg-blue-100 text-blue-700';
      case 'COMPLETED':
        return 'bg-muted text-muted-foreground';
      case 'CANCELLED':
        return 'bg-red-100 text-red-700';
      default:
        return 'bg-muted text-muted-foreground';
    }
  };

  return (
    <div className="px-4 py-4 space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold text-foreground">Events</h1>
        <Button 
          size="sm" 
          onClick={() => navigate(`/${organization.slug}/eventmanagement/create`)}
          className="gap-1"
        >
          <Plus className="h-4 w-4" />
          Create
        </Button>
      </div>

      {/* Events List */}
      {isLoading ? (
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary" />
        </div>
      ) : events && events.length > 0 ? (
        <div className="space-y-3">
          {events.map((event) => (
            <button
              key={event.id}
              onClick={() => navigate(`/${organization.slug}/eventmanagement/${event.id}`)}
              className="w-full text-left p-4 bg-card border border-border rounded-2xl hover:bg-muted/50 transition-colors shadow-sm"
            >
              <div className="flex items-start gap-3">
                <div className="p-2 rounded-xl bg-primary/10 shrink-0">
                  <Calendar className="h-6 w-6 text-primary" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-2">
                    <h3 className="font-semibold text-foreground truncate">{event.name}</h3>
                    <span className={`text-xs px-2 py-0.5 rounded-full shrink-0 ${getStatusColor(event.status)}`}>
                      {event.status}
                    </span>
                  </div>
                  
                  {event.description && (
                    <p className="text-sm text-muted-foreground mt-1 line-clamp-2">
                      {event.description}
                    </p>
                  )}
                  
                  <div className="flex flex-wrap items-center gap-3 mt-2 text-xs text-muted-foreground">
                    <span className="flex items-center gap-1">
                      <Clock className="h-3 w-3" />
                      {format(new Date(event.start_date), 'MMM d, yyyy')}
                    </span>
                    <span className="flex items-center gap-1">
                      <MapPin className="h-3 w-3" />
                      {event.mode}
                    </span>
                    {event.capacity && (
                      <span className="flex items-center gap-1">
                        <Users className="h-3 w-3" />
                        {event.capacity} capacity
                      </span>
                    )}
                  </div>
                </div>
              </div>
            </button>
          ))}
        </div>
      ) : (
        <div className="flex flex-col items-center justify-center py-12 text-center">
          <div className="p-4 rounded-full bg-muted mb-4">
            <Calendar className="h-8 w-8 text-muted-foreground" />
          </div>
          <h3 className="font-medium text-foreground mb-1">No events yet</h3>
          <p className="text-sm text-muted-foreground mb-4">
            Create your first event to get started
          </p>
          <Button onClick={() => navigate(`/${organization.slug}/eventmanagement/create`)}>
            <Plus className="h-4 w-4 mr-1" />
            Create Event
          </Button>
        </div>
      )}
    </div>
  );
};
