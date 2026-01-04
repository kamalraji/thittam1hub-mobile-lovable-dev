import React from 'react';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Checkbox } from '@/components/ui/checkbox';
import { Card, CardContent } from '@/components/ui/card';
import { Search, MapPin } from 'lucide-react';
import { ServiceCategory, SearchFilters, formatCategory } from './types';

interface ServiceFiltersProps {
  filters: SearchFilters;
  onFilterChange: (newFilters: Partial<SearchFilters>) => void;
}

export const ServiceFilters: React.FC<ServiceFiltersProps> = ({ filters, onFilterChange }) => {
  return (
    <Card className="border-border/60">
      <CardContent className="p-5">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {/* Search Query */}
          <div className="space-y-2">
            <Label htmlFor="search" className="text-sm font-medium text-foreground">
              Search Services
            </Label>
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
                id="search"
                type="text"
                placeholder="e.g., wedding photography..."
                value={filters.query || ''}
                onChange={(e) => onFilterChange({ query: e.target.value })}
                className="pl-9"
              />
            </div>
          </div>

          {/* Category Filter */}
          <div className="space-y-2">
            <Label className="text-sm font-medium text-foreground">Category</Label>
            <Select
              value={filters.category || 'all'}
              onValueChange={(value) => onFilterChange({ category: value === 'all' ? undefined : value as ServiceCategory })}
            >
              <SelectTrigger>
                <SelectValue placeholder="All Categories" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Categories</SelectItem>
                {Object.values(ServiceCategory).map((category) => (
                  <SelectItem key={category} value={category}>
                    {formatCategory(category)}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          {/* Location Filter */}
          <div className="space-y-2">
            <Label htmlFor="location" className="text-sm font-medium text-foreground">
              Location
            </Label>
            <div className="relative">
              <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
                id="location"
                type="text"
                placeholder="City, State"
                value={filters.location || ''}
                onChange={(e) => onFilterChange({ location: e.target.value })}
                className="pl-9"
              />
            </div>
          </div>

          {/* Sort By */}
          <div className="space-y-2">
            <Label className="text-sm font-medium text-foreground">Sort By</Label>
            <Select
              value={filters.sortBy}
              onValueChange={(value) => onFilterChange({ sortBy: value as SearchFilters['sortBy'] })}
            >
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="relevance">Relevance</SelectItem>
                <SelectItem value="price">Price</SelectItem>
                <SelectItem value="rating">Rating</SelectItem>
                <SelectItem value="distance">Distance</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>

        {/* Additional Filters */}
        <div className="mt-4 flex items-center space-x-2">
          <Checkbox
            id="verified"
            checked={filters.verifiedOnly}
            onCheckedChange={(checked) => onFilterChange({ verifiedOnly: checked === true })}
          />
          <Label htmlFor="verified" className="text-sm text-muted-foreground cursor-pointer">
            Verified vendors only
          </Label>
        </div>
      </CardContent>
    </Card>
  );
};
