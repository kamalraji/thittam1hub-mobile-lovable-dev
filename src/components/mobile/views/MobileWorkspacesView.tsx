import React, { useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { Briefcase, Plus, Clock, ChevronRight } from 'lucide-react';
import { supabase } from '@/integrations/supabase/client';
import { Button } from '@/components/ui/button';
import { format } from 'date-fns';
import { PullToRefresh } from '../shared/PullToRefresh';
import { ListSkeleton } from '../shared/MobileSkeleton';

interface MobileWorkspacesViewProps {
  organization: {
    id: string;
    slug: string;
  };
  user: {
    id: string;
  };
}

interface Workspace {
  id: string;
  name: string;
  status: string;
  updated_at: string;
  event_id: string;
  event_name?: string;
}

export const MobileWorkspacesView: React.FC<MobileWorkspacesViewProps> = ({ 
  organization,
  user 
}) => {
  const navigate = useNavigate();
  

  const { data: workspaces, isLoading, refetch } = useQuery<Workspace[]>({
    queryKey: ['mobile-all-workspaces', organization.id, user.id],
    queryFn: async () => {
      // First get all events for this organization
      const { data: orgEvents } = await supabase
        .from('events')
        .select('id, name')
        .eq('organization_id', organization.id);
      
      const eventIds = (orgEvents || []).map(e => e.id);
      const eventMap = new Map((orgEvents || []).map(e => [e.id, e.name]));
      
      if (eventIds.length === 0) return [];

      const { data, error } = await supabase
        .from('workspaces')
        .select('id, name, status, updated_at, event_id')
        .in('event_id', eventIds)
        .order('updated_at', { ascending: false });
      
      if (error) throw error;
      
      return (data || []).map(ws => ({
        ...ws,
        event_name: eventMap.get(ws.event_id) || 'Unknown Event'
      }));
    },
  });

  const handleRefresh = useCallback(async () => {
    await refetch();
  }, [refetch]);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active':
        return 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400';
      case 'archived':
        return 'bg-muted text-muted-foreground';
      default:
        return 'bg-muted text-muted-foreground';
    }
  };

  return (
    <PullToRefresh onRefresh={handleRefresh} className="h-full">
      <div className="px-4 py-4 space-y-4">
        {/* Header */}
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold text-foreground">Workspaces</h1>
          <Button 
            size="sm" 
            onClick={() => navigate(`/${organization.slug}/workspaces`)}
            className="gap-1"
          >
            <Plus className="h-4 w-4" />
            Create
          </Button>
        </div>

        {/* Workspaces List */}
        {isLoading ? (
          <ListSkeleton count={5} />
        ) : workspaces && workspaces.length > 0 ? (
          <div className="space-y-3">
            {workspaces.map((workspace) => (
              <button
                key={workspace.id}
                onClick={() => navigate(`/${organization.slug}/workspaces/${workspace.event_id}/${workspace.id}`)}
                className="w-full text-left p-4 bg-card border border-border rounded-2xl hover:bg-muted/50 transition-colors shadow-sm active:scale-[0.98]"
              >
                <div className="flex items-start gap-3">
                  <div className="p-2 rounded-xl bg-green-500/10 shrink-0">
                    <Briefcase className="h-6 w-6 text-green-600" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-start justify-between gap-2">
                      <h3 className="font-semibold text-foreground truncate">{workspace.name}</h3>
                      <span className={`text-xs px-2 py-0.5 rounded-full shrink-0 ${getStatusColor(workspace.status)}`}>
                        {workspace.status}
                      </span>
                    </div>
                    
                    <p className="text-sm text-muted-foreground mt-1 truncate">
                      {workspace.event_name}
                    </p>
                    
                    <div className="flex items-center gap-2 mt-2 text-xs text-muted-foreground">
                      <Clock className="h-3 w-3" />
                      Updated {format(new Date(workspace.updated_at), 'MMM d, yyyy')}
                    </div>
                  </div>
                  <ChevronRight className="h-5 w-5 text-muted-foreground shrink-0" />
                </div>
              </button>
            ))}
          </div>
        ) : (
          <div className="flex flex-col items-center justify-center py-12 text-center">
            <div className="p-4 rounded-full bg-muted mb-4">
              <Briefcase className="h-8 w-8 text-muted-foreground" />
            </div>
            <h3 className="font-medium text-foreground mb-1">No workspaces yet</h3>
            <p className="text-sm text-muted-foreground mb-4">
              Create your first workspace to get started
            </p>
            <Button onClick={() => navigate(`/${organization.slug}/workspaces`)}>
              <Plus className="h-4 w-4 mr-1" />
              Create Workspace
            </Button>
          </div>
        )}
      </div>
    </PullToRefresh>
  );
};
