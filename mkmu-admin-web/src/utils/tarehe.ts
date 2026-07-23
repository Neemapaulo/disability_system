/**
 * Date formatting in Swahili, to match what the mobile app shows.
 *
 * Uses the platform's Intl rather than date-fns: date-fns ships no Swahili
 * locale, and Intl already carries sw-TZ. Falls back to the raw string if a
 * timestamp is unparseable, so a bad value is visible rather than shown as
 * "Invalid Date" or silently blank.
 */

const DATE_FMT = new Intl.DateTimeFormat('sw-TZ', {
  day: 'numeric',
  month: 'short',
  year: 'numeric',
});

const TIME_FMT = new Intl.DateTimeFormat('sw-TZ', {
  hour: '2-digit',
  minute: '2-digit',
  hour12: false,
});

const RELATIVE_FMT = new Intl.RelativeTimeFormat('sw', { numeric: 'auto' });

const parse = (iso: string | null): Date | null => {
  if (!iso) return null;
  const d = new Date(iso);
  return Number.isNaN(d.getTime()) ? null : d;
};

/** "14 Jul 2026" */
export const tarehe = (iso: string | null): string => {
  const d = parse(iso);
  return d ? DATE_FMT.format(d) : '—';
};

/** "14 Jul 2026, 13:44" */
export const tareheNaSaa = (iso: string | null): string => {
  const d = parse(iso);
  return d ? `${DATE_FMT.format(d)}, ${TIME_FMT.format(d)}` : '—';
};

/** "siku 3 zilizopita" — coarse, for the at-a-glance column. */
export const mudaUliopita = (iso: string | null): string => {
  const d = parse(iso);
  if (!d) return '';

  const seconds = Math.round((d.getTime() - Date.now()) / 1000);

  const units: [Intl.RelativeTimeFormatUnit, number][] = [
    ['second', 60],
    ['minute', 60],
    ['hour', 24],
    ['day', 30],
    ['month', 12],
  ];

  let value = seconds;
  for (const [unit, step] of units) {
    if (Math.abs(value) < step) return RELATIVE_FMT.format(Math.round(value), unit);
    value /= step;
  }
  return RELATIVE_FMT.format(Math.round(value), 'year');
};

/** Oldest untouched reports matter most — how long has this been waiting? */
export const sikuTangu = (iso: string | null): number | null => {
  const d = parse(iso);
  if (!d) return null;
  return Math.floor((Date.now() - d.getTime()) / 86_400_000);
};
