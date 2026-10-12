/**
 * @file Builds a contact sheet: one PNG with a grid of frames taken at even intervals across a
 * video. Used to check a recording without watching it. Only reads the video; it never touches
 * the site.
 *
 * Usage: node contact-sheet.js <video> [output.png] [cols] [rows] [tileWidth]
 *
 * The defaults (3 × 3 tiles, 512 px wide, about 1536 px in total) keep the sheet readable when
 * an image viewer or a model scales it down. To read text in one scene, use a smaller grid with
 * wider tiles on that scene's clip, for example `2 2 960`.
 */

import ffmpegPath from 'ffmpeg-static';
import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync } from 'node:fs';
import path from 'node:path';

const USAGE = 'Usage: node contact-sheet.js <video> [output.png] [cols] [rows] [tileWidth]';

const [input, output = 'output/contact-sheet.png', cols = '3', rows = '3', tileWidth = '512'] =
  process.argv.slice(2);

/**
 * Stops with a plain message, without a stack trace.
 * @param {string} message - What went wrong.
 * @returns {never}
 */
function fail(message) {
  console.error(message);
  process.exit(1);
}

/**
 * Reads a whole positive number from the command line.
 * @param {string} value - Argument text.
 * @param {string} name - Argument name, for the error message.
 * @returns {number} The number.
 */
function positiveInt(value, name) {
  const n = Number(value);
  if (!Number.isInteger(n) || n < 1) fail(`${name} must be a whole number above 0, not "${value}"`);
  return n;
}

/**
 * Reads a video's length from ffmpeg's report on the file.
 * @param {string} file - Video path.
 * @returns {number} Length in seconds.
 */
function durationSeconds(file) {
  // With only -i, ffmpeg prints the file details (including "Duration:") to stderr and exits.
  const { stderr } = spawnSync(ffmpegPath, ['-i', file], { encoding: 'utf8' });
  const match = stderr.match(/Duration: (\d+):(\d+):(\d+(?:\.\d+)?)/);
  if (!match) fail(`Could not read the duration of ${file}`);
  const [, h, m, s] = match;
  return Number(h) * 3600 + Number(m) * 60 + Number(s);
}

if (!input) fail(USAGE);
if (!existsSync(input)) fail(`Video not found: ${input}`);
const columns = positiveInt(cols, 'cols');
const rowCount = positiveInt(rows, 'rows');
const width = positiveInt(tileWidth, 'tileWidth');

const tiles = columns * rowCount;
const duration = durationSeconds(input);
if (duration <= 0) fail(`${input} has no length`);
// Sampling at tiles / duration frames per second spreads exactly `tiles` frames over the video.
const fps = tiles / duration;

mkdirSync(path.dirname(path.resolve(output)), { recursive: true });

// Each flag sits with its value; .flat() turns the pairs into one argument list.
const ffmpegArgs = [
  ['-y'],
  ['-loglevel', 'error'],
  ['-i', input],
  ['-vf', `fps=${fps},scale=${width}:-1,tile=${columns}x${rowCount}`],
  ['-frames:v', '1'],
  [output],
].flat();
const result = spawnSync(ffmpegPath, ffmpegArgs, { stdio: 'inherit' });

if (result.status !== 0) process.exit(result.status ?? 1);
const interval = (duration / tiles).toFixed(1);
console.log(
  `Saved ${output} (${columns}x${rowCount}, one frame every ${interval}s of ${duration.toFixed(1)}s)`,
);
