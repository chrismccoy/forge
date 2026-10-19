# Pixel Press: Batch Image Converter 🖼️

Pixel Press is a command line tool that converts folders of images
between formats and sizes. It reads a JSON config with a list of
transforms and writes the results to an output folder.

## Status
Stable. Version 1.4.0.

## Stack
- Node.js 20
- sharp
- commander

## Usage

```bash
npx pixel-press ./photos ./out --resize 1200x800 --format webp
```

## Features
- Skips files that have not changed since the last run
- Runs conversions in parallel, one worker per CPU core
- Dry run mode prints the planned work without writing files

See [SETUP.md](SETUP.md) for local development. The dev server runs at
http://localhost:3000.

Repo: https://github.com/example-user/pixel-press
