import { CompatibilityMatrix } from "../components/cerberus/CompatibilityMatrix";
import { DeveloperSection } from "../components/cerberus/DeveloperSection";
import { DocumentationSection } from "../components/cerberus/DocumentationSection";
import { DownloadCenter } from "../components/cerberus/DownloadCenter";
import { FeatureGrid } from "../components/cerberus/FeatureGrid";
import { Footer } from "../components/cerberus/Footer";
import { GuardianGrid } from "../components/cerberus/GuardianGrid";
import { Hero } from "../components/cerberus/Hero";
import { Navbar } from "../components/cerberus/Navbar";
import { ScreenshotShowcase } from "../components/cerberus/ScreenshotShowcase";
import { SecuritySection } from "../components/cerberus/SecuritySection";
import { TelemetryPipelineSection } from "../components/cerberus/TelemetryPipelineSection";
import { TrustSection } from "../components/cerberus/TrustSection";

export function Cerberus() {
  return (
    <>
      <a
        href="#main"
        className="sr-only focus:not-sr-only focus:absolute focus:left-4 focus:top-4 focus:z-50 focus:rounded focus:bg-paper focus:px-3 focus:py-2 focus:text-ink"
      >
        Skip to content
      </a>
      <Navbar />
      <main id="main">
        <Hero />
        <GuardianGrid />
        <FeatureGrid />
        <CompatibilityMatrix />
        <TelemetryPipelineSection />
        <ScreenshotShowcase />
        <TrustSection />
        <DownloadCenter />
        <SecuritySection />
        <DocumentationSection />
        <DeveloperSection />
      </main>
      <Footer />
    </>
  );
}
