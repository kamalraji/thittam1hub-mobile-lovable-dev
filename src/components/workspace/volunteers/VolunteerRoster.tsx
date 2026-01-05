import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Button } from '@/components/ui/button';
import { Users, UserPlus, CheckCircle, Clock, XCircle } from 'lucide-react';

interface Volunteer {
  id: string;
  name: string;
  email: string;
  status: 'active' | 'pending' | 'inactive';
  shiftsAssigned: number;
  hoursLogged: number;
}

interface VolunteerRosterProps {
  workspaceId: string;
}

// Mock data for demonstration
const MOCK_VOLUNTEERS: Volunteer[] = [
  { id: '1', name: 'Alex Johnson', email: 'alex@email.com', status: 'active', shiftsAssigned: 4, hoursLogged: 12 },
  { id: '2', name: 'Maria Garcia', email: 'maria@email.com', status: 'active', shiftsAssigned: 3, hoursLogged: 9 },
  { id: '3', name: 'James Wilson', email: 'james@email.com', status: 'pending', shiftsAssigned: 0, hoursLogged: 0 },
  { id: '4', name: 'Sarah Chen', email: 'sarah@email.com', status: 'active', shiftsAssigned: 5, hoursLogged: 16 },
  { id: '5', name: 'Mike Brown', email: 'mike@email.com', status: 'inactive', shiftsAssigned: 1, hoursLogged: 3 },
];

export function VolunteerRoster({ workspaceId: _workspaceId }: VolunteerRosterProps) {
  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'active':
        return <CheckCircle className="h-3 w-3 text-emerald-500" />;
      case 'pending':
        return <Clock className="h-3 w-3 text-amber-500" />;
      case 'inactive':
        return <XCircle className="h-3 w-3 text-muted-foreground" />;
      default:
        return null;
    }
  };

  const getStatusBadge = (status: string) => {
    const styles = {
      active: 'bg-emerald-500/10 text-emerald-600 border-emerald-500/20',
      pending: 'bg-amber-500/10 text-amber-600 border-amber-500/20',
      inactive: 'bg-muted text-muted-foreground border-border',
    };
    return (
      <Badge variant="outline" className={styles[status as keyof typeof styles]}>
        {status.charAt(0).toUpperCase() + status.slice(1)}
      </Badge>
    );
  };

  const activeCount = MOCK_VOLUNTEERS.filter(v => v.status === 'active').length;
  const pendingCount = MOCK_VOLUNTEERS.filter(v => v.status === 'pending').length;

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-4">
        <CardTitle className="flex items-center gap-2 text-base font-semibold">
          <Users className="h-4 w-4 text-pink-500" />
          Volunteer Roster
        </CardTitle>
        <Button size="sm" variant="outline" className="gap-1">
          <UserPlus className="h-3 w-3" />
          Add Volunteer
        </Button>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Summary Stats */}
        <div className="grid grid-cols-3 gap-3">
          <div className="rounded-lg bg-emerald-500/10 p-3 text-center">
            <div className="text-2xl font-bold text-emerald-600">{activeCount}</div>
            <div className="text-xs text-muted-foreground">Active</div>
          </div>
          <div className="rounded-lg bg-amber-500/10 p-3 text-center">
            <div className="text-2xl font-bold text-amber-600">{pendingCount}</div>
            <div className="text-xs text-muted-foreground">Pending</div>
          </div>
          <div className="rounded-lg bg-muted p-3 text-center">
            <div className="text-2xl font-bold">{MOCK_VOLUNTEERS.length}</div>
            <div className="text-xs text-muted-foreground">Total</div>
          </div>
        </div>

        {/* Volunteer List */}
        <div className="space-y-2">
          {MOCK_VOLUNTEERS.slice(0, 5).map((volunteer) => (
            <div
              key={volunteer.id}
              className="flex items-center justify-between rounded-lg border p-3 transition-colors hover:bg-muted/30"
            >
              <div className="flex items-center gap-3">
                <Avatar className="h-8 w-8">
                  <AvatarFallback className="bg-pink-500/10 text-pink-600 text-xs">
                    {volunteer.name.split(' ').map(n => n[0]).join('')}
                  </AvatarFallback>
                </Avatar>
                <div>
                  <div className="flex items-center gap-2">
                    <span className="font-medium text-sm">{volunteer.name}</span>
                    {getStatusIcon(volunteer.status)}
                  </div>
                  <div className="text-xs text-muted-foreground">{volunteer.email}</div>
                </div>
              </div>
              <div className="flex items-center gap-4">
                <div className="text-right text-xs">
                  <div className="font-medium">{volunteer.shiftsAssigned} shifts</div>
                  <div className="text-muted-foreground">{volunteer.hoursLogged}h logged</div>
                </div>
                {getStatusBadge(volunteer.status)}
              </div>
            </div>
          ))}
        </div>

        {MOCK_VOLUNTEERS.length > 5 && (
          <Button variant="ghost" size="sm" className="w-full">
            View All Volunteers
          </Button>
        )}
      </CardContent>
    </Card>
  );
}
