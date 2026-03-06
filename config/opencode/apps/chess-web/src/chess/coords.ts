import type { Color, Square } from "./types";

export function opposite(color: Color): Color {
  return color === "w" ? "b" : "w";
}

export function toSquare(file: number, rank: number): Square {
  return rank * 8 + file;
}

export function fileOf(square: Square): number {
  return square % 8;
}

export function rankOf(square: Square): number {
  return Math.floor(square / 8);
}

export function squareName(square: Square): string {
  const file = fileOf(square);
  const rank = rankOf(square);
  return `${String.fromCharCode(97 + file)}${rank + 1}`;
}

export function inBounds(file: number, rank: number): boolean {
  return file >= 0 && file < 8 && rank >= 0 && rank < 8;
}
