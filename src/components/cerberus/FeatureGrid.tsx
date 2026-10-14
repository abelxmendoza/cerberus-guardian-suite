import { Eye, LockKeyhole, Radar, ScanSearch, Shield, Wrench } from "lucide-react";
import type { LucideIcon } from "lucide-react";
import { capabilities } from "../../data/features";
import { Reveal } from "./Reveal";

const icons: Record<string, LucideIcon> = {
  integrity: Shield,
  posture: ScanSearch,
  network: Radar,
  threat: Eye,
  audit: LockKeyhole,
  remediation: Wrench,
};

export function FeatureGrid() {
  return (
    <section id="features" className="mx-auto max-w-6xl px-4 py-16 sm:px-6">
      <Reveal>
        <p className="font-mono text-xs uppercase tracking-[0.22em] text-accent">Capabilities</p>
        <h2 className="mt-2 font-display text-3xl tracking-[0.08em] text-paper sm:text-4xl">
          KNOW YOUR SYSTEM.
          <span className="mt-1 block">UNDERSTAND YOUR SECURITY.</span>
        </h2>
        <p className="mt-3 max-w-2xl text-muted">
          These are capabilities found in the source trees. A check in the matrix means the module
          exists. It does not mean every Guardian implements it the same way.
        </p>
      </Reveal>
      <div className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {capabilities.map((capability) => {
          const Icon = icons[capability.id] ?? Shield;
          const platforms = (Object.keys(capability.support) as Array<keyof typeof capability.support>).filter(
            (id) => capability.support[id].level === "present",
          );
          return (
            <Reveal key={capability.id}>
              <article className="panel h-full rounded-lg p-5">
                <Icon aria-hidden="true" className="text-accent" size={20} />
                <h3 className="mt-3 font-display text-xl tracking-wide text-paper">{capability.title}</h3>
                <p className="mt-2 text-sm leading-relaxed text-muted">{capability.summary}</p>
                <p className="mt-4 font-mono text-[11px] uppercase tracking-[0.14em] text-dim">
                  In repository: {platforms.join(" · ")}
                </p>
              </article>
            </Reveal>
          );
        })}
      </div>
    </section>
  );
}
