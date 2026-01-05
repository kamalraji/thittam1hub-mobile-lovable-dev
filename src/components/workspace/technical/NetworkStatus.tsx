import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Wifi, WifiOff, Signal, Activity } from 'lucide-react';
import { Progress } from '@/components/ui/progress';

interface NetworkZone {
  id: string;
  name: string;
  status: 'online' | 'offline' | 'degraded';
  bandwidth: number;
  devices: number;
  maxDevices: number;
}

export function NetworkStatus() {
  const zones: NetworkZone[] = [
    { id: '1', name: 'Main Hall WiFi', status: 'online', bandwidth: 78, devices: 156, maxDevices: 200 },
    { id: '2', name: 'Stage AV Network', status: 'online', bandwidth: 45, devices: 12, maxDevices: 30 },
    { id: '3', name: 'Breakout Rooms', status: 'degraded', bandwidth: 92, devices: 89, maxDevices: 100 },
    { id: '4', name: 'Staff Network', status: 'online', bandwidth: 23, devices: 35, maxDevices: 50 },
  ];

  const getStatusBadge = (status: NetworkZone['status']) => {
    switch (status) {
      case 'online':
        return (
          <Badge className="bg-success/10 text-success border-success/20">
            <Wifi className="h-3 w-3 mr-1" />
            Online
          </Badge>
        );
      case 'offline':
        return (
          <Badge className="bg-destructive/10 text-destructive border-destructive/20">
            <WifiOff className="h-3 w-3 mr-1" />
            Offline
          </Badge>
        );
      case 'degraded':
        return (
          <Badge className="bg-warning/10 text-warning border-warning/20">
            <Signal className="h-3 w-3 mr-1" />
            Degraded
          </Badge>
        );
    }
  };

  const getBandwidthColor = (bandwidth: number) => {
    if (bandwidth < 50) return 'bg-success';
    if (bandwidth < 80) return 'bg-warning';
    return 'bg-destructive';
  };

  return (
    <Card className="bg-card border-border">
      <CardHeader className="flex flex-row items-center justify-between">
        <div className="flex items-center gap-2">
          <Activity className="h-5 w-5 text-primary" />
          <CardTitle className="text-lg font-semibold text-foreground">Network Status</CardTitle>
        </div>
        <Badge variant="outline" className="font-mono">
          Live
        </Badge>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {zones.map((zone) => (
            <div key={zone.id} className="p-3 rounded-lg bg-muted/50">
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm font-medium text-foreground">{zone.name}</span>
                {getStatusBadge(zone.status)}
              </div>
              <div className="space-y-2">
                <div className="flex items-center justify-between text-xs text-muted-foreground">
                  <span>Bandwidth Usage</span>
                  <span>{zone.bandwidth}%</span>
                </div>
                <Progress value={zone.bandwidth} className={`h-1.5 ${getBandwidthColor(zone.bandwidth)}`} />
                <div className="flex items-center justify-between text-xs text-muted-foreground">
                  <span>Connected Devices</span>
                  <span>{zone.devices} / {zone.maxDevices}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}
