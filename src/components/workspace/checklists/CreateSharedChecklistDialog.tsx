import { useState } from 'react';
import { Plus, Trash2, GripVertical } from 'lucide-react';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';

interface CreateSharedChecklistDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (data: {
    title: string;
    description?: string;
    phase: 'pre_event' | 'during_event' | 'post_event';
    items: { title: string; description?: string }[];
    dueDate?: string;
  }) => void;
  isSubmitting: boolean;
}

export function CreateSharedChecklistDialog({
  open,
  onOpenChange,
  onSubmit,
  isSubmitting,
}: CreateSharedChecklistDialogProps) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [phase, setPhase] = useState<'pre_event' | 'during_event' | 'post_event'>('pre_event');
  const [dueDate, setDueDate] = useState('');
  const [items, setItems] = useState<{ title: string; description?: string }[]>([
    { title: '', description: '' },
  ]);

  const handleAddItem = () => {
    setItems([...items, { title: '', description: '' }]);
  };

  const handleRemoveItem = (index: number) => {
    if (items.length > 1) {
      setItems(items.filter((_, i) => i !== index));
    }
  };

  const handleItemChange = (index: number, field: 'title' | 'description', value: string) => {
    const newItems = [...items];
    newItems[index] = { ...newItems[index], [field]: value };
    setItems(newItems);
  };

  const handleSubmit = () => {
    if (!title.trim()) return;
    
    const validItems = items.filter(item => item.title.trim());
    if (validItems.length === 0) return;

    onSubmit({
      title: title.trim(),
      description: description.trim() || undefined,
      phase,
      items: validItems,
      dueDate: dueDate || undefined,
    });

    // Reset form
    setTitle('');
    setDescription('');
    setPhase('pre_event');
    setDueDate('');
    setItems([{ title: '', description: '' }]);
  };

  const handleClose = () => {
    onOpenChange(false);
    // Reset form on close
    setTitle('');
    setDescription('');
    setPhase('pre_event');
    setDueDate('');
    setItems([{ title: '', description: '' }]);
  };

  const isValid = title.trim() && items.some(item => item.title.trim());

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="max-w-lg max-h-[85vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Create Shared Checklist</DialogTitle>
        </DialogHeader>

        <div className="space-y-4 py-4">
          {/* Title */}
          <div className="space-y-2">
            <Label htmlFor="title">Title *</Label>
            <Input
              id="title"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="e.g., Pre-Event Setup Tasks"
            />
          </div>

          {/* Description */}
          <div className="space-y-2">
            <Label htmlFor="description">Description</Label>
            <Textarea
              id="description"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Brief description of this checklist..."
              rows={2}
            />
          </div>

          {/* Phase */}
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label>Phase *</Label>
              <Select value={phase} onValueChange={(v) => setPhase(v as typeof phase)}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="pre_event">Pre-Event</SelectItem>
                  <SelectItem value="during_event">During Event</SelectItem>
                  <SelectItem value="post_event">Post-Event</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {/* Due Date */}
            <div className="space-y-2">
              <Label htmlFor="dueDate">Due Date</Label>
              <Input
                id="dueDate"
                type="date"
                value={dueDate}
                onChange={(e) => setDueDate(e.target.value)}
              />
            </div>
          </div>

          {/* Items */}
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <Label>Checklist Items *</Label>
              <Button type="button" variant="ghost" size="sm" onClick={handleAddItem}>
                <Plus className="h-4 w-4 mr-1" />
                Add Item
              </Button>
            </div>

            <div className="space-y-2">
              {items.map((item, index) => (
                <div key={index} className="flex items-start gap-2">
                  <div className="pt-2.5 text-muted-foreground">
                    <GripVertical className="h-4 w-4" />
                  </div>
                  <div className="flex-1 space-y-1">
                    <Input
                      value={item.title}
                      onChange={(e) => handleItemChange(index, 'title', e.target.value)}
                      placeholder={`Item ${index + 1}`}
                    />
                  </div>
                  <Button
                    type="button"
                    variant="ghost"
                    size="icon"
                    className="h-9 w-9 text-muted-foreground hover:text-destructive"
                    onClick={() => handleRemoveItem(index)}
                    disabled={items.length === 1}
                  >
                    <Trash2 className="h-4 w-4" />
                  </Button>
                </div>
              ))}
            </div>
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={handleClose}>
            Cancel
          </Button>
          <Button onClick={handleSubmit} disabled={!isValid || isSubmitting}>
            {isSubmitting ? 'Creating...' : 'Create Checklist'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
