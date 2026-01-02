/**
 * GrapesJS block definitions for the Event Page Builder
 */

interface HeroBlockProps {
  name: string;
  description: string;
  logoUrl?: string;
}

export function heroBlockHtml({ name, description, logoUrl }: HeroBlockProps): string {
  const safeName = name || 'Your event name';
  const safeDescription = description || 'Add a short description to explain why this event matters.';

  const logoImg = logoUrl
    ? `<div class="hero-logo" aria-hidden="true"><img src="${logoUrl}" alt="${safeName} logo" /></div>`
    : '';

  return `
  <header class="hero" data-type="hero">
    <div class="hero-inner">
      ${logoImg}
      <p class="eyebrow">Hosted on Thittam1Hub</p>
      <h1>${safeName}</h1>
      <p class="lead">${safeDescription}</p>
      <div class="hero-meta" aria-label="Event key info">
        <span class="pill">Date &amp; time</span>
        <span class="pill">Location or virtual link</span>
        <span class="pill">Limited seats • Reserve now</span>
      </div>
      <div class="cta-row" aria-label="Primary actions">
        <a href="#registration" class="btn-primary">Register now</a>
        <a href="#schedule" class="btn-secondary">View schedule</a>
      </div>
    </div>
  </header>
  `;
}

export function scheduleBlockHtml(): string {
  return `
  <section id="schedule" class="schedule" aria-label="Event schedule">
    <h2>Schedule</h2>
    <p class="muted">Outline the key moments so attendees know what to expect.</p>
    <ul>
      <li>
        <strong>09:00 – Check-in &amp; networking</strong>
        <p>Welcome coffee and badge pickup.</p>
      </li>
      <li>
        <strong>10:00 – Opening keynote</strong>
        <p>Kick off the day with an inspiring keynote.</p>
      </li>
      <li>
        <strong>11:30 – Breakout sessions</strong>
        <p>Parallel tracks tailored to different audiences.</p>
      </li>
    </ul>
  </section>
  `;
}

export function registrationBlockHtml(): string {
  return `
  <section id="registration" class="registration" aria-label="Registration form">
    <h2>Reserve your seat</h2>
    <p class="muted">This is a visual-only form. Actual registration happens on the main Thittam1Hub flow.</p>
    <form>
      <label>
        Full name
        <input type="text" name="name" placeholder="Jane Doe" />
      </label>
      <label>
        Email address
        <input type="email" name="email" placeholder="you@example.com" />
      </label>
      <label>
        Ticket type
        <select name="ticket">
          <option>General admission</option>
          <option>Student</option>
          <option>VIP</option>
        </select>
      </label>
      <button type="button">Complete registration on Thittam1Hub</button>
    </form>
  </section>
  `;
}
