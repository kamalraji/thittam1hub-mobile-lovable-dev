import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Button } from '@/components/ui/button';
import { Loader2, TicketIcon } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/looseClient';

interface TicketingSettings {
  isFree: boolean;
  price: number | null;
  currency: string;
  allowWaitlist: boolean;
  registrationType: 'OPEN' | 'INVITE_ONLY' | 'APPROVAL_REQUIRED';
}

interface RegistrationSettingsCardProps {
  eventId: string;
  branding: Record<string, any>;
  onUpdate: () => void;
}

const CURRENCIES = [
  { value: 'INR', label: '₹ INR' },
  { value: 'USD', label: '$ USD' },
  { value: 'EUR', label: '€ EUR' },
  { value: 'GBP', label: '£ GBP' },
];

const REGISTRATION_TYPES = [
  { value: 'OPEN', label: 'Open Registration', description: 'Anyone can register' },
  { value: 'INVITE_ONLY', label: 'Invite Only', description: 'Only invited users can register' },
  { value: 'APPROVAL_REQUIRED', label: 'Approval Required', description: 'Registrations require approval' },
];

export const RegistrationSettingsCard: React.FC<RegistrationSettingsCardProps> = ({
  eventId,
  branding,
  onUpdate,
}) => {
  const { toast } = useToast();
  const [isSaving, setIsSaving] = useState(false);

  const defaultSettings: TicketingSettings = {
    isFree: true,
    price: null,
    currency: 'INR',
    allowWaitlist: false,
    registrationType: 'OPEN',
  };

  const [settings, setSettings] = useState<TicketingSettings>(() => ({
    ...defaultSettings,
    ...branding?.ticketing,
  }));

  useEffect(() => {
    setSettings({
      ...defaultSettings,
      ...branding?.ticketing,
    });
  }, [branding]);

  const handleSave = async () => {
    setIsSaving(true);
    try {
      const updatedBranding = {
        ...branding,
        ticketing: settings,
      };

      const { error } = await supabase
        .from('events')
        .update({ branding: updatedBranding })
        .eq('id', eventId);

      if (error) throw error;

      toast({
        title: 'Settings saved',
        description: 'Registration settings have been updated.',
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

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center gap-2">
          <div className="p-2 rounded-lg bg-primary/10">
            <TicketIcon className="h-5 w-5 text-primary" />
          </div>
          <div>
            <CardTitle className="text-lg">Registration & Ticketing</CardTitle>
            <CardDescription>Configure registration type and pricing</CardDescription>
          </div>
        </div>
      </CardHeader>
      <CardContent className="space-y-6">
        {/* Is Free Event */}
        <div className="flex items-center justify-between">
          <div className="space-y-0.5">
            <Label htmlFor="isFree">Free Event</Label>
            <p className="text-sm text-muted-foreground">
              Toggle off to set ticket pricing
            </p>
          </div>
          <Switch
            id="isFree"
            checked={settings.isFree}
            onCheckedChange={(checked) =>
              setSettings({ ...settings, isFree: checked, price: checked ? null : settings.price })
            }
          />
        </div>

        {/* Ticket Price (if not free) */}
        {!settings.isFree && (
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="price">Ticket Price</Label>
              <Input
                id="price"
                type="number"
                min="0"
                step="0.01"
                placeholder="0.00"
                value={settings.price || ''}
                onChange={(e) =>
                  setSettings({ ...settings, price: parseFloat(e.target.value) || null })
                }
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="currency">Currency</Label>
              <Select
                value={settings.currency}
                onValueChange={(value) => setSettings({ ...settings, currency: value })}
              >
                <SelectTrigger id="currency">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {CURRENCIES.map((currency) => (
                    <SelectItem key={currency.value} value={currency.value}>
                      {currency.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>
        )}

        {/* Registration Type */}
        <div className="space-y-2">
          <Label htmlFor="registrationType">Registration Type</Label>
          <Select
            value={settings.registrationType}
            onValueChange={(value: 'OPEN' | 'INVITE_ONLY' | 'APPROVAL_REQUIRED') =>
              setSettings({ ...settings, registrationType: value })
            }
          >
            <SelectTrigger id="registrationType">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {REGISTRATION_TYPES.map((type) => (
                <SelectItem key={type.value} value={type.value}>
                  <div className="flex flex-col">
                    <span>{type.label}</span>
                  </div>
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          <p className="text-xs text-muted-foreground">
            {REGISTRATION_TYPES.find((t) => t.value === settings.registrationType)?.description}
          </p>
        </div>

        {/* Allow Waitlist */}
        <div className="flex items-center justify-between">
          <div className="space-y-0.5">
            <Label htmlFor="allowWaitlist">Allow Waitlist</Label>
            <p className="text-sm text-muted-foreground">
              Enable waitlist when capacity is full
            </p>
          </div>
          <Switch
            id="allowWaitlist"
            checked={settings.allowWaitlist}
            onCheckedChange={(checked) => setSettings({ ...settings, allowWaitlist: checked })}
          />
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
