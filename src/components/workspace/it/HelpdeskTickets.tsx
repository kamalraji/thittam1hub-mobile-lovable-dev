import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { TicketCheck, Clock, User, ArrowRight } from 'lucide-react';
import { Skeleton } from '@/components/ui/skeleton';
import { ITTicket } from '@/hooks/useITDashboardData';

interface HelpdeskTicketsProps {
  tickets?: ITTicket[];
  isLoading?: boolean;
}

export function HelpdeskTickets({ tickets = [], isLoading }: HelpdeskTicketsProps) {
  const getPriorityBadge = (priority: ITTicket['priority']) => {
    switch (priority) {
      case 'urgent':
        return <Badge className="bg-destructive text-destructive-foreground">Urgent</Badge>;
      case 'high':
        return <Badge className="bg-warning/10 text-warning border-warning/20">High</Badge>;
      case 'medium':
        return <Badge className="bg-primary/10 text-primary border-primary/20">Medium</Badge>;
      case 'low':
        return <Badge variant="secondary">Low</Badge>;
    }
  };

  const getCategoryBadge = (category: ITTicket['category']) => {
    const colors: Record<ITTicket['category'], string> = {
      software: 'bg-blue-500/10 text-blue-600 dark:text-blue-400 border-blue-500/20',
      hardware: 'bg-purple-500/10 text-purple-600 dark:text-purple-400 border-purple-500/20',
      access: 'bg-orange-500/10 text-orange-600 dark:text-orange-400 border-orange-500/20',
      network: 'bg-cyan-500/10 text-cyan-600 dark:text-cyan-400 border-cyan-500/20',
      other: 'bg-muted text-muted-foreground',
    };
    return <Badge className={colors[category]}>{category}</Badge>;
  };

  const openTickets = tickets.filter(t => t.status !== 'resolved');

  if (isLoading) {
    return (
      <Card className="bg-card border-border">
        <CardHeader className="flex flex-row items-center justify-between">
          <div className="flex items-center gap-2">
            <TicketCheck className="h-5 w-5 text-primary" />
            <div>
              <Skeleton className="h-5 w-24" />
              <Skeleton className="h-4 w-20 mt-1" />
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {[1, 2, 3].map((i) => (
              <div key={i} className="p-3 rounded-lg bg-muted/50">
                <Skeleton className="h-4 w-full mb-2" />
                <Skeleton className="h-3 w-3/4" />
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    );
  }

  // Use sample data if no real data
  const displayTickets = tickets.length > 0 ? tickets : [
    { id: 'HD-101', title: 'No tickets yet', requester: 'System', category: 'other' as const, priority: 'low' as const, status: 'new' as const, createdAt: 'Just now' },
  ];

  return (
    <Card className="bg-card border-border">
      <CardHeader className="flex flex-row items-center justify-between">
        <div className="flex items-center gap-2">
          <TicketCheck className="h-5 w-5 text-primary" />
          <div>
            <CardTitle className="text-lg font-semibold text-foreground">Helpdesk</CardTitle>
            <p className="text-sm text-muted-foreground">{openTickets.length} open tickets</p>
          </div>
        </div>
        <Button size="sm" variant="ghost">
          View All <ArrowRight className="h-4 w-4 ml-1" />
        </Button>
      </CardHeader>
      <CardContent>
        <div className="space-y-3">
          {displayTickets.map((ticket) => (
            <div
              key={ticket.id}
              className={`p-3 rounded-lg transition-colors cursor-pointer active:scale-[0.98] ${
                ticket.status === 'resolved' ? 'bg-muted/30 opacity-60' : 'bg-muted/50 hover:bg-muted'
              }`}
            >
              <div className="flex items-start justify-between mb-2">
                <div className="flex items-center gap-2 flex-wrap">
                  <span className="text-xs font-mono text-muted-foreground">{ticket.id}</span>
                  {getPriorityBadge(ticket.priority)}
                  {getCategoryBadge(ticket.category)}
                </div>
              </div>
              <p className="text-sm font-medium text-foreground">{ticket.title}</p>
              <div className="flex items-center gap-4 mt-2 text-xs text-muted-foreground flex-wrap">
                <div className="flex items-center gap-1">
                  <User className="h-3 w-3" />
                  {ticket.requester}
                </div>
                <div className="flex items-center gap-1">
                  <Clock className="h-3 w-3" />
                  {ticket.createdAt}
                </div>
                {ticket.assignedTo && (
                  <span>Assigned to: {ticket.assignedTo}</span>
                )}
              </div>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}
