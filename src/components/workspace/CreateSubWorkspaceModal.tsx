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
  getWorkspaceTypeLabel,
  getResponsibleRoleForWorkspace,
  getWorkspaceRoleLabel,
  WORKSPACE_DEPARTMENTS,
  DEPARTMENT_COMMITTEES,
} from '@/lib/workspaceHierarchy';
import { 
  Building2, 
  Users, 
  Layers, 
  Sparkles,
  ArrowRight,
  Check,
  ChevronLeft
} from 'lucide-react';
import { cn } from '@/lib/utils';

interface CreateSubWorkspaceModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  parentWorkspaceId: string;
  eventId: string;
}

type CreationType = 'department' | 'committee' | 'team' | null;

interface OptionItem {
  id: string;
  name: string;
  description?: string;
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

  const [selectedType, setSelectedType] = useState<CreationType>(null);
  const [selectedOption, setSelectedOption] = useState<string>('');
  const [customName, setCustomName] = useState('');

  // Fetch parent workspace
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

  const parentType = useMemo(() => {
    if (!parentWorkspace) return undefined;
    if (parentWorkspace.workspace_type) {
      return parentWorkspace.workspace_type as WorkspaceType;
    }
    return parentWorkspace.parent_workspace_id ? undefined : WorkspaceType.ROOT;
  }, [parentWorkspace]);

  // Get available creation types based on parent
  const availableTypes = useMemo((): CreationType[] => {
    if (!parentType) return ['department', 'committee'];
    
    switch (parentType) {
      case WorkspaceType.ROOT:
        return ['department', 'committee'];
      case WorkspaceType.DEPARTMENT:
        return ['committee', 'team'];
      case WorkspaceType.COMMITTEE:
        return ['team'];
      default:
        return [];
    }
  }, [parentType]);

  // Get options based on selected type
  const currentOptions = useMemo((): OptionItem[] => {
    if (selectedType === 'department') {
      return WORKSPACE_DEPARTMENTS.map(d => ({
        id: d.id,
        name: d.name,
        description: d.description,
      }));
    }
    if (selectedType === 'committee') {
      const deptId = parentWorkspace?.department_id;
      if (deptId && DEPARTMENT_COMMITTEES[deptId]) {
        return DEPARTMENT_COMMITTEES[deptId].map(c => ({ id: c.id, name: c.name }));
      }
      // Return all committees if no specific department
      return Object.values(DEPARTMENT_COMMITTEES).flat().map(c => ({ id: c.id, name: c.name }));
    }
    return [];
  }, [selectedType, parentWorkspace?.department_id]);

  const allowCustomName = selectedType === 'team';

  // Map to WorkspaceType
  const getWorkspaceType = (): WorkspaceType | null => {
    switch (selectedType) {
      case 'department': return WorkspaceType.DEPARTMENT;
      case 'committee': return WorkspaceType.COMMITTEE;
      case 'team': return WorkspaceType.TEAM;
      default: return null;
    }
  };

  const workspaceType = getWorkspaceType();

  // Get department_id for the new workspace
  const getDepartmentId = (): string | null => {
    if (selectedType === 'department') {
      return selectedOption || null;
    }
    return parentWorkspace?.department_id || null;
  };

  // Get responsible role
  const responsibleRole = useMemo((): WorkspaceRole | null => {
    if (!workspaceType) return null;
    
    const departmentId = selectedType === 'department' 
      ? selectedOption 
      : parentWorkspace?.department_id || undefined;
    
    const committeeId = selectedType === 'committee' 
      ? selectedOption 
      : undefined;
    
    return getResponsibleRoleForWorkspace(workspaceType, departmentId, committeeId);
  }, [workspaceType, selectedType, selectedOption, parentWorkspace?.department_id]);

  const getFinalName = (): string => {
    if (allowCustomName) return customName;
    const option = currentOptions.find((o: OptionItem) => o.id === selectedOption);
    return option?.name || '';
  };

  const createSubWorkspaceMutation = useMutation({
    mutationFn: async () => {
      if (!user) throw new Error('Must be authenticated');
      if (!workspaceType) throw new Error('Select a workspace type');

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
          workspace_type: workspaceType,
          department_id: getDepartmentId(),
        })
        .select('id, name')
        .single();

      if (wsError) throw wsError;

      if (responsibleRole) {
        await supabase
          .from('workspace_team_members')
          .insert({
            workspace_id: workspace.id,
            user_id: user.id,
            role: responsibleRole,
            status: 'active',
          });
      }

      return { ...workspace, assignedRole: responsibleRole };
    },
    onSuccess: (data) => {
      toast({
        title: `${getWorkspaceTypeLabel(workspaceType || undefined)} created`,
        description: `"${data.name}" has been created successfully.`,
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
    setSelectedType(null);
    setSelectedOption('');
    setCustomName('');
  };

  useEffect(() => {
    if (open) resetForm();
  }, [open, parentWorkspaceId]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    createSubWorkspaceMutation.mutate();
  };

  const isValid = selectedType && (allowCustomName ? customName.trim().length > 0 : selectedOption.length > 0);

  const typeConfig = {
    department: { 
      icon: Building2, 
      label: 'Department',
      sublabel: 'L2',
      color: 'text-blue-500',
      bg: 'bg-blue-500/10',
      border: 'border-blue-500/30',
      gradient: 'from-blue-500/15'
    },
    committee: { 
      icon: Users, 
      label: 'Committee',
      sublabel: 'L3',
      color: 'text-amber-500',
      bg: 'bg-amber-500/10',
      border: 'border-amber-500/30',
      gradient: 'from-amber-500/15'
    },
    team: { 
      icon: Layers, 
      label: 'Team',
      sublabel: 'L4',
      color: 'text-emerald-500',
      bg: 'bg-emerald-500/10',
      border: 'border-emerald-500/30',
      gradient: 'from-emerald-500/15'
    },
  };

  const currentConfig = selectedType ? typeConfig[selectedType] : null;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[380px] p-0 overflow-hidden border-border/50 bg-card gap-0">
        {/* Header */}
        <div className={cn(
          "px-4 pt-4 pb-3 bg-gradient-to-b to-transparent",
          currentConfig?.gradient || "from-primary/10"
        )}>
          <DialogHeader className="space-y-1">
            <div className="flex items-center gap-2">
              {selectedType && (
                <button
                  type="button"
                  onClick={() => { setSelectedType(null); setSelectedOption(''); }}
                  className="p-1 -ml-1 rounded-md hover:bg-accent transition-colors"
                >
                  <ChevronLeft className="h-4 w-4 text-muted-foreground" />
                </button>
              )}
              <div className={cn(
                "w-8 h-8 rounded-lg flex items-center justify-center",
                currentConfig?.bg || "bg-primary/10"
              )}>
                {currentConfig ? (
                  <currentConfig.icon className={cn("h-4 w-4", currentConfig.color)} />
                ) : (
                  <Sparkles className="h-4 w-4 text-primary" />
                )}
              </div>
              <div className="flex-1">
                <DialogTitle className="text-sm font-semibold text-foreground">
                  {selectedType ? `New ${typeConfig[selectedType].label}` : 'Create Sub-Workspace'}
                </DialogTitle>
                <DialogDescription className="text-[11px] text-muted-foreground">
                  Under "{parentWorkspace?.name || 'Workspace'}"
                </DialogDescription>
              </div>
            </div>
          </DialogHeader>
        </div>

        <form onSubmit={handleSubmit} className="px-4 pb-4 space-y-3">
          {/* Step 1: Select Type */}
          {!selectedType ? (
            <div className="grid grid-cols-2 gap-2">
              {availableTypes.map((type) => {
                if (!type) return null;
                const config = typeConfig[type];
                return (
                  <button
                    key={type}
                    type="button"
                    onClick={() => setSelectedType(type)}
                    className={cn(
                      "flex flex-col items-center gap-2 p-4 rounded-xl transition-all",
                      "border-2 border-border/50 hover:border-primary/50 hover:bg-accent/30",
                      "bg-background"
                    )}
                  >
                    <div className={cn("w-10 h-10 rounded-xl flex items-center justify-center", config.bg)}>
                      <config.icon className={cn("h-5 w-5", config.color)} />
                    </div>
                    <div className="text-center">
                      <span className="text-sm font-medium text-foreground block">{config.label}</span>
                      <span className="text-[10px] text-muted-foreground">{config.sublabel}</span>
                    </div>
                  </button>
                );
              })}
            </div>
          ) : (
            <>
              {/* Step 2: Select Option or Enter Name */}
              {allowCustomName ? (
                <Input
                  value={customName}
                  onChange={(e) => setCustomName(e.target.value)}
                  placeholder="Enter team name..."
                  maxLength={100}
                  autoFocus
                  className="h-9 text-sm"
                />
              ) : currentOptions.length > 0 ? (
                <div className="space-y-1.5 max-h-[200px] overflow-y-auto">
                  {currentOptions.map((option) => {
                    const isSelected = selectedOption === option.id;
                    return (
                      <button
                        key={option.id}
                        type="button"
                        onClick={() => setSelectedOption(option.id)}
                        className={cn(
                          "w-full flex items-center gap-2.5 p-2.5 rounded-lg text-left transition-all",
                          "border hover:border-primary/50",
                          isSelected 
                            ? "border-primary bg-primary/5" 
                            : "border-border/40 bg-background hover:bg-accent/20"
                        )}
                      >
                        <div className={cn(
                          "flex h-3.5 w-3.5 shrink-0 items-center justify-center rounded-full border-[1.5px] transition-colors",
                          isSelected ? "border-primary bg-primary" : "border-muted-foreground/40"
                        )}>
                          {isSelected && <Check className="h-2 w-2 text-primary-foreground" />}
                        </div>
                        <div className="flex-1 min-w-0">
                          <span className="text-xs font-medium text-foreground block truncate">
                            {option.name}
                          </span>
                          {option.description && (
                            <p className="text-[10px] text-muted-foreground truncate">
                              {option.description}
                            </p>
                          )}
                        </div>
                      </button>
                    );
                  })}
                </div>
              ) : (
                <p className="text-xs text-muted-foreground text-center py-3">
                  No options available.
                </p>
              )}

              {/* Role preview */}
              {responsibleRole && isValid && (
                <div className="flex items-center gap-2 px-2.5 py-1.5 rounded-md bg-primary/5 border border-primary/20">
                  <Sparkles className="h-3 w-3 text-primary shrink-0" />
                  <span className="text-[11px] text-muted-foreground">
                    Role: <span className="font-medium text-foreground">{getWorkspaceRoleLabel(responsibleRole)}</span>
                  </span>
                </div>
              )}

              {/* Actions */}
              <div className="flex items-center gap-2 pt-1">
                <Button
                  type="button"
                  variant="ghost"
                  size="sm"
                  onClick={() => onOpenChange(false)}
                  disabled={createSubWorkspaceMutation.isPending}
                  className="flex-1 h-8 text-xs"
                >
                  Cancel
                </Button>
                <Button
                  type="submit"
                  size="sm"
                  disabled={!isValid || createSubWorkspaceMutation.isPending}
                  className="flex-1 h-8 text-xs gap-1"
                >
                  {createSubWorkspaceMutation.isPending ? (
                    <div className="h-3 w-3 border-2 border-primary-foreground/30 border-t-primary-foreground rounded-full animate-spin" />
                  ) : (
                    <>Create <ArrowRight className="h-3 w-3" /></>
                  )}
                </Button>
              </div>
            </>
          )}
        </form>
      </DialogContent>
    </Dialog>
  );
}
