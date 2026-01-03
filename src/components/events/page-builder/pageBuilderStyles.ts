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
    'section.schedule, section.registration, section.speakers, section.sponsors, section.faq, section.countdown { padding: 2.5rem 1.5rem; max-width: 64rem; margin: 0 auto; }',
    'section.schedule h2, section.registration h2, section.speakers h2, section.sponsors h2, section.faq h2, section.countdown h2 { font-size: 1.5rem; margin-bottom: 0.75rem; }',
    'section.schedule ul { list-style: none; margin: 0; padding: 0; display: grid; gap: 0.75rem; }',
    'section.schedule li { padding: 0.9rem 1rem; border-radius: 0.9rem; border: 1px solid rgba(148, 163, 184, 0.35); background: #f9fafb; }',
    'section.registration form { display: grid; gap: 0.75rem; max-width: 28rem; }',
    'section.registration label { font-size: 0.8rem; font-weight: 500; color: #0f172a; }',
    'section.registration input, section.registration select { margin-top: 0.3rem; border-radius: 0.6rem; border: 1px solid rgba(148, 163, 184, 0.7); padding: 0.55rem 0.75rem; font-size: 0.85rem; }',
    'section.registration button { margin-top: 0.5rem; padding: 0.75rem 1rem; border-radius: 0.75rem; border: none; background: var(--th-primary); color: #f9fafb; font-weight: 600; font-size: 0.9rem; }',
    // Speakers section
    '.speakers-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 1.5rem; margin-top: 1.5rem; }',
    '.speaker-card { padding: 1.5rem; border-radius: 1rem; border: 1px solid rgba(148, 163, 184, 0.35); background: #f9fafb; text-align: center; }',
    '.speaker-avatar { width: 80px; height: 80px; border-radius: 50%; background: linear-gradient(135deg, var(--th-primary), rgba(37, 99, 235, 0.7)); margin: 0 auto 1rem; display: flex; align-items: center; justify-content: center; font-size: 2rem; color: #fff; }',
    '.speaker-card h3 { font-size: 1.1rem; margin-bottom: 0.25rem; }',
    '.speaker-role { font-size: 0.85rem; color: #64748b; margin-bottom: 0.5rem; }',
    '.speaker-bio { font-size: 0.8rem; color: #475569; line-height: 1.5; }',
    // Sponsors section
    '.sponsors-tier { margin-bottom: 2rem; }',
    '.tier-label { font-size: 0.9rem; font-weight: 600; color: #64748b; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 1rem; }',
    '.sponsors-row { display: flex; flex-wrap: wrap; gap: 1.5rem; justify-content: center; }',
    '.sponsor-logo { width: 140px; height: 70px; border-radius: 0.75rem; border: 1px solid rgba(148, 163, 184, 0.35); background: #f9fafb; display: flex; align-items: center; justify-content: center; font-size: 0.9rem; color: #94a3b8; }',
    '.sponsor-gold { width: 120px; height: 60px; }',
    '.sponsor-silver { width: 100px; height: 50px; }',
    // FAQ section
    '.faq-list { display: grid; gap: 0.75rem; margin-top: 1.5rem; }',
    '.faq-item { border-radius: 0.75rem; border: 1px solid rgba(148, 163, 184, 0.35); background: #f9fafb; overflow: hidden; }',
    '.faq-item summary { padding: 1rem 1.25rem; font-weight: 500; cursor: pointer; list-style: none; }',
    '.faq-item summary::-webkit-details-marker { display: none; }',
    '.faq-item p { padding: 0 1.25rem 1rem; color: #475569; font-size: 0.9rem; line-height: 1.6; margin: 0; }',
    // Countdown section
    '.countdown { text-align: center; background: linear-gradient(135deg, var(--th-primary), rgba(15, 23, 42, 0.95)); color: #f9fafb; }',
    '.countdown-timer { display: flex; justify-content: center; gap: 1.5rem; margin: 2rem 0; }',
    '.countdown-unit { display: flex; flex-direction: column; align-items: center; }',
    '.countdown-value { font-size: 3rem; font-weight: 700; line-height: 1; background: rgba(255,255,255,0.15); padding: 1rem 1.5rem; border-radius: 0.75rem; min-width: 80px; }',
    '.countdown-label { font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.1em; margin-top: 0.5rem; opacity: 0.8; }',
    '.muted { color: #64748b; font-size: 0.9rem; }',
    '.countdown .muted { color: rgba(255,255,255,0.7); }',
  ];
}
