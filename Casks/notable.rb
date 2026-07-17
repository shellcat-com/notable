cask "notable" do
  version "0.1.0"
  sha256 :no_check

  url "https://github.com/bswxyz/notable/releases/download/v#{version}/Notable.zip"
  name "Notable"
  desc "Local-first macOS Capture, annotation, and recording app"
  homepage "https://github.com/bswxyz/notable"

  depends_on macos: ">= :ventura"

  app "Notable.app"

  zap trash: [
    "~/Library/Application Support/io.notable.Notable",
  ]
end
