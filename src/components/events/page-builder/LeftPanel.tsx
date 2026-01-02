import React, { useState } from 'react';
import { cn } from '@/lib/utils';
import { 
  ChevronDown, 
  ChevronRight, 
  Home, 
  Image as ImageIcon,
  Layout,
  Navigation,
  LayoutTemplate,
  Type,
  Video,
  Square
} from 'lucide-react';

interface LeftPanelProps {
  blocksContainerRef?: React.RefObject<HTMLDivElement>;
  layersContainerRef?: React.RefObject<HTMLDivElement>;
}

type TabType = 'Pages' | 'Layers' | 'Assets';

export const LeftPanel: React.FC<LeftPanelProps> = ({
  blocksContainerRef,
  layersContainerRef,
}) => {
  const [activeTab, setActiveTab] = useState<TabType>('Layers');

  return (
    <div className="flex h-full w-64 flex-col border-r border-[hsl(220,13%,18%)] bg-[hsl(220,13%,10%)]">
      {/* Tabs */}
      <div className="flex h-10 items-center border-b border-[hsl(220,13%,18%)] px-3">
        {(['Pages', 'Layers', 'Assets'] as TabType[]).map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={cn(
              'px-3 py-1.5 text-xs font-medium rounded-md transition-colors',
              activeTab === tab
                ? 'bg-primary text-primary-foreground'
                : 'text-muted-foreground hover:text-foreground'
            )}
          >
            {tab}
          </button>
        ))}
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto">
        {activeTab === 'Pages' && <PagesPanel />}
        {activeTab === 'Layers' && <LayersPanel layersContainerRef={layersContainerRef} />}
        {activeTab === 'Assets' && <AssetsPanel blocksContainerRef={blocksContainerRef} />}
      </div>
    </div>
  );
};

const PagesPanel: React.FC = () => {
  return (
    <div className="p-2">
      {/* Page selector */}
      <button className="flex w-full items-center gap-2 rounded-md px-2 py-1.5 text-sm text-foreground hover:bg-[hsl(220,13%,15%)] transition-colors">
        <Home className="h-4 w-4 text-muted-foreground" />
        <span>Home</span>
        <ChevronDown className="ml-auto h-3 w-3 text-muted-foreground" />
      </button>
    </div>
  );
};

interface LayersPanelProps {
  layersContainerRef?: React.RefObject<HTMLDivElement>;
}

const LayersPanel: React.FC<LayersPanelProps> = ({ layersContainerRef }) => {
  return (
    <div className="p-2">
      {/* Page dropdown */}
      <button className="mb-3 flex w-full items-center gap-2 rounded-md px-2 py-1.5 text-sm text-foreground hover:bg-[hsl(220,13%,15%)] transition-colors">
        <Home className="h-4 w-4 text-muted-foreground" />
        <span>Home</span>
        <ChevronDown className="ml-auto h-3 w-3 text-muted-foreground" />
      </button>

      {/* Layer tree - placeholder structure */}
      <div className="space-y-0.5">
        <LayerItem icon={Layout} label="Desktop" badge="Primary" level={0} expanded />
        <LayerItem icon={Navigation} label="Navigation" level={1} componentIcon />
        <LayerItem icon={LayoutTemplate} label="Header" level={1} expanded />
        <LayerItem icon={Square} label="Hero" level={2} expanded />
        <LayerItem icon={Type} label="Title" level={3} selected />
        <LayerItem icon={Type} label="Paragraph" level={3} />
        <LayerItem icon={ImageIcon} label="Slideshow" level={3} componentIcon />
        <LayerItem icon={Video} label="Video" level={2} />
        <LayerItem icon={Square} label="CTA" level={2} />
        <LayerItem icon={Video} label="Videos" level={1} />
        <LayerItem icon={LayoutTemplate} label="Footer" level={1} />
      </div>

      {/* GrapesJS layers container (hidden but available) */}
      <div ref={layersContainerRef} className="panel-layers mt-4" />
    </div>
  );
};

interface AssetsBlocksPanelProps {
  blocksContainerRef?: React.RefObject<HTMLDivElement>;
}

const AssetsPanel: React.FC<AssetsBlocksPanelProps> = ({ blocksContainerRef }) => {
  return (
    <div className="p-2">
      <p className="mb-3 px-2 text-xs text-muted-foreground">Drag blocks to add sections</p>
      {/* GrapesJS blocks container */}
      <div ref={blocksContainerRef} className="panel-blocks" />
    </div>
  );
};

interface LayerItemProps {
  icon: React.ElementType;
  label: string;
  level?: number;
  expanded?: boolean;
  selected?: boolean;
  badge?: string;
  componentIcon?: boolean;
}

const LayerItem: React.FC<LayerItemProps> = ({
  icon: Icon,
  label,
  level = 0,
  expanded,
  selected,
  badge,
  componentIcon,
}) => {
  const paddingLeft = 8 + level * 16;

  return (
    <button
      className={cn(
        'group flex w-full items-center gap-1.5 rounded-md py-1 text-xs transition-colors',
        selected
          ? 'bg-primary text-primary-foreground'
          : 'text-foreground hover:bg-[hsl(220,13%,15%)]'
      )}
      style={{ paddingLeft: `${paddingLeft}px`, paddingRight: '8px' }}
    >
      {expanded !== undefined ? (
        <ChevronRight className={cn('h-3 w-3 shrink-0 transition-transform', expanded && 'rotate-90')} />
      ) : (
        <span className="w-3" />
      )}
      <Icon className={cn(
        'h-3.5 w-3.5 shrink-0',
        componentIcon ? 'text-purple-400' : selected ? 'text-primary-foreground' : 'text-primary'
      )} />
      <span className="truncate">{label}</span>
      {badge && (
        <span className="ml-auto shrink-0 text-[10px] text-primary">{badge}</span>
      )}
    </button>
  );
};
