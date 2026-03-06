import type { CastlingRights, Color, GameState, Piece, PieceType } from "./types";
import { toSquare } from "./coords";
import { evaluateStatus, positionKey } from "./movegen";

const START_FEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR";

const DEFAULT_CASTLING: CastlingRights = {
  wk: true,
  wq: true,
  bk: true,
  bq: true,
};

const PIECE_MAP: Record<string, PieceType> = {
  p: "p",
  n: "n",
  b: "b",
  r: "r",
  q: "q",
  k: "k",
};

export const INITIAL_CLOCK_MS = 10 * 60 * 1000;

function parseBoard(fenBoard: string): Piece[] {
  const board: Array<Piece | null> = Array.from({ length: 64 }, () => null);
  const rows = fenBoard.split("/");

  if (rows.length !== 8) {
    throw new Error("Invalid board definition");
  }

  for (let fenRank = 0; fenRank < 8; fenRank += 1) {
    const row = rows[fenRank];
    if (!row) {
      throw new Error("Missing FEN row");
    }

    let file = 0;
    for (const char of row) {
      if (/\d/.test(char)) {
        file += Number(char);
      } else {
        const type = PIECE_MAP[char.toLowerCase()];
        if (!type) {
          throw new Error(`Unknown piece code: ${char}`);
        }
        const color: Color = char === char.toUpperCase() ? "w" : "b";
        const rank = 7 - fenRank;
        board[toSquare(file, rank)] = { color, type };
        file += 1;
      }
    }
  }

  return board as Piece[];
}

export function createInitialState(): GameState {
  const base: GameState = {
    board: parseBoard(START_FEN),
    turn: "w",
    castling: DEFAULT_CASTLING,
    enPassant: null,
    halfMoveClock: 0,
    fullMoveNumber: 1,
    historyKeys: [],
    moveHistory: [],
    status: "active",
    whiteMs: INITIAL_CLOCK_MS,
    blackMs: INITIAL_CLOCK_MS,
  };

  const withHistory: GameState = {
    ...base,
    historyKeys: [positionKey(base)],
  };

  return {
    ...withHistory,
    status: evaluateStatus(withHistory),
  };
}
