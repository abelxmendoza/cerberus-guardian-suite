import { useMemo, useState } from "react";
import { guardians } from "../../data/guardians";
import {
  generateUnifiedReport,
  normalizeGuardianEvent,
  sampleRawGuardianEvents,
} from "../../data/pipeline";
import type { GuardianId } from "../../data/types";
import { Reveal } from "./Reveal";

export function TelemetryPipelineSection() {
  const [selectedIndex, setSelectedIndex] = useState(0);

  const normalizedEvents = useMemo(
    () => sampleRawGuardianEvents.map((item) => normalizeGuardianEvent(item.raw, item.platform)),
    [],
  );

  const unifiedReport = useMemo(() => generateUnifiedReport(normalizedEvents), [normalizedEvents]);

  const currentSample = sampleRawGuardianEvents[selectedIndex] ?? sampleRawGuardianEvents[0];
  const currentNormalized = normalizedEvents[selectedIndex] ?? normalizedEvents[0];

  const colorForPlatform = (id: GuardianId) =>
    guardians.find((g) => g.id === id)?.themeColor ?? "#00BFFF";

  return (
    <section
      id="pipeline"
      className="mx-auto max-w-6xl px-4 py-16 sm:px-6"
      aria-labelledby="pipeline-title"
    >
      <Reveal>
        <p className="font-mono text-xs uppercase tracking-[0.22em] text-accent">
          Unified Telemetry Workflow
        </p>
        <h2
          id="pipeline-title"
          className="mt-2 font-display text-3xl tracking-[0.1em] text-paper sm:text-4xl"
        >
          DETECT. NORMALIZE. REPORT.
        </h2>
        <p className="mt-3 max-w-3xl text-muted">
          Each Guardian emits platform-native security records. The shared{" "}
          <code className="font-mono text-xs text-paper">shared/schemas/event_spec_v1.json</code>{" "}
          and{" "}
          <code className="font-mono text-xs text-paper">
            shared/pipeline/normalize_and_report.py
          </code>{" "}
          pipeline normalizes raw events from Windows, Linux, and macOS into one schema and builds
          a unified posture report.
        </p>
      </Reveal>

      <div className="mt-8 flex flex-wrap gap-2" role="group" aria-label="Select raw Guardian event">
        {sampleRawGuardianEvents.map((item, idx) => {
          const active = idx === selectedIndex;
          const color = colorForPlatform(item.platform);
          return (
            <button
              key={item.label}
              type="button"
              onClick={() => setSelectedIndex(idx)}
              className="rounded border px-4 py-2 font-mono text-xs uppercase tracking-[0.14em]"
              style={{
                borderColor: active ? color : "rgba(245,247,255,0.16)",
                color: active ? color : "#c5cbe0",
                background: active ? `${color}18` : "transparent",
              }}
            >
              {item.label}
            </button>
          );
        })}
      </div>

      <div className="mt-6 grid gap-5 lg:grid-cols-3">
        <article className="panel rounded-lg p-5">
          <p className="font-mono text-[11px] uppercase tracking-[0.14em] text-dim">
            1. Detect (Raw Platform Event)
          </p>
          <h3 className="mt-2 font-display text-lg text-paper">{currentSample.label}</h3>
          <pre className="mt-3 overflow-x-auto rounded border border-white/10 bg-black/50 p-3 font-mono text-xs text-paper">
            {JSON.stringify(currentSample.raw, null, 2)}
          </pre>
        </article>

        <article className="panel rounded-lg p-5">
          <p className="font-mono text-[11px] uppercase tracking-[0.14em] text-dim">
            2. Normalize (Event Spec v1.0.0)
          </p>
          <h3 className="mt-2 font-display text-lg text-paper">
            {currentNormalized.type} · {currentNormalized.kind}
          </h3>
          <pre className="mt-3 overflow-x-auto rounded border border-white/10 bg-black/50 p-3 font-mono text-xs text-paper">
            {JSON.stringify(currentNormalized, null, 2)}
          </pre>
        </article>

        <article className="panel flex flex-col justify-between rounded-lg p-5">
          <div>
            <p className="font-mono text-[11px] uppercase tracking-[0.14em] text-dim">
              3. Generate Report &amp; Display
            </p>
            <div className="mt-3 flex items-baseline justify-between">
              <h3 className="font-display text-xl text-paper">Unified Posture Score</h3>
              <span className="font-display text-3xl text-accent">
                {unifiedReport.securityScore}/100
              </span>
            </div>
            <p className="mt-1 font-mono text-xs uppercase tracking-[0.14em] text-dim">
              Status: {unifiedReport.overallStatus}
            </p>
            <p className="mt-3 text-sm leading-relaxed text-muted">
              {unifiedReport.executiveSummary}
            </p>
            <ul className="mt-4 space-y-2 text-xs text-muted">
              {unifiedReport.events.map((ev) => (
                <li
                  key={`${ev.platform}-${ev.timestamp}`}
                  className="rounded border border-white/10 bg-black/30 p-2.5"
                >
                  <span
                    className="font-mono uppercase"
                    style={{ color: colorForPlatform(ev.platform) }}
                  >
                    [{ev.platform}]
                  </span>{" "}
                  <span className="font-mono uppercase text-paper">{ev.severity}</span> ·{" "}
                  <span>{ev.message}</span>
                </li>
              ))}
            </ul>
          </div>
          <p className="mt-4 font-mono text-[11px] text-dim">
            CLI: <code>./cerberus.sh --report</code>
          </p>
        </article>
      </div>
    </section>
  );
}
