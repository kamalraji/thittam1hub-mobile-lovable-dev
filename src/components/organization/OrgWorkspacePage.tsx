import React, { useEffect, useState } from 'react';
import { useParams, useSearchParams } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { Workspace, WorkspaceStatus, UserRole } from '@/types';
import { useCurrentOrganization } from './OrganizationContext';
import { OrganizationBreadcrumbs } from '@/components/organization/OrganizationBreadcrumbs';
import { WorkspaceDashboard } from '@/components/workspace/WorkspaceDashboard';
import { useAuth } from '@/hooks/useAuth';
import { Button } from '@/components/ui/button';
import { PlusIcon, Squares2X2Icon } from '@heroicons/react/24/outline';
import { toast } from 'sonner';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';

/**
 * OrgWorkspacePage
 *
 * Organization-scoped workspace portal for the route `/:orgSlug/workspaces/:eventId`.
 * Shows workspace list and full workspace dashboard when one is selected.
 * The eventId is now a required URL parameter, not a query param.
 */
export const OrgWorkspacePage: React.FC = () => {
  const organization = useCurrentOrganization();
  const { orgSlug, eventId } = useParams<{ orgSlug: string; eventId: string }>();
  const [searchParams, setSearchParams] = useSearchParams();
  const { user } = useAuth();
  const queryClient = useQueryClient();

  const selectedWorkspaceId = searchParams.get('workspaceId') || undefined;
  const [isCreateDialogOpen, setIsCreateDialogOpen] = useState(false);
  const [newWorkspaceName, setNewWorkspaceName] = useState('');

  // Load workspaces for this specific event
  const { data: workspaces, isLoading: workspacesLoading } = useQuery<Workspace[]>({
    queryKey: ['org-workspaces', organization?.id, eventId],
    queryFn: async () => {
      if (!organization?.id || !eventId) return [] as Workspace[];

      const { data, error } = await supabase
        .from('workspaces')
        .select(
          'id, name, status, created_at, updated_at, event_id, events!inner(id, name, organization_id)'
        )
        .eq('events.organization_id', organization.id)
        .eq('event_id', eventId)
        .order('created_at', { ascending: false });

      if (error) throw error;

      return ((data || []).map((row: any) => ({
        id: row.id,
        eventId: row.event_id,
        name: row.name,
        status: row.status as WorkspaceStatus,
        createdAt: row.created_at,
        updatedAt: row.updated_at,
        description: undefined,
        event: row.events
          ? {
            id: row.events.id,
            name: row.events.name,
          }
          : undefined,
        teamMembers: [],
        taskSummary: undefined,
        channels: [],
      })) as unknown) as Workspace[];
    },
    enabled: !!organization?.id && !!eventId,
  });

  // Get event details
  const { data: event } = useQuery({
    queryKey: ['event-name', eventId],
    queryFn: async () => {
      if (!eventId) return null;
      const { data, error } = await supabase
        .from('events')
        .select('id, name')
        .eq('id', eventId)
        .maybeSingle();
      if (error) throw error;
      return data;
    },
    enabled: !!eventId,
  });

  // Create workspace mutation
  const createWorkspaceMutation = useMutation({
    mutationFn: async (name: string) => {
      if (!eventId || !user?.id) throw new Error('Missing required data');
      
      const { data, error } = await supabase
        .from('workspaces')
        .insert({
          name,
          event_id: eventId,
          organizer_id: user.id,
          status: 'ACTIVE',
        })
        .select('id')
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: (data) => {
      toast.success('Workspace created successfully');
      queryClient.invalidateQueries({ queryKey: ['org-workspaces', organization?.id, eventId] });
      setIsCreateDialogOpen(false);
      setNewWorkspaceName('');
      // Select the newly created workspace
      setSearchParams((prev) => {
        const next = new URLSearchParams(prev);
        next.set('workspaceId', data.id);
        return next;
      });
    },
    onError: (error) => {
      console.error('Failed to create workspace:', error);
      toast.error('Failed to create workspace');
    },
  });

  // Auto-select first workspace if none selected and workspaces exist
  useEffect(() => {
    if (!selectedWorkspaceId && workspaces && workspaces.length > 0) {
      setSearchParams((prev) => {
        const next = new URLSearchParams(prev);
        next.set('workspaceId', workspaces[0].id);
        return next;
      }, { replace: true });
    }
  }, [selectedWorkspaceId, workspaces, setSearchParams]);

  const canManageWorkspaces =
    !!user && (user.role === UserRole.ORGANIZER || user.role === UserRole.SUPER_ADMIN);

  const hasNoWorkspaces = !workspacesLoading && (!workspaces || workspaces.length === 0);

  const handleCreateWorkspace = () => {
    if (!newWorkspaceName.trim()) {
      toast.error('Please enter a workspace name');
      return;
    }
    createWorkspaceMutation.mutate(newWorkspaceName.trim());
  };

  return (
    <div className="flex flex-col gap-4">
      <header className="space-y-2">
        <OrganizationBreadcrumbs
          items={[
            {
              label: organization?.name ?? 'Organization',
              href: orgSlug ? `/${orgSlug}` : undefined,
            },
            {
              label: 'Events',
              href: `/${orgSlug}/eventmanagement`,
            },
            {
              label: event?.name ?? 'Event',
              href: `/${orgSlug}/eventmanagement/${eventId}`,
            },
            {
              label: 'Workspaces',
              isCurrent: true,
            },
          ]}
          className="text-xs"
        />
        <div className="flex items-center justify-between gap-4">
          <div>
            <h1 className="text-xl font-semibold tracking-tight text-foreground">
              {event?.name ? `${event.name} Workspaces` : 'Event Workspaces'}
            </h1>
            <p className="text-sm text-muted-foreground">
              Manage workspaces for this event with tasks, team, and communication.
            </p>
          </div>
          {canManageWorkspaces && !hasNoWorkspaces && (
            <Button
              onClick={() => setIsCreateDialogOpen(true)}
              size="sm"
              className="gap-2"
            >
              <PlusIcon className="h-4 w-4" />
              <span className="hidden sm:inline">New Workspace</span>
            </Button>
          )}
        </div>
      </header>

      {/* Workspace dashboard */}
      <main className="min-h-[400px]">
        {selectedWorkspaceId ? (
          <WorkspaceDashboard workspaceId={selectedWorkspaceId} orgSlug={orgSlug} />
        ) : hasNoWorkspaces ? (
          <div className="rounded-2xl border border-border/70 bg-card/80 p-8 shadow-sm flex flex-col items-center justify-center min-h-[400px]">
            <div className="flex h-16 w-16 items-center justify-center rounded-full bg-primary/10 mb-4">
              <Squares2X2Icon className="h-8 w-8 text-primary" />
            </div>
            <h2 className="text-lg font-semibold text-foreground mb-2">No workspaces yet</h2>
            <p className="text-sm text-muted-foreground text-center max-w-md mb-6">
              Create your first workspace to start organizing tasks, managing your team, and coordinating communication for this event.
            </p>
            {canManageWorkspaces && (
              <Button
                onClick={() => setIsCreateDialogOpen(true)}
                className="gap-2"
              >
                <PlusIcon className="h-4 w-4" />
                Create Workspace
              </Button>
            )}
          </div>
        ) : (
          <div className="rounded-2xl border border-border/70 bg-card/80 p-6 shadow-sm flex flex-col items-center justify-center min-h-[400px]">
            <h2 className="text-base font-semibold text-foreground mb-2">Select a workspace</h2>
            <p className="text-sm text-muted-foreground text-center max-w-md">
              Choose a workspace from the list to view tasks, team members, and communication.
            </p>
          </div>
        )}
      </main>

      {/* Create Workspace Dialog */}
      <Dialog open={isCreateDialogOpen} onOpenChange={setIsCreateDialogOpen}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Create Workspace</DialogTitle>
            <DialogDescription>
              Create a new workspace for {event?.name || 'this event'} to organize your team and tasks.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="workspace-name">Workspace Name</Label>
              <Input
                id="workspace-name"
                placeholder="e.g., Main Operations, Marketing Team"
                value={newWorkspaceName}
                onChange={(e) => setNewWorkspaceName(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    handleCreateWorkspace();
                  }
                }}
              />
            </div>
          </div>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => {
                setIsCreateDialogOpen(false);
                setNewWorkspaceName('');
              }}
            >
              Cancel
            </Button>
            <Button
              onClick={handleCreateWorkspace}
              disabled={createWorkspaceMutation.isPending || !newWorkspaceName.trim()}
            >
              {createWorkspaceMutation.isPending ? 'Creating...' : 'Create Workspace'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default OrgWorkspacePage;
