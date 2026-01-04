import React, { useCallback, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { 
  ArrowLeft, 
  Briefcase, 
  Check, 
  Clock, 
  MoreVertical,
  Plus,
  Users,
  ChevronRight,
  Trash2
} from 'lucide-react';
import { supabase } from '@/integrations/supabase/client';
import { Button } from '@/components/ui/button';
import { format } from 'date-fns';
import { PullToRefresh } from '../shared/PullToRefresh';
import { TaskListSkeleton } from '../shared/MobileSkeleton';
import { cn } from '@/lib/utils';
import { toast } from 'sonner';

interface MobileWorkspaceDetailViewProps {
  workspaceId: string;
  eventId: string;
  organization: {
    id: string;
    slug: string;
  };
  user: {
    id: string;
  };
}

interface Task {
  id: string;
  title: string;
  description: string | null;
  status: string;
  priority: string;
  due_date: string | null;
  assigned_to: string | null;
}

interface Workspace {
  id: string;
  name: string;
  status: string;
  created_at: string;
}

export const MobileWorkspaceDetailView: React.FC<MobileWorkspaceDetailViewProps> = ({
  workspaceId,
}) => {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [swipingTaskId, setSwipingTaskId] = useState<string | null>(null);
  const [swipeOffset, setSwipeOffset] = useState(0);

  // Fetch workspace details
  const { data: workspace, isLoading: workspaceLoading } = useQuery<Workspace>({
    queryKey: ['mobile-workspace', workspaceId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('workspaces')
        .select('id, name, status, created_at')
        .eq('id', workspaceId)
        .single();
      if (error) throw error;
      return data;
    },
  });

  // Fetch tasks
  const { data: tasks, isLoading: tasksLoading, refetch: refetchTasks } = useQuery<Task[]>({
    queryKey: ['mobile-workspace-tasks', workspaceId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('workspace_tasks')
        .select('id, title, description, status, priority, due_date, assigned_to')
        .eq('workspace_id', workspaceId)
        .order('created_at', { ascending: false });
      if (error) throw error;
      return data || [];
    },
  });

  // Fetch team members count
  const { data: teamCount } = useQuery({
    queryKey: ['mobile-workspace-team-count', workspaceId],
    queryFn: async () => {
      const { count, error } = await supabase
        .from('workspace_team_members')
        .select('*', { count: 'exact', head: true })
        .eq('workspace_id', workspaceId);
      if (error) throw error;
      return count || 0;
    },
  });

  // Update task status mutation
  const updateTaskMutation = useMutation({
    mutationFn: async ({ taskId, status }: { taskId: string; status: string }) => {
      const { error } = await supabase
        .from('workspace_tasks')
        .update({ status })
        .eq('id', taskId);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['mobile-workspace-tasks', workspaceId] });
      toast.success('Task updated');
    },
    onError: () => {
      toast.error('Failed to update task');
    },
  });

  // Delete task mutation
  const deleteTaskMutation = useMutation({
    mutationFn: async (taskId: string) => {
      const { error } = await supabase
        .from('workspace_tasks')
        .delete()
        .eq('id', taskId);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['mobile-workspace-tasks', workspaceId] });
      toast.success('Task deleted');
    },
    onError: () => {
      toast.error('Failed to delete task');
    },
  });

  const handleRefresh = useCallback(async () => {
    await refetchTasks();
  }, [refetchTasks]);

  const handleBack = () => {
    navigate(-1);
  };

  // Swipe gesture handlers
  const handleTouchStart = (taskId: string) => {
    setSwipingTaskId(taskId);
    setSwipeOffset(0);
  };

  const handleTouchMove = (e: React.TouchEvent) => {
    if (!swipingTaskId) return;
    const touch = e.touches[0];
    const startX = e.currentTarget.getBoundingClientRect().left;
    const currentX = touch.clientX - startX;
    // Allow swipe left (negative) and right (positive) with resistance
    setSwipeOffset(Math.max(-100, Math.min(100, currentX - 150)));
  };

  const handleTouchEnd = (task: Task) => {
    if (!swipingTaskId) return;
    
    const SWIPE_THRESHOLD = 60;
    
    if (swipeOffset < -SWIPE_THRESHOLD) {
      // Swipe left - delete task
      deleteTaskMutation.mutate(task.id);
    } else if (swipeOffset > SWIPE_THRESHOLD) {
      // Swipe right - mark as complete or in-progress
      const newStatus = task.status === 'completed' ? 'todo' : 'completed';
      updateTaskMutation.mutate({ taskId: task.id, status: newStatus });
    }
    
    setSwipingTaskId(null);
    setSwipeOffset(0);
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'high':
        return 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400';
      case 'medium':
        return 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400';
      case 'low':
        return 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400';
      default:
        return 'bg-muted text-muted-foreground';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'completed':
        return <Check className="h-4 w-4 text-green-600" />;
      case 'in_progress':
        return <Clock className="h-4 w-4 text-blue-600" />;
      default:
        return <div className="h-4 w-4 rounded-full border-2 border-muted-foreground" />;
    }
  };

  const pendingTasks = tasks?.filter(t => t.status !== 'completed') || [];
  const completedTasks = tasks?.filter(t => t.status === 'completed') || [];

  return (
    <div className="min-h-screen bg-background flex flex-col">
      {/* Back Navigation Header */}
      <header className="fixed top-0 left-0 right-0 z-50 h-16 bg-background/95 backdrop-blur-md border-b border-border">
        <div className="flex items-center h-full px-4 gap-3">
          <button
            onClick={handleBack}
            className="p-2 -ml-2 rounded-lg hover:bg-muted transition-colors"
          >
            <ArrowLeft className="h-5 w-5 text-foreground" />
          </button>
          <div className="flex-1 min-w-0">
            {workspaceLoading ? (
              <div className="h-5 w-32 bg-muted rounded animate-pulse" />
            ) : (
              <h1 className="font-semibold text-foreground truncate">
                {workspace?.name}
              </h1>
            )}
          </div>
          <Button variant="ghost" size="icon" className="shrink-0">
            <MoreVertical className="h-5 w-5" />
          </Button>
        </div>
      </header>

      {/* Content */}
      <PullToRefresh onRefresh={handleRefresh} className="flex-1 pt-16">
        <div className="px-4 py-4 space-y-6">
          {/* Stats Cards */}
          <div className="grid grid-cols-2 gap-3">
            <div className="bg-card border border-border rounded-xl p-4">
              <div className="flex items-center gap-2 mb-2">
                <div className="p-1.5 rounded-lg bg-primary/10">
                  <Briefcase className="h-4 w-4 text-primary" />
                </div>
                <span className="text-xs text-muted-foreground">Tasks</span>
              </div>
              <p className="text-2xl font-bold text-foreground">{tasks?.length || 0}</p>
            </div>
            <div className="bg-card border border-border rounded-xl p-4">
              <div className="flex items-center gap-2 mb-2">
                <div className="p-1.5 rounded-lg bg-purple-500/10">
                  <Users className="h-4 w-4 text-purple-600" />
                </div>
                <span className="text-xs text-muted-foreground">Members</span>
              </div>
              <p className="text-2xl font-bold text-foreground">{teamCount || 0}</p>
            </div>
          </div>

          {/* Swipe Hint */}
          <div className="flex items-center justify-center gap-4 text-xs text-muted-foreground py-2">
            <span className="flex items-center gap-1">
              <ChevronRight className="h-3 w-3" /> Swipe right to complete
            </span>
            <span className="flex items-center gap-1">
              Swipe left to delete <Trash2 className="h-3 w-3" />
            </span>
          </div>

          {/* Tasks Section */}
          <section>
            <div className="flex items-center justify-between mb-3">
              <h2 className="text-base font-semibold text-foreground">
                Tasks ({pendingTasks.length})
              </h2>
              <Button size="sm" variant="ghost" className="gap-1 text-primary">
                <Plus className="h-4 w-4" />
                Add
              </Button>
            </div>

            {tasksLoading ? (
              <TaskListSkeleton count={4} />
            ) : pendingTasks.length > 0 ? (
              <div className="space-y-2">
                {pendingTasks.map((task) => (
                  <div
                    key={task.id}
                    className="relative overflow-hidden rounded-xl"
                  >
                    {/* Swipe actions background */}
                    <div className="absolute inset-y-0 left-0 w-20 bg-green-500 flex items-center justify-center">
                      <Check className="h-6 w-6 text-white" />
                    </div>
                    <div className="absolute inset-y-0 right-0 w-20 bg-red-500 flex items-center justify-center">
                      <Trash2 className="h-6 w-6 text-white" />
                    </div>
                    
                    {/* Task card */}
                    <div
                      className={cn(
                        "relative bg-card border border-border p-4 transition-transform touch-pan-y",
                        swipingTaskId === task.id ? "" : "transition-transform duration-200"
                      )}
                      style={{
                        transform: swipingTaskId === task.id 
                          ? `translateX(${swipeOffset}px)` 
                          : 'translateX(0)'
                      }}
                      onTouchStart={() => handleTouchStart(task.id)}
                      onTouchMove={handleTouchMove}
                      onTouchEnd={() => handleTouchEnd(task)}
                    >
                      <div className="flex items-start gap-3">
                        <button
                          onClick={() => updateTaskMutation.mutate({ 
                            taskId: task.id, 
                            status: task.status === 'completed' ? 'todo' : 'completed' 
                          })}
                          className="mt-0.5 shrink-0"
                        >
                          {getStatusIcon(task.status)}
                        </button>
                        <div className="flex-1 min-w-0">
                          <p className={cn(
                            "font-medium text-foreground",
                            task.status === 'completed' && "line-through text-muted-foreground"
                          )}>
                            {task.title}
                          </p>
                          {task.description && (
                            <p className="text-sm text-muted-foreground mt-0.5 line-clamp-1">
                              {task.description}
                            </p>
                          )}
                          <div className="flex items-center gap-2 mt-2">
                            <span className={cn(
                              "text-xs px-2 py-0.5 rounded-full",
                              getPriorityColor(task.priority)
                            )}>
                              {task.priority}
                            </span>
                            {task.due_date && (
                              <span className="text-xs text-muted-foreground flex items-center gap-1">
                                <Clock className="h-3 w-3" />
                                {format(new Date(task.due_date), 'MMM d')}
                              </span>
                            )}
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="bg-card border border-border rounded-xl p-6 text-center">
                <p className="text-sm text-muted-foreground">No pending tasks</p>
              </div>
            )}
          </section>

          {/* Completed Tasks */}
          {completedTasks.length > 0 && (
            <section>
              <div className="flex items-center justify-between mb-3">
                <h2 className="text-base font-semibold text-muted-foreground">
                  Completed ({completedTasks.length})
                </h2>
              </div>
              <div className="space-y-2">
                {completedTasks.slice(0, 3).map((task) => (
                  <div
                    key={task.id}
                    className="bg-card/50 border border-border rounded-xl p-4"
                  >
                    <div className="flex items-center gap-3">
                      <Check className="h-4 w-4 text-green-600 shrink-0" />
                      <p className="text-sm text-muted-foreground line-through truncate">
                        {task.title}
                      </p>
                    </div>
                  </div>
                ))}
                {completedTasks.length > 3 && (
                  <button className="w-full text-sm text-primary py-2">
                    View all {completedTasks.length} completed tasks
                  </button>
                )}
              </div>
            </section>
          )}
        </div>
      </PullToRefresh>
    </div>
  );
};
