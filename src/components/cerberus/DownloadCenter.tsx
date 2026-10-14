import { guardians } from "../../data/guardians";
import { isPublishableDownload } from "../../data/releases";
import { ExternalLink } from "./ExternalLink";

function display(value: string | null): string {
  return value ?? "Not published";
}

export function DownloadCenter() {
  return (
    <section id="download" className="mx-auto max-w-6xl px-4 py-16 sm:px-6">
      <p className="font-mono text-xs uppercase tracking-[0.22em] text-accent">Releases</p>
      <h2 className="mt-2 font-display text-3xl tracking-[0.12em] text-paper sm:text-4xl">
        DEPLOY YOUR GUARDIAN.
      </h2>
      <p className="mt-3 max-w-3xl text-muted">
        Linux and macOS are ready. Download either archive and it saves to your laptop, then follow
        the install steps under that panel. Windows is still in development and is the least complete
        Guardian, so it has no download.
      </p>
      <div className="mt-8 grid gap-5 lg:grid-cols-3">
        {guardians.map((guardian) => {
          const release = guardian.release;
          const ready = isPublishableDownload(release);
          return (
            <article
              key={guardian.id}
              className="panel rounded-lg p-5"
              style={{ borderColor: `${guardian.themeColor}66` }}
            >
              <h3 className="font-display text-xl tracking-wide text-paper">{guardian.name}</h3>
              <dl className="mt-4 space-y-3 text-sm">
                <div className="flex justify-between gap-4">
                  <dt className="text-dim">Latest version</dt>
                  <dd className="text-right text-paper">{display(release.version)}</dd>
                </div>
                <div className="flex justify-between gap-4">
                  <dt className="text-dim">Status</dt>
                  <dd className="text-right text-paper">{release.statusLabel}</dd>
                </div>
                <div>
                  <dt className="text-dim">Supported OS</dt>
                  <dd className="mt-1 text-paper">{guardian.supportedVersions[0]}</dd>
                </div>
                <div className="flex justify-between gap-4">
                  <dt className="text-dim">Architecture</dt>
                  <dd className="text-right text-paper">
                    {release.architectures.length > 0 ? release.architectures.join(", ") : "Not published"}
                  </dd>
                </div>
                <div className="flex justify-between gap-4">
                  <dt className="text-dim">Release date</dt>
                  <dd className="text-right text-paper">{display(release.releaseDate)}</dd>
                </div>
                <div className="flex justify-between gap-4">
                  <dt className="text-dim">File size</dt>
                  <dd className="text-right text-paper">{display(release.fileSize)}</dd>
                </div>
                <div>
                  <dt className="text-dim">SHA-256</dt>
                  <dd className="mt-1 break-all font-mono text-xs text-paper">{display(release.checksum)}</dd>
                </div>
              </dl>
              <p className="mt-4 text-xs leading-relaxed text-dim">{release.versionNote}</p>
              <div className="mt-5 flex flex-col gap-2">
                {ready && release.downloadUrl && release.downloadLabel ? (
                  <ExternalLink
                    href={release.downloadUrl}
                    className="inline-flex min-h-12 items-center justify-center rounded px-4 text-center font-display tracking-wide"
                    style={{ background: guardian.themeColor, color: "#F5F7FF" }}
                  >
                    {release.downloadLabel}
                  </ExternalLink>
                ) : (
                  <p className="inline-flex min-h-12 items-center justify-center rounded border border-dashed border-white/20 px-3 text-center text-dim" role="status">
                    In development — no download yet
                  </p>
                )}
                <ExternalLink href={guardian.repositoryUrl} className="text-sm text-accent">
                  GitHub source
                </ExternalLink>
                {release.releaseNotesUrl ? (
                  <ExternalLink href={release.releaseNotesUrl} className="text-sm text-accent">
                    Release notes
                  </ExternalLink>
                ) : (
                  <p className="text-sm text-dim">Release notes: not published</p>
                )}
                <ExternalLink href={release.releasePageUrl} className="text-sm text-muted">
                  GitHub Releases page
                </ExternalLink>
              </div>
            </article>
          );
        })}
      </div>

      <div className="panel mt-8 rounded-lg p-5 sm:p-6">
        <h3 className="font-display text-2xl tracking-wide text-paper">Verify a future download</h3>
        <p className="mt-3 text-sm leading-relaxed text-muted">
          There is no file to checksum today. When a Guardian publishes a GitHub Release asset, compare
          the SHA-256 on that release with a hash you compute locally. Do not run a build from a
          random mirror.
        </p>
        <div className="mt-4 grid min-w-0 gap-4 md:grid-cols-2">
          <div>
            <h4 className="font-mono text-[11px] uppercase tracking-[0.14em] text-dim">Windows</h4>
            <pre className="mt-2 max-w-full whitespace-pre-wrap rounded border border-white/10 bg-black/40 p-3 font-mono text-xs text-paper">
              Get-FileHash .\asset.zip -Algorithm SHA256
            </pre>
          </div>
          <div>
            <h4 className="font-mono text-[11px] uppercase tracking-[0.14em] text-dim">Linux and macOS</h4>
            <pre className="mt-2 max-w-full whitespace-pre-wrap rounded border border-white/10 bg-black/40 p-3 font-mono text-xs text-paper">
              shasum -a 256 asset.zip
            </pre>
          </div>
        </div>
      </div>

      <div className="mt-6 grid gap-4 lg:grid-cols-3">
        {guardians.map((guardian) => (
          <article key={guardian.id} className="panel rounded-lg p-5">
            <h3 className="font-display text-lg text-paper">{guardian.platform}</h3>
            <h4 className="mt-4 font-mono text-[11px] uppercase tracking-[0.14em] text-dim">Install from source</h4>
            <ol className="mt-2 list-decimal space-y-2 pl-4 text-sm text-muted">
              {guardian.install.map((step) => (
                <li key={step}>{step}</li>
              ))}
            </ol>
            <h4 className="mt-4 font-mono text-[11px] uppercase tracking-[0.14em] text-dim">Uninstall</h4>
            <ul className="mt-2 list-disc space-y-2 pl-4 text-sm text-muted">
              {guardian.uninstall.map((step) => (
                <li key={step}>{step}</li>
              ))}
            </ul>
          </article>
        ))}
      </div>
    </section>
  );
}
