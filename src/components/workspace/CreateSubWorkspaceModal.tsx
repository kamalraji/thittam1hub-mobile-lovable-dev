import { useState, useEffect, useMemo } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/hooks/useAuth';
import { WorkspaceType, WorkspaceRole } from '@/types';
import {
  MAX_WORKSPACE_DEPTH,
  getWorkspaceTypeLabel,
  getCreationOptions,
  canHaveChildren,
  getResponsibleRoleForWorkspace,
  getWorkspaceRoleLabel,
} from '@/lib/workspaceHierarchy';
import { 
  AlertTriangle, 
  Building2, 
  Users, 
  Layers, 
  Sparkles,
  ArrowRight,
  Check
} from 'lucide-react';
import { cn } from '@/lib/utils';

interface CreateSubWorkspaceModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  parentWorkspaceId: string;
  eventId: string;
}

export function CreateSubWorkspaceModal({
  open,
  onOpenChange,
  parentWorkspaceId,
  eventId,
}: CreateSubWorkspaceModalProps) {
  const { user } = useAuth();
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const [selectedOption, setSelectedOption] = useState<string>('');
  const [customName, setCustomName] = useState('');

  // Fetch parent workspace to get its type and department_id
  const { data: parentWorkspace } = useQuery({
    queryKey: ['workspace-parent', parentWorkspaceId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('workspaces')
        .select('id, name, workspace_type, department_id, parent_workspace_id')
        .eq('id', parentWorkspaceId)
        .single();

      if (error) throw error;
      return data;
    },
    enabled: open && !!parentWorkspaceId,
  });

  // Get parent workspace type with fallback for legacy data
  const parentType = useMemo(() => {
    if (!parentWorkspace) return undefined;
    if (parentWorkspace.workspace_type) {
      return parentWorkspace.workspace_type as WorkspaceType;
    }
    return parentWorkspace.parent_workspace_id ? undefined : WorkspaceType.ROOT;
  }, [parentWorkspace]);

  // Get creation options based on parent type
  const creationInfo = useMemo(() => {
    return getCreationOptions(parentType, parentWorkspace?.department_id || undefined);
  }, [parentType, parentWorkspace?.department_id]);

  const nextType = creationInfo.nextType;
  const options = creationInfo.options;
  const allowCustomName = creationInfo.allowCustomName;

  // Check if creation is allowed
  const canCreate = nextType !== null && canHaveChildren(parentType);

  // Determine final name based on selection
  const getFinalName = (): string => {
    if (allowCustomName) {
      return customName;
    }
    if (options && selectedOption) {
      const option = options.find(o => o.id === selectedOption);
      return option?.name || '';
    }
    return '';
  };

  // Get department_id for the new workspace
  const getDepartmentId = (): string | null => {
    if (nextType === WorkspaceType.DEPARTMENT) {
      return selectedOption || null;
    }
    return parentWorkspace?.department_id || null;
  };

  // Get the responsible role for the workspace being created
  const responsibleRole = useMemo((): WorkspaceRole | null => {
    if (!nextType) return null;
    
    const departmentId = nextType === WorkspaceType.DEPARTMENT 
      ? selectedOption 
      : parentWorkspace?.department_id || undefined;
    
    const committeeId = nextType === WorkspaceType.COMMITTEE 
      ? selectedOption 
      : undefined;
    
    return getResponsibleRoleForWorkspace(nextType, departmentId, committeeId);
  }, [nextType, selectedOption, parentWorkspace?.department_id]);

  const createSubWorkspaceMutation = useMutation({
    mutationFn: async () => {
      if (!user) throw new Error('Must be authenticated');
      if (!canCreate) throw new Error('Cannot create sub-workspace at this level');

      const name = getFinalName();
      if (!name.trim()) throw new Error('Name is required');

      const { data: workspace, error: wsError } = await supabase
        .from('workspaces')
        .insert({
          name: name.trim(),
          event_id: eventId,
          parent_workspace_id: parentWorkspaceId,
          organizer_id: user.id,
          status: 'ACTIVE',
          workspace_type: nextType,
          department_id: getDepartmentId(),
        })
        .select('id, name')
        .single();

      if (wsError) throw wsError;

      if (responsibleRole) {
        const { error: memberError } = await supabase
          .from('workspace_team_members')
          .insert({
            workspace_id: workspace.id,
            user_id: user.id,
            role: responsibleRole,
            status: 'active',
          });

        if (memberError) {
          console.error('Failed to auto-assign role:', memberError);
        }
      }

      return { ...workspace, assignedRole: responsibleRole };
    },
    onSuccess: (data) => {
      const roleMessage = data.assignedRole 
        ? ` You've been assigned as ${getWorkspaceRoleLabel(data.assignedRole)}.`
        : '';
      
      toast({
        title: `${getWorkspaceTypeLabel(nextType || undefined)} created`,
        description: `"${data.name}" has been created successfully.${roleMessage}`,
      });
      queryClient.invalidateQueries({ queryKey: ['event-workspaces', eventId] });
      queryClient.invalidateQueries({ queryKey: ['workspace-hierarchy', eventId] });
      queryClient.invalidateQueries({ queryKey: ['user-workspaces'] });
      queryClient.invalidateQueries({ queryKey: ['workspace', parentWorkspaceId] });
      queryClient.invalidateQueries({ queryKey: ['workspace-team-members'] });
      onOpenChange(false);
      resetForm();
    },
    onError: (error: Error) => {
      toast({
        title: 'Failed to create',
        description: error.message,
        variant: 'destructive',
      });
    },
  });

  const resetForm = () => {
    setSelectedOption('');
    setCustomName('');
  };

  useEffect(() => {
    if (open) {
      resetForm();
    }
  }, [open, parentWorkspaceId]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    createSubWorkspaceMutation.mutate();
  };

  const isValid = allowCustomName ? customName.trim().length > 0 : selectedOption.length > 0;

  // Get styling for workspace type
  const getTypeStyles = () => {
    switch (nextType) {
      case WorkspaceType.DEPARTMENT:
        return { 
          icon: Building2, 
          gradient: 'from-blue-500/20 via-blue-500/10 to-transparent',
          border: 'border-blue-500/30',
          iconColor: 'text-blue-500',
          ring: 'ring-blue-500/20'
        };
      case WorkspaceType.COMMITTEE:
        return { 
          icon: Users, 
          gradient: 'from-amber-500/20 via-amber-500/10 to-transparent',
          border: 'border-amber-500/30',
          iconColor: 'text-amber-500',
          ring: 'ring-amber-500/20'
        };
      case WorkspaceType.TEAM:
        return { 
          icon: Layers, 
          gradient: 'from-emerald-500/20 via-emerald-500/10 to-transparent',
          border: 'border-emerald-500/30',
          iconColor: 'text-emerald-500',
          ring: 'ring-emerald-500/20'
        };
      default:
        return { 
          icon: Sparkles, 
          gradient: 'from-primary/20 via-primary/10 to-transparent',
          border: 'border-primary/30',
          iconColor: 'text-primary',
          ring: 'ring-primary/20'
        };
    }
  };

  const styles = getTypeStyles();
  const TypeIcon = styles.icon;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[400px] p-0 overflow-hidden border-border/50 bg-card gap-0">
        {/* Compact Header */}
        <div className={cn(
          "px-5 pt-5 pb-4 bg-gradient-to-b",
          styles.gradient
        )}>
          <DialogHeader className="space-y-2">
            <div className="flex items-center gap-3">
              <div className={cn(
                "w-10 h-10 rounded-xl flex items-center justify-center",
                "bg-background/80 border shadow-sm",
                styles.border
              )}>
                <TypeIcon className={cn("h-5 w-5", styles.iconColor)} />
              </div>
              <div className="flex-1 min-w-0">
                <DialogTitle className="text-base font-semibold text-foreground">
                  New {getWorkspaceTypeLabel(nextType || undefined)}
                </DialogTitle>
                <DialogDescription className="text-xs text-muted-foreground truncate">
                  {canCreate 
                    ? `Under "${parentWorkspace?.name || 'Workspace'}"`
                    : 'Maximum depth reached'}
                </DialogDescription>
              </div>
            </div>
          </DialogHeader>
        </div>

        {!canCreate ? (
          <div className="flex flex-col items-center gap-3 p-6">
            <div className="rounded-full bg-destructive/10 p-3">
              <AlertTriangle className="h-5 w-5 text-destructive" />
            </div>
            <p className="text-sm text-muted-foreground text-center">
              Teams are the final level (L{MAX_WORKSPACE_DEPTH}).
            </p>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="px-5 pb-5 space-y-4">
            {/* Input Section */}
            {allowCustomName ? (
              <div className="space-y-2">
                <Input
                  value={customName}
                  onChange={(e) => setCustomName(e.target.value)}
                  placeholder="Enter workspace name..."
                  maxLength={100}
                  autoFocus
                  className="h-10"
                />
              </div>
            ) : options && options.length > 0 ? (
              <div className="space-y-2 max-h-[240px] overflow-y-auto pr-1">
                {options.map((option) => {
                  const isSelected = selectedOption === option.id;
                  return (
                    <button
                      key={option.id}
                      type="button"
                      onClick={() => setSelectedOption(option.id)}
                      className={cn(
                        "w-full flex items-center gap-3 p-3 rounded-lg text-left transition-all",
                        "border hover:border-primary/50 hover:bg-accent/30",
                        isSelected 
                          ? "border-primary bg-primary/5" 
                          : "border-border/50 bg-background"
                      )}
                    >
                      <div className={cn(
                        "flex h-4 w-4 shrink-0 items-center justify-center rounded-full border-2 transition-colors",
                        isSelected 
                          ? "border-primary bg-primary" 
                          : "border-muted-foreground/30"
                      )}>
                        {isSelected && <Check className="h-2.5 w-2.5 text-primary-foreground" />}
                      </div>
                      <div className="flex-1 min-w-0">
                        <span className={cn(
                          "text-sm font-medium block",
                          isSelected ? "text-foreground" : "text-foreground/80"
                        )}>
                          {option.name}
                        </span>
                        {option.description && (
                          <p className="text-[11px] text-muted-foreground truncate">
                            {option.description}
                          </p>
                        )}
                      </div>
                    </button>
                  );
                })}
              </div>
            ) : (
              <p className="text-sm text-muted-foreground text-center py-4">
                No options available.
              </p>
            )}

            {/* Role badge - compact */}
            {responsibleRole && isValid && (
              <div className="flex items-center gap-2 px-3 py-2 rounded-lg bg-primary/5 border border-primary/20">
                <Sparkles className="h-3.5 w-3.5 text-primary shrink-0" />
                <span className="text-xs text-muted-foreground">
                  You'll be <span className="font-medium text-foreground">{getWorkspaceRoleLabel(responsibleRole)}</span>
                </span>
              </div>
            )}

            {/* Compact action buttons */}
            <div className="flex items-center gap-2 pt-1">
              <Button
                type="button"
                variant="ghost"
                size="sm"
                onClick={() => onOpenChange(false)}
                disabled={createSubWorkspaceMutation.isPending}
                className="flex-1"
              >
                Cancel
              </Button>
              <Button
                type="submit"
                size="sm"
                disabled={!isValid || createSubWorkspaceMutation.isPending}
                className="flex-1 gap-1.5"
              >
                {createSubWorkspaceMutation.isPending ? (
                  <div className="h-3.5 w-3.5 border-2 border-primary-foreground/30 border-t-primary-foreground rounded-full animate-spin" />
                ) : (
                  <>
                    Create
                    <ArrowRight className="h-3.5 w-3.5" />
                  </>
                )}
              </Button>
            </div>
          </form>
        )}
      </DialogContent>
    </Dialog>
  );
}
