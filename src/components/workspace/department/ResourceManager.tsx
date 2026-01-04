import { Package, Users, MapPin, Laptop, Plus, AlertTriangle } from 'lucide-react';
import { Badge } from '@/components/ui/badge';

type ResourceType = 'equipment' | 'personnel' | 'venue' | 'digital';
type ResourceStatus = 'available' | 'reserved' | 'in_use' | 'depleted';

interface Resource {
  id: string;
  name: string;
  type: ResourceType;
  quantity: number;
  available: number;
  status: ResourceStatus;
  assignedTo?: string;
}

interface ResourceManagerProps {
  departmentId?: string;
  resources?: Resource[];
}

const mockResources: Resource[] = [
  { id: '1', name: 'Projectors', type: 'equipment', quantity: 5, available: 2, status: 'in_use', assignedTo: 'Event Committee' },
  { id: '2', name: 'Volunteers', type: 'personnel', quantity: 25, available: 8, status: 'available' },
  { id: '3', name: 'Main Hall', type: 'venue', quantity: 1, available: 0, status: 'reserved', assignedTo: 'Catering Committee' },
  { id: '4', name: 'Laptops', type: 'equipment', quantity: 10, available: 4, status: 'available' },
  { id: '5', name: 'Conference Room A', type: 'venue', quantity: 1, available: 1, status: 'available' },
  { id: '6', name: 'Design Tools License', type: 'digital', quantity: 3, available: 1, status: 'in_use' },
];

const typeConfig: Record<ResourceType, { icon: React.ComponentType<any>; color: string; bgColor: string }> = {
  equipment: { icon: Package, color: 'text-blue-600 dark:text-blue-400', bgColor: 'bg-blue-500/10' },
  personnel: { icon: Users, color: 'text-green-600 dark:text-green-400', bgColor: 'bg-green-500/10' },
  venue: { icon: MapPin, color: 'text-purple-600 dark:text-purple-400', bgColor: 'bg-purple-500/10' },
  digital: { icon: Laptop, color: 'text-orange-600 dark:text-orange-400', bgColor: 'bg-orange-500/10' },
};

const statusConfig: Record<ResourceStatus, { label: string; variant: 'default' | 'secondary' | 'destructive' | 'outline' }> = {
  available: { label: 'Available', variant: 'default' },
  reserved: { label: 'Reserved', variant: 'secondary' },
  in_use: { label: 'In Use', variant: 'outline' },
  depleted: { label: 'Depleted', variant: 'destructive' },
};

export function ResourceManager({ resources = mockResources }: ResourceManagerProps) {
  const totalResources = resources.length;
  const lowAvailability = resources.filter(r => r.available === 0 && r.status !== 'depleted').length;

  const groupedResources = resources.reduce((acc, resource) => {
    if (!acc[resource.type]) acc[resource.type] = [];
    acc[resource.type].push(resource);
    return acc;
  }, {} as Record<ResourceType, Resource[]>);

  return (
    <div className="bg-card rounded-xl border border-border shadow-sm">
      <div className="p-4 sm:p-6">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <div className="p-2 rounded-lg bg-secondary/50">
              <Package className="h-5 w-5 text-secondary-foreground" />
            </div>
            <div>
              <h3 className="text-base sm:text-lg font-semibold text-foreground">Resource Pool</h3>
              <p className="text-xs text-muted-foreground">{totalResources} resources tracked</p>
            </div>
          </div>
          <button className="flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-primary bg-primary/10 rounded-lg hover:bg-primary/20 transition-colors">
            <Plus className="h-4 w-4" />
            Add
          </button>
        </div>

        {/* Alert for low availability */}
        {lowAvailability > 0 && (
          <div className="flex items-center gap-2 p-3 mb-4 rounded-lg bg-amber-500/10 border border-amber-500/20">
            <AlertTriangle className="h-4 w-4 text-amber-600 dark:text-amber-400 shrink-0" />
            <p className="text-sm text-amber-700 dark:text-amber-300">
              {lowAvailability} resource{lowAvailability > 1 ? 's' : ''} fully allocated
            </p>
          </div>
        )}

        {/* Resource list grouped by type */}
        <div className="space-y-4">
          {(Object.entries(groupedResources) as [ResourceType, Resource[]][]).map(([type, typeResources]) => {
            const config = typeConfig[type];
            const Icon = config.icon;
            
            return (
              <div key={type} className="space-y-2">
                <div className="flex items-center gap-2">
                  <div className={`p-1.5 rounded ${config.bgColor}`}>
                    <Icon className={`h-3.5 w-3.5 ${config.color}`} />
                  </div>
                  <span className="text-sm font-medium text-foreground capitalize">{type}</span>
                  <span className="text-xs text-muted-foreground">({typeResources.length})</span>
                </div>
                
                <div className="space-y-2 pl-7">
                  {typeResources.map((resource) => {
                    const statusCfg = statusConfig[resource.status];
                    const utilizationPercent = resource.quantity > 0 
                      ? ((resource.quantity - resource.available) / resource.quantity) * 100 
                      : 0;
                    
                    return (
                      <div 
                        key={resource.id} 
                        className="flex items-center justify-between p-2.5 rounded-lg bg-muted/50 hover:bg-muted transition-colors"
                      >
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2">
                            <span className="text-sm font-medium text-foreground truncate">{resource.name}</span>
                            <Badge variant={statusCfg.variant} className="text-[10px] px-1.5 py-0">
                              {statusCfg.label}
                            </Badge>
                          </div>
                          <div className="flex items-center gap-2 mt-1">
                            <span className="text-xs text-muted-foreground">
                              {resource.available}/{resource.quantity} available
                            </span>
                            {resource.assignedTo && (
                              <span className="text-xs text-primary">
                                → {resource.assignedTo}
                              </span>
                            )}
                          </div>
                        </div>
                        <div className="w-16 h-1.5 rounded-full bg-muted ml-3">
                          <div 
                            className={`h-full rounded-full transition-all ${
                              utilizationPercent >= 100 ? 'bg-destructive' : 
                              utilizationPercent >= 75 ? 'bg-amber-500' : 'bg-primary'
                            }`}
                            style={{ width: `${Math.min(utilizationPercent, 100)}%` }}
                          />
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            );
          })}
        </div>

        {/* Quick stats */}
        <div className="grid grid-cols-3 gap-3 mt-4 pt-4 border-t border-border">
          <div className="text-center">
            <p className="text-lg font-bold text-foreground">{resources.filter(r => r.status === 'available').length}</p>
            <p className="text-xs text-muted-foreground">Available</p>
          </div>
          <div className="text-center">
            <p className="text-lg font-bold text-foreground">{resources.filter(r => r.status === 'in_use').length}</p>
            <p className="text-xs text-muted-foreground">In Use</p>
          </div>
          <div className="text-center">
            <p className="text-lg font-bold text-foreground">{resources.filter(r => r.status === 'reserved').length}</p>
            <p className="text-xs text-muted-foreground">Reserved</p>
          </div>
        </div>
      </div>
    </div>
  );
}
