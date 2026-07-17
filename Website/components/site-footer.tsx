import Link from "next/link";
import { DOWNLOAD_URL, GITHUB_URL } from "@/lib/site";

export function SiteFooter() {
  return (
    <footer className="border-t border-border/60">
      <div className="mx-auto flex max-w-6xl flex-col gap-4 px-4 py-10 text-sm text-muted-foreground md:flex-row md:items-center">
        <p>
          <span className="font-semibold text-foreground">Parcel</span> — the
          native macOS Capture studio from{" "}
          <a
            href="https://parable.dev"
            className="text-foreground/80 underline-offset-4 hover:underline"
          >
            Parable
          </a>
          . MIT licensed.
        </p>
        <nav className="flex flex-wrap gap-4 md:ml-auto">
          <a href="#features" className="hover:text-foreground">
            Features
          </a>
          <a href="#install" className="hover:text-foreground">
            Install
          </a>
          <a href={DOWNLOAD_URL} download className="hover:text-foreground">
            Download
          </a>
          <a
            href={GITHUB_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="hover:text-foreground"
          >
            GitHub
          </a>
          <Link
            href="https://github.com/bswxyz/parable"
            className="hover:text-foreground"
          >
            Parable UI
          </Link>
        </nav>
      </div>
    </footer>
  );
}
