import { Card, CardContent } from '@/components/ui/card';
import { DollarSign, Package, UserPlus, AlertCircle } from 'lucide-react';
import { cn } from '@/lib/utils';

interface ApprovalsSummaryCardsProps {
  budgetCount: number;
  resourceCount: number;
  accessCount: number;
}

export function ApprovalsSummaryCards({
  budgetCount,
  resourceCount,
  accessCount,
}: ApprovalsSummaryCardsProps) {
  const totalPending = budgetCount + resourceCount + accessCount;

  const cards = [
    {
      label: 'Total Pending',
      count: totalPending,
      icon: AlertCircle,
      color: 'text-primary',
      bgColor: 'bg-primary/10',
      borderColor: 'border-primary/20',
    },
    {
      label: 'Budget Requests',
      count: budgetCount,
      icon: DollarSign,
      color: 'text-emerald-600',
      bgColor: 'bg-emerald-500/10',
      borderColor: 'border-emerald-500/20',
    },
    {
      label: 'Resource Requests',
      count: resourceCount,
      icon: Package,
      color: 'text-blue-600',
      bgColor: 'bg-blue-500/10',
      borderColor: 'border-blue-500/20',
    },
    {
      label: 'Access Requests',
      count: accessCount,
      icon: UserPlus,
      color: 'text-amber-600',
      bgColor: 'bg-amber-500/10',
      borderColor: 'border-amber-500/20',
    },
  ];

  return (
    <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
      {cards.map((card) => (
        <Card
          key={card.label}
          className={cn(
            'border',
            card.borderColor,
            'transition-all duration-200 hover:shadow-sm'
          )}
        >
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className={cn('p-2 rounded-lg', card.bgColor)}>
                <card.icon className={cn('h-4 w-4', card.color)} />
              </div>
              <div>
                <p className="text-2xl font-bold text-foreground">{card.count}</p>
                <p className="text-xs text-muted-foreground">{card.label}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      ))}
    </div>
  );
}
