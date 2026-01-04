import React, { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { MobileHeader } from './MobileHeader';
import { MobileBottomNav } from './MobileBottomNav';
import { MobileFAB } from './MobileFAB';
import { MobileQuickActionsSheet } from './MobileQuickActionsSheet';
import { MobileHomeView } from './views/MobileHomeView';
import { MobileEventsView } from './views/MobileEventsView';
import { MobileEmailView } from './views/MobileEmailView';
import { MobileAnalyticsView } from './views/MobileAnalyticsView';
import { MobileSearchView } from './views/MobileSearchView';

export type MobileTab = 'home' | 'events' | 'email' | 'analytics' | 'search';

interface MobileAppShellProps {
  organization: {
    id: string;
    name: string;
    slug: string;
    logo_url?: string | null;
  };
  user: {
    id: string;
    name?: string;
    email?: string;
    avatarUrl?: string;
  };
  children?: React.ReactNode;
}

export const MobileAppShell: React.FC<MobileAppShellProps> = ({
  organization,
  user,
  children,
}) => {
  const navigate = useNavigate();
  const location = useLocation();
  const [activeTab, setActiveTab] = useState<MobileTab>('home');
  const [isQuickActionsOpen, setIsQuickActionsOpen] = useState(false);

  // Check if we're on a detail page (workspace, event detail, etc.)
  const isDetailPage = 
    location.pathname.includes('/workspaces/') && location.pathname.split('/').length > 4 ||
    location.pathname.includes('/eventmanagement/') && location.pathname.split('/').length > 4;

  // If we're on a detail page, render the children (detail view) with back navigation
  if (isDetailPage && children) {
    return (
      <div className="min-h-screen bg-background flex flex-col">
        {children}
      </div>
    );
  }

  const handleTabChange = (tab: MobileTab) => {
    setActiveTab(tab);
  };

  const handleFABPress = () => {
    setIsQuickActionsOpen(true);
  };

  const handleQuickAction = (action: string) => {
    setIsQuickActionsOpen(false);
    switch (action) {
      case 'create-event':
        navigate(`/${organization.slug}/eventmanagement/create`);
        break;
      case 'create-task':
        // Navigate to tasks or open task modal
        break;
      case 'invite-member':
        navigate(`/${organization.slug}/team?tab=invite`);
        break;
      case 'view-analytics':
        setActiveTab('analytics');
        break;
      case 'settings':
        navigate(`/${organization.slug}/settings`);
        break;
      default:
        break;
    }
  };

  const renderContent = () => {
    switch (activeTab) {
      case 'home':
        return <MobileHomeView organization={organization} user={user} />;
      case 'events':
        return <MobileEventsView organization={organization} />;
      case 'email':
        return <MobileEmailView />;
      case 'analytics':
        return <MobileAnalyticsView organization={organization} />;
      case 'search':
        return <MobileSearchView organization={organization} />;
      default:
        return <MobileHomeView organization={organization} user={user} />;
    }
  };

  return (
    <div className="min-h-screen bg-background flex flex-col">
      {/* Fixed Header */}
      <MobileHeader 
        organization={organization} 
        user={user} 
      />

      {/* Scrollable Content Area */}
      <main className="flex-1 overflow-y-auto pt-16 pb-20">
        {renderContent()}
      </main>

      {/* Floating Action Button */}
      <MobileFAB onPress={handleFABPress} />

      {/* Fixed Bottom Navigation */}
      <MobileBottomNav 
        activeTab={activeTab} 
        onTabChange={handleTabChange} 
      />

      {/* Quick Actions Bottom Sheet */}
      <MobileQuickActionsSheet
        isOpen={isQuickActionsOpen}
        onClose={() => setIsQuickActionsOpen(false)}
        onAction={handleQuickAction}
        organization={organization}
      />
    </div>
  );
};
