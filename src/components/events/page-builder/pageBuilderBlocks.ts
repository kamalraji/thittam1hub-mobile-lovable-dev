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

export function speakersBlockHtml(): string {
  return `
  <section id="speakers" class="speakers" aria-label="Event speakers">
    <h2>Meet Our Speakers</h2>
    <p class="muted">Learn from industry experts and thought leaders.</p>
    <div class="speakers-grid">
      <div class="speaker-card">
        <div class="speaker-avatar">👤</div>
        <h3>Speaker Name</h3>
        <p class="speaker-role">CEO, Company</p>
        <p class="speaker-bio">Brief bio about the speaker and their expertise.</p>
      </div>
      <div class="speaker-card">
        <div class="speaker-avatar">👤</div>
        <h3>Speaker Name</h3>
        <p class="speaker-role">CTO, Company</p>
        <p class="speaker-bio">Brief bio about the speaker and their expertise.</p>
      </div>
      <div class="speaker-card">
        <div class="speaker-avatar">👤</div>
        <h3>Speaker Name</h3>
        <p class="speaker-role">Director, Company</p>
        <p class="speaker-bio">Brief bio about the speaker and their expertise.</p>
      </div>
    </div>
  </section>
  `;
}

export function sponsorsBlockHtml(): string {
  return `
  <section id="sponsors" class="sponsors" aria-label="Event sponsors">
    <h2>Our Sponsors</h2>
    <p class="muted">This event is made possible by our generous sponsors.</p>
    <div class="sponsors-tier">
      <h3 class="tier-label">Platinum</h3>
      <div class="sponsors-row">
        <div class="sponsor-logo">Logo</div>
        <div class="sponsor-logo">Logo</div>
      </div>
    </div>
    <div class="sponsors-tier">
      <h3 class="tier-label">Gold</h3>
      <div class="sponsors-row">
        <div class="sponsor-logo sponsor-gold">Logo</div>
        <div class="sponsor-logo sponsor-gold">Logo</div>
        <div class="sponsor-logo sponsor-gold">Logo</div>
      </div>
    </div>
    <div class="sponsors-tier">
      <h3 class="tier-label">Silver</h3>
      <div class="sponsors-row">
        <div class="sponsor-logo sponsor-silver">Logo</div>
        <div class="sponsor-logo sponsor-silver">Logo</div>
        <div class="sponsor-logo sponsor-silver">Logo</div>
        <div class="sponsor-logo sponsor-silver">Logo</div>
      </div>
    </div>
  </section>
  `;
}

export function faqBlockHtml(): string {
  return `
  <section id="faq" class="faq" aria-label="Frequently asked questions">
    <h2>Frequently Asked Questions</h2>
    <p class="muted">Find answers to common questions about the event.</p>
    <div class="faq-list">
      <details class="faq-item">
        <summary>What is the refund policy?</summary>
        <p>Full refunds are available up to 7 days before the event. After that, tickets are non-refundable but can be transferred.</p>
      </details>
      <details class="faq-item">
        <summary>Is there parking available?</summary>
        <p>Yes, free parking is available at the venue. VIP ticket holders get reserved spots near the entrance.</p>
      </details>
      <details class="faq-item">
        <summary>Can I get a certificate of attendance?</summary>
        <p>Yes! All registered attendees will receive a digital certificate after completing the event.</p>
      </details>
      <details class="faq-item">
        <summary>Will sessions be recorded?</summary>
        <p>Select keynote sessions will be recorded and shared with registered attendees after the event.</p>
      </details>
    </div>
  </section>
  `;
}

export function countdownBlockHtml(): string {
  return `
  <section id="countdown" class="countdown" aria-label="Event countdown">
    <h2>Event Starts In</h2>
    <div class="countdown-timer">
      <div class="countdown-unit">
        <span class="countdown-value">00</span>
        <span class="countdown-label">Days</span>
      </div>
      <div class="countdown-unit">
        <span class="countdown-value">00</span>
        <span class="countdown-label">Hours</span>
      </div>
      <div class="countdown-unit">
        <span class="countdown-value">00</span>
        <span class="countdown-label">Minutes</span>
      </div>
      <div class="countdown-unit">
        <span class="countdown-value">00</span>
        <span class="countdown-label">Seconds</span>
      </div>
    </div>
    <p class="muted">Don't miss out – register now to secure your spot!</p>
  </section>
  `;
}
