/**
 * Home page (placeholder).
 *
 * This is a server component: it is turned into plain HTML on the server,
 * so it sends no JavaScript to the phone. The ask box is switched off
 * until the answer engine exists (plan milestones M3 to M6).
 */
export default function Home() {
  return (
    <main className="mx-auto flex w-full max-w-xl flex-1 flex-col gap-8 px-4 py-8">
      <header className="flex items-baseline justify-between">
        <p className="text-2xl font-semibold tracking-tight">Sawari</p>
        <p className="text-sm text-muted">Ranchi · pilot</p>
      </header>

      <section aria-labelledby="ask-heading" className="flex flex-col gap-4">
        <h1 id="ask-heading" className="text-3xl font-semibold leading-tight">
          Ranchi mein kahin jaana hai?
        </h1>
        <p className="text-muted">
          Kaunsa shared auto ya e-rickshaw lena hai, kahan se milega, kahan utarna hai, aur
          kiraya lagbhag kitna — local logon ki jaankari se.
        </p>

        <form className="flex flex-col gap-3" aria-describedby="ask-status">
          <label htmlFor="ask" className="sr-only">
            Aapka sawaal
          </label>
          <input
            id="ask"
            name="q"
            type="text"
            disabled
            placeholder="Jaise: Station se Lalpur"
            className="h-12 rounded-lg border border-border bg-surface px-4 text-base placeholder:text-muted disabled:cursor-not-allowed"
          />
          <button
            type="submit"
            disabled
            className="h-12 rounded-lg bg-accent font-semibold text-accent-ink disabled:cursor-not-allowed disabled:opacity-60"
          >
            Poochiye
          </button>
        </form>

        <p id="ask-status" className="rounded-lg bg-accent-soft px-4 py-3 text-sm">
          Sawari abhi ban raha hai. Pilot shuru hone par yahan seedha jawab milega.
        </p>
      </section>

      <section aria-labelledby="what-heading" className="flex flex-col gap-3">
        <h2 id="what-heading" className="text-lg font-semibold">
          Jawab mein kya milega
        </h2>
        <ol className="list-decimal space-y-2 pl-5">
          <li>Gaadi kahan se pakadni hai — stand ya landmark</li>
          <li>Kaunsa shared auto ya e-rickshaw lena hai</li>
          <li>Kahan utarna hai, aur change karna ho to kahan</li>
          <li>Kiraya lagbhag kitna, aur jaankari kitni pakki hai</li>
        </ol>
      </section>

      <footer className="mt-auto border-t border-border pt-4 text-sm text-muted">
        Jaankari community se aati hai aur galat ho sakti hai. Kiraya hamesha “lagbhag” hai,
        fix nahi.
      </footer>
    </main>
  );
}
