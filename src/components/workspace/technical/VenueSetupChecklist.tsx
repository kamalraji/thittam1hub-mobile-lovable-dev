import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Checkbox } from '@/components/ui/checkbox';
import { Badge } from '@/components/ui/badge';
import { ClipboardCheck, MapPin } from 'lucide-react';
import { useState } from 'react';

interface ChecklistItem {
  id: string;
  task: string;
  location: string;
  completed: boolean;
}

export function VenueSetupChecklist() {
  const [items, setItems] = useState<ChecklistItem[]>([
    { id: '1', task: 'Test main projector and screen', location: 'Main Hall', completed: true },
    { id: '2', task: 'Setup wireless microphone system', location: 'Stage', completed: true },
    { id: '3', task: 'Configure live streaming equipment', location: 'AV Booth', completed: false },
    { id: '4', task: 'Test backup power supply', location: 'All Areas', completed: true },
    { id: '5', task: 'Setup registration tablets', location: 'Entrance', completed: false },
    { id: '6', task: 'Configure speaker timer displays', location: 'Stage', completed: false },
    { id: '7', task: 'Test video conferencing in breakout rooms', location: 'Rooms A-D', completed: false },
  ]);

  const completedCount = items.filter(i => i.completed).length;
  const progressPercent = Math.round((completedCount / items.length) * 100);

  const toggleItem = (id: string) => {
    setItems(prev => prev.map(item => 
      item.id === id ? { ...item, completed: !item.completed } : item
    ));
  };

  return (
    <Card className="bg-card border-border">
      <CardHeader className="flex flex-row items-center justify-between">
        <div className="flex items-center gap-2">
          <ClipboardCheck className="h-5 w-5 text-primary" />
          <CardTitle className="text-lg font-semibold text-foreground">Venue Setup Checklist</CardTitle>
        </div>
        <Badge variant="outline" className="font-medium">
          {completedCount}/{items.length} ({progressPercent}%)
        </Badge>
      </CardHeader>
      <CardContent>
        <div className="space-y-3">
          {items.map((item) => (
            <div
              key={item.id}
              className={`flex items-start gap-3 p-3 rounded-lg transition-colors ${
                item.completed ? 'bg-success/5' : 'bg-muted/50'
              }`}
            >
              <Checkbox
                checked={item.completed}
                onCheckedChange={() => toggleItem(item.id)}
                className="mt-0.5"
              />
              <div className="flex-1">
                <p className={`text-sm ${item.completed ? 'text-muted-foreground line-through' : 'text-foreground'}`}>
                  {item.task}
                </p>
                <div className="flex items-center gap-1 mt-1">
                  <MapPin className="h-3 w-3 text-muted-foreground" />
                  <span className="text-xs text-muted-foreground">{item.location}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}
