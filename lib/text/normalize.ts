/**
 * Small text helpers used before parsing a passenger's question.
 *
 * Example: "Station se Lalpur kaise jaun??" -> "station se lalpur kaise jaun"
 *
 * Spelling variants (jaana/jana, kaise/kese) are handled later by the
 * parser (plan milestone M3); this file only cleans up the raw text.
 */

/** Unicode block for Devanagari script (Hindi): U+0900 to U+097F. */
const DEVANAGARI = /[ऀ-ॿ]/;

/**
 * Punctuation we turn into spaces. Includes the Hindi full stop "।"
 * (danda, U+0964) and double danda "॥" (U+0965).
 */
const PUNCTUATION = /[?!.,;:'"()[\]{}।॥]/g;

/** True if the text contains any Hindi (Devanagari) letters. */
export function hasDevanagari(text: string): boolean {
  return DEVANAGARI.test(text);
}

/** Which script the user typed in, so we can reply in the same script. */
export function detectScript(text: string): "hi-Deva" | "latin" {
  return hasDevanagari(text) ? "hi-Deva" : "latin";
}

/**
 * Cleans a query for matching:
 *  1. NFC normalisation, so the same Hindi word typed on different
 *     keyboards becomes the same sequence of characters;
 *  2. lowercase (has no effect on Devanagari);
 *  3. punctuation -> space;
 *  4. many spaces -> one space, and trim the ends.
 */
export function normalizeQuery(text: string): string {
  return text
    .normalize("NFC")
    .toLowerCase()
    .replace(PUNCTUATION, " ")
    .replace(/\s+/g, " ")
    .trim();
}
