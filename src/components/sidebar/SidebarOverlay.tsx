import React from 'react';
import { useSidebar } from '@/components/ui/sidebar';
import { cn } from '@/lib/utils';

interface SidebarOverlayProps {
  className?: string;
}

/**
 * Overlay that appears behind the desktop sidebar when open.
 * Clicking it collapses/closes the sidebar.
 * Only renders on desktop (md+) when sidebar is expanded.
 */
export const SidebarOverlay: React.FC<SidebarOverlayProps> = ({ className }) => {
  const { state, setOpen, isMobile } = useSidebar();

  // Don't render on mobile (Sheet handles its own overlay) or when collapsed
  if (isMobile || state === 'collapsed') {
    return null;
  }

  const handleClick = () => {
    setOpen(false);
  };

  return (
    <div
      onClick={handleClick}
      className={cn(
        'fixed inset-0 z-[5] bg-black/20 backdrop-blur-[1px] transition-opacity duration-200',
        'hidden md:block',
        className
      )}
      aria-hidden="true"
    />
  );
};

export default SidebarOverlay;
