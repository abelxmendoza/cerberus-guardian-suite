export const site = {
  name: "CERBERUS",
  subtitle: "The Guardian Security Suite",
  tagline: "Three Platforms. One Guardian.",
  secondaryTagline: "Detect. Monitor. Protect.",
  title: "CERBERUS | Cross-Platform Security Toolkit",
  description:
    "Explore CERBERUS, an independent open-source security monitoring and system hardening toolkit for Windows, Linux, and macOS.",
  canonicalUrl: "https://www.abelxmendoza.com/projects/cerberus",
  github: "https://github.com/abelxmendoza",
} as const;

export const navItems = [
  { href: "#overview", label: "Overview" },
  { href: "#guardians", label: "Guardians" },
  { href: "#features", label: "Features" },
  { href: "#security", label: "Security" },
  { href: "#documentation", label: "Documentation" },
  { href: site.github, label: "GitHub", external: true },
] as const;

export const developer = {
  name: "Abel Mendoza",
  background:
    "Computer Science graduate from California State University, Fullerton.",
  experience:
    "Experience across robotics operations, hardware testing, systems validation, and software engineering.",
  interests: "Robotics, autonomous systems, Linux, security tooling, and systems engineering.",
  summary:
    "CERBERUS represents an independent engineering effort to develop transparent, cross-platform security monitoring tools.",
  links: [
    { label: "Personal Portfolio", href: "https://www.abelxmendoza.com" },
    { label: "GitHub", href: "https://github.com/abelxmendoza" },
    { label: "LinkedIn", href: "https://www.linkedin.com/in/abelxmendoza/" },
  ],
} as const;
