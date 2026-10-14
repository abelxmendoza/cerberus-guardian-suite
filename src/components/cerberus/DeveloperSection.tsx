import { developer, site } from "../../data/site";
import { ExternalLink } from "./ExternalLink";

export function DeveloperSection() {
  return (
    <section id="developer" className="mx-auto max-w-6xl px-4 py-16 sm:px-6">
      <p className="font-mono text-xs uppercase tracking-[0.22em] text-accent">Author</p>
      <h2 className="mt-2 max-w-3xl font-display text-3xl uppercase tracking-[0.08em] text-paper sm:text-4xl">
        {site.manifesto}
      </h2>
      <div className="panel mt-8 rounded-lg p-6 sm:p-8">
        <h3 className="font-display text-2xl tracking-wide text-paper">{developer.name}</h3>
        <p className="mt-3 text-muted">{developer.background}</p>
        <p className="mt-3 text-muted">{developer.experience}</p>
        <p className="mt-3 text-muted">
          <span className="text-paper">Interests. </span>
          {developer.interests}
        </p>
        <p className="mt-4 max-w-3xl text-muted">{developer.summary}</p>
        <ul className="mt-6 flex flex-col gap-3 sm:flex-row sm:flex-wrap">
          {developer.links.map((link) => (
            <li key={link.href}>
              <ExternalLink
                href={link.href}
                className="inline-flex min-h-12 items-center rounded border border-white/15 px-4 text-paper hover:border-accent"
              >
                {link.label}
              </ExternalLink>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
