Place `Parcel.zip` here before deploying the marketing site.

Generate a Debug zip for local testing:

```bash
xcodegen generate
xcodebuild -project Parcel.xcodeproj -scheme Parcel -configuration Debug \
  -derivedDataPath .derivedData build CODE_SIGN_IDENTITY="-" CODE_SIGNING_ALLOWED=YES
cd .derivedData/Build/Products/Debug && zip -r ../../../../Website/public/downloads/Parcel.zip Parcel.app
```

For production, use `Scripts/release.sh` with Developer ID signing and notarization.
