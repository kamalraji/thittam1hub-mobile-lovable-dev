/**
 * Modern Event Card Component
 * A globally reusable, responsive, and stylish event card with animations
 */

import { Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import { 
  Calendar, Users, Clock, ArrowRight, Zap, Eye, Pencil, FolderOpen,
  Globe, MapPin, Code, GraduationCap, Presentation, Mic, Briefcase, 
  Trophy, Video, Award, LayoutGrid 
} from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { EventMode, EventStatus, EventCategory } from '@/types';

export interface ModernEventCardProps {
  id: string;
  name: string;
  description?: string;
  startDate: string;
  endDate: string;
  status: EventStatus | string;
  mode?: EventMode | string;
  category?: EventCategory | string;
  registrationCount?: number;
  capacity?: number | null;
  landingPageUrl?: string;
  organizationSlug?: string;
  variant?: 'participant' | 'organizer';
  index?: number;
}

const categoryConfig: Record<string, { icon: typeof Code; label: string; color: string }> = {
  HACKATHON: { icon: Code, label: 'Hackathon', color: 'bg-violet-500/10 text-violet-600 dark:text-violet-400 border-violet-500/20' },
  BOOTCAMP: { icon: GraduationCap, label: 'Bootcamp', color: 'bg-blue-500/10 text-blue-600 dark:text-blue-400 border-blue-500/20' },
  WORKSHOP: { icon: Presentation, label: 'Workshop', color: 'bg-amber-500/10 text-amber-600 dark:text-amber-400 border-amber-500/20' },
  CONFERENCE: { icon: Mic, label: 'Conference', color: 'bg-rose-500/10 text-rose-600 dark:text-rose-400 border-rose-500/20' },
  MEETUP: { icon: Users, label: 'Meetup', color: 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/20' },
  STARTUP_PITCH: { icon: Briefcase, label: 'Startup Pitch', color: 'bg-orange-500/10 text-orange-600 dark:text-orange-400 border-orange-500/20' },
  HIRING_CHALLENGE: { icon: Trophy, label: 'Hiring Challenge', color: 'bg-cyan-500/10 text-cyan-600 dark:text-cyan-400 border-cyan-500/20' },
  WEBINAR: { icon: Video, label: 'Webinar', color: 'bg-pink-500/10 text-pink-600 dark:text-pink-400 border-pink-500/20' },
  COMPETITION: { icon: Award, label: 'Competition', color: 'bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 border-indigo-500/20' },
  OTHER: { icon: LayoutGrid, label: 'Other', color: 'bg-muted text-muted-foreground border-border' },
};

const getModeIcon = (mode?: string) => {
  switch (mode) {
    case 'ONLINE': return <Globe className="h-3.5 w-3.5" />;
    case 'OFFLINE': return <MapPin className="h-3.5 w-3.5" />;
    case 'HYBRID': return <Users className="h-3.5 w-3.5" />;
    default: return <Calendar className="h-3.5 w-3.5" />;
  }
};

const getModeLabel = (mode?: string) => {
  switch (mode) {
    case 'ONLINE': return 'Online';
    case 'OFFLINE': return 'In Person';
    case 'HYBRID': return 'Hybrid';
    default: return '';
  }
};

const getStatusConfig = (status: string) => {
  switch (status) {
    case 'ONGOING': 
      return { label: 'Live Now', variant: 'default' as const, icon: <Zap className="h-3 w-3" />, isLive: true };
    case 'PUBLISHED': 
      return { label: 'Upcoming', variant: 'secondary' as const, icon: <Clock className="h-3 w-3" />, isLive: false };
    case 'DRAFT': 
      return { label: 'Draft', variant: 'outline' as const, icon: null, isLive: false };
    case 'COMPLETED': 
      return { label: 'Completed', variant: 'outline' as const, icon: null, isLive: false };
    default: 
      return { label: status, variant: 'secondary' as const, icon: null, isLive: false };
  }
};

const formatEventDate = (dateStr: string) => {
  const date = new Date(dateStr);
  return {
    day: date.getDate(),
    month: date.toLocaleDateString('en-US', { month: 'short' }),
    year: date.getFullYear(),
    time: date.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', hour12: true }),
    weekday: date.toLocaleDateString('en-US', { weekday: 'short' })
  };
};

export function ModernEventCard({
  id,
  name,
  description,
  startDate,
  status,
  mode,
  category,
  registrationCount,
  capacity,
  landingPageUrl,
  organizationSlug,
  variant = 'participant',
  index = 0,
}: ModernEventCardProps) {
  const parsedStartDate = formatEventDate(startDate);
  const statusConfig = getStatusConfig(status);
  const isLive = statusConfig.isLive;
  const isDraft = status === 'DRAFT';
  const isPublished = status === 'PUBLISHED';
  
  const categoryInfo = category && categoryConfig[category] ? categoryConfig[category] : null;
  const CategoryIcon = categoryInfo?.icon;

  const cardContent = (
    <>
      {/* Live indicator bar */}
      {isLive && (
        <div className="h-1.5 bg-gradient-to-r from-red-500 via-orange-500 to-red-500 animate-pulse" />
      )}
      
      <div className="p-4 sm:p-5 flex flex-col h-full">
        {/* Header with date badge */}
        <div className="flex items-start gap-3 sm:gap-4 mb-3 sm:mb-4">
          <div className={`flex-shrink-0 w-14 sm:w-16 text-center rounded-xl p-2 sm:p-2.5 transition-all duration-300 ${
            isLive 
              ? 'bg-gradient-to-br from-red-500/20 to-orange-500/20 border border-red-500/30 shadow-lg shadow-red-500/10' 
              : 'bg-primary/10 group-hover:bg-primary/15 group-hover:scale-105'
          }`}>
            <span className="block text-[10px] font-medium text-muted-foreground uppercase tracking-wide">
              {parsedStartDate.weekday}
            </span>
            <span className={`block text-xl sm:text-2xl font-bold ${isLive ? 'text-red-500' : 'text-primary'}`}>
              {parsedStartDate.day}
            </span>
            <span className={`block text-[10px] sm:text-xs font-semibold uppercase ${isLive ? 'text-red-500/80' : 'text-primary/80'}`}>
              {parsedStartDate.month}
            </span>
          </div>
          
          <div className="flex-1 min-w-0">
            {/* Status Badge */}
            <div className="flex flex-wrap items-center gap-2 mb-2">
              <Badge 
                variant={statusConfig.variant}
                className={`text-xs ${
                  isLive 
                    ? 'animate-pulse bg-red-500/10 text-red-600 dark:text-red-400 border-red-500/30' 
                    : isDraft 
                      ? 'bg-amber-500/10 text-amber-600 dark:text-amber-400 border-amber-500/30'
                      : isPublished
                        ? 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/30'
                        : ''
                }`}
              >
                {statusConfig.icon && <span className="mr-1">{statusConfig.icon}</span>}
                {statusConfig.label}
              </Badge>
              
              {/* Mode Badge */}
              {mode && (
                <Badge variant="outline" className="text-xs bg-background/50">
                  {getModeIcon(mode)}
                  <span className="ml-1 hidden xs:inline">{getModeLabel(mode)}</span>
                </Badge>
              )}
            </div>
            
            {/* Event Title */}
            <h3 className="text-sm sm:text-base font-semibold text-foreground line-clamp-2 group-hover:text-primary transition-colors leading-tight">
              {name}
            </h3>
          </div>
        </div>
        
        {/* Category Badge */}
        {categoryInfo && category !== 'OTHER' && CategoryIcon && (
          <div className="mb-3">
            <Badge variant="outline" className={`text-xs ${categoryInfo.color}`}>
              <CategoryIcon className="h-3 w-3 mr-1" />
              {categoryInfo.label}
            </Badge>
          </div>
        )}
        
        {/* Description */}
        {description && (
          <p className="text-xs sm:text-sm text-muted-foreground line-clamp-2 mb-4 flex-grow">
            {description}
          </p>
        )}
        
        {/* Stats Row - Organizer variant */}
        {variant === 'organizer' && (
          <div className="flex items-center gap-4 text-xs text-muted-foreground mb-4">
            <span className="inline-flex items-center gap-1.5">
              <Users className="h-3.5 w-3.5" />
              <span className="font-medium text-foreground">{registrationCount ?? 0}</span>
              {capacity && <span>/ {capacity}</span>}
            </span>
            <span className="inline-flex items-center gap-1.5">
              <Clock className="h-3.5 w-3.5" />
              <span>{parsedStartDate.time}</span>
            </span>
          </div>
        )}
        
        {/* Participant variant footer */}
        {variant === 'participant' && (
          <div className="flex items-center justify-between mt-auto pt-3 border-t border-border/50">
            <span className="text-xs text-muted-foreground">
              {parsedStartDate.time}
            </span>
            <span className="inline-flex items-center gap-1.5 text-xs sm:text-sm font-medium text-primary opacity-0 translate-x-2 group-hover:opacity-100 group-hover:translate-x-0 transition-all duration-300">
              View details
              <ArrowRight className="h-3.5 w-3.5" />
            </span>
          </div>
        )}
        
        {/* Organizer variant actions */}
        {variant === 'organizer' && organizationSlug && (
          <div className="flex items-center gap-2 pt-3 border-t border-border/50 mt-auto">
            <Button asChild variant="ghost" size="sm" className="flex-1 h-8 text-xs">
              <Link to={`/${organizationSlug}/eventmanagement/${id}`}>
                <Eye className="h-3.5 w-3.5 mr-1" />
                View
              </Link>
            </Button>
            <Button asChild variant="ghost" size="sm" className="flex-1 h-8 text-xs">
              <Link to={`/${organizationSlug}/eventmanagement/${id}/edit`}>
                <Pencil className="h-3.5 w-3.5 mr-1" />
                Edit
              </Link>
            </Button>
            <Button asChild variant="outline" size="sm" className="flex-1 h-8 text-xs group/btn">
              <Link to={`/${organizationSlug}/workspaces?eventId=${id}`}>
                <FolderOpen className="h-3.5 w-3.5 mr-1" />
                Workspace
                <ArrowRight className="h-3 w-3 ml-1 opacity-0 -translate-x-1 group-hover/btn:opacity-100 group-hover/btn:translate-x-0 transition-all" />
              </Link>
            </Button>
          </div>
        )}
      </div>
    </>
  );

  const cardClasses = "group relative bg-card rounded-2xl border-2 border-border/50 overflow-hidden hover:border-primary/40 hover:shadow-2xl hover:shadow-primary/5 transition-all duration-300 h-full flex flex-col";

  if (variant === 'participant') {
    return (
      <motion.div
        initial={{ opacity: 0, y: 20, scale: 0.96 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ duration: 0.3, delay: index * 0.05 }}
      >
        <Link
          to={landingPageUrl || `/events/${id}`}
          className={cardClasses}
        >
          {cardContent}
        </Link>
      </motion.div>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3, delay: index * 0.05 }}
      className={cardClasses}
    >
      {cardContent}
    </motion.div>
  );
}

export default ModernEventCard;
