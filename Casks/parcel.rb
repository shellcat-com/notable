cask "parcel" do
  version "1.0.0"
  sha256 :no_check

  url "https://github.com/bswxyz/notable/releases/download/v#{version}/Parcel.zip"
  name "Parcel"
  desc "Local-first macOS Capture, annotation, and recording app from Parable"
  homepage "https://parcel.parable.dev"

  depends_on macos: ">= :ventura"

  app "Parcel.app"

  zap trash: [
    "~/Library/Application Support/dev.parable.Parcel",
    "~/Library/Application Support/io.notable.Notable",
  ]
end
