import React from 'react';
import { useNavigate } from 'react-router-dom';
import { LogOut, User, Settings, ChevronUp } from 'lucide-react';
import { useSidebar, SidebarFooter } from '@/components/ui/sidebar';
import { cn } from '@/lib/utils';
import { sidebarStyles } from './sidebarConfig';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';

interface UserInfo {
  id: string;
  email?: string;
  full_name?: string;
  avatar_url?: string;
}

interface SidebarUserFooterProps {
  user: UserInfo | null;
  onLogout?: () => void;
}

/**
 * Sidebar footer with user profile info and quick actions.
 */
export const SidebarUserFooter: React.FC<SidebarUserFooterProps> = ({
  user,
  onLogout,
}) => {
  const { state } = useSidebar();
  const navigate = useNavigate();
  const isCollapsed = state === 'collapsed';

  if (!user) return null;

  const initials = user.full_name
    ? user.full_name
        .split(' ')
        .map((n) => n[0])
        .join('')
        .toUpperCase()
        .slice(0, 2)
    : user.email?.slice(0, 2).toUpperCase() || 'U';

  const displayName = user.full_name || user.email?.split('@')[0] || 'User';

  return (
    <SidebarFooter className="border-t border-sidebar-border p-2">
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <button
            className={cn(
              'flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left transition-all duration-200',
              'hover:bg-muted/70 focus:outline-none focus-visible:ring-2 focus-visible:ring-sidebar-ring',
              isCollapsed && 'justify-center px-2'
            )}
          >
            <Avatar className="h-8 w-8 shrink-0">
              {user.avatar_url && (
                <AvatarImage src={user.avatar_url} alt={displayName} />
              )}
              <AvatarFallback className="bg-primary/10 text-primary text-xs font-semibold">
                {initials}
              </AvatarFallback>
            </Avatar>

            {!isCollapsed && (
              <>
                <div className="flex flex-1 flex-col min-w-0 animate-fade-in">
                  <span className={cn(sidebarStyles.textLabel, 'max-w-[130px]')}>
                    {displayName}
                  </span>
                  {user.email && (
                    <span className={cn(sidebarStyles.textMeta, 'truncate max-w-[130px]')}>
                      {user.email}
                    </span>
                  )}
                </div>
                <ChevronUp className="h-4 w-4 text-muted-foreground shrink-0" />
              </>
            )}
          </button>
        </DropdownMenuTrigger>

        <DropdownMenuContent
          align="end"
          side="top"
          className="w-56"
          sideOffset={8}
        >
          <div className="px-2 py-1.5">
            <p className="text-sm font-medium">{displayName}</p>
            {user.email && (
              <p className="text-xs text-muted-foreground truncate">{user.email}</p>
            )}
          </div>
          <DropdownMenuSeparator />
          <DropdownMenuItem onClick={() => navigate('/profile')}>
            <User className="mr-2 h-4 w-4" />
            Profile
          </DropdownMenuItem>
          <DropdownMenuItem onClick={() => navigate('/settings')}>
            <Settings className="mr-2 h-4 w-4" />
            Settings
          </DropdownMenuItem>
          {onLogout && (
            <>
              <DropdownMenuSeparator />
              <DropdownMenuItem
                onClick={onLogout}
                className="text-destructive focus:text-destructive"
              >
                <LogOut className="mr-2 h-4 w-4" />
                Log out
              </DropdownMenuItem>
            </>
          )}
        </DropdownMenuContent>
      </DropdownMenu>
    </SidebarFooter>
  );
};

export default SidebarUserFooter;
