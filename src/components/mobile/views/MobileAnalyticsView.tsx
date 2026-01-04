import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { BarChart3, Users, Calendar, TrendingUp, Eye } from 'lucide-react';
import { supabase } from '@/integrations/supabase/client';

interface MobileAnalyticsViewProps {
  organization: {
    id: string;
    slug: string;
  };
}

export const MobileAnalyticsView: React.FC<MobileAnalyticsViewProps> = ({ organization }) => {
  // Fetch basic stats
  const { data: stats } = useQuery({
    queryKey: ['mobile-analytics', organization.id],
    queryFn: async () => {
      const [eventsRes, registrationsRes, checkinsRes] = await Promise.all([
        supabase
          .from('events')
          .select('*', { count: 'exact', head: true })
          .eq('organization_id', organization.id),
        supabase
          .from('registrations')
          .select('id, events!inner(organization_id)', { count: 'exact', head: true })
          .eq('events.organization_id', organization.id),
        supabase
          .from('attendance_records')
          .select('id, events!inner(organization_id)', { count: 'exact', head: true })
          .eq('events.organization_id', organization.id),
      ]);

      return {
        totalEvents: eventsRes.count || 0,
        totalRegistrations: registrationsRes.count || 0,
        totalCheckins: checkinsRes.count || 0,
      };
    },
  });

  const statCards = [
    {
      label: 'Total Events',
      value: stats?.totalEvents || 0,
      icon: Calendar,
      color: 'bg-blue-500/10 text-blue-600',
    },
    {
      label: 'Registrations',
      value: stats?.totalRegistrations || 0,
      icon: Users,
      color: 'bg-green-500/10 text-green-600',
    },
    {
      label: 'Check-ins',
      value: stats?.totalCheckins || 0,
      icon: Eye,
      color: 'bg-purple-500/10 text-purple-600',
    },
    {
      label: 'Conversion Rate',
      value: stats?.totalRegistrations 
        ? `${Math.round((stats.totalCheckins / stats.totalRegistrations) * 100)}%`
        : '0%',
      icon: TrendingUp,
      color: 'bg-orange-500/10 text-orange-600',
    },
  ];

  return (
    <div className="px-4 py-4 space-y-4">
      {/* Header */}
      <div>
        <h1 className="text-xl font-bold text-foreground">Analytics</h1>
        <p className="text-sm text-muted-foreground mt-1">
          Overview of your organization's performance
        </p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-2 gap-3">
        {statCards.map((stat) => {
          const Icon = stat.icon;
          return (
            <div
              key={stat.label}
              className="bg-card border border-border rounded-2xl p-4 shadow-sm"
            >
              <div className={`inline-flex p-2 rounded-xl ${stat.color} mb-3`}>
                <Icon className="h-5 w-5" />
              </div>
              <p className="text-2xl font-bold text-foreground">{stat.value}</p>
              <p className="text-xs text-muted-foreground mt-1">{stat.label}</p>
            </div>
          );
        })}
      </div>

      {/* Placeholder for Charts */}
      <div className="bg-card border border-border rounded-2xl p-6 shadow-sm">
        <div className="flex items-center gap-2 mb-4">
          <BarChart3 className="h-5 w-5 text-muted-foreground" />
          <h2 className="font-semibold text-foreground">Activity Overview</h2>
        </div>
        <div className="flex items-center justify-center h-40 bg-muted/30 rounded-xl">
          <p className="text-sm text-muted-foreground">
            Charts coming soon
          </p>
        </div>
      </div>
    </div>
  );
};
