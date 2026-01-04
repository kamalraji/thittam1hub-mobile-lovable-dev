import * as React from "react";
import { ChevronDown } from "lucide-react";

import { cn } from "@/lib/utils";

/**
 * NOTE: We intentionally avoid Radix NavigationMenu here.
 * Some environments can crash at runtime with Radix scope/version issues
 * (e.g. `createRovingFocusGroupScope is not a function`).
 *
 * This lightweight implementation keeps the API surface compatible for our app.
 */

type NavMenuCtxValue = {
  openId: string | null;
  setOpenId: (id: string | null) => void;
};

const NavMenuCtx = React.createContext<NavMenuCtxValue | null>(null);

function useNavMenuCtx(component: string) {
  const ctx = React.useContext(NavMenuCtx);
  if (!ctx) throw new Error(`${component} must be used within <NavigationMenu>`);
  return ctx;
}

type NavItemCtxValue = { id: string };
const NavItemCtx = React.createContext<NavItemCtxValue | null>(null);
function useNavItemCtx(component: string) {
  const ctx = React.useContext(NavItemCtx);
  if (!ctx) throw new Error(`${component} must be used within <NavigationMenuItem>`);
  return ctx;
}

const TRIGGER_BASE =
  "group inline-flex h-10 w-max items-center justify-center rounded-md bg-background px-4 py-2 text-sm font-medium transition-colors hover:bg-accent hover:text-accent-foreground focus:bg-accent focus:text-accent-foreground focus:outline-none disabled:pointer-events-none disabled:opacity-50";

// cva-compatible API (accepts optional object with className)
const navigationMenuTriggerStyle = (args?: { className?: string }) => cn(TRIGGER_BASE, args?.className);

const NavigationMenu = React.forwardRef<HTMLElement, React.HTMLAttributes<HTMLElement>>(
  ({ className, children, ...props }, ref) => {
    const [openId, setOpenId] = React.useState<string | null>(null);

    React.useEffect(() => {
      if (!openId) return;
      const onKeyDown = (e: KeyboardEvent) => {
        if (e.key === "Escape") setOpenId(null);
      };
      window.addEventListener("keydown", onKeyDown);
      return () => window.removeEventListener("keydown", onKeyDown);
    }, [openId]);

    return (
      <NavMenuCtx.Provider value={{ openId, setOpenId }}>
        <nav ref={ref} className={cn("relative z-10 flex max-w-max flex-1 items-center justify-center", className)} {...props}>
          {children}
        </nav>
      </NavMenuCtx.Provider>
    );
  },
);
NavigationMenu.displayName = "NavigationMenu";

const NavigationMenuList = React.forwardRef<HTMLUListElement, React.HTMLAttributes<HTMLUListElement>>(
  ({ className, ...props }, ref) => (
    <ul ref={ref} className={cn("group flex flex-1 list-none items-center justify-center space-x-1", className)} {...props} />
  ),
);
NavigationMenuList.displayName = "NavigationMenuList";

const NavigationMenuItem: React.FC<React.LiHTMLAttributes<HTMLLIElement>> = ({ className, ...props }) => {
  const id = React.useId();
  return (
    <NavItemCtx.Provider value={{ id }}>
      <li className={cn("relative", className)} {...props} />
    </NavItemCtx.Provider>
  );
};

const NavigationMenuTrigger = React.forwardRef<HTMLButtonElement, React.ButtonHTMLAttributes<HTMLButtonElement>>(
  ({ className, children, onClick, ...props }, ref) => {
    const { openId, setOpenId } = useNavMenuCtx("NavigationMenuTrigger");
    const { id } = useNavItemCtx("NavigationMenuTrigger");
    const open = openId === id;

    return (
      <button
        ref={ref}
        type="button"
        aria-expanded={open}
        className={cn(navigationMenuTriggerStyle(), "group", className)}
        onClick={(e) => {
          onClick?.(e);
          setOpenId(open ? null : id);
        }}
        {...props}
      >
        {children}
        <ChevronDown
          className="relative top-[1px] ml-1 h-3 w-3 transition duration-200 group-aria-expanded:rotate-180"
          aria-hidden="true"
        />
      </button>
    );
  },
);
NavigationMenuTrigger.displayName = "NavigationMenuTrigger";

const NavigationMenuContent = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(
  ({ className, ...props }, ref) => {
    const { openId, setOpenId } = useNavMenuCtx("NavigationMenuContent");
    const { id } = useNavItemCtx("NavigationMenuContent");
    const open = openId === id;

    if (!open) return null;

    return (
      <div
        ref={ref}
        className={cn(
          "absolute left-0 top-full mt-1.5 w-[min(24rem,calc(100vw-1rem))] overflow-hidden rounded-md border bg-popover text-popover-foreground shadow-lg",
          className,
        )}
        onMouseLeave={() => setOpenId(null)}
        {...props}
      />
    );
  },
);
NavigationMenuContent.displayName = "NavigationMenuContent";

const NavigationMenuLink = React.forwardRef<HTMLAnchorElement, React.AnchorHTMLAttributes<HTMLAnchorElement>>(
  ({ className, ...props }, ref) => (
    <a ref={ref} className={cn("block select-none rounded-md px-3 py-2 text-sm leading-none no-underline outline-none hover:bg-accent hover:text-accent-foreground", className)} {...props} />
  ),
);
NavigationMenuLink.displayName = "NavigationMenuLink";

// Kept for API compatibility; no-op in this lightweight implementation.
const NavigationMenuViewport = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>((_, ref) => (
  <div ref={ref} />
));
NavigationMenuViewport.displayName = "NavigationMenuViewport";

const NavigationMenuIndicator = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>((_, ref) => (
  <div ref={ref} />
));
NavigationMenuIndicator.displayName = "NavigationMenuIndicator";

export {
  navigationMenuTriggerStyle,
  NavigationMenu,
  NavigationMenuList,
  NavigationMenuItem,
  NavigationMenuContent,
  NavigationMenuTrigger,
  NavigationMenuLink,
  NavigationMenuIndicator,
  NavigationMenuViewport,
};

