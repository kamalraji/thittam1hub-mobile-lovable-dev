import * as React from "react";
import { createPortal } from "react-dom";

import { cn } from "@/lib/utils";

type Align = "start" | "center" | "end";

type PopoverContextValue = {
  open: boolean;
  setOpen: (open: boolean) => void;
  triggerRef: React.RefObject<HTMLElement>;
};

const PopoverContext = React.createContext<PopoverContextValue | null>(null);

function usePopoverCtx(component: string) {
  const ctx = React.useContext(PopoverContext);
  if (!ctx) throw new Error(`${component} must be used within <Popover>`);
  return ctx;
}

export const Popover: React.FC<{
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

  return <PopoverContext.Provider value={{ open, setOpen, triggerRef }}>{children}</PopoverContext.Provider>;
};

export const PopoverTrigger = React.forwardRef<HTMLElement, { asChild?: boolean; children: React.ReactElement }>(
  ({ children }, forwardedRef) => {
    const { open, setOpen, triggerRef } = usePopoverCtx("PopoverTrigger");

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
PopoverTrigger.displayName = "PopoverTrigger";

export const PopoverContent = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement> & { align?: Align; sideOffset?: number }
>(({ className, align = "center", sideOffset = 4, style, ...props }, forwardedRef) => {
  const { open, setOpen, triggerRef } = usePopoverCtx("PopoverContent");
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

    // First pass uses start alignment; a rAF will adjust once content measures.
    setPos({ top, left: rect.left });

    const raf = window.requestAnimationFrame(() => {
      const w = contentRef.current?.offsetWidth ?? 0;
      let left = rect.left;
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
      role="dialog"
      className={cn(
        "z-50 w-72 rounded-md border bg-popover p-4 text-popover-foreground shadow-md outline-none",
        className,
      )}
      style={{ position: "fixed", top: pos?.top ?? 0, left: pos?.left ?? 0, ...style }}
      {...props}
    />,
    document.body,
  );
});
PopoverContent.displayName = "PopoverContent";

