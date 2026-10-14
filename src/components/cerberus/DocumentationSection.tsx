import { guardians } from "../../data/guardians";
import { ExternalLink } from "./ExternalLink";

export function DocumentationSection() {
  return (
    <section id="documentation" className="mx-auto max-w-6xl px-4 py-16 sm:px-6">
      <p className="font-mono text-xs uppercase tracking-[0.22em] text-accent">Docs</p>
      <h2 className="mt-2 font-display text-3xl tracking-[0.12em] text-paper sm:text-4xl">
        READ THE REPOSITORIES.
      </h2>
      <p className="mt-3 max-w-2xl text-muted">
        There is no separate documentation site. These links open files that exist in the public
        repositories.
      </p>
      <div className="mt-8 grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {guardians.map((guardian) => (
          <article key={guardian.id} className="panel rounded-lg p-5">
            <h3 className="font-display text-lg text-paper">{guardian.name}</h3>
            <ul className="mt-4 space-y-2">
              {guardian.docs.map((doc) => (
                <li key={doc.href}>
                  <ExternalLink href={doc.href} className="text-sm text-accent">
                    {doc.label}
                  </ExternalLink>
                </li>
              ))}
            </ul>
          </article>
        ))}
      </div>
    </section>
  );
}
