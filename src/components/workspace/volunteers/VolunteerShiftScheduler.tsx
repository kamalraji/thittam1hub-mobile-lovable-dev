import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Calendar, Clock, Users, Plus, CheckCircle2 } from 'lucide-react';
import { cn } from '@/lib/utils';

interface Shift {
  id: string;
  name: string;
  date: string;
  startTime: string;
  endTime: string;
  requiredVolunteers: number;
  assignedVolunteers: number;
  location: string;
}

interface VolunteerShiftSchedulerProps {
  workspaceId: string;
}

// Mock data for demonstration
const MOCK_SHIFTS: Shift[] = [
  {
    id: '1',
    name: 'Registration Desk',
    date: '2026-01-10',
    startTime: '08:00',
    endTime: '12:00',
    requiredVolunteers: 4,
    assignedVolunteers: 3,
    location: 'Main Entrance',
  },
  {
    id: '2',
    name: 'Session Support',
    date: '2026-01-10',
    startTime: '09:00',
    endTime: '17:00',
    requiredVolunteers: 6,
    assignedVolunteers: 6,
    location: 'Conference Hall A',
  },
  {
    id: '3',
    name: 'Lunch Service',
    date: '2026-01-10',
    startTime: '12:00',
    endTime: '14:00',
    requiredVolunteers: 8,
    assignedVolunteers: 5,
    location: 'Cafeteria',
  },
  {
    id: '4',
    name: 'Tech Booth',
    date: '2026-01-10',
    startTime: '08:00',
    endTime: '18:00',
    requiredVolunteers: 2,
    assignedVolunteers: 2,
    location: 'Innovation Zone',
  },
];

export function VolunteerShiftScheduler({ workspaceId: _workspaceId }: VolunteerShiftSchedulerProps) {
  const [shifts] = useState<Shift[]>(MOCK_SHIFTS);

  const getShiftStatus = (shift: Shift) => {
    const fillRate = shift.assignedVolunteers / shift.requiredVolunteers;
    if (fillRate >= 1) return 'filled';
    if (fillRate >= 0.5) return 'partial';
    return 'critical';
  };

  const getStatusBadge = (status: string) => {
    const styles = {
      filled: 'bg-emerald-500/10 text-emerald-600 border-emerald-500/20',
      partial: 'bg-amber-500/10 text-amber-600 border-amber-500/20',
      critical: 'bg-red-500/10 text-red-600 border-red-500/20',
    };
    const labels = {
      filled: 'Filled',
      partial: 'Needs More',
      critical: 'Critical',
    };
    return (
      <Badge variant="outline" className={styles[status as keyof typeof styles]}>
        {labels[status as keyof typeof labels]}
      </Badge>
    );
  };

  const totalRequired = shifts.reduce((sum, s) => sum + s.requiredVolunteers, 0);
  const totalAssigned = shifts.reduce((sum, s) => sum + s.assignedVolunteers, 0);
  const fillPercentage = Math.round((totalAssigned / totalRequired) * 100);

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-4">
        <CardTitle className="flex items-center gap-2 text-base font-semibold">
          <Calendar className="h-4 w-4 text-pink-500" />
          Shift Schedule
        </CardTitle>
        <Button size="sm" variant="outline" className="gap-1">
          <Plus className="h-3 w-3" />
          Add Shift
        </Button>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Summary Bar */}
        <div className="flex items-center justify-between rounded-lg bg-muted/50 p-3">
          <div className="flex items-center gap-2 text-sm">
            <Users className="h-4 w-4 text-muted-foreground" />
            <span className="text-muted-foreground">Overall Fill Rate:</span>
            <span className="font-medium">{totalAssigned}/{totalRequired}</span>
          </div>
          <Badge 
            variant="outline"
            className={cn(
              fillPercentage >= 90 
                ? 'bg-emerald-500/10 text-emerald-600' 
                : fillPercentage >= 70 
                  ? 'bg-amber-500/10 text-amber-600'
                  : 'bg-red-500/10 text-red-600'
            )}
          >
            {fillPercentage}%
          </Badge>
        </div>

        {/* Shifts List */}
        <div className="space-y-3">
          {shifts.map((shift) => {
            const status = getShiftStatus(shift);
            return (
              <div
                key={shift.id}
                className={cn(
                  'flex items-center justify-between rounded-lg border p-3 transition-colors hover:bg-muted/30',
                  status === 'filled' && 'border-emerald-500/20 bg-emerald-500/5',
                  status === 'partial' && 'border-amber-500/20 bg-amber-500/5',
                  status === 'critical' && 'border-red-500/20 bg-red-500/5'
                )}
              >
                <div className="space-y-1">
                  <div className="flex items-center gap-2">
                    <span className="font-medium">{shift.name}</span>
                    {status === 'filled' && (
                      <CheckCircle2 className="h-4 w-4 text-emerald-500" />
                    )}
                  </div>
                  <div className="flex items-center gap-3 text-xs text-muted-foreground">
                    <span className="flex items-center gap-1">
                      <Clock className="h-3 w-3" />
                      {shift.startTime} - {shift.endTime}
                    </span>
                    <span>{shift.location}</span>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <div className="text-right">
                    <div className="text-sm font-medium">
                      {shift.assignedVolunteers}/{shift.requiredVolunteers}
                    </div>
                    <div className="text-xs text-muted-foreground">volunteers</div>
                  </div>
                  {getStatusBadge(status)}
                </div>
              </div>
            );
          })}
        </div>
      </CardContent>
    </Card>
  );
}
