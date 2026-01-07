import React, { useEffect, useState } from 'react';
import { Routes, Route, Navigate, useParams, useLocation, useSearchParams, useNavigate } from 'react-router-dom';
import { WorkspaceServiceDashboard } from './WorkspaceServiceDashboard';
import { WorkspaceListPage } from './WorkspaceListPage';
import { WorkspaceDetailPage } from './WorkspaceDetailPage';
import { WorkspaceCreatePage } from './WorkspaceCreatePage';
import { OrgWorkspacePage } from '@/components/organization/OrgWorkspacePage';
import { OrgWorkspaceListPage } from '@/components/organization/OrgWorkspaceListPage';
import { WorkspaceSettingsPage } from '@/components/workspace/WorkspaceSettingsPage';
import { supabase } from '@/integrations/supabase/client';
import { buildWorkspaceUrl } from '@/lib/workspaceNavigation';

/**
 * LegacyWorkspaceRedirect - Redirects legacy /:eventId/:workspaceId URLs to new type-based URLs
 */
const LegacyWorkspaceRedirect: React.FC = () => {
  const { orgSlug, eventId, workspaceId } = useParams<{ orgSlug: string; eventId: string; workspaceId: string }>();
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const redirectToNewUrl = async () => {
      if (!orgSlug || !eventId || !workspaceId) {
        navigate('/console/workspaces', { replace: true });
        return;
      }

      // Check if workspaceId is actually a type path (root, department, committee, team)
      if (['root', 'department', 'committee', 'team'].includes(workspaceId)) {
        setIsLoading(false);
        return; // Not a legacy URL, let normal routing handle it
      }

      try {
        // Fetch workspace data to get type and name
        const { data: workspace, error } = await supabase
          .from('workspaces')
          .select('id, name, workspace_type')
          .eq('id', workspaceId)
          .single();

        if (error || !workspace) {
          console.error('Workspace not found for redirect:', workspaceId);
          navigate(`/${orgSlug}/workspaces/${eventId}`, { replace: true });
          return;
        }

        // Build new URL with type path
        const tab = searchParams.get('tab');
        const taskId = searchParams.get('taskId');
        const sectionId = searchParams.get('sectionid');
        
        const newUrl = buildWorkspaceUrl({
          orgSlug,
          eventId,
          workspaceId: workspace.id,
          workspaceType: workspace.workspace_type || 'ROOT',
          workspaceName: workspace.name,
          tab: tab || undefined,
          taskId: taskId || undefined,
          sectionId: sectionId || undefined,
        });

        navigate(newUrl, { replace: true });
      } catch (err) {
        console.error('Error redirecting legacy workspace URL:', err);
        navigate(`/${orgSlug}/workspaces/${eventId}`, { replace: true });
      }
    };

    redirectToNewUrl();
  }, [orgSlug, eventId, workspaceId, searchParams, navigate]);

  if (isLoading) {
    return null; // Brief loading state during redirect
  }

  return <WorkspaceDetailPage />;
};

/**
 * WorkspaceService component provides the main routing structure for the Workspace Management Service.
 * 
 * Routes:
 * - /:orgSlug/workspaces - Organization workspace list (grouped by ownership)
 * - /:orgSlug/workspaces/:eventId - Event-specific workspace portal
 * - /:orgSlug/workspaces/:eventId/root?workspaceId=xxx - Root workspace (L1)
 * - /:orgSlug/workspaces/:eventId/department?name=xxx&workspaceId=xxx - Department workspace (L2)
 * - /:orgSlug/workspaces/:eventId/committee?name=xxx&workspaceId=xxx - Committee workspace (L3)
 * - /:orgSlug/workspaces/:eventId/team?name=xxx&workspaceId=xxx - Team workspace (L4)
 */

const WorkspaceIndexRoute: React.FC = () => {
  const { orgSlug, eventId } = useParams<{ orgSlug?: string; eventId?: string }>();
  const location = useLocation();
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  
  const pathParts = location.pathname.split('/').filter(Boolean);
  const isOrgContext = pathParts.length >= 1 && pathParts[0] !== 'dashboard' && pathParts[0] !== 'console';
  const workspaceId = searchParams.get('workspaceId');

  // Redirect old URLs with workspaceId query param to new type-based URLs
  useEffect(() => {
    const redirectToNewUrl = async () => {
      if (!isOrgContext || !eventId || !workspaceId || !orgSlug) return;

      try {
        const { data: workspace, error } = await supabase
          .from('workspaces')
          .select('id, name, workspace_type')
          .eq('id', workspaceId)
          .single();

        if (error || !workspace) return;

        const tab = searchParams.get('tab');
        const taskId = searchParams.get('taskId');
        const sectionId = searchParams.get('sectionid');

        const newUrl = buildWorkspaceUrl({
          orgSlug,
          eventId,
          workspaceId: workspace.id,
          workspaceType: workspace.workspace_type || 'ROOT',
          workspaceName: workspace.name,
          tab: tab || undefined,
          taskId: taskId || undefined,
          sectionId: sectionId || undefined,
        });

        navigate(newUrl, { replace: true });
      } catch (err) {
        console.error('Error redirecting to new workspace URL:', err);
      }
    };

    redirectToNewUrl();
  }, [isOrgContext, eventId, workspaceId, orgSlug, searchParams, navigate]);

  if (isOrgContext && eventId) {
    return <OrgWorkspacePage />;
  }

  if (isOrgContext) {
    return <OrgWorkspaceListPage />;
  }

  return <WorkspaceServiceDashboard />;
};

export const WorkspaceService: React.FC = () => {
  return (
    <Routes>
      {/* Index route */}
      <Route index element={<WorkspaceIndexRoute />} />

      {/* Workspace List & Create Pages */}
      <Route path="list" element={<WorkspaceListPage />} />
      <Route path="create" element={<WorkspaceCreatePage />} />
      <Route path="create/:eventId" element={<WorkspaceCreatePage />} />

      {/* Event-specific workspace portal */}
      <Route path=":eventId" element={<WorkspaceIndexRoute />} />

      {/* ============================================
          Type-based workspace routes (L1-L4)
          URL: /:orgSlug/workspaces/:eventId/:workspaceType?name=xxx&workspaceId=xxx
          ============================================ */}
      
      {/* Root workspace (L1) */}
      <Route path=":eventId/root" element={<OrgWorkspacePage />} />
      <Route path=":eventId/root/settings" element={<WorkspaceSettingsPage />} />
      
      {/* Department workspace (L2) */}
      <Route path=":eventId/department" element={<OrgWorkspacePage />} />
      <Route path=":eventId/department/settings" element={<WorkspaceSettingsPage />} />
      
      {/* Committee workspace (L3) */}
      <Route path=":eventId/committee" element={<OrgWorkspacePage />} />
      <Route path=":eventId/committee/settings" element={<WorkspaceSettingsPage />} />
      
      {/* Team workspace (L4) */}
      <Route path=":eventId/team" element={<OrgWorkspacePage />} />
      <Route path=":eventId/team/settings" element={<WorkspaceSettingsPage />} />

      {/* ============================================
          Legacy routes - redirect to new URL structure
          ============================================ */}
      <Route path=":eventId/:workspaceId/settings" element={<LegacyWorkspaceRedirect />} />
      <Route path=":eventId/:workspaceId/*" element={<LegacyWorkspaceRedirect />} />
      <Route path=":eventId/:workspaceId" element={<LegacyWorkspaceRedirect />} />

      {/* Fallback */}
      <Route path="*" element={<Navigate to="/console/workspaces" replace />} />
    </Routes>
  );
};

export default WorkspaceService;
