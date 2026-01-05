import React from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../../../hooks/useAuth';
import { PageHeader } from '../PageHeader';
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';

/**
 * MarketplaceServiceDashboard provides the AWS-style service landing page for Marketplace Management.
 * Features:
 * - Service overview with key marketplace metrics
 * - Quick action buttons for common marketplace tasks
 * - Recent bookings and vendor activity
 * - Service-specific widgets and analytics
 * - Role-based interface (organizer vs vendor view)
 */
export const MarketplaceServiceDashboard: React.FC = () => {
  const { user } = useAuth();

  // Fetch real metrics from Supabase
  const { data: metrics } = useQuery({
    queryKey: ['marketplace-metrics'],
    queryFn: async () => {
      const [servicesResult, vendorsResult, pendingBookingsResult, completedBookingsResult, revenueResult] = await Promise.all([
        supabase.from('vendor_services').select('id', { count: 'exact', head: true }).eq('status', 'active'),
        supabase.from('vendors').select('id', { count: 'exact', head: true }).eq('verification_status', 'VERIFIED'),
        supabase.from('vendor_bookings').select('id', { count: 'exact', head: true }).in('status', ['pending', 'quote_sent']),
        supabase.from('vendor_bookings').select('id', { count: 'exact', head: true }).eq('status', 'completed'),
        supabase.from('vendor_bookings').select('final_price').eq('status', 'completed'),
      ]);

      const totalRevenue = revenueResult.data?.reduce((sum, b) => sum + (b.final_price || 0), 0) || 0;

      return {
        totalServices: servicesResult.count || 0,
        activeVendors: vendorsResult.count || 0,
        pendingBookings: pendingBookingsResult.count || 0,
        completedBookings: completedBookingsResult.count || 0,
        totalRevenue,
      };
    },
  });

  // Fetch recent bookings
  const { data: recentBookings } = useQuery({
    queryKey: ['marketplace-recent-bookings'],
    queryFn: async () => {
      const { data } = await supabase
        .from('vendor_bookings')
        .select(`
          id,
          event_name,
          status,
          event_date,
          final_price,
          quoted_price,
          vendor_id,
          service_id,
          vendors(business_name),
          vendor_services(name)
        `)
        .order('created_at', { ascending: false })
        .limit(5);

      return data?.map((booking) => ({
        id: booking.id,
        serviceName: (booking.vendor_services as any)?.name || 'Service',
        vendorName: (booking.vendors as any)?.business_name || 'Vendor',
        eventName: booking.event_name,
        status: booking.status?.toUpperCase().replace(' ', '_') || 'PENDING',
        serviceDate: booking.event_date,
        amount: booking.final_price || booking.quoted_price || 0,
      })) || [];
    },
  });

  // Fetch top categories
  const { data: topCategories } = useQuery({
    queryKey: ['marketplace-top-categories'],
    queryFn: async () => {
      const { data: services } = await supabase
        .from('vendor_services')
        .select('category')
        .eq('status', 'active');

      const { data: bookings } = await supabase
        .from('vendor_bookings')
        .select('service_id, final_price, vendor_services(category)')
        .eq('status', 'completed');

      // Count services per category
      const categoryCounts: Record<string, number> = {};
      services?.forEach((s) => {
        categoryCounts[s.category] = (categoryCounts[s.category] || 0) + 1;
      });

      // Sum revenue per category
      const categoryRevenue: Record<string, number> = {};
      bookings?.forEach((b) => {
        const cat = (b.vendor_services as any)?.category;
        if (cat) {
          categoryRevenue[cat] = (categoryRevenue[cat] || 0) + (b.final_price || 0);
        }
      });

      // Combine and sort by count
      const categories = Object.entries(categoryCounts)
        .map(([category, count]) => ({
          category,
          count,
          revenue: categoryRevenue[category] || 0,
        }))
        .sort((a, b) => b.count - a.count)
        .slice(0, 4);

      return categories;
    },
  });

  const quickActions = [
    {
      title: 'Browse Public Marketplace',
      description: 'Visit the customer-facing marketplace to discover services',
      href: '/marketplace',
      icon: '🏪',
      primary: true,
    },
    {
      title: 'Vendor Dashboard',
      description: 'Comprehensive vendor management and analytics',
      href: '/marketplace/vendor',
      icon: '🏢',
    },
    {
      title: 'Manage Bookings',
      description: 'View and manage your service bookings',
      href: '/marketplace/bookings',
      icon: '📋',
    },
    {
      title: 'Analytics & Reports',
      description: 'View marketplace performance metrics',
      href: '/marketplace/analytics',
      icon: '📈',
    },
  ];

  const pageActions = [
    {
      label: 'Visit Marketplace',
      action: () => { window.location.href = '/marketplace'; },
      variant: 'primary' as const,
    },
    {
      label: 'Manage Bookings',
      action: () => { window.location.href = '/marketplace/bookings'; },
      variant: 'secondary' as const,
    },
  ];

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'CONFIRMED':
        return 'bg-green-100 text-green-800';
      case 'QUOTE_SENT':
        return 'bg-blue-100 text-blue-800';
      case 'IN_PROGRESS':
        return 'bg-purple-100 text-purple-800';
      case 'PENDING':
        return 'bg-yellow-100 text-yellow-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusText = (status: string) => {
    return status.replace('_', ' ').toLowerCase().replace(/\b\w/g, (l: string) => l.toUpperCase());
  };

  return (
    <div className="px-4 sm:px-6 lg:px-8 py-4 sm:py-6">
      <div className="max-w-7xl mx-auto space-y-6 sm:space-y-8">
        {/* Page Header */}
        <PageHeader
          title="Marketplace"
          subtitle="Discover and book services from verified vendors"
          actions={pageActions}
        />
 
        {/* Welcome Message */}
        {user && (
          <div className="bg-emerald-50 border border-emerald-200 rounded-lg p-3 sm:p-4 text-xs sm:text-sm">
            <p className="text-emerald-800">
              Welcome to the marketplace, <span className="font-semibold">{user.name}</span>! Explore
              services from our verified vendors.
            </p>
          </div>
        )}
 
        {/* Service Overview Metrics */}
        <div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4 sm:gap-6">
            <div className="bg-card rounded-lg border border-border p-4 sm:p-6">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <span className="text-xl sm:text-2xl">🛍️</span>
                </div>
                <div className="ml-3 sm:ml-4">
                  <p className="text-xs sm:text-sm font-medium text-muted-foreground">Total Services</p>
                  <p className="text-xl sm:text-2xl font-bold text-foreground">{metrics?.totalServices || 0}</p>
                </div>
              </div>
            </div>
 
            <div className="bg-card rounded-lg border border-border p-4 sm:p-6">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <span className="text-xl sm:text-2xl">🏪</span>
                </div>
                <div className="ml-3 sm:ml-4">
                  <p className="text-xs sm:text-sm font-medium text-muted-foreground">Active Vendors</p>
                  <p className="text-xl sm:text-2xl font-bold text-primary">{metrics?.activeVendors || 0}</p>
                </div>
              </div>
            </div>
 
            <div className="bg-card rounded-lg border border-border p-4 sm:p-6">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <span className="text-xl sm:text-2xl">⏳</span>
                </div>
                <div className="ml-3 sm:ml-4">
                  <p className="text-xs sm:text-sm font-medium text-muted-foreground">Pending Bookings</p>
                  <p className="text-xl sm:text-2xl font-bold text-amber-500">{metrics?.pendingBookings || 0}</p>
                </div>
              </div>
            </div>
 
            <div className="bg-card rounded-lg border border-border p-4 sm:p-6">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <span className="text-xl sm:text-2xl">✅</span>
                </div>
                <div className="ml-3 sm:ml-4">
                  <p className="text-xs sm:text-sm font-medium text-muted-foreground">Completed Bookings</p>
                  <p className="text-xl sm:text-2xl font-bold text-emerald-500">{metrics?.completedBookings || 0}</p>
                </div>
              </div>
            </div>
 
            <div className="bg-card rounded-lg border border-border p-4 sm:p-6">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <span className="text-xl sm:text-2xl">💰</span>
                </div>
                <div className="ml-3 sm:ml-4">
                  <p className="text-xs sm:text-sm font-medium text-muted-foreground">Total Revenue</p>
                  <p className="text-xl sm:text-2xl font-bold text-violet-500">
                    ${(metrics?.totalRevenue || 0).toLocaleString()}
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
 
        {/* Quick Actions */}
        <div className="space-y-3 sm:space-y-4">
          <h3 className="text-base sm:text-lg font-medium text-foreground">Quick Actions</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4">
            {quickActions.map((action, index) => (
              <Link
                key={index}
                to={action.href}
                className={`block p-4 sm:p-6 rounded-lg border transition-all duration-200 hover:shadow-md ${
                  action.primary
                    ? 'border-primary/20 bg-primary/5 hover:bg-primary/10'
                    : 'border-border bg-card hover:bg-muted'
                }`}
              >
                <div className="flex items-center gap-2.5 sm:gap-3 mb-2 sm:mb-3">
                  <span className="text-xl sm:text-2xl">{action.icon}</span>
                  <h4
                    className={`text-sm sm:text-base font-medium ${
                      action.primary ? 'text-primary' : 'text-foreground'
                    }`}
                  >
                    {action.title}
                  </h4>
                </div>
                <p
                  className={`text-xs sm:text-sm ${
                    action.primary ? 'text-primary' : 'text-muted-foreground'
                  }`}
                >
                  {action.description}
                </p>
              </Link>
            ))}
          </div>
        </div>
 
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 sm:gap-8">
          {/* Recent Bookings */}
          <div className="space-y-3 sm:space-y-4">
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2.5 sm:gap-3">
              <h3 className="text-base sm:text-lg font-medium text-foreground">Recent Bookings</h3>
              <Link
                to="/marketplace/bookings"
                className="text-xs sm:text-sm text-primary hover:text-primary/80 font-medium"
              >
                View all bookings →
              </Link>
            </div>
 
            <div className="bg-card rounded-lg border border-border overflow-hidden">
              <div className="divide-y divide-border">
                {recentBookings && recentBookings.length > 0 ? (
                  recentBookings.map((booking) => (
                    <div key={booking.id} className="p-4 sm:p-5 hover:bg-muted/60">
                      <div className="flex items-center justify-between mb-1.5 sm:mb-2">
                        <h4 className="text-sm font-medium text-foreground">{booking.serviceName}</h4>
                        <span
                          className={`inline-flex px-2 py-1 text-[11px] sm:text-xs font-semibold rounded-full ${getStatusColor(
                            booking.status,
                          )}`}
                        >
                          {getStatusText(booking.status)}
                        </span>
                      </div>
                      <p className="text-xs sm:text-sm text-muted-foreground mb-1">
                        {booking.vendorName}
                      </p>
                      <p className="text-xs sm:text-sm text-muted-foreground mb-1">
                        Event: {booking.eventName}
                      </p>
                      <div className="flex items-center justify-between">
                        <span className="text-xs sm:text-sm text-muted-foreground">
                          {new Date(booking.serviceDate).toLocaleDateString()}
                        </span>
                        <span className="text-sm font-medium text-foreground">
                          ${booking.amount.toLocaleString()}
                        </span>
                      </div>
                    </div>
                  ))
                ) : (
                  <div className="p-4 sm:p-5 text-center text-muted-foreground text-sm">
                    No bookings yet
                  </div>
                )}
              </div>
            </div>
          </div>
 
          {/* Top Categories */}
          <div className="space-y-3 sm:space-y-4">
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2.5 sm:gap-3">
              <h3 className="text-base sm:text-lg font-medium text-foreground">Top Service Categories</h3>
              <Link
                to="/marketplace/services"
                className="text-xs sm:text-sm text-primary hover:text-primary/80 font-medium"
              >
                Browse all services →
              </Link>
            </div>
 
            <div className="bg-card rounded-lg border border-border overflow-hidden">
              <div className="divide-y divide-border">
                {topCategories && topCategories.length > 0 ? (
                  topCategories.map((category, index) => (
                    <div key={category.category} className="p-4 sm:p-5 hover:bg-muted/60">
                      <div className="flex items-center justify-between mb-1.5 sm:mb-2">
                        <h4 className="text-sm font-medium text-foreground">
                          {category.category
                            .replace('_', ' ')
                            .toLowerCase()
                            .replace(/\b\w/g, (l: string) => l.toUpperCase())}
                        </h4>
                        <span className="text-xs sm:text-sm text-muted-foreground">#{index + 1}</span>
                      </div>
                      <div className="flex items-center justify-between">
                        <span className="text-xs sm:text-sm text-muted-foreground">
                          {category.count} services
                        </span>
                        <span className="text-xs sm:text-sm font-medium text-foreground">
                          ${category.revenue.toLocaleString()} revenue
                        </span>
                      </div>
                    </div>
                  ))
                ) : (
                  <div className="p-4 sm:p-5 text-center text-muted-foreground text-sm">
                    No services yet
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
 
        {/* Service Information */}
        <div className="bg-primary/5 rounded-lg p-4 sm:p-6">
          <h3 className="text-base sm:text-lg font-medium text-primary mb-2">About Marketplace Service</h3>
          <p className="text-xs sm:text-sm text-muted-foreground mb-3 sm:mb-4">
            The Marketplace Service connects event organizers with verified vendors offering professional services.
            From venue booking to catering, photography, and technical support - find everything you need for successful
            events.
          </p>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-3 sm:gap-4 text-xs sm:text-sm">
            <div>
              <h4 className="font-medium text-foreground mb-1">Service Discovery</h4>
              <p className="text-muted-foreground">
                Browse and filter services by category, location, and budget to find the perfect match.
              </p>
            </div>
            <div>
              <h4 className="font-medium text-foreground mb-1">Booking Management</h4>
              <p className="text-muted-foreground">
                Request quotes, communicate with vendors, and manage bookings all in one place.
              </p>
            </div>
            <div>
              <h4 className="font-medium text-foreground mb-1">Vendor Network</h4>
              <p className="text-muted-foreground">
                Access a curated network of verified vendors with ratings and reviews from other organizers.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
