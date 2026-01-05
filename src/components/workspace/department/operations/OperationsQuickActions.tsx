import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { 
  CalendarDays, 
  Truck, 
  UtensilsCrossed, 
  Building2,
  ClipboardList,
  AlertCircle,
  Users,
  FileBarChart
} from 'lucide-react';
import { toast } from 'sonner';

export function OperationsQuickActions() {
  const actions = [
    {
      label: 'Event Briefing',
      description: 'Review day-of schedule',
      icon: CalendarDays,
      color: 'text-blue-500',
      bgColor: 'bg-blue-500/10',
      hoverColor: 'hover:bg-blue-500/20',
    },
    {
      label: 'Logistics Status',
      description: 'Check shipment tracking',
      icon: Truck,
      color: 'text-green-500',
      bgColor: 'bg-green-500/10',
      hoverColor: 'hover:bg-green-500/20',
    },
    {
      label: 'Catering Update',
      description: 'View meal schedules',
      icon: UtensilsCrossed,
      color: 'text-amber-500',
      bgColor: 'bg-amber-500/10',
      hoverColor: 'hover:bg-amber-500/20',
    },
    {
      label: 'Facility Check',
      description: 'Safety & setup status',
      icon: Building2,
      color: 'text-purple-500',
      bgColor: 'bg-purple-500/10',
      hoverColor: 'hover:bg-purple-500/20',
    },
    {
      label: 'Master Checklist',
      description: 'All operations tasks',
      icon: ClipboardList,
      color: 'text-indigo-500',
      bgColor: 'bg-indigo-500/10',
      hoverColor: 'hover:bg-indigo-500/20',
    },
    {
      label: 'Incident Report',
      description: 'Log issues & alerts',
      icon: AlertCircle,
      color: 'text-red-500',
      bgColor: 'bg-red-500/10',
      hoverColor: 'hover:bg-red-500/20',
    },
    {
      label: 'Team Roster',
      description: 'Staff assignments',
      icon: Users,
      color: 'text-teal-500',
      bgColor: 'bg-teal-500/10',
      hoverColor: 'hover:bg-teal-500/20',
    },
    {
      label: 'Ops Report',
      description: 'Generate summary',
      icon: FileBarChart,
      color: 'text-orange-500',
      bgColor: 'bg-orange-500/10',
      hoverColor: 'hover:bg-orange-500/20',
    },
  ];

  const handleAction = (label: string) => {
    toast.info(`${label} action coming soon`);
  };

  return (
    <Card className="border-border">
      <CardHeader className="pb-3">
        <CardTitle className="text-base font-semibold">Operations Quick Actions</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-8 gap-2">
          {actions.map((action) => (
            <Button
              key={action.label}
              variant="ghost"
              className={`flex flex-col h-auto py-3 px-2 ${action.bgColor} ${action.hoverColor} border-0`}
              onClick={() => handleAction(action.label)}
            >
              <action.icon className={`h-5 w-5 mb-1.5 ${action.color}`} />
              <span className="text-xs font-medium text-foreground">{action.label}</span>
              <span className="text-[10px] text-muted-foreground">{action.description}</span>
            </Button>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}
