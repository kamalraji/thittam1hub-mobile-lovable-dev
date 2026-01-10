import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Loader2, SearchIcon, X } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/looseClient';

interface SEOSettings {
  tags: string[];
  metaDescription: string;
  customSlug: string;
}

interface SEOSettingsCardProps {
  eventId: string;
  branding: Record<string, any>;
  eventName: string;
  onUpdate: () => void;
}

export const SEOSettingsCard: React.FC<SEOSettingsCardProps> = ({
  eventId,
  branding,
  eventName,
  onUpdate,
}) => {
  const { toast } = useToast();
  const [isSaving, setIsSaving] = useState(false);
  const [tagInput, setTagInput] = useState('');

  const defaultSettings: SEOSettings = {
    tags: [],
    metaDescription: '',
    customSlug: '',
  };

  const [settings, setSettings] = useState<SEOSettings>(() => ({
    ...defaultSettings,
    ...branding?.seo,
  }));

  useEffect(() => {
    setSettings({
      ...defaultSettings,
      ...branding?.seo,
    });
  }, [branding]);

  const addTag = () => {
    const trimmedTag = tagInput.trim().toLowerCase();
    if (trimmedTag && !settings.tags.includes(trimmedTag) && settings.tags.length < 10) {
      setSettings({ ...settings, tags: [...settings.tags, trimmedTag] });
      setTagInput('');
    }
  };

  const removeTag = (tagToRemove: string) => {
    setSettings({ ...settings, tags: settings.tags.filter((tag) => tag !== tagToRemove) });
  };

  const handleTagInputKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter' || e.key === ',') {
      e.preventDefault();
      addTag();
    }
  };

  const handleSave = async () => {
    setIsSaving(true);
    try {
      const updatedBranding = {
        ...branding,
        seo: settings,
      };

      const { error } = await supabase
        .from('events')
        .update({ branding: updatedBranding })
        .eq('id', eventId);

      if (error) throw error;

      toast({
        title: 'Settings saved',
        description: 'SEO settings have been updated.',
      });
      onUpdate();
    } catch (error) {
      toast({
        title: 'Error saving settings',
        description: 'Please try again.',
        variant: 'destructive',
      });
    } finally {
      setIsSaving(false);
    }
  };

  const slugify = (text: string) =>
    text
      .toLowerCase()
      .replace(/[^\w\s-]/g, '')
      .replace(/\s+/g, '-')
      .replace(/-+/g, '-')
      .trim();

  const previewSlug = settings.customSlug || slugify(eventName);

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center gap-2">
          <div className="p-2 rounded-lg bg-primary/10">
            <SearchIcon className="h-5 w-5 text-primary" />
          </div>
          <div>
            <CardTitle className="text-lg">SEO & Discovery</CardTitle>
            <CardDescription>Optimize event visibility in search results</CardDescription>
          </div>
        </div>
      </CardHeader>
      <CardContent className="space-y-6">
        {/* Tags */}
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <Label htmlFor="tags">Tags</Label>
            <span className="text-xs text-muted-foreground">{settings.tags.length}/10</span>
          </div>
          <div className="flex gap-2">
            <Input
              id="tags"
              placeholder="Add a tag and press Enter"
              value={tagInput}
              onChange={(e) => setTagInput(e.target.value)}
              onKeyDown={handleTagInputKeyDown}
              disabled={settings.tags.length >= 10}
            />
            <Button
              type="button"
              variant="secondary"
              onClick={addTag}
              disabled={!tagInput.trim() || settings.tags.length >= 10}
            >
              Add
            </Button>
          </div>
          {settings.tags.length > 0 && (
            <div className="flex flex-wrap gap-2">
              {settings.tags.map((tag) => (
                <Badge key={tag} variant="secondary" className="pl-2 pr-1 py-1">
                  {tag}
                  <button
                    onClick={() => removeTag(tag)}
                    className="ml-1 rounded-full p-0.5 hover:bg-muted-foreground/20"
                  >
                    <X className="h-3 w-3" />
                  </button>
                </Badge>
              ))}
            </div>
          )}
          <p className="text-xs text-muted-foreground">
            Add keywords to help people discover your event
          </p>
        </div>

        {/* Meta Description */}
        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <Label htmlFor="metaDescription">Meta Description</Label>
            <span className="text-xs text-muted-foreground">
              {settings.metaDescription.length}/160
            </span>
          </div>
          <Textarea
            id="metaDescription"
            placeholder="A brief description of your event for search engines..."
            value={settings.metaDescription}
            onChange={(e) => {
              if (e.target.value.length <= 160) {
                setSettings({ ...settings, metaDescription: e.target.value });
              }
            }}
            rows={3}
          />
          <p className="text-xs text-muted-foreground">
            This appears in search engine results
          </p>
        </div>

        {/* Custom URL Slug */}
        <div className="space-y-2">
          <Label htmlFor="customSlug">Custom URL Slug</Label>
          <div className="flex items-center gap-2">
            <span className="text-sm text-muted-foreground">/events/</span>
            <Input
              id="customSlug"
              placeholder={slugify(eventName)}
              value={settings.customSlug}
              onChange={(e) => setSettings({ ...settings, customSlug: slugify(e.target.value) })}
            />
          </div>
          <p className="text-xs text-muted-foreground">
            Preview: <code className="bg-muted px-1 rounded">/events/{previewSlug}</code>
          </p>
        </div>

        {/* Save Button */}
        <div className="flex justify-end pt-4 border-t">
          <Button onClick={handleSave} disabled={isSaving}>
            {isSaving && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
            Save Changes
          </Button>
        </div>
      </CardContent>
    </Card>
  );
};
