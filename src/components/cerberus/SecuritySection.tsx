import { evidenceDate, guardians } from "../../data/guardians";
import { ExternalLink } from "./ExternalLink";

export function SecuritySection() {
  return (
    <section id="security" className="mx-auto max-w-6xl px-4 py-16 sm:px-6">
      <p className="font-mono text-xs uppercase tracking-[0.22em] text-accent">Limits</p>
      <h2 className="mt-2 font-display text-3xl tracking-[0.1em] text-paper sm:text-4xl">
        BUILT FOR TRANSPARENCY.
      </h2>
      <p className="mt-3 max-w-3xl text-muted">
        CERBERUS watches a machine and can suggest or apply changes the operator approves. It does
        not promise complete protection. Facts below were taken from the repositories on {evidenceDate}.
        Where a project is silent, this page stays silent.
      </p>
      <div className="mt-8 grid gap-5 lg:grid-cols-3">
        {guardians.map((guardian) => (
          <article
            key={guardian.id}
            className="panel rounded-lg p-5"
            style={{ borderColor: `${guardian.themeColor}55` }}
          >
            <h3 className="font-display text-xl text-paper">{guardian.name}</h3>
            <h4 className="mt-4 font-mono text-[11px] uppercase tracking-[0.14em] text-dim">What it monitors</h4>
            <ul className="mt-2 list-disc space-y-1 pl-4 text-sm text-muted">
              {guardian.verifiedFeatures.map((item) => (
                <li key={item}>{item}</li>
              ))}
            </ul>
            <h4 className="mt-4 font-mono text-[11px] uppercase tracking-[0.14em] text-dim">Permissions</h4>
            <ul className="mt-2 list-disc space-y-1 pl-4 text-sm text-muted">
              {guardian.permissions.map((item) => (
                <li key={item}>{item}</li>
              ))}
            </ul>
            <h4 className="mt-4 font-mono text-[11px] uppercase tracking-[0.14em] text-dim">Network</h4>
            <ul className="mt-2 list-disc space-y-1 pl-4 text-sm text-muted">
              {guardian.networkBehavior.map((item) => (
                <li key={item}>{item}</li>
              ))}
            </ul>
            <h4 className="mt-4 font-mono text-[11px] uppercase tracking-[0.14em] text-dim">Known limits</h4>
            <ul className="mt-2 list-disc space-y-1 pl-4 text-sm text-muted">
              {guardian.limitations.map((item) => (
                <li key={item}>{item}</li>
              ))}
            </ul>
          </article>
        ))}
      </div>
      <div className="panel mt-6 rounded-lg p-5">
        <h3 className="font-display text-xl text-paper">Report a vulnerability</h3>
        <p className="mt-3 text-sm leading-relaxed text-muted">
          macOS is the only Guardian with a SECURITY.md. That file asks reporters not to open a public
          issue, then gives the contact as the placeholder &quot;[Your Security Email]&quot;. Until a real
          address is committed, do not send exploit detail to that placeholder, and do not post a
          working exploit in a public issue.
        </p>
        <p className="mt-3 text-sm leading-relaxed text-muted">
          Linux and Windows do not publish SECURITY.md. Use the repository&apos;s private security
          advisory flow if GitHub has it enabled, or ask in a non-sensitive issue for the current
          contact before sharing technical detail.
        </p>
        <ExternalLink
          href="https://github.com/abelxmendoza/MacGuardianWatchdog/blob/main/SECURITY.md"
          className="mt-4 inline-flex font-mono text-xs uppercase tracking-[0.14em] text-accent"
        >
          Read macOS SECURITY.md
        </ExternalLink>
      </div>
    </section>
  );
}
