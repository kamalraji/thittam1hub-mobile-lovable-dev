import * as React from "react";
import { createPortal } from "react-dom";

import { cn } from "@/lib/utils";

type Align = "start" | "center" | "end";

type SelectContextValue = {
  open: boolean;
  setOpen: (open: boolean) => void;
  value: string | undefined;
  setValue: (value: string) => void;
  triggerRef: React.RefObject<HTMLElement>;
  items: React.MutableRefObject<Map<string, string>>;
};

const SelectContext = React.createContext<SelectContextValue | null>(null);

function useSelectCtx(component: string) {
  const ctx = React.useContext(SelectContext);
  if (!ctx) throw new Error(`${component} must be used within <Select>`);
  return ctx;
}

export const Select: React.FC<{
  children: React.ReactNode;
  value?: string;
  defaultValue?: string;
  onValueChange?: (value: string) => void;
  disabled?: boolean;
}> = ({ children, value: valueProp, defaultValue, onValueChange }) => {
  const [uncontrolledValue, setUncontrolledValue] = React.useState<string | undefined>(defaultValue);
  const [open, setOpen] = React.useState(false);
  const value = valueProp ?? uncontrolledValue;

  const triggerRef = React.useRef<HTMLElement>(null);
  const items = React.useRef<Map<string, string>>(new Map());

  const setValue = React.useCallback(
    (next: string) => {
      onValueChange?.(next);
      if (valueProp === undefined) setUncontrolledValue(next);
    },
    [onValueChange, valueProp],
  );

  const ctx = React.useMemo<SelectContextValue>(
    () => ({ open, setOpen, value, setValue, triggerRef, items }),
    [open, value, setValue],
  );

  return <SelectContext.Provider value={ctx}>{children}</SelectContext.Provider>;
};

export const SelectGroup: React.FC<{ children: React.ReactNode }> = ({ children }) => <>{children}</>;

export const SelectValue: React.FC<{ placeholder?: string }> = ({ placeholder }) => {
  const { value, items } = useSelectCtx("SelectValue");
  const label = value ? items.current.get(value) : undefined;
  return <span className={cn(!label ? "text-muted-foreground" : "text-foreground")}>{label ?? placeholder ?? ""}</span>;
};

export const SelectTrigger = React.forwardRef<
  HTMLButtonElement,
  React.ButtonHTMLAttributes<HTMLButtonElement> & { children: React.ReactNode }
>(({ className, children, onClick, ...props }, forwardedRef) => {
  const { open, setOpen, triggerRef } = useSelectCtx("SelectTrigger");

  return (
    <button
      type="button"
      ref={(node) => {
        triggerRef.current = node as any;
        if (typeof forwardedRef === "function") forwardedRef(node);
        else if (forwardedRef && typeof forwardedRef === "object") (forwardedRef as any).current = node;
      }}
      className={cn(
        "flex h-10 w-full items-center justify-between rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50",
        className,
      )}
      aria-expanded={open}
      onClick={(e) => {
        onClick?.(e);
        setOpen(!open);
      }}
      {...props}
    >
      <span className="flex-1 min-w-0 text-left">{children}</span>
      <span className="ml-2 text-muted-foreground" aria-hidden>
        ▾
      </span>
    </button>
  );
});
SelectTrigger.displayName = "SelectTrigger";

export const SelectContent = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement> & { position?: "popper"; align?: Align; sideOffset?: number }
>(({ className, children, align = "start", sideOffset = 6, style, ...props }, forwardedRef) => {
  const { open, setOpen, triggerRef } = useSelectCtx("SelectContent");
  const contentRef = React.useRef<HTMLDivElement | null>(null);
  const [pos, setPos] = React.useState<{ top: number; left: number; width: number } | null>(null);

  const setRefs = React.useCallback(
    (node: HTMLDivElement | null) => {
      contentRef.current = node;
      if (typeof forwardedRef === "function") forwardedRef(node);
      else if (forwardedRef && typeof forwardedRef === "object") (forwardedRef as any).current = node;
    },
    [forwardedRef],
  );

  React.useLayoutEffect(() => {
    if (!open) return;
    const triggerEl = triggerRef.current;
    if (!triggerEl) return;

    const rect = triggerEl.getBoundingClientRect();
    const top = rect.bottom + sideOffset;
    const width = rect.width;

    setPos({ top, left: rect.left, width });

    const raf = window.requestAnimationFrame(() => {
      const w = contentRef.current?.offsetWidth ?? width;
      let left = rect.left;
      if (align === "center") left = rect.left + rect.width / 2 - w / 2;
      if (align === "end") left = rect.right - w;
      setPos({ top, left: Math.max(8, left), width });
    });

    return () => window.cancelAnimationFrame(raf);
  }, [open, align, sideOffset, triggerRef]);

  React.useEffect(() => {
    if (!open) return;

    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") setOpen(false);
    };

    const onPointerDown = (e: MouseEvent | TouchEvent) => {
      const target = e.target as Node | null;
      if (!target) return;
      const triggerEl = triggerRef.current;
      const contentEl = contentRef.current;
      if (contentEl?.contains(target)) return;
      if (triggerEl?.contains(target)) return;
      setOpen(false);
    };

    window.addEventListener("keydown", onKeyDown);
    window.addEventListener("mousedown", onPointerDown);
    window.addEventListener("touchstart", onPointerDown);
    return () => {
      window.removeEventListener("keydown", onKeyDown);
      window.removeEventListener("mousedown", onPointerDown);
      window.removeEventListener("touchstart", onPointerDown);
    };
  }, [open, setOpen, triggerRef]);

  if (!open) return null;

  return createPortal(
    <div
      ref={setRefs}
      className={cn(
        "relative z-50 max-h-96 overflow-auto rounded-md border bg-popover p-1 text-popover-foreground shadow-md",
        className,
      )}
      style={{ position: "fixed", top: pos?.top ?? 0, left: pos?.left ?? 0, minWidth: pos?.width ?? 160, ...style }}
      {...props}
    >
      {children}
    </div>,
    document.body,
  );
});
SelectContent.displayName = "SelectContent";

export const SelectLabel: React.FC<React.HTMLAttributes<HTMLDivElement>> = ({ className, ...props }) => (
  <div className={cn("py-1.5 pl-2 pr-2 text-sm font-semibold", className)} {...props} />
);

export const SelectItem = React.forwardRef<
  HTMLButtonElement,
  React.ButtonHTMLAttributes<HTMLButtonElement> & { value: string }
>(({ className, children, value, onClick, ...props }, forwardedRef) => {
  const { setOpen, setValue, items, value: selected } = useSelectCtx("SelectItem");

  React.useEffect(() => {
    const label = typeof children === "string" ? children : typeof children === "number" ? String(children) : "";
    if (label) items.current.set(value, label);
    return () => {
      if (items.current.get(value) === label) items.current.delete(value);
    };
  }, [children, items, value]);

  const isSelected = selected === value;

  return (
    <button
      ref={forwardedRef}
      type="button"
      role="option"
      aria-selected={isSelected}
      className={cn(
        "relative flex w-full select-none items-center rounded-sm px-2 py-1.5 text-sm outline-none transition-colors hover:bg-accent hover:text-accent-foreground",
        isSelected && "bg-accent text-accent-foreground",
        className,
      )}
      onClick={(e) => {
        onClick?.(e);
        setValue(value);
        setOpen(false);
      }}
      {...props}
    >
      {children}
    </button>
  );
});
SelectItem.displayName = "SelectItem";

export const SelectSeparator: React.FC<React.HTMLAttributes<HTMLDivElement>> = ({ className, ...props }) => (
  <div className={cn("-mx-1 my-1 h-px bg-muted", className)} {...props} />
);

// Kept for API compatibility; no-op in the lightweight implementation.
export const SelectScrollUpButton: React.FC = () => null;
export const SelectScrollDownButton: React.FC = () => null;
