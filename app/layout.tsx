import type { Metadata } from "next";
import { Noto_Sans, Noto_Sans_Devanagari } from "next/font/google";
import "./globals.css";

// Noto Sans covers Hinglish (Latin letters). Noto Sans Devanagari covers
// Hindi script. Both are downloaded at build time and served from our own
// site, so users' phones don't contact Google Fonts.
const notoSans = Noto_Sans({
  variable: "--font-latin",
  subsets: ["latin"],
  display: "swap",
});

// Not preloaded: most first visits are Hinglish, so phones only download
// the Hindi font when Hindi text actually appears on screen.
const notoDevanagari = Noto_Sans_Devanagari({
  variable: "--font-deva",
  subsets: ["devanagari"],
  display: "swap",
  preload: false,
});

export const metadata: Metadata = {
  title: "Sawari — Ranchi trip planner",
  description:
    "Ranchi mein shared auto aur e-rickshaw se kaise jaayein: kahan se pakdein, kahan utrein, kiraya lagbhag kitna.",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    // "hi-Latn" = Hindi written in Latin letters (Hinglish).
    <html
      lang="hi-Latn"
      className={`${notoSans.variable} ${notoDevanagari.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col">{children}</body>
    </html>
  );
}
