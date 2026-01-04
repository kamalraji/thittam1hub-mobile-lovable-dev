import React from 'react';
import { Mail, Send, Inbox, FileText } from 'lucide-react';
import { Button } from '@/components/ui/button';

export const MobileEmailView: React.FC = () => {
  return (
    <div className="px-4 py-4 space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold text-foreground">Communications</h1>
        <Button size="sm" className="gap-1">
          <Send className="h-4 w-4" />
          Compose
        </Button>
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-3 gap-3">
        <div className="bg-card border border-border rounded-xl p-3 text-center">
          <Inbox className="h-5 w-5 text-primary mx-auto mb-1" />
          <p className="text-lg font-bold text-foreground">0</p>
          <p className="text-xs text-muted-foreground">Inbox</p>
        </div>
        <div className="bg-card border border-border rounded-xl p-3 text-center">
          <Send className="h-5 w-5 text-green-600 mx-auto mb-1" />
          <p className="text-lg font-bold text-foreground">0</p>
          <p className="text-xs text-muted-foreground">Sent</p>
        </div>
        <div className="bg-card border border-border rounded-xl p-3 text-center">
          <FileText className="h-5 w-5 text-orange-600 mx-auto mb-1" />
          <p className="text-lg font-bold text-foreground">0</p>
          <p className="text-xs text-muted-foreground">Drafts</p>
        </div>
      </div>

      {/* Empty State */}
      <div className="flex flex-col items-center justify-center py-12 text-center">
        <div className="p-4 rounded-full bg-muted mb-4">
          <Mail className="h-8 w-8 text-muted-foreground" />
        </div>
        <h3 className="font-medium text-foreground mb-1">No messages</h3>
        <p className="text-sm text-muted-foreground max-w-xs">
          Send announcements and updates to your event attendees
        </p>
      </div>
    </div>
  );
};
