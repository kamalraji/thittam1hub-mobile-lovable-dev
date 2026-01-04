import * as React from "react";

/**
 * NOTE: This project has experienced runtime crashes in some environments due to Radix Popper
 * scope/version issues (e.g. `createPopperScope is not a function`).
 *
 * To keep the app stable (especially in Live Preview), we provide a lightweight tooltip shim
 * that degrades to the native `title` attribute.
 */

type TooltipContextValue = {
  label: React.ReactNode | null;
  setLabel: (label: React.ReactNode | null) => void;
};

const TooltipContext = React.createContext<TooltipContextValue | null>(null);

export const TooltipProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => <>{children}</>;

export const Tooltip: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [label, setLabel] = React.useState<React.ReactNode | null>(null);
  return <TooltipContext.Provider value={{ label, setLabel }}>{children}</TooltipContext.Provider>;
};

export const TooltipTrigger = React.forwardRef<HTMLElement, { asChild?: boolean; children: React.ReactElement }>(
  ({ children }, forwardedRef) => {
    const ctx = React.useContext(TooltipContext);
    if (!ctx) return children;

    const title = typeof ctx.label === "string" ? ctx.label : undefined;

    return React.cloneElement(children, {
      title: (children.props as any).title ?? title,
      ref: (node: any) => {
        const childRef = (children as any).ref;
        if (typeof childRef === "function") childRef(node);
        else if (childRef && typeof childRef === "object") childRef.current = node;

        if (typeof forwardedRef === "function") forwardedRef(node);
        else if (forwardedRef && typeof forwardedRef === "object") (forwardedRef as any).current = node;
      },
    } as any);
  },
);
TooltipTrigger.displayName = "TooltipTrigger";

export const TooltipContent = React.forwardRef<
  HTMLDivElement,
  React.HTMLAttributes<HTMLDivElement> & {
    side?: "top" | "right" | "bottom" | "left";
    align?: "start" | "center" | "end";
    sideOffset?: number;
    hidden?: boolean;
  }
>(({ children }, _ref) => {
  const ctx = React.useContext(TooltipContext);
  React.useEffect(() => {
    ctx?.setLabel(children ?? null);
    return () => ctx?.setLabel(null);
  }, [ctx, children]);
  return null;
});
TooltipContent.displayName = "TooltipContent";
