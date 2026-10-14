import { Apple, AppWindow, Terminal } from "lucide-react";
import type { LucideIcon } from "lucide-react";
import { artwork } from "../../data/artwork";
import { isPublishableDownload } from "../../data/releases";
import type { Guardian, GuardianId } from "../../data/types";
import { ExternalLink } from "./ExternalLink";

const icons: Record<GuardianId, LucideIcon> = {
  windows: AppWindow,
  linux: Terminal,
  macos: Apple,
};

interface GuardianCardProps {
  guardian: Guardian;
}

export function GuardianCard({ guardian }: GuardianCardProps) {
  const Icon = icons[guardian.id];
  const art = artwork[guardian.id];
  const canDownload = isPublishableDownload(guardian.release);

  return (
    <article
      className="panel flex h-full flex-col rounded-lg p-5"
      style={{ borderColor: `${guardian.themeColor}66` }}
    >
      <div className="flex items-center gap-3">
        <span
          className="inline-flex h-10 w-10 items-center justify-center rounded border"
          style={{ borderColor: guardian.themeColor, color: guardian.themeColor }}
        >
          <Icon aria-hidden="true" size={18} />
        </span>
        <p className="font-mono text-[11px] uppercase tracking-[0.18em]" style={{ color: guardian.themeColor }}>
          {guardian.platform}
        </p>
      </div>
      <img
        src={art.logo}
        alt={art.logoAlt}
        width={640}
        height={640}
        className="mx-auto mt-4 h-44 w-full object-contain"
      />
      <h3 className="mt-4 font-display text-xl tracking-wide text-paper">{guardian.name}</h3>
      <p className="mt-2 text-sm leading-relaxed text-muted">{guardian.description}</p>
      <dl className="mt-4 space-y-2 text-sm">
        <div>
          <dt className="font-mono text-[11px] uppercase tracking-[0.14em] text-dim">Release status</dt>
          <dd className="text-paper">{guardian.release.statusLabel}</dd>
        </div>
        <div>
          <dt className="font-mono text-[11px] uppercase tracking-[0.14em] text-dim">Latest release</dt>
          <dd className="text-paper">{guardian.release.version ?? "Not published"}</dd>
        </div>
      </dl>
      <p className="mt-3 text-xs leading-relaxed text-dim">{guardian.release.versionNote}</p>
      <h4 className="mt-5 font-mono text-[11px] uppercase tracking-[0.16em] text-dim">Supported versions</h4>
      <ul className="mt-2 list-disc space-y-1 pl-4 text-sm text-muted">
        {guardian.supportedVersions.map((item) => (
          <li key={item}>{item}</li>
        ))}
      </ul>
      <h4 className="mt-5 font-mono text-[11px] uppercase tracking-[0.16em] text-dim">Verified features</h4>
      <ul className="mt-2 list-disc space-y-1 pl-4 text-sm text-muted">
        {guardian.verifiedFeatures.map((item) => (
          <li key={item}>{item}</li>
        ))}
      </ul>
      <div className="mt-auto flex flex-col gap-2 pt-6">
        {canDownload && guardian.release.downloadUrl ? (
          <ExternalLink
            href={guardian.release.downloadUrl}
            className="inline-flex min-h-12 items-center justify-center rounded px-4 font-display tracking-wide text-ink"
          >
            Download for {guardian.platform}
          </ExternalLink>
        ) : (
          <p
            className="inline-flex min-h-12 items-center justify-center rounded border border-dashed border-white/20 px-4 text-center font-display tracking-wide text-dim"
            role="status"
          >
            {guardian.release.statusLabel}
          </p>
        )}
        <ExternalLink
          href={guardian.repositoryUrl}
          className="inline-flex min-h-12 items-center justify-center rounded border px-4 font-display tracking-wide text-paper hover:border-white/40"
        >
          View Source Code
        </ExternalLink>
      </div>
    </article>
  );
}
