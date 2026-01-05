import { useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Loader2 } from 'lucide-react';
import {
  WORKSPACE_DEPARTMENTS,
  DEPARTMENT_COMMITTEES,
  getWorkspaceRoleLabel,
} from '@/lib/workspaceHierarchy';

interface WorkspaceNode {
  id: string;
  name: string;
  workspaceType: string | null;
  departmentId: string | null;
  parentWorkspaceId: string | null;
  status: string;
}

interface WorkspaceHierarchyDiagramProps {
  eventId?: string;
  className?: string;
}

export function WorkspaceHierarchyDiagram({ eventId, className }: WorkspaceHierarchyDiagramProps) {
  // Fetch all workspaces for the event
  const { data: workspaces, isLoading } = useQuery({
    queryKey: ['workspace-hierarchy-diagram', eventId],
    queryFn: async () => {
      let query = supabase
        .from('workspaces')
        .select('id, name, workspace_type, department_id, parent_workspace_id, status')
        .eq('status', 'ACTIVE');
      
      if (eventId) {
        query = query.eq('event_id', eventId);
      }
      
      const { data, error } = await query.order('workspace_type', { ascending: true });
      
      if (error) throw error;
      
      return (data || []).map(w => ({
        id: w.id,
        name: w.name,
        workspaceType: w.workspace_type,
        departmentId: w.department_id,
        parentWorkspaceId: w.parent_workspace_id,
        status: w.status,
      })) as WorkspaceNode[];
    },
  });

  // Generate mermaid diagram code
  const mermaidCode = useMemo(() => {
    if (!workspaces || workspaces.length === 0) {
      return generateTemplateHierarchy();
    }
    return generateMermaidFromData(workspaces);
  }, [workspaces]);

  if (isLoading) {
    return (
      <Card className={className}>
        <CardContent className="flex items-center justify-center py-12">
          <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className={className}>
      <CardHeader>
        <CardTitle className="text-lg">Workspace Hierarchy Structure</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-6">
          {/* Visual hierarchy representation */}
          <div className="space-y-4">
            {renderHierarchyLevels(workspaces || [])}
          </div>
          
          {/* Code block for mermaid */}
          <details className="mt-4">
            <summary className="cursor-pointer text-sm text-muted-foreground hover:text-foreground">
              View Mermaid Diagram Code
            </summary>
            <pre className="mt-2 p-4 bg-muted rounded-lg text-xs overflow-x-auto">
              {mermaidCode}
            </pre>
          </details>
        </div>
      </CardContent>
    </Card>
  );
}

function renderHierarchyLevels(workspaces: WorkspaceNode[]) {
  const root = workspaces.filter(w => w.workspaceType === 'ROOT');
  const departments = workspaces.filter(w => w.workspaceType === 'DEPARTMENT');
  const committees = workspaces.filter(w => w.workspaceType === 'COMMITTEE');
  const teams = workspaces.filter(w => w.workspaceType === 'TEAM');

  const levels = [
    { label: 'L1 - ROOT', items: root, color: 'bg-blue-500', role: 'WORKSPACE_OWNER' },
    { label: 'L2 - DEPARTMENT', items: departments, color: 'bg-purple-500', role: '*_MANAGER' },
    { label: 'L3 - COMMITTEE', items: committees, color: 'bg-emerald-500', role: '*_LEAD' },
    { label: 'L4 - TEAM', items: teams, color: 'bg-amber-500', role: '*_COORDINATOR' },
  ];

  return (
    <div className="space-y-3">
      {levels.map((level) => (
        <div key={level.label} className="flex items-start gap-3">
          {/* Level badge */}
          <div className={`${level.color} text-white text-xs font-medium px-2 py-1 rounded min-w-[120px] text-center`}>
            {level.label}
          </div>
          
          {/* Items */}
          <div className="flex flex-wrap gap-2 flex-1">
            {level.items.length > 0 ? (
              level.items.map(item => (
                <div
                  key={item.id}
                  className="px-3 py-1.5 bg-muted rounded-md text-sm border"
                >
                  <span className="font-medium">{item.name}</span>
                  <span className="text-muted-foreground text-xs ml-2">
                    ({getRoleForWorkspace(item)})
                  </span>
                </div>
              ))
            ) : (
              <span className="text-muted-foreground text-sm italic">
                No {level.label.split(' - ')[1].toLowerCase()}s created
              </span>
            )}
          </div>
        </div>
      ))}
    </div>
  );
}

function getRoleForWorkspace(workspace: WorkspaceNode): string {
  if (workspace.workspaceType === 'ROOT') {
    return 'Owner';
  }
  if (workspace.workspaceType === 'DEPARTMENT') {
    const dept = WORKSPACE_DEPARTMENTS.find(d => d.id === workspace.departmentId);
    return dept ? getWorkspaceRoleLabel(dept.managerRole).replace(' Manager', '') : 'Manager';
  }
  if (workspace.workspaceType === 'COMMITTEE') {
    // Try to find the committee by name
    for (const [, committees] of Object.entries(DEPARTMENT_COMMITTEES)) {
      const committee = committees.find(c => 
        c.name.toLowerCase() === workspace.name.toLowerCase()
      );
      if (committee) {
        return getWorkspaceRoleLabel(committee.leadRole).replace(' Lead', '');
      }
    }
    return 'Lead';
  }
  if (workspace.workspaceType === 'TEAM') {
    return 'Coordinator';
  }
  return 'Member';
}

function generateMermaidFromData(workspaces: WorkspaceNode[]): string {
  const root = workspaces.filter(w => w.workspaceType === 'ROOT');
  const departments = workspaces.filter(w => w.workspaceType === 'DEPARTMENT');
  const committees = workspaces.filter(w => w.workspaceType === 'COMMITTEE');
  const teams = workspaces.filter(w => w.workspaceType === 'TEAM');

  let code = `graph TD\n`;
  
  // Subgraphs for each level
  code += `    subgraph L1["Level 1 - ROOT"]\n`;
  root.forEach(w => {
    code += `        ${sanitizeId(w.id)}["🏢 ${w.name}"]\n`;
  });
  code += `    end\n\n`;
  
  code += `    subgraph L2["Level 2 - DEPARTMENTS"]\n`;
  if (departments.length > 0) {
    departments.forEach(w => {
      code += `        ${sanitizeId(w.id)}["⚙️ ${w.name}"]\n`;
    });
  } else {
    code += `        L2_EMPTY["<i>No departments</i>"]\n`;
  }
  code += `    end\n\n`;
  
  code += `    subgraph L3["Level 3 - COMMITTEES"]\n`;
  if (committees.length > 0) {
    committees.forEach(w => {
      code += `        ${sanitizeId(w.id)}["📋 ${w.name}"]\n`;
    });
  } else {
    code += `        L3_EMPTY["<i>No committees</i>"]\n`;
  }
  code += `    end\n\n`;
  
  code += `    subgraph L4["Level 4 - TEAMS"]\n`;
  if (teams.length > 0) {
    teams.forEach(w => {
      code += `        ${sanitizeId(w.id)}["👥 ${w.name}"]\n`;
    });
  } else {
    code += `        L4_EMPTY["<i>No teams</i>"]\n`;
  }
  code += `    end\n\n`;
  
  // Add connections
  workspaces.forEach(w => {
    if (w.parentWorkspaceId) {
      code += `    ${sanitizeId(w.parentWorkspaceId)} --> ${sanitizeId(w.id)}\n`;
    }
  });
  
  // Styling
  code += `\n    style L1 fill:#1e40af,color:#fff\n`;
  code += `    style L2 fill:#7c3aed,color:#fff\n`;
  code += `    style L3 fill:#059669,color:#fff\n`;
  code += `    style L4 fill:#d97706,color:#fff\n`;
  
  return code;
}

function generateTemplateHierarchy(): string {
  let code = `graph TD\n`;
  
  // L1
  code += `    subgraph L1["Level 1 - ROOT"]\n`;
  code += `        ROOT["🏢 Event Workspace<br/><i>WORKSPACE_OWNER</i>"]\n`;
  code += `    end\n\n`;
  
  // L2
  code += `    subgraph L2["Level 2 - DEPARTMENTS"]\n`;
  WORKSPACE_DEPARTMENTS.forEach(dept => {
    code += `        ${dept.id.toUpperCase()}["⚙️ ${dept.name}<br/><i>${getWorkspaceRoleLabel(dept.managerRole)}</i>"]\n`;
  });
  code += `    end\n\n`;
  
  // L3 - Show committees per department
  code += `    subgraph L3["Level 3 - COMMITTEES"]\n`;
  Object.entries(DEPARTMENT_COMMITTEES).forEach(([deptId, committees]) => {
    committees.forEach(committee => {
      code += `        ${committee.id.toUpperCase()}_${deptId.toUpperCase()}["📋 ${committee.name}<br/><i>${getWorkspaceRoleLabel(committee.leadRole)}</i>"]\n`;
    });
  });
  code += `    end\n\n`;
  
  // L4
  code += `    subgraph L4["Level 4 - TEAMS"]\n`;
  code += `        TEAM_PLACEHOLDER["👥 Custom Teams<br/><i>*_COORDINATOR</i>"]\n`;
  code += `    end\n\n`;
  
  // Connections
  WORKSPACE_DEPARTMENTS.forEach(dept => {
    code += `    ROOT --> ${dept.id.toUpperCase()}\n`;
  });
  
  Object.entries(DEPARTMENT_COMMITTEES).forEach(([deptId, committees]) => {
    committees.forEach(committee => {
      code += `    ${deptId.toUpperCase()} --> ${committee.id.toUpperCase()}_${deptId.toUpperCase()}\n`;
    });
  });
  
  // Styling
  code += `\n    style L1 fill:#1e40af,color:#fff\n`;
  code += `    style L2 fill:#7c3aed,color:#fff\n`;
  code += `    style L3 fill:#059669,color:#fff\n`;
  code += `    style L4 fill:#d97706,color:#fff\n`;
  
  return code;
}

function sanitizeId(id: string): string {
  return id.replace(/-/g, '_');
}
