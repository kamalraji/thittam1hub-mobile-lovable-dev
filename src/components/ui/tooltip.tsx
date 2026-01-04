import * as React from "react";
import { cn } from "../../lib/utils";

/**
 * SafeTooltipProvider - A lightweight tooltip provider that avoids 
 * Radix UI runtime crashes from version conflicts
 */
const TooltipContext = React.createContext<{
  delayDuration?: number;
}>({ delayDuration: 400 });

interface TooltipProviderProps {
  children: React.ReactNode;
  delayDuration?: number;
  skipDelayDuration?: number;
  disableHoverableContent?: boolean;
}

const TooltipProvider: React.FC<TooltipProviderProps> = ({ 
  children, 
  delayDuration = 400 
}) => {
  const value = React.useMemo(() => ({ delayDuration }), [delayDuration]);
  return (
    <TooltipContext.Provider value={value}>
      {children}
    </TooltipContext.Provider>
  );
};
TooltipProvider.displayName = "TooltipProvider";

interface TooltipProps {
  children: React.ReactNode;
  open?: boolean;
  defaultOpen?: boolean;
  onOpenChange?: (open: boolean) => void;
  delayDuration?: number;
}

interface TooltipContextValue {
  open: boolean;
  setOpen: (open: boolean) => void;
  triggerRef: React.RefObject<HTMLElement | null>;
  delayDuration: number;
}

const TooltipStateContext = React.createContext<TooltipContextValue | null>(null);

const Tooltip: React.FC<TooltipProps> = ({ 
  children, 
  open: controlledOpen, 
  defaultOpen = false,
  onOpenChange,
  delayDuration: propDelayDuration
}) => {
  const providerContext = React.useContext(TooltipContext);
  const delayDuration = propDelayDuration ?? providerContext.delayDuration ?? 400;
  
  const [internalOpen, setInternalOpen] = React.useState(defaultOpen);
  const isControlled = controlledOpen !== undefined;
  const open = isControlled ? controlledOpen : internalOpen;
  
  const triggerRef = React.useRef<HTMLElement | null>(null);
  
  const setOpen = React.useCallback((newOpen: boolean) => {
    if (!isControlled) {
      setInternalOpen(newOpen);
    }
    onOpenChange?.(newOpen);
  }, [isControlled, onOpenChange]);
  
  const value = React.useMemo(() => ({
    open,
    setOpen,
    triggerRef,
    delayDuration,
  }), [open, setOpen, delayDuration]);
  
  return (
    <TooltipStateContext.Provider value={value}>
      {children}
    </TooltipStateContext.Provider>
  );
};
Tooltip.displayName = "Tooltip";

interface TooltipTriggerProps extends React.HTMLAttributes<HTMLElement> {
  asChild?: boolean;
  children: React.ReactElement | React.ReactNode;
}

const TooltipTrigger = React.forwardRef<HTMLElement, TooltipTriggerProps>(
  ({ asChild, children, ...props }, forwardedRef) => {
    const context = React.useContext(TooltipStateContext);
    const timeoutRef = React.useRef<ReturnType<typeof setTimeout>>();
    
    const handleMouseEnter = React.useCallback(() => {
      if (!context) return;
      
      timeoutRef.current = setTimeout(() => {
        context.setOpen(true);
      }, context.delayDuration);
    }, [context]);
    
    const handleMouseLeave = React.useCallback(() => {
      if (!context) return;
      
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current);
      }
      context.setOpen(false);
    }, [context]);
    
    const handleFocus = React.useCallback(() => {
      context?.setOpen(true);
    }, [context]);
    
    const handleBlur = React.useCallback(() => {
      context?.setOpen(false);
    }, [context]);
    
    React.useEffect(() => {
      return () => {
        if (timeoutRef.current) {
          clearTimeout(timeoutRef.current);
        }
      };
    }, []);
    
    const childProps = {
      ...props,
      onMouseEnter: handleMouseEnter,
      onMouseLeave: handleMouseLeave,
      onFocus: handleFocus,
      onBlur: handleBlur,
      ref: (node: HTMLElement | null) => {
        if (context) {
          (context.triggerRef as React.MutableRefObject<HTMLElement | null>).current = node;
        }
        if (typeof forwardedRef === 'function') {
          forwardedRef(node);
        } else if (forwardedRef) {
          forwardedRef.current = node;
        }
      },
    };
    
    if (asChild && React.isValidElement(children)) {
      return React.cloneElement(children, childProps);
    }
    
    return (
      <span {...childProps}>
        {children}
      </span>
    );
  }
);
TooltipTrigger.displayName = "TooltipTrigger";

interface TooltipContentProps extends React.HTMLAttributes<HTMLDivElement> {
  side?: "top" | "right" | "bottom" | "left";
  sideOffset?: number;
  align?: "start" | "center" | "end";
  hidden?: boolean;
}

const TooltipContent = React.forwardRef<HTMLDivElement, TooltipContentProps>(
  ({ className, side = "top", sideOffset = 4, align = "center", hidden, children, ...props }, ref) => {
    const context = React.useContext(TooltipStateContext);
    const [position, setPosition] = React.useState({ top: 0, left: 0 });
    const contentRef = React.useRef<HTMLDivElement | null>(null);
    
    const combinedRef = React.useCallback((node: HTMLDivElement | null) => {
      contentRef.current = node;
      if (typeof ref === 'function') {
        ref(node);
      } else if (ref) {
        ref.current = node;
      }
    }, [ref]);
    
    // Calculate position based on trigger element
    React.useLayoutEffect(() => {
      if (!context?.open || !context.triggerRef.current || !contentRef.current) {
        return;
      }
      
      const triggerRect = context.triggerRef.current.getBoundingClientRect();
      const contentRect = contentRef.current.getBoundingClientRect();
      
      let top = 0;
      let left = 0;
      
      switch (side) {
        case "top":
          top = triggerRect.top - contentRect.height - sideOffset;
          left = triggerRect.left + (triggerRect.width - contentRect.width) / 2;
          break;
        case "bottom":
          top = triggerRect.bottom + sideOffset;
          left = triggerRect.left + (triggerRect.width - contentRect.width) / 2;
          break;
        case "left":
          top = triggerRect.top + (triggerRect.height - contentRect.height) / 2;
          left = triggerRect.left - contentRect.width - sideOffset;
          break;
        case "right":
          top = triggerRect.top + (triggerRect.height - contentRect.height) / 2;
          left = triggerRect.right + sideOffset;
          break;
      }
      
      // Apply alignment adjustments
      if (side === "top" || side === "bottom") {
        if (align === "start") {
          left = triggerRect.left;
        } else if (align === "end") {
          left = triggerRect.right - contentRect.width;
        }
      } else {
        if (align === "start") {
          top = triggerRect.top;
        } else if (align === "end") {
          top = triggerRect.bottom - contentRect.height;
        }
      }
      
      // Ensure tooltip stays in viewport
      const padding = 8;
      left = Math.max(padding, Math.min(left, window.innerWidth - contentRect.width - padding));
      top = Math.max(padding, Math.min(top, window.innerHeight - contentRect.height - padding));
      
      setPosition({ top, left });
    }, [context?.open, context?.triggerRef, side, sideOffset, align]);
    
    if (!context?.open || hidden) {
      return null;
    }
    
    return (
      <div
        ref={combinedRef}
        role="tooltip"
        style={{
          position: 'fixed',
          top: position.top,
          left: position.left,
          zIndex: 50,
        }}
        className={cn(
          "overflow-hidden rounded-md border bg-popover px-3 py-1.5 text-sm text-popover-foreground shadow-md animate-in fade-in-0 zoom-in-95",
          className,
        )}
        {...props}
      >
        {children}
      </div>
    );
  }
);
TooltipContent.displayName = "TooltipContent";

export { Tooltip, TooltipTrigger, TooltipContent, TooltipProvider };
