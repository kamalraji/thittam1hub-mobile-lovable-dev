import React, { useState } from 'react';
import { Search, Calendar, Briefcase, Users, X } from 'lucide-react';
import { Input } from '@/components/ui/input';
import { useNavigate } from 'react-router-dom';

interface MobileSearchViewProps {
  organization: {
    id: string;
    slug: string;
  };
}

export const MobileSearchView: React.FC<MobileSearchViewProps> = ({ organization }) => {
  const navigate = useNavigate();
  const [query, setQuery] = useState('');

  const recentSearches = [
    'Annual Conference 2024',
    'Team Meeting',
    'Product Launch',
  ];

  const quickLinks = [
    { label: 'Events', icon: Calendar, path: `/${organization.slug}/eventmanagement` },
    { label: 'Workspaces', icon: Briefcase, path: `/${organization.slug}/workspaces` },
    { label: 'Team', icon: Users, path: `/${organization.slug}/team` },
  ];

  return (
    <div className="px-4 py-4 space-y-6">
      {/* Search Input */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground" />
        <Input
          type="search"
          placeholder="Search events, workspaces, team..."
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          className="pl-10 pr-10 h-12 rounded-xl bg-card border-border"
        />
        {query && (
          <button
            onClick={() => setQuery('')}
            className="absolute right-3 top-1/2 -translate-y-1/2 p-1 rounded-full hover:bg-muted"
          >
            <X className="h-4 w-4 text-muted-foreground" />
          </button>
        )}
      </div>

      {/* Quick Links */}
      <section>
        <h2 className="text-sm font-medium text-muted-foreground mb-3">Quick Access</h2>
        <div className="flex gap-2">
          {quickLinks.map((link) => {
            const Icon = link.icon;
            return (
              <button
                key={link.label}
                onClick={() => navigate(link.path)}
                className="flex items-center gap-2 px-4 py-2 bg-card border border-border rounded-full hover:bg-muted/50 transition-colors"
              >
                <Icon className="h-4 w-4 text-muted-foreground" />
                <span className="text-sm font-medium text-foreground">{link.label}</span>
              </button>
            );
          })}
        </div>
      </section>

      {/* Recent Searches */}
      {!query && (
        <section>
          <h2 className="text-sm font-medium text-muted-foreground mb-3">Recent Searches</h2>
          <div className="space-y-1">
            {recentSearches.map((search, index) => (
              <button
                key={index}
                onClick={() => setQuery(search)}
                className="flex items-center gap-3 w-full p-3 rounded-xl hover:bg-muted/50 transition-colors"
              >
                <Search className="h-4 w-4 text-muted-foreground" />
                <span className="text-sm text-foreground">{search}</span>
              </button>
            ))}
          </div>
        </section>
      )}

      {/* Search Results Placeholder */}
      {query && (
        <section>
          <p className="text-sm text-muted-foreground text-center py-8">
            Search functionality coming soon
          </p>
        </section>
      )}
    </div>
  );
};
