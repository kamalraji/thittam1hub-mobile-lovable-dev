import React, { useState, useEffect, useRef, useCallback } from 'react';
import { useQuery, useInfiniteQuery } from '@tanstack/react-query';
import api from '@/lib/api';
import { Search, LayoutGrid, List } from 'lucide-react';
import { ServiceListing, SearchFilters } from './types';
import { ServiceFilters } from './ServiceFilters';
import { ServiceCard } from './ServiceCard';
import { ServiceCardSkeleton } from './ServiceCardSkeleton';
import { BookingRequestModal } from './BookingRequestModal';
import { Toggle } from '@/components/ui/toggle';
import {
  Pagination,
  PaginationContent,
  PaginationEllipsis,
  PaginationItem,
  PaginationLink,
  PaginationNext,
  PaginationPrevious,
} from '@/components/ui/pagination';

const ITEMS_PER_PAGE = 10;

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
  const [currentPage, setCurrentPage] = useState(1);
  const [useInfiniteScroll, setUseInfiniteScroll] = useState(false);
  
  const loadMoreRef = useRef<HTMLDivElement>(null);

  // Build query params helper
  const buildParams = (page: number) => {
    const params = new URLSearchParams();
    if (filters.query) params.append('query', filters.query);
    if (filters.category) params.append('category', filters.category);
    if (filters.location) params.append('location', filters.location);
    if (filters.budgetRange?.min) params.append('minBudget', filters.budgetRange.min.toString());
    if (filters.budgetRange?.max) params.append('maxBudget', filters.budgetRange.max.toString());
    if (filters.verifiedOnly) params.append('verifiedOnly', 'true');
    params.append('sortBy', filters.sortBy);
    params.append('page', page.toString());
    params.append('limit', ITEMS_PER_PAGE.toString());
    return params;
  };

  // Paginated query
  const paginatedQuery = useQuery({
    queryKey: ['marketplace-services', filters, currentPage],
    queryFn: async () => {
      const params = buildParams(currentPage);
      const response = await api.get(`/marketplace/services/search?${params.toString()}`);
      return {
        services: response.data.services as ServiceListing[],
        totalCount: response.data.totalCount as number || 0,
      };
    },
    enabled: !useInfiniteScroll,
  });

  // Infinite scroll query
  const infiniteQuery = useInfiniteQuery({
    queryKey: ['marketplace-services-infinite', filters],
    queryFn: async ({ pageParam = 1 }) => {
      const params = buildParams(pageParam);
      const response = await api.get(`/marketplace/services/search?${params.toString()}`);
      return {
        services: response.data.services as ServiceListing[],
        totalCount: response.data.totalCount as number || 0,
        nextPage: pageParam + 1,
      };
    },
    getNextPageParam: (lastPage, allPages) => {
      const totalLoaded = allPages.reduce((acc, page) => acc + page.services.length, 0);
      return totalLoaded < lastPage.totalCount ? lastPage.nextPage : undefined;
    },
    initialPageParam: 1,
    enabled: useInfiniteScroll,
  });

  // Intersection observer for infinite scroll
  useEffect(() => {
    if (!useInfiniteScroll) return;

    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting && infiniteQuery.hasNextPage && !infiniteQuery.isFetchingNextPage) {
          infiniteQuery.fetchNextPage();
        }
      },
      { threshold: 0.1 }
    );

    if (loadMoreRef.current) {
      observer.observe(loadMoreRef.current);
    }

    return () => observer.disconnect();
  }, [useInfiniteScroll, infiniteQuery.hasNextPage, infiniteQuery.isFetchingNextPage, infiniteQuery.fetchNextPage]);

  // Derived state
  const isLoading = useInfiniteScroll ? infiniteQuery.isLoading : paginatedQuery.isLoading;
  const services = useInfiniteScroll
    ? infiniteQuery.data?.pages.flatMap(page => page.services) || []
    : paginatedQuery.data?.services || [];
  const totalCount = useInfiniteScroll
    ? infiniteQuery.data?.pages[0]?.totalCount || 0
    : paginatedQuery.data?.totalCount || 0;
  const totalPages = Math.ceil(totalCount / ITEMS_PER_PAGE);

  const handleFilterChange = useCallback((newFilters: Partial<SearchFilters>) => {
    setFilters(prev => ({ ...prev, ...newFilters }));
    setCurrentPage(1);
  }, []);

  const handleBookService = (service: ServiceListing) => {
    setSelectedService(service);
    setShowBookingModal(true);
  };

  const handleToggleScrollMode = () => {
    setUseInfiniteScroll(prev => !prev);
    setCurrentPage(1);
  };

  const getPageNumbers = () => {
    const pages: (number | 'ellipsis')[] = [];
    if (totalPages <= 7) {
      for (let i = 1; i <= totalPages; i++) pages.push(i);
    } else {
      pages.push(1);
      if (currentPage > 3) pages.push('ellipsis');
      for (let i = Math.max(2, currentPage - 1); i <= Math.min(totalPages - 1, currentPage + 1); i++) {
        pages.push(i);
      }
      if (currentPage < totalPages - 2) pages.push('ellipsis');
      pages.push(totalPages);
    }
    return pages;
  };

  const renderSkeletons = (count: number) => (
    <>
      {Array.from({ length: count }).map((_, i) => (
        <ServiceCardSkeleton key={`skeleton-${i}`} />
      ))}
    </>
  );

  return (
    <div className="space-y-6">
      {/* Search and Filters */}
      <ServiceFilters filters={filters} onFilterChange={handleFilterChange} />

      {/* View mode toggle and results count */}
      <div className="flex items-center justify-between">
        {!isLoading && totalCount > 0 && (
          <p className="text-sm text-muted-foreground">
            {useInfiniteScroll
              ? `Showing ${services.length} of ${totalCount} services`
              : `Showing ${((currentPage - 1) * ITEMS_PER_PAGE) + 1}–${Math.min(currentPage * ITEMS_PER_PAGE, totalCount)} of ${totalCount} services`}
          </p>
        )}
        {isLoading && <div />}
        
        <div className="flex items-center gap-2">
          <span className="text-sm text-muted-foreground">View:</span>
          <Toggle
            pressed={!useInfiniteScroll}
            onPressedChange={() => !useInfiniteScroll || handleToggleScrollMode()}
            size="sm"
            aria-label="Paginated view"
          >
            <LayoutGrid className="h-4 w-4" />
          </Toggle>
          <Toggle
            pressed={useInfiniteScroll}
            onPressedChange={() => useInfiniteScroll || handleToggleScrollMode()}
            size="sm"
            aria-label="Infinite scroll view"
          >
            <List className="h-4 w-4" />
          </Toggle>
        </div>
      </div>

      {/* Service Listings */}
      <div className="space-y-4">
        {isLoading ? (
          renderSkeletons(3)
        ) : services && services.length > 0 ? (
          <>
            {services.map((service) => (
              <ServiceCard
                key={service.id}
                service={service}
                onBookService={handleBookService}
              />
            ))}
            
            {/* Infinite scroll loading indicator */}
            {useInfiniteScroll && (
              <div ref={loadMoreRef} className="py-4">
                {infiniteQuery.isFetchingNextPage && renderSkeletons(2)}
                {!infiniteQuery.hasNextPage && services.length > 0 && (
                  <p className="text-center text-sm text-muted-foreground">
                    You've reached the end of the list
                  </p>
                )}
              </div>
            )}
          </>
        ) : (
          <div className="text-center py-12">
            <Search className="mx-auto h-12 w-12 text-muted-foreground/40 mb-4" />
            <h3 className="text-lg font-medium text-foreground mb-2">No services found</h3>
            <p className="text-muted-foreground">Try adjusting your search criteria or browse all categories.</p>
          </div>
        )}
      </div>

      {/* Pagination (only for paginated mode) */}
      {!useInfiniteScroll && totalPages > 1 && (
        <Pagination>
          <PaginationContent>
            <PaginationItem>
              <PaginationPrevious
                href="#"
                onClick={(e) => {
                  e.preventDefault();
                  if (currentPage > 1) setCurrentPage(currentPage - 1);
                }}
                className={currentPage === 1 ? 'pointer-events-none opacity-50' : 'cursor-pointer'}
              />
            </PaginationItem>
            {getPageNumbers().map((page, idx) =>
              page === 'ellipsis' ? (
                <PaginationItem key={`ellipsis-${idx}`}>
                  <PaginationEllipsis />
                </PaginationItem>
              ) : (
                <PaginationItem key={page}>
                  <PaginationLink
                    href="#"
                    isActive={currentPage === page}
                    onClick={(e) => {
                      e.preventDefault();
                      setCurrentPage(page);
                    }}
                    className="cursor-pointer"
                  >
                    {page}
                  </PaginationLink>
                </PaginationItem>
              )
            )}
            <PaginationItem>
              <PaginationNext
                href="#"
                onClick={(e) => {
                  e.preventDefault();
                  if (currentPage < totalPages) setCurrentPage(currentPage + 1);
                }}
                className={currentPage === totalPages ? 'pointer-events-none opacity-50' : 'cursor-pointer'}
              />
            </PaginationItem>
          </PaginationContent>
        </Pagination>
      )}

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
