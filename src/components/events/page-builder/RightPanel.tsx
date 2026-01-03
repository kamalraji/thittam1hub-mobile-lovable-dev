import React, { useState } from 'react';
import { cn } from '@/lib/utils';
import { Plus, Eye, Settings, Palette, Box } from 'lucide-react';

interface RightPanelProps {
  stylesContainerRef?: React.RefObject<HTMLDivElement>;
  traitsContainerRef?: React.RefObject<HTMLDivElement>;
}

type TabType = 'Design' | 'Prototype';

export const RightPanel: React.FC<RightPanelProps> = ({ stylesContainerRef, traitsContainerRef }) => {
  const [activeTab, setActiveTab] = useState<TabType>('Design');

  return (
    <div className="flex h-full w-72 flex-col border-l border-[hsl(220,13%,18%)] bg-[hsl(220,13%,10%)]">
      {/* Tabs */}
      <div className="flex h-10 items-center border-b border-[hsl(220,13%,18%)] px-3">
        {(['Design', 'Prototype'] as TabType[]).map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={cn(
              'relative px-3 py-1.5 text-xs font-medium transition-all duration-200',
              activeTab === tab
                ? 'text-foreground'
                : 'text-muted-foreground hover:text-foreground'
            )}
          >
            {tab}
            {activeTab === tab && (
              <span className="absolute bottom-0 left-1/2 h-0.5 w-4 -translate-x-1/2 rounded-full bg-primary shadow-[0_0_8px_hsl(221,83%,53%/0.5)]" />
            )}
          </button>
        ))}
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto custom-scrollbar">
        {activeTab === 'Design' && (
          <DesignPanel 
            stylesContainerRef={stylesContainerRef} 
            traitsContainerRef={traitsContainerRef}
          />
        )}
        {activeTab === 'Prototype' && <PrototypePanel />}
      </div>
    </div>
  );
};

interface DesignPanelProps {
  stylesContainerRef?: React.RefObject<HTMLDivElement>;
  traitsContainerRef?: React.RefObject<HTMLDivElement>;
}

const DesignPanel: React.FC<DesignPanelProps> = ({ stylesContainerRef, traitsContainerRef }) => {
  return (
    <div className="p-3 space-y-4">
      {/* Component Properties (Traits) */}
      <Section 
        title="Properties" 
        icon={Settings}
        description="Edit selected element"
      >
        <div 
          ref={traitsContainerRef} 
          className="panel-traits min-h-[40px]"
        />
      </Section>

      {/* Element Styles */}
      <Section 
        title="Styles" 
        icon={Palette}
        description="Customize appearance"
      >
        <div ref={stylesContainerRef} className="panel-styles" />
      </Section>

      {/* Color styles */}
      <Section title="Color Tokens" icon={Box}>
        <div className="space-y-2">
          <ColorStyleItem label="Background" color="hsl(220,13%,10%)" />
          <ColorStyleItem label="Surface" color="hsl(220,13%,15%)" />
          <ColorStyleItem label="Primary" color="hsl(221,83%,53%)" glow />
          <ColorStyleItem label="Muted" color="hsl(215,20%,65%)" />
        </div>
      </Section>
    </div>
  );
};

const PrototypePanel: React.FC = () => {
  return (
    <div className="p-3">
      <div className="rounded-lg border border-dashed border-[hsl(220,13%,25%)] bg-[hsl(220,13%,8%)] p-4 text-center">
        <div className="mx-auto mb-2 flex h-10 w-10 items-center justify-center rounded-full bg-[hsl(220,13%,15%)]">
          <Plus className="h-5 w-5 text-muted-foreground" />
        </div>
        <p className="text-xs text-muted-foreground">
          Select an element and add interactions or animations.
        </p>
      </div>
    </div>
  );
};

interface SectionProps {
  title: string;
  icon?: React.ElementType;
  description?: string;
  addButton?: boolean;
  children: React.ReactNode;
}

const Section: React.FC<SectionProps> = ({ title, icon: Icon, description, addButton, children }) => (
  <div className="rounded-lg border border-[hsl(220,13%,18%)] bg-[hsl(220,13%,8%)] overflow-hidden">
    <div className="flex items-center justify-between px-3 py-2 border-b border-[hsl(220,13%,18%)]">
      <div className="flex items-center gap-2">
        {Icon && <Icon className="h-3.5 w-3.5 text-muted-foreground" />}
        <h4 className="text-xs font-medium text-foreground">{title}</h4>
      </div>
      {addButton && (
        <button className="text-muted-foreground hover:text-foreground transition-colors">
          <Plus className="h-3.5 w-3.5" />
        </button>
      )}
    </div>
    {description && (
      <p className="px-3 pt-2 text-[10px] text-muted-foreground/60">{description}</p>
    )}
    <div className="p-3">
      {children}
    </div>
  </div>
);

interface ColorStyleItemProps {
  label: string;
  color: string;
  glow?: boolean;
}

const ColorStyleItem: React.FC<ColorStyleItemProps> = ({ label, color, glow }) => (
  <div className="flex items-center gap-2 group">
    <div
      className={cn(
        "h-5 w-5 rounded border border-[hsl(220,13%,25%)] transition-all",
        glow && "shadow-[0_0_8px_hsl(221,83%,53%/0.4)]"
      )}
      style={{ backgroundColor: color }}
    />
    <span className="text-xs text-foreground flex-1">{label}</span>
    <button className="opacity-0 group-hover:opacity-100 transition-opacity">
      <Eye className="h-3 w-3 text-muted-foreground hover:text-foreground" />
    </button>
  </div>
);
