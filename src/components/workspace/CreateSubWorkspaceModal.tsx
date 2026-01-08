import { useState, useEffect } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/hooks/useAuth';
import { WorkspaceType } from '@/types';
import {
  getResponsibleRoleForWorkspace,
  WORKSPACE_DEPARTMENTS,
  DEPARTMENT_COMMITTEES,
} from '@/lib/workspaceHierarchy';
import { 
  Building2, 
  Users, 
  Sparkles,
  ArrowRight,
  Check,
  ChevronRight,
  ChevronDown,
  CheckCircle,
} from 'lucide-react';
import { cn } from '@/lib/utils';

interface CreateSubWorkspaceModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  parentWorkspaceId: string;
  eventId: string;
}

interface SelectedItem {
  id: string;
  name: string;
  type: 'department' | 'committee';
  departmentId?: string;
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

  const [selectedItems, setSelectedItems] = useState<SelectedItem[]>([]);
  const [expandedDepts, setExpandedDepts] = useState<Set<string>>(new Set());

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

  // Fetch existing sub-workspaces to prevent duplicates
  const { data: existingWorkspaces } = useQuery({
    queryKey: ['existing-sub-workspaces', eventId, parentWorkspaceId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('workspaces')
        .select('id, name, workspace_type, department_id')
        .eq('event_id', eventId)
        .eq('parent_workspace_id', parentWorkspaceId);

      if (error) throw error;
      return data || [];
    },
    enabled: open && !!parentWorkspaceId && !!eventId,
  });

  // Build sets of already-created items for quick lookup
  const existingDepartmentIds = new Set(
    existingWorkspaces
      ?.filter(w => w.workspace_type === WorkspaceType.DEPARTMENT && w.department_id)
      .map(w => w.department_id) || []
  );

  const existingCommitteeNames = new Set(
    existingWorkspaces
      ?.filter(w => w.workspace_type === WorkspaceType.COMMITTEE)
      .map(w => w.name.toLowerCase()) || []
  );

  const toggleDeptExpanded = (deptId: string) => {
    setExpandedDepts(prev => {
      const next = new Set(prev);
      if (next.has(deptId)) {
        next.delete(deptId);
      } else {
        next.add(deptId);
      }
      return next;
    });
  };

  const toggleSelection = (item: SelectedItem) => {
    setSelectedItems(prev => {
      const exists = prev.find(i => i.id === item.id && i.type === item.type);
      if (exists) {
        return prev.filter(i => !(i.id === item.id && i.type === item.type));
      }
      return [...prev, item];
    });
  };

  const isSelected = (id: string, type: 'department' | 'committee') => {
    return selectedItems.some(i => i.id === id && i.type === type);
  };

  // Check if item already exists
  const isDeptCreated = (deptId: string) => existingDepartmentIds.has(deptId);
  const isCommCreated = (commName: string) => existingCommitteeNames.has(commName.toLowerCase());

  const selectAllCommitteesInDept = (deptId: string) => {
    const committees = DEPARTMENT_COMMITTEES[deptId] || [];
    // Only consider non-created committees
    const availableComms = committees.filter(c => !isCommCreated(c.name));
    const allSelected = availableComms.every(c => isSelected(c.id, 'committee'));
    
    if (allSelected) {
      // Deselect all
      setSelectedItems(prev => prev.filter(i => !(i.type === 'committee' && i.departmentId === deptId)));
    } else {
      // Select all missing (that aren't already created)
      const newItems = availableComms
        .filter(c => !isSelected(c.id, 'committee'))
        .map(c => ({ id: c.id, name: c.name, type: 'committee' as const, departmentId: deptId }));
      setSelectedItems(prev => [...prev, ...newItems]);
    }
  };

  const createSubWorkspacesMutation = useMutation({
    mutationFn: async () => {
      if (!user) throw new Error('Must be authenticated');
      if (selectedItems.length === 0) throw new Error('Select at least one item');

      const createdWorkspaces: { id: string; name: string }[] = [];

      for (const item of selectedItems) {
        const workspaceType = item.type === 'department' 
          ? WorkspaceType.DEPARTMENT 
          : WorkspaceType.COMMITTEE;

        const departmentId = item.type === 'department' 
          ? item.id 
          : item.departmentId || parentWorkspace?.department_id || null;

        const { data: workspace, error: wsError } = await supabase
          .from('workspaces')
          .insert({
            name: item.name,
            event_id: eventId,
            parent_workspace_id: parentWorkspaceId,
            organizer_id: user.id,
            status: 'ACTIVE',
            workspace_type: workspaceType,
            department_id: departmentId,
          })
          .select('id, name')
          .single();

        if (wsError) throw wsError;

        const responsibleRole = getResponsibleRoleForWorkspace(
          workspaceType,
          departmentId || undefined,
          item.type === 'committee' ? item.id : undefined
        );

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

        createdWorkspaces.push(workspace);
      }

      return createdWorkspaces;
    },
    onSuccess: (data) => {
      const count = data.length;
      toast({
        title: `${count} workspace${count > 1 ? 's' : ''} created`,
        description: count === 1 
          ? `"${data[0].name}" has been created.`
          : `Created: ${data.map(w => w.name).join(', ')}`,
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
    setSelectedItems([]);
    setExpandedDepts(new Set());
  };

  useEffect(() => {
    if (open) resetForm();
  }, [open, parentWorkspaceId]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    createSubWorkspacesMutation.mutate();
  };

  const isValid = selectedItems.length > 0;

  const selectedDepts = selectedItems.filter(i => i.type === 'department');
  const selectedComms = selectedItems.filter(i => i.type === 'committee');

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[440px] p-0 overflow-hidden border-border/50 bg-card gap-0">
        {/* Header */}
        <div className="px-4 pt-4 pb-3 bg-gradient-to-b from-primary/10 to-transparent">
          <DialogHeader className="space-y-1">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-lg flex items-center justify-center bg-primary/10">
                <Sparkles className="h-4 w-4 text-primary" />
              </div>
              <div className="flex-1">
                <DialogTitle className="text-sm font-semibold text-foreground">
                  Create Sub-Workspaces
                </DialogTitle>
                <DialogDescription className="text-[11px] text-muted-foreground">
                  Select departments & committees • Multi-select enabled
                </DialogDescription>
              </div>
            </div>
          </DialogHeader>
        </div>

        <form onSubmit={handleSubmit} className="space-y-0">
          {/* Tree View */}
          <div className="px-3 py-3">
            <div className="space-y-1 max-h-[320px] overflow-y-auto pr-1">
              {WORKSPACE_DEPARTMENTS.map((dept) => {
                const committees = DEPARTMENT_COMMITTEES[dept.id] || [];
                const isExpanded = expandedDepts.has(dept.id);
                const isDeptSelected = isSelected(dept.id, 'department');
                const deptAlreadyCreated = isDeptCreated(dept.id);
                const selectedCommCount = committees.filter(c => isSelected(c.id, 'committee')).length;
                const createdCommCount = committees.filter(c => isCommCreated(c.name)).length;

                return (
                  <div key={dept.id} className="space-y-0.5">
                    {/* Department Row */}
                    <div className="flex items-center gap-1">
                      {/* Expand/Collapse */}
                      <button
                        type="button"
                        onClick={() => toggleDeptExpanded(dept.id)}
                        className="p-1 rounded hover:bg-accent/50 text-muted-foreground"
                      >
                        {isExpanded ? (
                          <ChevronDown className="h-3.5 w-3.5" />
                        ) : (
                          <ChevronRight className="h-3.5 w-3.5" />
                        )}
                      </button>

                      {/* Checkbox + Label */}
                      <button
                        type="button"
                        onClick={() => !deptAlreadyCreated && toggleSelection({ id: dept.id, name: dept.name, type: 'department' })}
                        disabled={deptAlreadyCreated}
                        className={cn(
                          "flex-1 flex items-center gap-2 p-2 rounded-md text-left transition-all",
                          deptAlreadyCreated 
                            ? "opacity-50 cursor-not-allowed" 
                            : "hover:bg-accent/30",
                          isDeptSelected && !deptAlreadyCreated && "bg-blue-500/10"
                        )}
                      >
                        {deptAlreadyCreated ? (
                          <CheckCircle className="h-4 w-4 text-green-500 shrink-0" />
                        ) : (
                          <div className={cn(
                            "flex h-4 w-4 shrink-0 items-center justify-center rounded transition-colors",
                            "border-[1.5px]",
                            isDeptSelected 
                              ? "border-blue-500 bg-blue-500" 
                              : "border-muted-foreground/40"
                          )}>
                            {isDeptSelected && <Check className="h-2.5 w-2.5 text-white" />}
                          </div>
                        )}
                        <Building2 className={cn("h-3.5 w-3.5", deptAlreadyCreated ? "text-green-500" : "text-blue-500")} />
                        <span className={cn("text-xs font-medium flex-1", deptAlreadyCreated ? "text-muted-foreground" : "text-foreground")}>
                          {dept.name}
                        </span>
                        {deptAlreadyCreated ? (
                          <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-green-500/20 text-green-600">
                            Created
                          </span>
                        ) : selectedCommCount > 0 ? (
                          <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-amber-500/20 text-amber-600">
                            {selectedCommCount} comm
                          </span>
                        ) : createdCommCount > 0 ? (
                          <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-green-500/10 text-green-600">
                            {createdCommCount}/{committees.length}
                          </span>
                        ) : null}
                      </button>
                    </div>

                    {/* Committees (Nested) */}
                    {isExpanded && committees.length > 0 && (
                      <div className="ml-6 pl-2 border-l border-border/50 space-y-0.5">
                        {/* Select All - only show if there are available committees */}
                        {committees.some(c => !isCommCreated(c.name)) && (
                          <button
                            type="button"
                            onClick={() => selectAllCommitteesInDept(dept.id)}
                            className="w-full text-left px-2 py-1 text-[10px] text-muted-foreground hover:text-foreground hover:bg-accent/30 rounded transition-colors"
                          >
                            {committees.filter(c => !isCommCreated(c.name)).every(c => isSelected(c.id, 'committee')) 
                              ? 'Deselect all' 
                              : 'Select available'}
                          </button>
                        )}

                        {committees.map((comm) => {
                          const isCommSelected = isSelected(comm.id, 'committee');
                          const commAlreadyCreated = isCommCreated(comm.name);
                          
                          return (
                            <button
                              key={comm.id}
                              type="button"
                              onClick={() => !commAlreadyCreated && toggleSelection({ 
                                id: comm.id, 
                                name: comm.name, 
                                type: 'committee',
                                departmentId: dept.id 
                              })}
                              disabled={commAlreadyCreated}
                              className={cn(
                                "w-full flex items-center gap-2 p-2 rounded-md text-left transition-all",
                                commAlreadyCreated 
                                  ? "opacity-50 cursor-not-allowed"
                                  : "hover:bg-accent/30",
                                isCommSelected && !commAlreadyCreated && "bg-amber-500/10"
                              )}
                            >
                              {commAlreadyCreated ? (
                                <CheckCircle className="h-3.5 w-3.5 text-green-500 shrink-0" />
                              ) : (
                                <div className={cn(
                                  "flex h-3.5 w-3.5 shrink-0 items-center justify-center rounded transition-colors",
                                  "border-[1.5px]",
                                  isCommSelected 
                                    ? "border-amber-500 bg-amber-500" 
                                    : "border-muted-foreground/40"
                                )}>
                                  {isCommSelected && <Check className="h-2 w-2 text-white" />}
                                </div>
                              )}
                              <Users className={cn("h-3 w-3", commAlreadyCreated ? "text-green-500" : "text-amber-500")} />
                              <span className={cn("text-[11px] flex-1", commAlreadyCreated ? "text-muted-foreground" : "text-foreground")}>
                                {comm.name}
                              </span>
                              {commAlreadyCreated && (
                                <span className="text-[9px] px-1 py-0.5 rounded bg-green-500/20 text-green-600">
                                  Created
                                </span>
                              )}
                            </button>
                          );
                        })}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </div>

          {/* Selection Summary */}
          {selectedItems.length > 0 && (
            <div className="px-4 pb-2">
              <div className="flex flex-wrap gap-1">
                {selectedItems.slice(0, 8).map((item) => (
                  <span
                    key={`${item.type}-${item.id}`}
                    className={cn(
                      "inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-medium",
                      item.type === 'department'
                        ? "bg-blue-500/10 text-blue-600"
                        : "bg-amber-500/10 text-amber-600"
                    )}
                  >
                    {item.type === 'department' ? <Building2 className="h-2.5 w-2.5" /> : <Users className="h-2.5 w-2.5" />}
                    {item.name}
                  </span>
                ))}
                {selectedItems.length > 8 && (
                  <span className="text-[10px] text-muted-foreground px-2 py-0.5">
                    +{selectedItems.length - 8} more
                  </span>
                )}
              </div>
            </div>
          )}

          {/* Actions */}
          <div className="flex items-center gap-2 px-4 pb-4 pt-2 border-t border-border/30">
            <div className="flex-1 text-[10px] text-muted-foreground">
              {selectedDepts.length > 0 && <span className="text-blue-500">{selectedDepts.length} dept</span>}
              {selectedDepts.length > 0 && selectedComms.length > 0 && <span> • </span>}
              {selectedComms.length > 0 && <span className="text-amber-500">{selectedComms.length} comm</span>}
            </div>
            <Button
              type="button"
              variant="ghost"
              size="sm"
              onClick={() => onOpenChange(false)}
              disabled={createSubWorkspacesMutation.isPending}
              className="h-8 text-xs px-3"
            >
              Cancel
            </Button>
            <Button
              type="submit"
              size="sm"
              disabled={!isValid || createSubWorkspacesMutation.isPending}
              className="h-8 text-xs gap-1 px-4"
            >
              {createSubWorkspacesMutation.isPending ? (
                <div className="h-3 w-3 border-2 border-primary-foreground/30 border-t-primary-foreground rounded-full animate-spin" />
              ) : (
                <>
                  Create ({selectedItems.length})
                  <ArrowRight className="h-3 w-3" />
                </>
              )}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
