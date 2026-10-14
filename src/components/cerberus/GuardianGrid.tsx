import { guardians } from "../../data/guardians";
import { GuardianCard } from "./GuardianCard";
import { Reveal } from "./Reveal";

export function GuardianGrid() {
  return (
    <section id="guardians" className="mx-auto max-w-6xl px-4 py-16 sm:px-6">
      <Reveal>
        <p className="font-mono text-xs uppercase tracking-[0.22em] text-accent">Platforms</p>
        <h2 className="mt-2 font-display text-3xl tracking-[0.12em] text-paper sm:text-4xl">
          CHOOSE YOUR GUARDIAN
        </h2>
        <p className="mt-3 max-w-2xl text-muted">
          Three specialized security applications. One unified mission.
        </p>
      </Reveal>
      <div className="mt-8 grid gap-5 md:grid-cols-2 lg:grid-cols-3">
        {guardians.map((guardian, index) => (
          <Reveal key={guardian.id} delay={index * 0.05} className="h-full">
            <GuardianCard guardian={guardian} />
          </Reveal>
        ))}
      </div>
    </section>
  );
}
