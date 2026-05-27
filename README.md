# HEIC to JPEG

HEIC to JPEG is a local-first macOS utility for quickly converting HEIC images into JPEG files.

Drop HEIC files, or folders containing HEIC files, onto the app. Each converted JPEG is written next to the original image. Existing JPEGs are preserved by choosing an available filename such as `Photo 2.jpg`.

## Run the macOS App

```sh
./scripts/run-app.sh
```

The helper script builds the Swift package, wraps the executable in a local `.app` bundle under `.build/debug`, and opens it.

## Development

Run tests with:

```sh
swift test
```
