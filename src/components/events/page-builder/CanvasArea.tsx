import React from 'react';
import { cn } from '@/lib/utils';
import { Play, Plus } from 'lucide-react';

interface CanvasAreaProps {
  containerRef: React.RefObject<HTMLDivElement>;
  device: 'Desktop' | 'Mobile';
  onDeviceChange: (device: 'Desktop' | 'Mobile') => void;
}

export const CanvasArea: React.FC<CanvasAreaProps> = ({
  containerRef,
  device,
  onDeviceChange,
}) => {
  const deviceWidth = device === 'Desktop' ? '1200' : '375';

  return (
    <div className="flex h-full flex-1 flex-col bg-[hsl(220,13%,6%)]">
      {/* Device bar */}
      <div className="flex h-10 items-center justify-between border-b border-[hsl(220,13%,18%)] bg-[hsl(220,13%,10%)] px-4">
        <div className="flex items-center gap-3">
          <button className="flex h-6 w-6 items-center justify-center rounded bg-primary/20 text-primary">
            <Play className="h-3 w-3" fill="currentColor" />
          </button>
          <div className="flex items-center gap-2">
            <button
              onClick={() => onDeviceChange('Desktop')}
              className={cn(
                'text-sm transition-colors',
                device === 'Desktop' ? 'text-foreground' : 'text-muted-foreground hover:text-foreground'
              )}
            >
              Desktop
            </button>
            <span className="text-muted-foreground">·</span>
            <span className="text-sm text-muted-foreground">{deviceWidth}</span>
          </div>
        </div>

        <button className="flex items-center gap-1.5 rounded-md px-2 py-1 text-sm text-muted-foreground hover:bg-[hsl(220,13%,15%)] hover:text-foreground transition-colors">
          Breakpoint
          <Plus className="h-3.5 w-3.5" />
        </button>
      </div>

      {/* Canvas container */}
      <div className="relative flex-1 overflow-hidden p-6">
        <div className="mx-auto h-full max-w-full overflow-hidden rounded-lg bg-[hsl(220,13%,12%)] shadow-2xl ring-1 ring-[hsl(220,13%,18%)]">
          <div
            ref={containerRef}
            className="gjs-editor-container h-full w-full"
          />
        </div>
      </div>
    </div>
  );
};
