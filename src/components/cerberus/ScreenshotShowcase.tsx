import { useId, useState, type KeyboardEvent } from "react";
import { artwork } from "../../data/artwork";
import { guardians } from "../../data/guardians";
import type { GuardianId } from "../../data/types";

export function ScreenshotShowcase() {
  const [active, setActive] = useState<GuardianId>("windows");
  const baseId = useId();
  const guardian = guardians.find((item) => item.id === active) ?? guardians[0];
  const art = artwork[guardian.id];

  function onKeyDown(event: KeyboardEvent<HTMLButtonElement>) {
    const index = guardians.findIndex((item) => item.id === active);
    if (event.key === "ArrowRight") {
      event.preventDefault();
      setActive(guardians[(index + 1) % guardians.length].id);
    }
    if (event.key === "ArrowLeft") {
      event.preventDefault();
      setActive(guardians[(index - 1 + guardians.length) % guardians.length].id);
    }
  }

  return (
    <section id="showcase" className="mx-auto max-w-6xl px-4 py-16 sm:px-6" aria-labelledby="showcase-title">
      <p className="font-mono text-xs uppercase tracking-[0.22em] text-accent">Applications</p>
      <h2 id="showcase-title" className="mt-2 font-display text-3xl tracking-[0.12em] text-paper sm:text-4xl">
        SECURITY YOU CAN SEE.
      </h2>
      <p className="mt-3 max-w-2xl text-muted">
        None of the three repositories publish an application screenshot. The frames below show the
        real logo artwork and say so. They are not pictures of the running software.
      </p>
      <div className="mt-8 flex flex-col gap-2 sm:flex-row" role="tablist" aria-label="Guardian artwork">
        {guardians.map((item) => {
          const selected = item.id === active;
          return (
            <button
              key={item.id}
              id={`${baseId}-tab-${item.id}`}
              type="button"
              role="tab"
              aria-selected={selected}
              aria-controls={`${baseId}-panel-${item.id}`}
              tabIndex={selected ? 0 : -1}
              className="min-h-12 flex-1 rounded border px-4 font-display tracking-[0.16em]"
              style={{
                borderColor: selected ? item.themeColor : "rgba(245,247,255,0.16)",
                color: selected ? item.themeColor : "#c5cbe0",
                background: selected ? `${item.themeColor}18` : "transparent",
              }}
              onClick={() => setActive(item.id)}
              onKeyDown={onKeyDown}
            >
              {item.id === "windows" ? "WINDOWS" : item.id === "linux" ? "LINUX" : "MACOS"}
            </button>
          );
        })}
      </div>
      <div
        id={`${baseId}-panel-${guardian.id}`}
        role="tabpanel"
        aria-labelledby={`${baseId}-tab-${guardian.id}`}
        className="panel mt-4 rounded-lg p-5 sm:p-8"
      >
        <div className="grid items-center gap-6 lg:grid-cols-[minmax(0,280px)_1fr]">
          <img
            src={art.logo}
            alt={art.logoAlt}
            width={640}
            height={640}
            className="mx-auto h-auto w-full max-w-xs object-contain"
          />
          <div>
            <p className="inline-flex rounded border border-accent/50 px-2 py-1 font-mono text-[11px] uppercase tracking-[0.14em] text-accent">
              Placeholder · no screenshot published
            </p>
            <h3 className="mt-4 font-display text-2xl tracking-wide text-paper">{guardian.name}</h3>
            <p className="mt-2 text-sm leading-relaxed text-muted">{guardian.description}</p>
            <h4 className="mt-5 font-mono text-[11px] uppercase tracking-[0.14em] text-dim">Supported systems</h4>
            <ul className="mt-2 list-disc space-y-1 pl-4 text-sm text-muted">
              {guardian.supportedVersions.map((item) => (
                <li key={item}>{item}</li>
              ))}
            </ul>
            <h4 className="mt-5 font-mono text-[11px] uppercase tracking-[0.14em] text-dim">Development status</h4>
            <p className="mt-2 text-sm text-paper">{guardian.release.statusLabel}</p>
            <p className="mt-1 text-sm text-muted">{guardian.ciNote}</p>
          </div>
        </div>
      </div>
    </section>
  );
}
