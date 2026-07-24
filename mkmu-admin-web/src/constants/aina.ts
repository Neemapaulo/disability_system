/**
 * The report categories.
 *
 * Mirrors `ainaLabel` in lib/core/models/ripoti_model.dart. The citizen picks
 * one of these on the report form and sees the long Swahili label; the column
 * stores the snake_case key. Showing the raw key on the dashboard leaks a
 * database detail into a page a council officer reads, so it is mapped back.
 */
export const AINA_ORDER = [
  'njia_kutopitika',
  'kituo_hakina_rampu',
  'makutano_yasio_salama',
  'ukosefu_miongozo',
  'nyingine',
] as const;

export type Aina = (typeof AINA_ORDER)[number];

interface AinaMeta {
  /** Full Swahili label — what the citizen chose on the report form. */
  label: string;
  /** Short label for axes and legends, where the full one will not fit. */
  short: string;
}

export const AINA: Record<Aina, AinaMeta> = {
  njia_kutopitika:       { label: 'Njia kutopitika / Miundombinu mibovu', short: 'Njia kutopitika' },
  kituo_hakina_rampu:    { label: 'Kituo cha basi hakina ngazi/rampu',    short: 'Kituo bila rampu' },
  makutano_yasio_salama: { label: 'Makutano ya barabara yasiyo salama',   short: 'Makutano hatari' },
  ukosefu_miongozo:      { label: 'Ukosefu wa miongozo ya sauti au alama', short: 'Hakuna miongozo' },
  nyingine:              { label: 'Nyingine',                             short: 'Nyingine' },
};

const isAina = (v: string): v is Aina => v in AINA;

/**
 * Falls back to the key with underscores opened up, so a category added to the
 * database before it is added here still reads as words rather than vanishing.
 */
const humanise = (v: string): string =>
  v.replace(/_/g, ' ').replace(/^./, c => c.toUpperCase());

export const ainaLabel = (v: string): string => (isAina(v) ? AINA[v].label : humanise(v));
export const ainaShort = (v: string): string => (isAina(v) ? AINA[v].short : humanise(v));
