import { evidenceDate, guardians } from "../../data/guardians";
import { ExternalLink } from "./ExternalLink";
import { Reveal } from "./Reveal";

const cards = [
  {
    title: "Open source",
    body: "All three Guardian repositories are public. You can read the implementation instead of trusting a binary.",
    href: guardians[0].repositoryUrl,
    link: "Windows repository",
  },
  {
    title: "Verified releases",
    body: `All three downloads on this page are GitHub archives of those apps, each with a SHA-256 you can check. All three are in active development. Windows is the least ready, and its archive is not a signed installer. Checked ${evidenceDate}.`,
    href: guardians[0].release.downloadUrl ?? guardians[0].repositoryUrl,
    link: "Windows download",
  },
  {
    title: "Automated testing",
    body: "Linux documents a local pytest run and also a failed GitHub Actions run on main. Windows publishes a successful desktop build and CodeQL, not a unit-test report. macOS has test scripts; recent CI runs on main failed.",
    href: guardians[1].ciUrl,
    link: "Linux Actions",
  },
  {
    title: "Permission transparency",
    body: "Windows requests administrator via app.manifest. Linux keeps routine checks in the user session and uses polkit for changes. macOS documents Full Disk Access, network access, optional Accessibility, and occasional sudo in SECURITY.md.",
    href: "https://github.com/abelxmendoza/MacGuardianWatchdog/blob/main/SECURITY.md",
    link: "macOS SECURITY.md",
  },
  {
    title: "Security documentation",
    body: "macOS publishes SECURITY.md in its standalone repository, Linux records a security review summary in docs/RELEASE_READINESS.md, and the unified CerberusGuardian-SecuritySuite includes SECURITY.md across all three Guardians.",
    href: "https://github.com/abelxmendoza/LinuxGuardianWatchdog/blob/main/docs/RELEASE_READINESS.md",
    link: "Linux readiness notes",
  },
  {
    title: "Privacy",
    body: "All three Guardians store scan results and timelines locally on the machine (~/.macguardian, ~/.linuxguardian, and %LocalAppData%\\WindowsGuardianWatchdog) with zero telemetry.",
    href: "https://github.com/abelxmendoza/MacGuardianWatchdog/blob/main/PRIVACY.md",
    link: "macOS PRIVACY.md",
  },
];

export function TrustSection() {
  return (
    <section className="mx-auto max-w-6xl px-4 py-16 sm:px-6" aria-labelledby="trust-title">
      <Reveal>
        <p className="font-mono text-xs uppercase tracking-[0.22em] text-accent">Transparency</p>
        <h2 id="trust-title" className="mt-2 font-display text-3xl tracking-[0.12em] text-paper sm:text-4xl">
          DON&apos;T TRUST. VERIFY.
        </h2>
        <p className="mt-3 max-w-3xl text-muted">
          Security software should earn your trust through transparency, testing, and verifiable
          engineering. The notes below are limited to what was in the public repositories on{" "}
          {evidenceDate}.
        </p>
      </Reveal>
      <div className="mt-8 grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {cards.map((card) => (
          <Reveal key={card.title}>
            <article className="panel flex h-full flex-col rounded-lg p-5">
              <h3 className="font-display text-xl tracking-wide text-paper">{card.title}</h3>
              <p className="mt-3 flex-1 text-sm leading-relaxed text-muted">{card.body}</p>
              <ExternalLink href={card.href} className="mt-4 font-mono text-xs uppercase tracking-[0.14em] text-accent">
                {card.link}
              </ExternalLink>
            </article>
          </Reveal>
        ))}
      </div>
    </section>
  );
}
