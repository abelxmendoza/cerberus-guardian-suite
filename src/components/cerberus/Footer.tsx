import { evidenceDate } from "../../data/guardians";
import { site } from "../../data/site";
import { ExternalLink } from "./ExternalLink";

export function Footer() {
  return (
    <footer className="border-t border-white/10">
      <div className="mx-auto flex max-w-6xl flex-col gap-4 px-4 py-10 text-sm text-dim sm:px-6">
        <p className="font-display tracking-[0.18em] text-paper">{site.name}</p>
        <p className="max-w-3xl leading-relaxed">
          {site.tagline} CERBERUS is an independent monitoring and hardening effort. It is not
          antivirus, not endpoint protection, and not a guarantee of safety. Linux and macOS
          repositories use the MIT License. The Windows repository has no LICENSE file.
        </p>
        <p>Repository evidence checked {evidenceDate}.</p>
        <ExternalLink href={site.github} className="text-accent">
          github.com/abelxmendoza
        </ExternalLink>
      </div>
    </footer>
  );
}
