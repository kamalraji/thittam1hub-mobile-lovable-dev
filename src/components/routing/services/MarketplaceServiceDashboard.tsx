import React from 'react';
import { Link } from 'react-router-dom';
import { PageHeader } from '../PageHeader';

/**
 * MarketplaceServiceDashboard provides the service landing page for Marketplace.
 * Features quick actions and service information for discovery.
 */
export const MarketplaceServiceDashboard: React.FC = () => {
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

  return (
    <div className="px-4 sm:px-6 lg:px-8 py-4 sm:py-6">
      <div className="max-w-7xl mx-auto space-y-6 sm:space-y-8">
        {/* Page Header */}
        <PageHeader
          title="Marketplace"
          subtitle="Discover and book services from verified vendors"
          actions={pageActions}
        />

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
