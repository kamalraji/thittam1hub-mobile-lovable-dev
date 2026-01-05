import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { 
  UserCheck, 
  Clock, 
  TrendingUp, 
  AlertTriangle,
  CheckCircle2,
  XCircle,
} from 'lucide-react';

interface VolunteerCheckInStatsProps {
  workspaceId: string;
}

// Mock data for demonstration
const MOCK_STATS = {
  totalVolunteers: 24,
  checkedIn: 18,
  late: 2,
  noShow: 4,
  avgCheckInTime: '07:45',
  onTimePercentage: 88,
};

export function VolunteerCheckInStats({ workspaceId: _workspaceId }: VolunteerCheckInStatsProps) {
  const checkInRate = Math.round((MOCK_STATS.checkedIn / MOCK_STATS.totalVolunteers) * 100);

  return (
    <Card>
      <CardHeader className="pb-4">
        <CardTitle className="flex items-center gap-2 text-base font-semibold">
          <UserCheck className="h-4 w-4 text-pink-500" />
          Check-In Status
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Main Progress */}
        <div className="space-y-2">
          <div className="flex items-center justify-between text-sm">
            <span className="text-muted-foreground">Check-in Progress</span>
            <span className="font-medium">{MOCK_STATS.checkedIn}/{MOCK_STATS.totalVolunteers}</span>
          </div>
          <Progress value={checkInRate} className="h-2" />
          <div className="flex justify-between text-xs text-muted-foreground">
            <span>{checkInRate}% checked in</span>
            <span>{MOCK_STATS.totalVolunteers - MOCK_STATS.checkedIn} remaining</span>
          </div>
        </div>

        {/* Status Grid */}
        <div className="grid grid-cols-2 gap-3">
          <div className="flex items-center gap-3 rounded-lg border border-emerald-500/20 bg-emerald-500/5 p-3">
            <div className="rounded-full bg-emerald-500/20 p-2">
              <CheckCircle2 className="h-4 w-4 text-emerald-600" />
            </div>
            <div>
              <div className="text-xl font-bold text-emerald-600">{MOCK_STATS.checkedIn}</div>
              <div className="text-xs text-muted-foreground">Checked In</div>
            </div>
          </div>

          <div className="flex items-center gap-3 rounded-lg border border-amber-500/20 bg-amber-500/5 p-3">
            <div className="rounded-full bg-amber-500/20 p-2">
              <Clock className="h-4 w-4 text-amber-600" />
            </div>
            <div>
              <div className="text-xl font-bold text-amber-600">{MOCK_STATS.late}</div>
              <div className="text-xs text-muted-foreground">Late</div>
            </div>
          </div>

          <div className="flex items-center gap-3 rounded-lg border border-red-500/20 bg-red-500/5 p-3">
            <div className="rounded-full bg-red-500/20 p-2">
              <XCircle className="h-4 w-4 text-red-600" />
            </div>
            <div>
              <div className="text-xl font-bold text-red-600">{MOCK_STATS.noShow}</div>
              <div className="text-xs text-muted-foreground">No Show</div>
            </div>
          </div>

          <div className="flex items-center gap-3 rounded-lg border p-3">
            <div className="rounded-full bg-muted p-2">
              <TrendingUp className="h-4 w-4 text-muted-foreground" />
            </div>
            <div>
              <div className="text-xl font-bold">{MOCK_STATS.onTimePercentage}%</div>
              <div className="text-xs text-muted-foreground">On Time</div>
            </div>
          </div>
        </div>

        {/* Alert for No Shows */}
        {MOCK_STATS.noShow > 0 && (
          <div className="flex items-center gap-2 rounded-lg bg-red-500/10 p-3">
            <AlertTriangle className="h-4 w-4 text-red-600" />
            <span className="text-sm text-red-600">
              {MOCK_STATS.noShow} volunteer{MOCK_STATS.noShow > 1 ? 's' : ''} have not checked in
            </span>
          </div>
        )}

        {/* Avg Check-in Time */}
        <div className="flex items-center justify-between rounded-lg bg-muted/50 p-3">
          <span className="text-sm text-muted-foreground">Avg. Check-in Time</span>
          <Badge variant="outline">{MOCK_STATS.avgCheckInTime} AM</Badge>
        </div>
      </CardContent>
    </Card>
  );
}
