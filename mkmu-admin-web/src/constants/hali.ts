/**
 * The five report statuses.
 *
 * These must stay in sync with `haliLabel` in lib/core/models/ripoti_model.dart —
 * the mobile app renders the same Swahili label to the citizen who filed the
 * report, so a label that drifts here means the two halves of the system
 * describe the same report differently.
 *
 * Order is the intended progression, and drives the dropdown ordering.
 */
export const HALI_ORDER = [
  'mpya',
  'inaangaliwa',
  'imepewa_mamlaka',
  'inashughulikiwa',
  'imekamilika',
] as const;

export type Hali = (typeof HALI_ORDER)[number];

interface HaliMeta {
  /** Swahili label — matches what the mobile app shows the citizen. */
  label: string;
  /** Short English label for dense UI (table badges, chart legend). */
  short: string;
  /** Tailwind background class for the status dot. */
  dot: string;
  /** Hex, for the d3 chart which cannot use Tailwind classes. */
  hex: string;
}

export const HALI: Record<Hali, HaliMeta> = {
  mpya:            { label: 'Inasubiri Mapitio',          short: 'Mpya',        dot: 'bg-orange-400',  hex: '#f97316' },
  inaangaliwa:     { label: 'Inaangaliwa',                short: 'Inaangaliwa', dot: 'bg-amber-500',   hex: '#f59e0b' },
  imepewa_mamlaka: { label: 'Mamlaka Imepewa Taarifa',    short: 'Mamlaka',     dot: 'bg-sky-500',     hex: '#0ea5e9' },
  inashughulikiwa: { label: 'Inashughulikiwa na Baraza',  short: 'Kazini',      dot: 'bg-purple-500',  hex: '#a855f7' },
  imekamilika:     { label: 'Imetatuliwa',                short: 'Imetatuliwa', dot: 'bg-emerald-500', hex: '#10b981' },
};

export const isHali = (v: string): v is Hali => v in HALI;

/** Falls back to the raw value so an unknown status is visible, not hidden. */
export const haliLabel = (v: string): string => (isHali(v) ? HALI[v].label : v);
export const haliShort = (v: string): string => (isHali(v) ? HALI[v].short : v);
export const haliDot = (v: string): string => (isHali(v) ? HALI[v].dot : 'bg-slate-400');
