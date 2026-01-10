import React, { useState } from 'react';
import { Workspace } from '@/types';
import { cn } from '@/lib/utils';
import { getCommitteeConfig, getCommitteeColors } from '@/lib/committeeConfig';
import { CommitteeActionDialog } from './committee-actions/CommitteeActionDialog';
import { actionConfigs } from './committee-actions/actionConfigs';
import {
  ChevronDown,
  ChevronRight,
  // Volunteers Committee
  Calendar,
  Send,
  UserCheck,
  Users,
  GraduationCap,
  Award,
  ClipboardList,
  // Finance Committee
  Receipt,
  FileText,
  CheckCircle,
  DollarSign,
  Download,
  // Registration Committee
  Scan,
  UserPlus,
  Mail,
  ListChecks,
  // Catering Committee
  Utensils,
  Package,
  ClipboardCheck,
  // Logistics Committee
  Truck,
  Map,
  Wrench,
  // Facility Committee
  Building,
  Shield,
  AlertTriangle,
  // Marketing Committee
  Megaphone,
  BarChart3,
  Zap,
  // Communication Committee
  MessageSquare,
  Newspaper,
  BellRing,
  // Sponsorship Committee
  Handshake,
  FileBarChart,
  Target,
  // Social Media Committee
  Share2,
  Hash,
  TrendingUp,
  // Content Committee
  Layers,
  Upload,
  Eye,
  // Speaker Liaison Committee
  Mic,
  Plane,
  FileCheck,
  // Judge Committee
  Scale,
  Star,
  // Media Committee
  Camera,
  Image,
  // Event Committee
  Clock,
  Crown,
  Activity,
  // Technical Committee
  Monitor,
  Headphones,
  Settings,
  // IT Committee
  Key,
  Server,
  AlertCircle,
} from 'lucide-react';

interface CommitteeAction {
  id: string;
  label: string;
  icon: React.ElementType;
  color: string;
}

interface CommitteeActionsMenuProps {
  workspace: Workspace;
  isCollapsed: boolean;
}

// Committee-specific action sets
const committeeActions: Record<string, CommitteeAction[]> = {
  volunteers: [
    { id: 'assign-shifts', label: 'Assign Shifts', icon: Calendar, color: 'text-pink-500' },
    { id: 'send-brief', label: 'Send Brief', icon: Send, color: 'text-rose-500' },
    { id: 'check-in', label: 'Check-in Volunteer', icon: UserCheck, color: 'text-emerald-500' },
    { id: 'create-team', label: 'Create Team', icon: Users, color: 'text-blue-500' },
    { id: 'training-status', label: 'Training Status', icon: GraduationCap, color: 'text-amber-500' },
    { id: 'performance-review', label: 'Performance Review', icon: Award, color: 'text-yellow-500' },
  ],
  finance: [
    { id: 'record-expense', label: 'Record Expense', icon: Receipt, color: 'text-green-500' },
    { id: 'generate-report', label: 'Generate Report', icon: FileText, color: 'text-blue-500' },
    { id: 'approve-request', label: 'Approve Request', icon: CheckCircle, color: 'text-amber-500' },
    { id: 'view-budget', label: 'View Budget', icon: DollarSign, color: 'text-emerald-500' },
    { id: 'export-data', label: 'Export Data', icon: Download, color: 'text-purple-500' },
  ],
  registration: [
    { id: 'scan-checkin', label: 'Scan Check-in', icon: Scan, color: 'text-teal-500' },
    { id: 'add-attendee', label: 'Add Attendee', icon: UserPlus, color: 'text-blue-500' },
    { id: 'export-list', label: 'Export List', icon: Download, color: 'text-purple-500' },
    { id: 'send-reminders', label: 'Send Reminders', icon: Mail, color: 'text-amber-500' },
    { id: 'view-waitlist', label: 'View Waitlist', icon: ListChecks, color: 'text-cyan-500' },
  ],
  catering: [
    { id: 'update-menu', label: 'Update Menu', icon: Utensils, color: 'text-orange-500' },
    { id: 'check-inventory', label: 'Check Inventory', icon: Package, color: 'text-amber-500' },
    { id: 'dietary-report', label: 'Dietary Report', icon: ClipboardCheck, color: 'text-emerald-500' },
    { id: 'confirm-headcount', label: 'Confirm Headcount', icon: Users, color: 'text-blue-500' },
  ],
  logistics: [
    { id: 'track-shipments', label: 'Track Shipments', icon: Truck, color: 'text-green-500' },
    { id: 'update-layout', label: 'Update Layout', icon: Map, color: 'text-blue-500' },
    { id: 'equipment-status', label: 'Equipment Status', icon: Wrench, color: 'text-amber-500' },
    { id: 'create-manifest', label: 'Create Manifest', icon: ClipboardList, color: 'text-purple-500' },
  ],
  facility: [
    { id: 'safety-check', label: 'Safety Check', icon: Shield, color: 'text-red-500' },
    { id: 'venue-walkthrough', label: 'Venue Walkthrough', icon: Building, color: 'text-slate-500' },
    { id: 'report-issue', label: 'Report Issue', icon: AlertTriangle, color: 'text-amber-500' },
    { id: 'room-status', label: 'Room Status', icon: Map, color: 'text-blue-500' },
  ],
  marketing: [
    { id: 'schedule-post', label: 'Schedule Post', icon: Megaphone, color: 'text-pink-500' },
    { id: 'view-analytics', label: 'View Analytics', icon: BarChart3, color: 'text-blue-500' },
    { id: 'create-campaign', label: 'Create Campaign', icon: Zap, color: 'text-amber-500' },
    { id: 'ab-test', label: 'A/B Test', icon: Target, color: 'text-purple-500' },
  ],
  communication: [
    { id: 'send-update', label: 'Send Update', icon: MessageSquare, color: 'text-cyan-500' },
    { id: 'draft-press', label: 'Draft Press Release', icon: Newspaper, color: 'text-blue-500' },
    { id: 'email-blast', label: 'Email Blast', icon: Mail, color: 'text-purple-500' },
    { id: 'stakeholder-report', label: 'Stakeholder Report', icon: FileText, color: 'text-emerald-500' },
  ],
  sponsorship: [
    { id: 'add-sponsor', label: 'Add Sponsor', icon: Handshake, color: 'text-amber-500' },
    { id: 'send-proposal', label: 'Send Proposal', icon: FileText, color: 'text-blue-500' },
    { id: 'track-deliverables', label: 'Track Deliverables', icon: ClipboardCheck, color: 'text-emerald-500' },
    { id: 'revenue-report', label: 'Revenue Report', icon: FileBarChart, color: 'text-green-500' },
  ],
  social_media: [
    { id: 'schedule-content', label: 'Schedule Content', icon: Share2, color: 'text-indigo-500' },
    { id: 'monitor-hashtags', label: 'Monitor Hashtags', icon: Hash, color: 'text-blue-500' },
    { id: 'engagement-report', label: 'Engagement Report', icon: TrendingUp, color: 'text-emerald-500' },
    { id: 'post-now', label: 'Post Now', icon: Send, color: 'text-pink-500' },
  ],
  content: [
    { id: 'review-content', label: 'Review Content', icon: Eye, color: 'text-purple-500' },
    { id: 'create-template', label: 'Create Template', icon: Layers, color: 'text-blue-500' },
    { id: 'assign-reviewer', label: 'Assign Reviewer', icon: UserPlus, color: 'text-amber-500' },
    { id: 'publish', label: 'Publish', icon: Upload, color: 'text-emerald-500' },
  ],
  speaker_liaison: [
    { id: 'invite-speaker', label: 'Invite Speaker', icon: Mic, color: 'text-rose-500' },
    { id: 'schedule-rehearsal', label: 'Schedule Rehearsal', icon: Calendar, color: 'text-blue-500' },
    { id: 'travel-coordination', label: 'Travel Coordination', icon: Plane, color: 'text-cyan-500' },
    { id: 'bio-collection', label: 'Bio Collection', icon: FileCheck, color: 'text-purple-500' },
  ],
  judge: [
    { id: 'assign-judges', label: 'Assign Judges', icon: Scale, color: 'text-emerald-500' },
    { id: 'setup-rubrics', label: 'Setup Rubrics', icon: ClipboardList, color: 'text-blue-500' },
    { id: 'view-scores', label: 'View Scores', icon: Star, color: 'text-amber-500' },
    { id: 'export-results', label: 'Export Results', icon: Download, color: 'text-purple-500' },
  ],
  media: [
    { id: 'upload-media', label: 'Upload Media', icon: Upload, color: 'text-fuchsia-500' },
    { id: 'create-shot-list', label: 'Create Shot List', icon: Camera, color: 'text-blue-500' },
    { id: 'gallery-review', label: 'Gallery Review', icon: Image, color: 'text-purple-500' },
    { id: 'export-assets', label: 'Export Assets', icon: Download, color: 'text-emerald-500' },
  ],
  event: [
    { id: 'update-schedule', label: 'Update Schedule', icon: Clock, color: 'text-blue-500' },
    { id: 'brief-teams', label: 'Brief Teams', icon: BellRing, color: 'text-amber-500' },
    { id: 'vip-tracker', label: 'VIP Tracker', icon: Crown, color: 'text-purple-500' },
    { id: 'run-of-show', label: 'Run of Show', icon: Activity, color: 'text-emerald-500' },
  ],
  technical: [
    { id: 'test-equipment', label: 'Test Equipment', icon: Monitor, color: 'text-sky-500' },
    { id: 'update-runsheet', label: 'Update Runsheet', icon: ClipboardList, color: 'text-blue-500' },
    { id: 'tech-check', label: 'Tech Check', icon: Settings, color: 'text-amber-500' },
    { id: 'issue-report', label: 'Issue Report', icon: AlertCircle, color: 'text-red-500' },
  ],
  it: [
    { id: 'check-systems', label: 'Check Systems', icon: Server, color: 'text-violet-500' },
    { id: 'update-credentials', label: 'Update Credentials', icon: Key, color: 'text-amber-500' },
    { id: 'service-status', label: 'Service Status', icon: Activity, color: 'text-emerald-500' },
    { id: 'ticket-queue', label: 'Ticket Queue', icon: Headphones, color: 'text-blue-500' },
  ],
};

// Fallback generic actions
const genericActions: CommitteeAction[] = [
  { id: 'view-tasks', label: 'View Tasks', icon: ClipboardList, color: 'text-blue-500' },
  { id: 'manage-team', label: 'Manage Team', icon: Users, color: 'text-emerald-500' },
  { id: 'send-update', label: 'Send Update', icon: MessageSquare, color: 'text-purple-500' },
  { id: 'create-report', label: 'Create Report', icon: FileText, color: 'text-amber-500' },
];

// Detect committee type from workspace name
function detectCommitteeType(workspaceName: string): string {
  const name = workspaceName.toLowerCase().replace(/\s+committee$/i, '').replace(/\s+/g, '_').trim();
  
  // Direct match first
  if (committeeActions[name]) return name;
  
  // Fuzzy matching for common variations
  if (name.includes('volunteer')) return 'volunteers';
  if (name.includes('finance') || name.includes('budget')) return 'finance';
  if (name.includes('registr') || name.includes('check-in') || name.includes('checkin')) return 'registration';
  if (name.includes('cater') || name.includes('food')) return 'catering';
  if (name.includes('logist') || name.includes('transport')) return 'logistics';
  if (name.includes('facilit') || name.includes('venue')) return 'facility';
  if (name.includes('market') || name.includes('promo')) return 'marketing';
  if (name.includes('communi') || name.includes('pr')) return 'communication';
  if (name.includes('sponsor') || name.includes('partner')) return 'sponsorship';
  if (name.includes('social') || name.includes('media')) return 'social_media';
  if (name.includes('content') || name.includes('editorial')) return 'content';
  if (name.includes('speaker') || name.includes('liaison')) return 'speaker_liaison';
  if (name.includes('judge') || name.includes('judging')) return 'judge';
  if (name.includes('media') || name.includes('photo') || name.includes('video')) return 'media';
  if (name.includes('event') || name.includes('program')) return 'event';
  if (name.includes('tech') || name.includes('av') || name.includes('audio')) return 'technical';
  if (name.includes('it') || name.includes('infra')) return 'it';
  
  return 'generic';
}

export function CommitteeActionsMenu({ workspace, isCollapsed }: CommitteeActionsMenuProps) {
  const [isExpanded, setIsExpanded] = useState(false);
  const [activeAction, setActiveAction] = useState<{ type: string; id: string } | null>(null);
  
  const committeeType = detectCommitteeType(workspace.name);
  const actions = committeeActions[committeeType] || genericActions;
  
  // Get committee config for color theming
  const config = getCommitteeConfig(workspace.name);
  const colors = config ? getCommitteeColors(config.color) : null;
  const headerColor = colors?.text || 'text-amber-500';

  const handleAction = (actionId: string) => {
    setActiveAction({ type: committeeType, id: actionId });
  };

  const handleSubmit = async (_data: Record<string, string>) => {
    // Simulate API call
    await new Promise(resolve => setTimeout(resolve, 1000));
    // In a real app, you'd save the data to the database here
  };

  const activeConfig = activeAction 
    ? actionConfigs[activeAction.type]?.[activeAction.id] 
    : null;

  if (isCollapsed) {
    return null; // Don't render in collapsed state
  }

  return (
    <>
      <div className="mt-1">
        {/* Collapsible Header */}
        <button
          onClick={() => setIsExpanded(!isExpanded)}
          className="w-full flex items-center justify-between px-3 py-2 text-xs font-medium text-muted-foreground hover:text-foreground transition-colors rounded-lg hover:bg-muted/30"
        >
          <span className={cn('uppercase tracking-wider', headerColor)}>
            Committee Actions
          </span>
          {isExpanded ? (
            <ChevronDown className="h-3.5 w-3.5" />
          ) : (
            <ChevronRight className="h-3.5 w-3.5" />
          )}
        </button>

        {/* Expanded Actions */}
        {isExpanded && (
          <div className="mt-1 space-y-0.5 px-1">
            {actions.map((action) => {
              const Icon = action.icon;
              return (
                <button
                  key={action.id}
                  onClick={() => handleAction(action.id)}
                  className="w-full flex items-center gap-2.5 px-3 py-2 text-xs rounded-lg hover:bg-muted/50 transition-colors text-left group"
                >
                  <Icon className={cn('h-3.5 w-3.5 flex-shrink-0', action.color)} />
                  <span className="truncate text-foreground/80 group-hover:text-foreground">
                    {action.label}
                  </span>
                </button>
              );
            })}
          </div>
        )}
      </div>

      {/* Action Dialog */}
      {activeConfig && (
        <CommitteeActionDialog
          open={!!activeAction}
          onOpenChange={(open) => !open && setActiveAction(null)}
          config={activeConfig}
          onSubmit={handleSubmit}
        />
      )}
    </>
  );
}