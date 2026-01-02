/**
 * Canvas styles for the Event Page Builder
 */

export function getCanvasStyles(primaryColor: string): string[] {
  return [
    // Base reset
    'body { margin: 0; font-family: system-ui, -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif; color: #020617; background-color: #ffffff; }',
    'a { color: inherit; text-decoration: none; }',
    'img { max-width: 100%; height: auto; display: block; }',
    // Brand tokens
    `:root { --th-primary: ${primaryColor}; }`,
    'header.hero { padding: 3rem 1.5rem; text-align: center; background: linear-gradient(135deg, var(--th-primary), rgba(15, 23, 42, 0.95)); color: #f9fafb; }',
    'header.hero h1 { font-size: 2.25rem; line-height: 1.1; margin-bottom: 0.75rem; }',
    'header.hero p { max-width: 36rem; margin: 0 auto 1.5rem; font-size: 1rem; opacity: 0.9; }',
    'header.hero .hero-meta { display: flex; flex-wrap: wrap; justify-content: center; gap: 0.75rem; margin-bottom: 1.5rem; }',
    'header.hero .pill { padding: 0.5rem 0.9rem; border-radius: 999px; border: 1px solid rgba(148, 163, 184, 0.4); font-size: 0.75rem; background: rgba(15, 23, 42, 0.7); }',
    'header.hero .cta-row { display: flex; flex-wrap: wrap; justify-content: center; gap: 0.75rem; }',
    'header.hero .btn-primary { padding: 0.75rem 1.4rem; border-radius: 999px; background: #f9fafb; color: #0f172a; font-weight: 600; font-size: 0.9rem; }',
    'header.hero .btn-secondary { padding: 0.7rem 1.3rem; border-radius: 999px; border: 1px solid rgba(148, 163, 184, 0.5); background: transparent; color: #e5e7eb; font-size: 0.85rem; }',
    'section.schedule, section.registration { padding: 2.5rem 1.5rem; max-width: 64rem; margin: 0 auto; }',
    'section.schedule h2, section.registration h2 { font-size: 1.5rem; margin-bottom: 0.75rem; }',
    'section.schedule ul { list-style: none; margin: 0; padding: 0; display: grid; gap: 0.75rem; }',
    'section.schedule li { padding: 0.9rem 1rem; border-radius: 0.9rem; border: 1px solid rgba(148, 163, 184, 0.35); background: #f9fafb; }',
    'section.registration form { display: grid; gap: 0.75rem; max-width: 28rem; }',
    'section.registration label { font-size: 0.8rem; font-weight: 500; color: #0f172a; }',
    'section.registration input, section.registration select { margin-top: 0.3rem; border-radius: 0.6rem; border: 1px solid rgba(148, 163, 184, 0.7); padding: 0.55rem 0.75rem; font-size: 0.85rem; }',
    'section.registration button { margin-top: 0.5rem; padding: 0.75rem 1rem; border-radius: 0.75rem; border: none; background: var(--th-primary); color: #f9fafb; font-weight: 600; font-size: 0.9rem; }',
  ];
}
