import { describe, expect, test } from "vitest";
import { detectScript, hasDevanagari, normalizeQuery } from "@/lib/text/normalize";

describe("normalizeQuery", () => {
  test("lowercases Hinglish and removes the question mark", () => {
    expect(normalizeQuery("Station se Lalpur kaise jaun?")).toBe("station se lalpur kaise jaun");
  });

  test("collapses extra spaces and repeated punctuation", () => {
    expect(normalizeQuery("   Lalpur    jana hai!!  ")).toBe("lalpur jana hai");
  });

  test("removes the Hindi full stop (danda) but keeps Hindi letters", () => {
    expect(normalizeQuery("स्टेशन से लालपुर।")).toBe("स्टेशन से लालपुर");
  });

  test("returns an empty string for punctuation-only input", () => {
    expect(normalizeQuery(" ?? ... ")).toBe("");
  });
});

describe("script detection", () => {
  test("finds Devanagari text", () => {
    expect(hasDevanagari("लालपुर कैसे जाऊं")).toBe(true);
    expect(detectScript("लालपुर कैसे जाऊं")).toBe("hi-Deva");
  });

  test("treats Hinglish in Latin letters as latin", () => {
    expect(hasDevanagari("Lalpur kaise jaun")).toBe(false);
    expect(detectScript("Lalpur kaise jaun")).toBe("latin");
  });
});
