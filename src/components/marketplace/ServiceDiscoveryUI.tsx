import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import api from '@/lib/api';
import { Loader2, Search } from 'lucide-react';
import { ServiceListing, SearchFilters } from './types';
import { ServiceFilters } from './ServiceFilters';
import { ServiceCard } from './ServiceCard';
import { BookingRequestModal } from './BookingRequestModal';

interface ServiceDiscoveryUIProps {
  eventId?: string;
}

const ServiceDiscoveryUI: React.FC<ServiceDiscoveryUIProps> = ({ eventId }) => {
  const [filters, setFilters] = useState<SearchFilters>({
    verifiedOnly: true,
    sortBy: 'relevance'
  });
  const [selectedService, setSelectedService] = useState<ServiceListing | null>(null);
  const [showBookingModal, setShowBookingModal] = useState(false);

  const { data: services, isLoading } = useQuery({
    queryKey: ['marketplace-services', filters],
    queryFn: async () => {
      const params = new URLSearchParams();
      
      if (filters.query) params.append('query', filters.query);
      if (filters.category) params.append('category', filters.category);
      if (filters.location) params.append('location', filters.location);
      if (filters.budgetRange?.min) params.append('minBudget', filters.budgetRange.min.toString());
      if (filters.budgetRange?.max) params.append('maxBudget', filters.budgetRange.max.toString());
      if (filters.verifiedOnly) params.append('verifiedOnly', 'true');
      params.append('sortBy', filters.sortBy);

      const response = await api.get(`/marketplace/services/search?${params.toString()}`);
      return response.data.services as ServiceListing[];
    },
  });

  const handleFilterChange = (newFilters: Partial<SearchFilters>) => {
    setFilters(prev => ({ ...prev, ...newFilters }));
  };

  const handleBookService = (service: ServiceListing) => {
    setSelectedService(service);
    setShowBookingModal(true);
  };

  return (
    <div className="space-y-6">
      {/* Search and Filters */}
      <ServiceFilters filters={filters} onFilterChange={handleFilterChange} />

      {/* Service Listings */}
      <div className="space-y-4">
        {isLoading ? (
          <div className="flex items-center justify-center py-12">
            <Loader2 className="h-8 w-8 animate-spin text-primary" />
          </div>
        ) : services && services.length > 0 ? (
          services.map((service) => (
            <ServiceCard
              key={service.id}
              service={service}
              onBookService={handleBookService}
            />
          ))
        ) : (
          <div className="text-center py-12">
            <Search className="mx-auto h-12 w-12 text-muted-foreground/40 mb-4" />
            <h3 className="text-lg font-medium text-foreground mb-2">No services found</h3>
            <p className="text-muted-foreground">Try adjusting your search criteria or browse all categories.</p>
          </div>
        )}
      </div>

      {/* Booking Modal */}
      {selectedService && (
        <BookingRequestModal
          service={selectedService}
          eventId={eventId}
          open={showBookingModal}
          onOpenChange={(open) => {
            setShowBookingModal(open);
            if (!open) setSelectedService(null);
          }}
        />
      )}
    </div>
  );
};

export default ServiceDiscoveryUI;
