import * as React from "react";
import { createPortal } from "react-dom";

import { cn } from "@/lib/utils";

type Align = "start" | "center" | "end";

type DropdownMenuContextValue = {
  open: boolean;
  setOpen: (open: boolean) => void;
  triggerRef: React.RefObject<HTMLElement>;
};

const DropdownMenuContext = React.createContext<DropdownMenuContextValue | null>(null);

function useDropdownCtx(component: string) {
  const ctx = React.useContext(DropdownMenuContext);
  if (!ctx) throw new Error(`${component} must be used within <DropdownMenu>`);
  return ctx;
}

/**
 * NOTE: We intentionally avoid Radix DropdownMenu here because in some environments it can crash
 * at runtime with Popper scope/version issues (e.g. `createPopperScope is not a function`).
 */
export const DropdownMenu: React.FC<{
  children: React.ReactNode;
  open?: boolean;
  defaultOpen?: boolean;
  onOpenChange?: (open: boolean) => void;
}> = ({ children, open: openProp, defaultOpen = false, onOpenChange }) => {
  const [uncontrolledOpen, setUncontrolledOpen] = React.useState(defaultOpen);
  const open = openProp ?? uncontrolledOpen;

  const setOpen = React.useCallback(
    (next: boolean) => {
      onOpenChange?.(next);
      if (openProp === undefined) setUncontrolledOpen(next);
    },
    [onOpenChange, openProp],
  );

  const triggerRef = React.useRef<HTMLElement>(null);
  return <DropdownMenuContext.Provider value={{ open, setOpen, triggerRef }}>{children}</DropdownMenuContext.Provider>;
};

export const DropdownMenuTrigger = React.forwardRef<HTMLElement, { asChild?: boolean; children: React.ReactElement }>(
  ({ children }, forwardedRef) => {
    const { open, setOpen, triggerRef } = useDropdownCtx("DropdownMenuTrigger");

    return React.cloneElement(children, {
      ref: (node: any) => {
        triggerRef.current = node;

        const childRef = (children as any).ref;
        if (typeof childRef === "function") childRef(node);
        else if (childRef && typeof childRef === "object") childRef.current = node;

        if (typeof forwardedRef === "function") forwardedRef(node);
        else if (forwardedRef && typeof forwardedRef === "object") (forwardedRef as any).current = node;
      },
      onClick: (e: any) => {
        children.props?.onClick?.(e);
        setOpen(!open);
      },
      "aria-expanded": open,
    } as any);
  },
);
DropdownMenuTrigger.displayName = "DropdownMenuTrigger";

export const DropdownMenuContent = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement> & { sideOffset?: number; align?: Align }
>(({ className, sideOffset = 6, align = "end", style, ...props }, forwardedRef) => {
  const { open, setOpen, triggerRef } = useDropdownCtx("DropdownMenuContent");
  const contentRef = React.useRef<HTMLDivElement | null>(null);
  const [pos, setPos] = React.useState<{ top: number; left: number } | null>(null);

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
    setPos({ top, left: rect.right });

    const raf = window.requestAnimationFrame(() => {
      const w = contentRef.current?.offsetWidth ?? 0;
      let left = rect.left;
      if (align === "start") left = rect.left;
      if (align === "center") left = rect.left + rect.width / 2 - w / 2;
      if (align === "end") left = rect.right - w;
      setPos({ top, left: Math.max(8, left) });
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
        "z-50 min-w-[10rem] overflow-hidden rounded-md border bg-popover p-1 text-popover-foreground shadow-md",
        className,
      )}
      style={{ position: "fixed", top: pos?.top ?? 0, left: pos?.left ?? 0, ...style }}
      role="menu"
      {...props}
    />,
    document.body,
  );
});
DropdownMenuContent.displayName = "DropdownMenuContent";

export const DropdownMenuItem = React.forwardRef<
  HTMLButtonElement,
  React.ButtonHTMLAttributes<HTMLButtonElement> & { inset?: boolean }
>(({ className, inset, onClick, ...props }, forwardedRef) => {
  const { setOpen } = useDropdownCtx("DropdownMenuItem");

  return (
    <button
      type="button"
      role="menuitem"
      ref={forwardedRef}
      className={cn(
        "flex w-full items-center rounded-sm px-2 py-1.5 text-sm text-left outline-none transition-colors hover:bg-accent hover:text-accent-foreground",
        inset && "pl-8",
        className,
      )}
      onClick={(e) => {
        onClick?.(e);
        setOpen(false);
      }}
      {...props}
    />
  );
});
DropdownMenuItem.displayName = "DropdownMenuItem";

export const DropdownMenuSeparator = ({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) => (
  <div className={cn("-mx-1 my-1 h-px bg-muted", className)} {...props} />
);

export const DropdownMenuLabel = ({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) => (
  <div className={cn("px-2 py-1.5 text-sm font-semibold", className)} {...props} />
);

export const DropdownMenuShortcut = ({ className, ...props }: React.HTMLAttributes<HTMLSpanElement>) => (
  <span className={cn("ml-auto text-xs tracking-widest opacity-60", className)} {...props} />
);

// API compatibility exports (not implemented)
export const DropdownMenuGroup: React.FC<{ children: React.ReactNode }> = ({ children }) => <>{children}</>;
export const DropdownMenuPortal: React.FC<{ children: React.ReactNode }> = ({ children }) => <>{children}</>;
export const DropdownMenuSub: React.FC<{ children: React.ReactNode }> = ({ children }) => <>{children}</>;
export const DropdownMenuRadioGroup: React.FC<{ children: React.ReactNode }> = ({ children }) => <>{children}</>;
export const DropdownMenuSubTrigger: React.FC<React.HTMLAttributes<HTMLDivElement> & { inset?: boolean }> = ({
  className,
  inset,
  ...props
}) => <div className={cn("px-2 py-1.5 text-sm", inset && "pl-8", className)} {...props} />;
export const DropdownMenuSubContent: React.FC<React.HTMLAttributes<HTMLDivElement>> = ({ className, ...props }) => (
  <div className={cn("min-w-[8rem] rounded-md border bg-popover p-1 text-popover-foreground shadow-md", className)} {...props} />
);
export const DropdownMenuCheckboxItem: typeof DropdownMenuItem = DropdownMenuItem as any;
export const DropdownMenuRadioItem: typeof DropdownMenuItem = DropdownMenuItem as any;

