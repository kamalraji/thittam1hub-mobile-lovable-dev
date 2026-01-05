import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { 
  Send, 
  Calendar, 
  ClipboardList, 
  Download, 
  MessageSquare, 
  UserPlus,
  Zap,
} from 'lucide-react';
import { toast } from 'sonner';

interface VolunteerQuickActionsProps {
  workspaceId: string;
}

export function VolunteerQuickActions({ workspaceId: _workspaceId }: VolunteerQuickActionsProps) {
  const handleAction = (action: string) => {
    toast.info(`${action} action triggered`);
  };

  const actions = [
    {
      id: 'send_brief',
      label: 'Send Brief',
      description: 'Send briefing to all volunteers',
      icon: Send,
      color: 'text-blue-500',
    },
    {
      id: 'assign_shifts',
      label: 'Assign Shifts',
      description: 'Bulk assign volunteer shifts',
      icon: Calendar,
      color: 'text-emerald-500',
    },
    {
      id: 'export_roster',
      label: 'Export Roster',
      description: 'Download volunteer list',
      icon: Download,
      color: 'text-purple-500',
    },
    {
      id: 'send_reminder',
      label: 'Send Reminder',
      description: 'Remind upcoming shifts',
      icon: MessageSquare,
      color: 'text-amber-500',
    },
    {
      id: 'add_volunteers',
      label: 'Add Volunteers',
      description: 'Invite new volunteers',
      icon: UserPlus,
      color: 'text-pink-500',
    },
    {
      id: 'check_in_mode',
      label: 'Check-In Mode',
      description: 'Start volunteer check-in',
      icon: ClipboardList,
      color: 'text-teal-500',
    },
  ];

  return (
    <Card>
      <CardHeader className="pb-4">
        <CardTitle className="flex items-center gap-2 text-base font-semibold">
          <Zap className="h-4 w-4 text-pink-500" />
          Quick Actions
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="grid grid-cols-2 gap-2">
          {actions.map((action) => (
            <Button
              key={action.id}
              variant="outline"
              className="h-auto flex-col items-start gap-1 p-3 text-left hover:bg-muted/50"
              onClick={() => handleAction(action.label)}
            >
              <div className="flex items-center gap-2">
                <action.icon className={`h-4 w-4 ${action.color}`} />
                <span className="font-medium text-sm">{action.label}</span>
              </div>
              <span className="text-xs text-muted-foreground">{action.description}</span>
            </Button>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}
