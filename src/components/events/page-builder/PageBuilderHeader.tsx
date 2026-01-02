import React from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { cn } from '@/lib/utils';
import { slugify } from './pageBuilderUtils';

interface PageBuilderHeaderProps {
  slug: string;
  onSlugChange: (slug: string) => void;
  device: 'Desktop' | 'Mobile';
  onDeviceChange: (device: 'Desktop' | 'Mobile') => void;
  onPreview: () => void;
  onSave: () => void;
  saving: boolean;
  hasCustomLanding: boolean;
  eventId?: string;
}

export const PageBuilderHeader: React.FC<PageBuilderHeaderProps> = ({
  slug,
  onSlugChange,
  device,
  onDeviceChange,
  onPreview,
  onSave,
  saving,
  hasCustomLanding,
  eventId,
}) => {
  return (
    <div className="border-b border-border bg-card/60 backdrop-blur">
      <div className="mx-auto flex max-w-7xl flex-col gap-4 px-4 py-4 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">
            Event page builder
          </p>
          <h1 className="text-xl font-semibold text-foreground">Design your public event page</h1>
          {hasCustomLanding && (
            <p className="mt-1 text-xs text-emerald-600 dark:text-emerald-400">
              This GrapesJS layout is currently live on your public landing page.
            </p>
          )}
        </div>
        <div className="flex flex-wrap items-center gap-3">
          <div className="flex items-center gap-2 rounded-full border border-border bg-background px-3 py-1.5">
            <span className="text-xs font-medium text-muted-foreground">Public URL slug</span>
            <Input
              value={slug}
              onChange={(e) => onSlugChange(slugify(e.target.value))}
              className="h-7 w-40 border-0 bg-transparent px-0 text-xs focus-visible:ring-0"
              placeholder="my-event"
            />
          </div>
          <div className="flex items-center gap-1 rounded-full border border-border bg-background px-1 py-1 text-xs font-medium">
            <button
              type="button"
              onClick={() => onDeviceChange('Desktop')}
              className={cn(
                'rounded-full px-2 py-0.5 transition-colors',
                device === 'Desktop' ? 'bg-primary text-primary-foreground' : 'text-muted-foreground',
              )}
            >
              Desktop
            </button>
            <button
              type="button"
              onClick={() => onDeviceChange('Mobile')}
              className={cn(
                'rounded-full px-2 py-0.5 transition-colors',
                device === 'Mobile' ? 'bg-primary text-primary-foreground' : 'text-muted-foreground',
              )}
            >
              Mobile
            </button>
          </div>
          <Button
            type="button"
            variant="outline"
            size="sm"
            onClick={onPreview}
            disabled={!eventId}
          >
            Preview public page
          </Button>
          <Button onClick={onSave} disabled={saving} size="sm">
            {saving ? 'Saving…' : 'Save & publish'}
          </Button>
        </div>
      </div>
    </div>
  );
};
