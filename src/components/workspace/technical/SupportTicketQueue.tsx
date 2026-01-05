import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Clock, AlertCircle, CheckCircle2, ArrowRight } from 'lucide-react';

interface Ticket {
  id: string;
  title: string;
  reporter: string;
  location: string;
  priority: 'low' | 'medium' | 'high' | 'critical';
  status: 'open' | 'in_progress' | 'resolved';
  createdAt: string;
}

export function SupportTicketQueue() {
  const tickets: Ticket[] = [
    { id: 'TKT-001', title: 'Projector not displaying', reporter: 'John Doe', location: 'Room A', priority: 'high', status: 'in_progress', createdAt: '10 min ago' },
    { id: 'TKT-002', title: 'WiFi connectivity issues', reporter: 'Sarah Smith', location: 'Main Hall', priority: 'critical', status: 'open', createdAt: '25 min ago' },
    { id: 'TKT-003', title: 'Microphone feedback', reporter: 'Mike Johnson', location: 'Stage', priority: 'medium', status: 'open', createdAt: '45 min ago' },
    { id: 'TKT-004', title: 'Laptop HDMI adapter needed', reporter: 'Emily Chen', location: 'Room B', priority: 'low', status: 'resolved', createdAt: '1 hour ago' },
  ];

  const getPriorityBadge = (priority: Ticket['priority']) => {
    switch (priority) {
      case 'critical':
        return <Badge className="bg-destructive text-destructive-foreground">Critical</Badge>;
      case 'high':
        return <Badge className="bg-warning/10 text-warning border-warning/20">High</Badge>;
      case 'medium':
        return <Badge className="bg-primary/10 text-primary border-primary/20">Medium</Badge>;
      case 'low':
        return <Badge variant="secondary">Low</Badge>;
    }
  };

  const getStatusIcon = (status: Ticket['status']) => {
    switch (status) {
      case 'open':
        return <AlertCircle className="h-4 w-4 text-warning" />;
      case 'in_progress':
        return <Clock className="h-4 w-4 text-primary" />;
      case 'resolved':
        return <CheckCircle2 className="h-4 w-4 text-success" />;
    }
  };

  const openTickets = tickets.filter(t => t.status !== 'resolved');

  return (
    <Card className="bg-card border-border">
      <CardHeader className="flex flex-row items-center justify-between">
        <div>
          <CardTitle className="text-lg font-semibold text-foreground">Support Tickets</CardTitle>
          <p className="text-sm text-muted-foreground mt-1">{openTickets.length} open tickets</p>
        </div>
        <Button size="sm" variant="ghost">
          View All
          <ArrowRight className="h-4 w-4 ml-1" />
        </Button>
      </CardHeader>
      <CardContent>
        <div className="space-y-3">
          {tickets.map((ticket) => (
            <div
              key={ticket.id}
              className="flex items-start justify-between p-3 rounded-lg bg-muted/50 hover:bg-muted transition-colors cursor-pointer"
            >
              <div className="flex items-start gap-3">
                {getStatusIcon(ticket.status)}
                <div>
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-mono text-muted-foreground">{ticket.id}</span>
                    {getPriorityBadge(ticket.priority)}
                  </div>
                  <p className="text-sm font-medium text-foreground mt-1">{ticket.title}</p>
                  <p className="text-xs text-muted-foreground mt-0.5">
                    {ticket.reporter} • {ticket.location} • {ticket.createdAt}
                  </p>
                </div>
              </div>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}
