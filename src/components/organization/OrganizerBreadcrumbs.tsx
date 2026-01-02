import { Link, useLocation } from 'react-router-dom';

interface OrganizerBreadcrumbsProps {
  current: 'dashboard' | 'event-management';
}

/**
 * Shared breadcrumbs for organizer-scoped console views.
 *
 * Keeps the navigation trail consistent between:
 * - /:orgSlug/dashboard (OrganizerDashboard)
 * - /:orgSlug/eventmanagement (EventServiceDashboard)
 * - /dashboard/eventmanagement (global organizer console)
 */
export const OrganizerBreadcrumbs: React.FC<OrganizerBreadcrumbsProps> = ({ current }) => {
  const location = useLocation();
  const segments = location.pathname.split('/').filter(Boolean);

  // Detect whether we're in global "/dashboard/..." or org-scoped "/:orgSlug/..." context
  const isGlobalDashboardContext = segments[0] === 'dashboard';

  const dashboardPath = isGlobalDashboardContext
    ? '/dashboard'
    : segments[0]
      ? `/${segments[0]}/dashboard`
      : '/dashboard';

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-2 text-xs sm:text-sm text-muted-foreground flex items-center gap-1">
      <span className="text-muted-foreground/70">Home</span>
      <span>/</span>
      {current === 'dashboard' ? (
        <span className="text-foreground font-medium">Organizer Dashboard</span>
      ) : (
        <>
          <Link
            to={dashboardPath}
            className="text-foreground/80 hover:text-foreground font-medium transition-colors"
          >
            Organizer Dashboard
          </Link>
          <span>/</span>
          <span className="text-foreground font-medium">Event Management</span>
        </>
      )}
    </div>
  );
};
