import * as React from "react";
import { cn } from "@/lib/utils";

interface SimplePopoverProps {
  children: React.ReactNode;
}

interface PopoverState {
  open: boolean;
  setOpen: React.Dispatch<React.SetStateAction<boolean>>;
  triggerRef: React.RefObject<HTMLElement>;
}

const PopoverStateContext = React.createContext<PopoverState | null>(null);

export const SimplePopover: React.FC<SimplePopoverProps> = ({ children }) => {
  const [open, setOpen] = React.useState(false);
  const triggerRef = React.useRef<HTMLElement>(null);

  return (
    <PopoverStateContext.Provider value={{ open, setOpen, triggerRef }}>
      {children}
    </PopoverStateContext.Provider>
  );
};

interface SimplePopoverTriggerProps {
  children: React.ReactNode;
  asChild?: boolean;
}

export const SimplePopoverTrigger = React.forwardRef<HTMLElement, SimplePopoverTriggerProps>(
  ({ children, asChild }, ref) => {
    const ctx = React.useContext(PopoverStateContext);
    if (!ctx) throw new Error("SimplePopoverTrigger must be used within SimplePopover");

    const { open, setOpen, triggerRef } = ctx;

    const handleClick = React.useCallback((e: React.MouseEvent) => {
      e.stopPropagation();
      setOpen((prev) => !prev);
    }, [setOpen]);

    if (asChild && React.isValidElement(children)) {
      return React.cloneElement(children as React.ReactElement<any>, {
        ref: (node: HTMLElement | null) => {
          (triggerRef as React.MutableRefObject<HTMLElement | null>).current = node;
          if (typeof ref === "function") ref(node);
          else if (ref) (ref as React.MutableRefObject<HTMLElement | null>).current = node;
        },
        onClick: (e: React.MouseEvent) => {
          handleClick(e);
          // Call original onClick if present
          const originalOnClick = (children as React.ReactElement<any>).props.onClick;
          if (originalOnClick) originalOnClick(e);
        },
        "aria-expanded": open,
        "aria-haspopup": "true",
      });
    }

    return (
      <button
        ref={(node) => {
          (triggerRef as React.MutableRefObject<HTMLElement | null>).current = node;
          if (typeof ref === "function") ref(node);
          else if (ref) (ref as React.MutableRefObject<HTMLElement | null>).current = node;
        }}
        onClick={handleClick}
        aria-expanded={open}
        aria-haspopup="true"
        type="button"
      >
        {children}
      </button>
    );
  }
);
SimplePopoverTrigger.displayName = "SimplePopoverTrigger";

interface SimplePopoverContentProps extends React.HTMLAttributes<HTMLDivElement> {
  side?: "top" | "right" | "bottom" | "left";
  align?: "start" | "center" | "end";
  sideOffset?: number;
}

export const SimplePopoverContent: React.FC<SimplePopoverContentProps> = ({
  children,
  className,
  side = "bottom",
  align = "center",
  sideOffset = 4,
  ...props
}) => {
  const ctx = React.useContext(PopoverStateContext);
  if (!ctx) throw new Error("SimplePopoverContent must be used within SimplePopover");

  const { open, setOpen, triggerRef } = ctx;
  const contentRef = React.useRef<HTMLDivElement>(null);
  const [pos, setPos] = React.useState<{ top: number; left: number } | null>(null);

  // Handle click outside
  React.useEffect(() => {
    if (!open) return;

    const handleClickOutside = (e: MouseEvent) => {
      const target = e.target as Node;
      if (
        contentRef.current &&
        !contentRef.current.contains(target) &&
        triggerRef.current &&
        !triggerRef.current.contains(target)
      ) {
        setOpen(false);
      }
    };

    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        setOpen(false);
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    document.addEventListener("keydown", handleEscape);
    
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
      document.removeEventListener("keydown", handleEscape);
    };
  }, [open, setOpen, triggerRef]);

  // Calculate position
  React.useLayoutEffect(() => {
    if (!open || !triggerRef.current) {
      setPos(null);
      return;
    }

    const updatePosition = () => {
      const triggerRect = triggerRef.current?.getBoundingClientRect();
      if (!triggerRect) return;

      const contentEl = contentRef.current;
      const contentWidth = contentEl?.offsetWidth || 288;
      const contentHeight = contentEl?.offsetHeight || 200;

      let top = 0;
      let left = 0;

      switch (side) {
        case "top":
          top = triggerRect.top - contentHeight - sideOffset;
          left = triggerRect.left + triggerRect.width / 2 - contentWidth / 2;
          break;
        case "bottom":
          top = triggerRect.bottom + sideOffset;
          left = triggerRect.left + triggerRect.width / 2 - contentWidth / 2;
          break;
        case "left":
          top = triggerRect.top + triggerRect.height / 2 - contentHeight / 2;
          left = triggerRect.left - contentWidth - sideOffset;
          break;
        case "right":
          top = triggerRect.top + triggerRect.height / 2 - contentHeight / 2;
          left = triggerRect.right + sideOffset;
          break;
      }

      // Adjust for align
      if (side === "top" || side === "bottom") {
        if (align === "start") left = triggerRect.left;
        else if (align === "end") left = triggerRect.right - contentWidth;
      } else {
        if (align === "start") top = triggerRect.top;
        else if (align === "end") top = triggerRect.bottom - contentHeight;
      }

      // Keep in viewport
      left = Math.max(8, Math.min(left, window.innerWidth - contentWidth - 8));
      top = Math.max(8, Math.min(top, window.innerHeight - contentHeight - 8));

      setPos({ top, left });
    };

    updatePosition();

    // Update on scroll/resize
    window.addEventListener("scroll", updatePosition, true);
    window.addEventListener("resize", updatePosition);

    return () => {
      window.removeEventListener("scroll", updatePosition, true);
      window.removeEventListener("resize", updatePosition);
    };
  }, [open, side, align, sideOffset, triggerRef]);

  if (!open) return null;

  return (
    <div
      ref={contentRef}
      role="dialog"
      className={cn(
        "fixed z-[9999] w-72 rounded-md border bg-popover p-4 text-popover-foreground shadow-md outline-none",
        "animate-in fade-in-0 zoom-in-95",
        className
      )}
      style={pos ? { top: pos.top, left: pos.left } : { visibility: "hidden" }}
      {...props}
    >
      {children}
    </div>
  );
};
SimplePopoverContent.displayName = "SimplePopoverContent";

// Alias exports for drop-in compatibility
export {
  SimplePopover as Popover,
  SimplePopoverTrigger as PopoverTrigger,
  SimplePopoverContent as PopoverContent,
};
