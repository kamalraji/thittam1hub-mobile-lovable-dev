import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Monitor, Mic, Camera, Projector, Speaker, Plus } from 'lucide-react';

interface Equipment {
  id: string;
  name: string;
  type: 'projector' | 'microphone' | 'camera' | 'monitor' | 'speaker';
  location: string;
  status: 'operational' | 'maintenance' | 'faulty';
  assignedTo?: string;
}

export function EquipmentInventory() {
  const equipment: Equipment[] = [
    { id: '1', name: 'Projector A1', type: 'projector', location: 'Main Hall', status: 'operational' },
    { id: '2', name: 'Wireless Mic Set', type: 'microphone', location: 'Stage', status: 'operational', assignedTo: 'Speaker Panel' },
    { id: '3', name: 'PTZ Camera 1', type: 'camera', location: 'Main Hall', status: 'operational' },
    { id: '4', name: 'Backup Projector', type: 'projector', location: 'Storage', status: 'maintenance' },
    { id: '5', name: 'Conference Speaker', type: 'speaker', location: 'Room B', status: 'faulty' },
    { id: '6', name: 'Presentation Monitor', type: 'monitor', location: 'Stage', status: 'operational' },
  ];

  const getIcon = (type: Equipment['type']) => {
    switch (type) {
      case 'projector': return Projector;
      case 'microphone': return Mic;
      case 'camera': return Camera;
      case 'monitor': return Monitor;
      case 'speaker': return Speaker;
    }
  };

  const getStatusBadge = (status: Equipment['status']) => {
    switch (status) {
      case 'operational':
        return <Badge className="bg-success/10 text-success border-success/20">Operational</Badge>;
      case 'maintenance':
        return <Badge className="bg-warning/10 text-warning border-warning/20">Maintenance</Badge>;
      case 'faulty':
        return <Badge className="bg-destructive/10 text-destructive border-destructive/20">Faulty</Badge>;
    }
  };

  return (
    <Card className="bg-card border-border">
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle className="text-lg font-semibold text-foreground">Equipment Inventory</CardTitle>
        <Button size="sm" variant="outline">
          <Plus className="h-4 w-4 mr-1" />
          Add Equipment
        </Button>
      </CardHeader>
      <CardContent>
        <div className="space-y-3">
          {equipment.map((item) => {
            const Icon = getIcon(item.type);
            return (
              <div
                key={item.id}
                className="flex items-center justify-between p-3 rounded-lg bg-muted/50 hover:bg-muted transition-colors"
              >
                <div className="flex items-center gap-3">
                  <div className="p-2 rounded-lg bg-primary/10">
                    <Icon className="h-4 w-4 text-primary" />
                  </div>
                  <div>
                    <p className="text-sm font-medium text-foreground">{item.name}</p>
                    <p className="text-xs text-muted-foreground">
                      {item.location}
                      {item.assignedTo && ` • ${item.assignedTo}`}
                    </p>
                  </div>
                </div>
                {getStatusBadge(item.status)}
              </div>
            );
          })}
        </div>
      </CardContent>
    </Card>
  );
}
