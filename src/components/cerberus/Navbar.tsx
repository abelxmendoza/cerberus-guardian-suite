import { Menu, X } from "lucide-react";
import { useState } from "react";
import { navItems } from "../../data/site";

export function Navbar() {
  const [open, setOpen] = useState(false);

  return (
    <header className="sticky top-0 z-40 border-b border-white/10 bg-[#050508]/85 backdrop-blur-md">
      <nav className="mx-auto flex h-16 w-full max-w-6xl items-center justify-between px-4 sm:px-6" aria-label="Primary">
        <a href="#overview" className="font-display text-lg tracking-[0.22em] text-paper">
          CERBERUS
        </a>
        <ul className="hidden items-center gap-6 lg:flex">
          {navItems.map((item) => (
            <li key={item.label}>
              {"external" in item && item.external ? (
                <a
                  href={item.href}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="font-mono text-xs uppercase tracking-[0.16em] text-muted hover:text-paper"
                >
                  {item.label}
                </a>
              ) : (
                <a
                  href={item.href}
                  className="font-mono text-xs uppercase tracking-[0.16em] text-muted hover:text-paper"
                >
                  {item.label}
                </a>
              )}
            </li>
          ))}
        </ul>
        <button
          type="button"
          className="inline-flex h-11 w-11 items-center justify-center rounded border border-white/15 text-paper lg:hidden"
          aria-expanded={open}
          aria-controls="mobile-nav"
          onClick={() => setOpen((value) => !value)}
        >
          <span className="sr-only">{open ? "Close menu" : "Open menu"}</span>
          {open ? <X aria-hidden="true" size={20} /> : <Menu aria-hidden="true" size={20} />}
        </button>
      </nav>
      {open ? (
        <ul id="mobile-nav" className="space-y-1 border-t border-white/10 px-4 py-3 lg:hidden">
          {navItems.map((item) => (
            <li key={item.label}>
              {"external" in item && item.external ? (
                <a
                  href={item.href}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="block rounded px-2 py-3 font-mono text-sm uppercase tracking-[0.14em] text-paper"
                  onClick={() => setOpen(false)}
                >
                  {item.label}
                </a>
              ) : (
                <a
                  href={item.href}
                  className="block rounded px-2 py-3 font-mono text-sm uppercase tracking-[0.14em] text-paper"
                  onClick={() => setOpen(false)}
                >
                  {item.label}
                </a>
              )}
            </li>
          ))}
        </ul>
      ) : null}
    </header>
  );
}
