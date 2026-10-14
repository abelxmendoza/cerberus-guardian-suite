import { artwork } from "../../data/artwork";
import { guardians } from "../../data/guardians";
import { site } from "../../data/site";
import { Reveal } from "./Reveal";

const order = ["windows", "linux", "macos"] as const;
const [manifestoLead, manifestoRest] = site.manifesto.split(". ");

export function Hero() {
  return (
    <section id="overview" className="relative overflow-hidden">
      <div className="circuit pointer-events-none absolute inset-0" aria-hidden="true" />
      <svg
        className="pointer-events-none absolute inset-x-0 top-0 h-72 w-full opacity-40"
        viewBox="0 0 1200 280"
        fill="none"
        aria-hidden="true"
      >
        <path className="circuit-dash" d="M0 40 H180 V120 H360" stroke="#00BFFF" strokeWidth="1" />
        <path className="circuit-dash" d="M1200 70 H980 V150 H760" stroke="#A020F0" strokeWidth="1" />
        <path className="circuit-dash" d="M80 220 H260 V160 H480" stroke="#FF1493" strokeWidth="1" />
      </svg>
      <div className="relative mx-auto max-w-6xl px-4 pb-16 pt-14 sm:px-6 sm:pt-20">
        <Reveal>
          <p className="font-mono text-xs uppercase tracking-[0.28em] text-accent">
            {site.secondaryTagline}
          </p>
          <h1 className="mt-4 font-display text-5xl tracking-[0.18em] text-paper sm:text-7xl lg:text-8xl">
            {site.name}
          </h1>
          <p className="mt-3 font-display text-lg tracking-[0.22em] text-muted sm:text-2xl">
            THE GUARDIAN SECURITY SUITE
          </p>
          <p className="tri-tone mt-6 max-w-xl font-display text-2xl tracking-wide sm:text-3xl">
            {site.tagline}
          </p>
          <p className="mt-5 max-w-3xl font-display text-lg uppercase leading-snug tracking-[0.12em] text-paper sm:text-2xl">
            {manifestoLead}.
            <span className="mt-1 block text-muted">{manifestoRest}</span>
          </p>
          <p className="mt-5 max-w-2xl text-base leading-relaxed text-muted sm:text-lg">
            An open-source security monitoring and system hardening ecosystem built for Windows,
            Linux, and macOS.
          </p>
          <p className="mt-3 max-w-2xl text-sm leading-relaxed text-dim">
            CERBERUS does not replace antivirus or endpoint protection. Each Guardian is a separate
            repository. This page only states what those repositories contain.
          </p>
          <div className="mt-8 flex flex-col gap-3 sm:flex-row">
            <a
              href="#guardians"
              className="inline-flex min-h-12 items-center justify-center rounded border border-windows/70 bg-windows/15 px-5 font-display tracking-wide text-paper hover:bg-windows/25"
            >
              Explore the Guardians
            </a>
            <a
              href={site.github}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex min-h-12 items-center justify-center rounded border border-white/20 px-5 font-display tracking-wide text-paper hover:border-accent hover:text-accent"
            >
              View on GitHub
            </a>
          </div>
        </Reveal>

        <div className="mt-14 grid gap-6 md:grid-cols-3">
          {order.map((id) => {
            const guardian = guardians.find((item) => item.id === id);
            const art = artwork[id];
            if (!guardian) return null;
            return (
              <figure key={id} className="panel relative overflow-hidden rounded-lg p-3">
                <div
                  className="wolf-glow pointer-events-none absolute inset-8 rounded-full blur-3xl"
                  style={{ background: guardian.themeColor }}
                  aria-hidden="true"
                />
                <img
                  src={art.logo}
                  alt={art.logoAlt}
                  width={900}
                  height={900}
                  className="relative z-10 mx-auto h-auto w-full max-w-sm object-contain"
                />
                <figcaption className="relative z-10 px-2 pb-2 pt-1 font-mono text-[11px] uppercase tracking-[0.16em] text-dim">
                  {guardian.id === "windows" ? "Active development · least ready" : "Active development"} · {guardian.platform}
                </figcaption>
              </figure>
            );
          })}
        </div>
      </div>
    </section>
  );
}
