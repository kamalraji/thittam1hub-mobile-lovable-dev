import React, { useState } from 'react';
import { cn } from '@/lib/utils';
import { Plus, Eye } from 'lucide-react';

interface RightPanelProps {
  stylesContainerRef?: React.RefObject<HTMLDivElement>;
}

type TabType = 'Design' | 'Prototype';

export const RightPanel: React.FC<RightPanelProps> = ({ stylesContainerRef }) => {
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
              'px-3 py-1.5 text-xs font-medium transition-colors',
              activeTab === tab
                ? 'text-foreground'
                : 'text-muted-foreground hover:text-foreground'
            )}
          >
            {tab}
          </button>
        ))}
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto">
        {activeTab === 'Design' && <DesignPanel stylesContainerRef={stylesContainerRef} />}
        {activeTab === 'Prototype' && <PrototypePanel />}
      </div>
    </div>
  );
};

interface DesignPanelProps {
  stylesContainerRef?: React.RefObject<HTMLDivElement>;
}

const DesignPanel: React.FC<DesignPanelProps> = ({ stylesContainerRef }) => {
  return (
    <div className="p-3 space-y-4">
      {/* Page section */}
      <Section title="Page">
        <div className="flex items-center gap-2">
          <div className="flex h-6 items-center gap-1.5 rounded bg-[hsl(220,13%,15%)] px-2">
            <div className="h-3 w-3 rounded-sm bg-[hsl(220,13%,12%)] border border-[hsl(220,13%,25%)]" />
            <span className="text-xs text-muted-foreground">181910</span>
          </div>
          <span className="text-xs text-muted-foreground">100%</span>
          <button className="ml-auto">
            <Eye className="h-3.5 w-3.5 text-muted-foreground hover:text-foreground transition-colors" />
          </button>
        </div>
      </Section>

      {/* Local variables */}
      <Section title="Local variables" addButton>
        <p className="text-xs text-muted-foreground/60 italic">No variables</p>
      </Section>

      {/* Local styles */}
      <Section title="Local styles" addButton>
        <p className="text-xs text-muted-foreground/60 italic">No local styles</p>
      </Section>

      {/* Color styles */}
      <Section title="Color styles">
        <div className="space-y-1.5">
          <ColorStyleItem label="BG" color="hsl(220,13%,10%)" />
          <ColorStyleItem label="Well" color="hsl(220,13%,15%)" />
          <ColorStyleItem label="Accent" color="hsl(40,95%,55%)" />
        </div>
      </Section>

      {/* Effect styles */}
      <Section title="Effect styles" addButton>
        <div className="flex items-center gap-2">
          <div className="h-4 w-4 rounded bg-[hsl(220,13%,15%)] shadow-md" />
          <span className="text-xs text-foreground">Shadow</span>
        </div>
      </Section>

      {/* Export */}
      <Section title="Export" addButton>
        <p className="text-xs text-muted-foreground/60 italic">No exports</p>
      </Section>

      {/* GrapesJS styles container */}
      <div className="border-t border-[hsl(220,13%,18%)] pt-3">
        <h4 className="mb-2 text-xs font-medium text-muted-foreground uppercase tracking-wide">
          Element Styles
        </h4>
        <div ref={stylesContainerRef} className="panel-styles" />
      </div>
    </div>
  );
};

const PrototypePanel: React.FC = () => {
  return (
    <div className="p-3">
      <p className="text-xs text-muted-foreground">
        Add interactions and animations to your page elements.
      </p>
    </div>
  );
};

interface SectionProps {
  title: string;
  addButton?: boolean;
  children: React.ReactNode;
}

const Section: React.FC<SectionProps> = ({ title, addButton, children }) => (
  <div>
    <div className="mb-2 flex items-center justify-between">
      <h4 className="text-xs font-medium text-muted-foreground">{title}</h4>
      {addButton && (
        <button className="text-muted-foreground hover:text-foreground transition-colors">
          <Plus className="h-3.5 w-3.5" />
        </button>
      )}
    </div>
    {children}
  </div>
);

interface ColorStyleItemProps {
  label: string;
  color: string;
}

const ColorStyleItem: React.FC<ColorStyleItemProps> = ({ label, color }) => (
  <div className="flex items-center gap-2">
    <div
      className="h-4 w-4 rounded-full border border-[hsl(220,13%,25%)]"
      style={{ backgroundColor: color }}
    />
    <span className="text-xs text-foreground">{label}</span>
  </div>
);
