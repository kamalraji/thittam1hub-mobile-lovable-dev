import React, { useState } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Loader2 } from 'lucide-react';
import api from '@/lib/api';
import { ServiceListing, formatPrice } from './types';
import { useToast } from '@/hooks/use-toast';

interface BookingRequestModalProps {
  service: ServiceListing;
  eventId?: string;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export const BookingRequestModal: React.FC<BookingRequestModalProps> = ({ 
  service, 
  eventId, 
  open, 
  onOpenChange 
}) => {
  const { toast } = useToast();
  const [bookingData, setBookingData] = useState({
    serviceDate: '',
    requirements: '',
    budgetMin: '',
    budgetMax: '',
    additionalNotes: ''
  });
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!eventId) return;

    setIsSubmitting(true);
    try {
      await api.post('/marketplace/bookings', {
        eventId,
        serviceListingId: service.id,
        serviceDate: bookingData.serviceDate,
        requirements: bookingData.requirements,
        budgetRange: bookingData.budgetMin && bookingData.budgetMax ? {
          min: parseFloat(bookingData.budgetMin),
          max: parseFloat(bookingData.budgetMax)
        } : undefined,
        additionalNotes: bookingData.additionalNotes
      });

      toast({
        title: 'Request sent',
        description: 'Your booking request has been sent successfully.',
      });
      onOpenChange(false);
    } catch (error) {
      console.error('Failed to create booking request:', error);
      toast({
        title: 'Error',
        description: 'Failed to send booking request. Please try again.',
        variant: 'destructive',
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Request Quote</DialogTitle>
        </DialogHeader>

        {/* Service Summary */}
        <div className="bg-muted rounded-lg p-4 mb-4">
          <h3 className="font-medium text-foreground mb-1">{service.title}</h3>
          <p className="text-sm text-muted-foreground mb-1">{service.vendor.businessName}</p>
          <p className="text-sm text-muted-foreground">{formatPrice(service.pricing)}</p>
        </div>

        {/* Booking Form */}
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="serviceDate">Service Date *</Label>
            <Input
              id="serviceDate"
              type="date"
              required
              value={bookingData.serviceDate}
              onChange={(e) => setBookingData(prev => ({ ...prev, serviceDate: e.target.value }))}
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="requirements">Requirements *</Label>
            <Textarea
              id="requirements"
              required
              rows={4}
              placeholder="Describe your specific requirements for this service..."
              value={bookingData.requirements}
              onChange={(e) => setBookingData(prev => ({ ...prev, requirements: e.target.value }))}
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="budgetMin">Budget Range (Min)</Label>
              <Input
                id="budgetMin"
                type="number"
                placeholder="0"
                value={bookingData.budgetMin}
                onChange={(e) => setBookingData(prev => ({ ...prev, budgetMin: e.target.value }))}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="budgetMax">Budget Range (Max)</Label>
              <Input
                id="budgetMax"
                type="number"
                placeholder="0"
                value={bookingData.budgetMax}
                onChange={(e) => setBookingData(prev => ({ ...prev, budgetMax: e.target.value }))}
              />
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="additionalNotes">Additional Notes</Label>
            <Textarea
              id="additionalNotes"
              rows={3}
              placeholder="Any additional information or special requests..."
              value={bookingData.additionalNotes}
              onChange={(e) => setBookingData(prev => ({ ...prev, additionalNotes: e.target.value }))}
            />
          </div>

          <div className="flex justify-end gap-3 pt-4">
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>
              Cancel
            </Button>
            <Button type="submit" disabled={isSubmitting}>
              {isSubmitting && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
              {isSubmitting ? 'Sending...' : 'Send Request'}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
};
