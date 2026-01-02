import React from 'react';
import { Button } from '@/components/ui/button';
import { 
  MousePointer2, 
  Plus, 
  LayoutGrid, 
  Type, 
  Image, 
  Component,
  Play,
  Share2,
  MoreHorizontal,
  ChevronDown
} from 'lucide-react';
import { cn } from '@/lib/utils';

interface BuilderToolbarProps {
  projectName?: string;
  onSave: () => void;
  onPreview: () => void;
  saving: boolean;
}

export const BuilderToolbar: React.FC<BuilderToolbarProps> = ({
  projectName = 'Event Page',
  onSave,
  onPreview,
  saving,
}) => {
  return (
    <div className="flex h-12 items-center justify-between border-b border-[hsl(220,13%,18%)] bg-[hsl(220,13%,10%)] px-2">
      {/* Left: Logo + Tools */}
      <div className="flex items-center gap-1">
        {/* Logo dropdown */}
        <button className="flex h-8 items-center gap-1 rounded-md px-2 hover:bg-[hsl(220,13%,15%)] transition-colors">
          <div className="flex h-5 w-5 items-center justify-center rounded bg-gradient-to-br from-primary to-accent text-[10px] font-bold text-primary-foreground">
            E
          </div>
          <ChevronDown className="h-3 w-3 text-muted-foreground" />
        </button>

        <div className="mx-2 h-5 w-px bg-[hsl(220,13%,20%)]" />

        {/* Tool buttons */}
        <ToolButton icon={MousePointer2} active />
        <ToolButton icon={Plus} />
        <ToolButton icon={LayoutGrid} />
        <ToolButton icon={Type} />
        <ToolButton icon={Image} />
        <ToolButton icon={Component} />
      </div>

      {/* Center: Project name */}
      <div className="flex items-center gap-2">
        <span className="text-sm text-muted-foreground">Drafts</span>
        <span className="text-muted-foreground">/</span>
        <button className="flex items-center gap-1 text-sm font-medium text-foreground hover:text-primary transition-colors">
          {projectName}
          <ChevronDown className="h-3 w-3" />
        </button>
      </div>

      {/* Right: Actions */}
      <div className="flex items-center gap-2">
        <Button
          variant="ghost"
          size="sm"
          className="h-7 gap-1.5 text-xs font-medium text-muted-foreground hover:text-foreground hover:bg-[hsl(220,13%,15%)]"
          onClick={onPreview}
        >
          <Play className="h-3.5 w-3.5" />
          Preview
        </Button>

        <Button
          size="sm"
          className="h-7 gap-1.5 bg-primary text-xs font-medium text-primary-foreground hover:bg-primary/90"
          onClick={onSave}
          disabled={saving}
        >
          <Share2 className="h-3.5 w-3.5" />
          {saving ? 'Saving…' : 'Share'}
        </Button>

        <button className="flex h-7 w-7 items-center justify-center rounded hover:bg-[hsl(220,13%,15%)] transition-colors">
          <MoreHorizontal className="h-4 w-4 text-muted-foreground" />
        </button>
      </div>
    </div>
  );
};

interface ToolButtonProps {
  icon: React.ElementType;
  active?: boolean;
  onClick?: () => void;
}

const ToolButton: React.FC<ToolButtonProps> = ({ icon: Icon, active, onClick }) => (
  <button
    onClick={onClick}
    className={cn(
      'flex h-8 w-8 items-center justify-center rounded-md transition-colors',
      active
        ? 'bg-[hsl(220,13%,18%)] text-foreground'
        : 'text-muted-foreground hover:bg-[hsl(220,13%,15%)] hover:text-foreground'
    )}
  >
    <Icon className="h-4 w-4" />
  </button>
);
