import { capabilities } from "../../data/features";
import { guardians } from "../../data/guardians";
import type { GuardianId } from "../../data/types";
import { Reveal } from "./Reveal";

const columns: GuardianId[] = ["windows", "linux", "macos"];

export function CompatibilityMatrix() {
  return (
    <section id="compatibility" className="mx-auto max-w-6xl px-4 pb-16 sm:px-6" aria-labelledby="matrix-title">
      <Reveal>
        <h2 id="matrix-title" className="font-display text-2xl tracking-[0.12em] text-paper sm:text-3xl">
          FEATURE COMPATIBILITY
        </h2>
        <p className="mt-3 max-w-3xl text-sm leading-relaxed text-muted">
          Present means the named file exists in that Guardian&apos;s repository. Linux&apos;s own
          readiness note says detection quality against real attacks has not been measured.
        </p>
      </Reveal>
      <div className="mt-6 hidden lg:block">
        <table className="panel w-full table-fixed border-collapse overflow-hidden rounded-lg text-left text-sm">
          <caption className="sr-only">
            Which CERBERUS Guardian repositories contain each security capability
          </caption>
          <thead>
            <tr className="border-b border-white/10 font-mono text-[11px] uppercase tracking-[0.14em] text-dim">
              <th scope="col" className="px-4 py-3 font-medium">
                Capability
              </th>
              {columns.map((id) => {
                const guardian = guardians.find((item) => item.id === id);
                return (
                  <th key={id} scope="col" className="px-4 py-3 font-medium" style={{ color: guardian?.themeColor }}>
                    {guardian?.platform}
                  </th>
                );
              })}
            </tr>
          </thead>
          <tbody>
            {capabilities.map((capability) => (
              <tr key={capability.id} className="border-b border-white/10 align-top last:border-0">
                <th scope="row" className="px-4 py-4 font-display text-base font-medium text-paper">
                  {capability.title}
                  <span className="mt-1 block font-sans text-xs font-normal text-dim">{capability.summary}</span>
                </th>
                {columns.map((id) => {
                  const support = capability.support[id];
                  return (
                    <td key={id} className="px-4 py-4 text-muted">
                      <span className="text-paper">{support.level === "present" ? "Present" : "Not in repo"}</span>
                      <span className="mt-1 block font-mono text-[11px] leading-relaxed break-words text-dim">{support.evidence}</span>
                    </td>
                  );
                })}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <div className="mt-6 space-y-4 lg:hidden">
        {capabilities.map((capability) => (
          <article key={capability.id} className="panel rounded-lg p-4">
            <h3 className="font-display text-lg text-paper">{capability.title}</h3>
            <p className="mt-1 text-sm text-muted">{capability.summary}</p>
            <ul className="mt-3 space-y-3">
              {columns.map((id) => {
                const guardian = guardians.find((item) => item.id === id);
                const support = capability.support[id];
                return (
                  <li key={id}>
                    <p className="font-mono text-[11px] uppercase tracking-[0.14em]" style={{ color: guardian?.themeColor }}>
                      {guardian?.platform}: {support.level === "present" ? "Present" : "Not in repo"}
                    </p>
                    <p className="text-xs text-dim">{support.evidence}</p>
                  </li>
                );
              })}
            </ul>
          </article>
        ))}
      </div>
    </section>
  );
}
