import { fileOf, inBounds, opposite, rankOf, squareName, toSquare } from "./coords";
import type { CastlingRights, Color, GameState, GameStatus, Move, Piece, PieceType, Square } from "./types";

const KNIGHT_DELTAS = [
  [1, 2],
  [2, 1],
  [2, -1],
  [1, -2],
  [-1, -2],
  [-2, -1],
  [-2, 1],
  [-1, 2],
] as const;

const KING_DELTAS = [
  [1, 1],
  [1, 0],
  [1, -1],
  [0, 1],
  [0, -1],
  [-1, 1],
  [-1, 0],
  [-1, -1],
] as const;

const BISHOP_LINES = [
  [1, 1],
  [1, -1],
  [-1, 1],
  [-1, -1],
] as const;

const ROOK_LINES = [
  [1, 0],
  [-1, 0],
  [0, 1],
  [0, -1],
] as const;

const PROMOTIONS: Array<"q" | "r" | "b" | "n"> = ["q", "r", "b", "n"];

type BoardArray = Array<Piece | null>;

interface MovePreview {
  readonly board: ReadonlyArray<Piece | null>;
  readonly castling: CastlingRights;
  readonly enPassant: Square | null;
  readonly halfMoveClock: number;
  readonly fullMoveNumber: number;
  readonly turn: Color;
}

function cloneCastling(castling: CastlingRights): CastlingRights {
  return {
    wk: castling.wk,
    wq: castling.wq,
    bk: castling.bk,
    bq: castling.bq,
  };
}

function findKingSquare(board: ReadonlyArray<Piece | null>, color: Color): Square | null {
  for (let square = 0; square < 64; square += 1) {
    const piece = board[square];
    if (piece && piece.color === color && piece.type === "k") {
      return square;
    }
  }
  return null;
}

function pieceAt(board: ReadonlyArray<Piece | null>, file: number, rank: number): Piece | null {
  if (!inBounds(file, rank)) {
    return null;
  }
  return board[toSquare(file, rank)];
}

export function isSquareAttacked(board: ReadonlyArray<Piece | null>, square: Square, byColor: Color): boolean {
  const file = fileOf(square);
  const rank = rankOf(square);

  const pawnDir = byColor === "w" ? 1 : -1;
  const pawnRank = rank - pawnDir;
  for (const pawnFile of [file - 1, file + 1]) {
    const pawn = pieceAt(board, pawnFile, pawnRank);
    if (pawn && pawn.color === byColor && pawn.type === "p") {
      return true;
    }
  }

  for (const [df, dr] of KNIGHT_DELTAS) {
    const knight = pieceAt(board, file + df, rank + dr);
    if (knight && knight.color === byColor && knight.type === "n") {
      return true;
    }
  }

  for (const [df, dr] of BISHOP_LINES) {
    let x = file + df;
    let y = rank + dr;
    while (inBounds(x, y)) {
      const piece = pieceAt(board, x, y);
      if (piece) {
        if (piece.color === byColor && (piece.type === "b" || piece.type === "q")) {
          return true;
        }
        break;
      }
      x += df;
      y += dr;
    }
  }

  for (const [df, dr] of ROOK_LINES) {
    let x = file + df;
    let y = rank + dr;
    while (inBounds(x, y)) {
      const piece = pieceAt(board, x, y);
      if (piece) {
        if (piece.color === byColor && (piece.type === "r" || piece.type === "q")) {
          return true;
        }
        break;
      }
      x += df;
      y += dr;
    }
  }

  for (const [df, dr] of KING_DELTAS) {
    const king = pieceAt(board, file + df, rank + dr);
    if (king && king.color === byColor && king.type === "k") {
      return true;
    }
  }

  return false;
}

export function isInCheck(state: GameState, color: Color): boolean {
  const kingSquare = findKingSquare(state.board, color);
  if (kingSquare === null) {
    return false;
  }
  return isSquareAttacked(state.board, kingSquare, opposite(color));
}

function makePreview(state: GameState, move: Move): MovePreview {
  const board: BoardArray = [...state.board];
  const moving = board[move.from];
  if (!moving) {
    throw new Error("No piece on source square");
  }

  let captured = board[move.to];
  board[move.from] = null;

  if (move.isEnPassant) {
    const offset = moving.color === "w" ? -8 : 8;
    const captureSquare = move.to + offset;
    captured = board[captureSquare];
    board[captureSquare] = null;
  }

  const castling = cloneCastling(state.castling);

  if (moving.type === "k") {
    if (moving.color === "w") {
      castling.wk = false;
      castling.wq = false;
    } else {
      castling.bk = false;
      castling.bq = false;
    }
  }

  if (moving.type === "r") {
    if (move.from === toSquare(0, 0)) {
      castling.wq = false;
    }
    if (move.from === toSquare(7, 0)) {
      castling.wk = false;
    }
    if (move.from === toSquare(0, 7)) {
      castling.bq = false;
    }
    if (move.from === toSquare(7, 7)) {
      castling.bk = false;
    }
  }

  if (captured && captured.type === "r") {
    if (move.to === toSquare(0, 0)) {
      castling.wq = false;
    }
    if (move.to === toSquare(7, 0)) {
      castling.wk = false;
    }
    if (move.to === toSquare(0, 7)) {
      castling.bq = false;
    }
    if (move.to === toSquare(7, 7)) {
      castling.bk = false;
    }
  }

  let pieceToPlace: Piece = moving;
  if (moving.type === "p" && move.promotion) {
    pieceToPlace = { color: moving.color, type: move.promotion };
  }

  board[move.to] = pieceToPlace;

  if (move.isCastle) {
    const rank = moving.color === "w" ? 0 : 7;
    if (move.isCastle === "kingside") {
      const rookFrom = toSquare(7, rank);
      const rookTo = toSquare(5, rank);
      board[rookTo] = board[rookFrom];
      board[rookFrom] = null;
    } else {
      const rookFrom = toSquare(0, rank);
      const rookTo = toSquare(3, rank);
      board[rookTo] = board[rookFrom];
      board[rookFrom] = null;
    }
  }

  let enPassant: Square | null = null;
  if (moving.type === "p") {
    const fromRank = rankOf(move.from);
    const toRank = rankOf(move.to);
    if (Math.abs(toRank - fromRank) === 2) {
      enPassant = toSquare(fileOf(move.from), (fromRank + toRank) / 2);
    }
  }

  const halfMoveClock = moving.type === "p" || captured ? 0 : state.halfMoveClock + 1;
  const fullMoveNumber = state.turn === "b" ? state.fullMoveNumber + 1 : state.fullMoveNumber;

  return {
    board,
    castling,
    enPassant,
    halfMoveClock,
    fullMoveNumber,
    turn: opposite(state.turn),
  };
}

function isLegalAfterMove(state: GameState, move: Move): boolean {
  const preview = makePreview(state, move);
  const kingSquare = findKingSquare(preview.board, state.turn);
  if (kingSquare === null) {
    return false;
  }
  return !isSquareAttacked(preview.board, kingSquare, opposite(state.turn));
}

function addPromotionMoves(target: Move[], from: Square, to: Square, capture = false): void {
  for (const promotion of PROMOTIONS) {
    target.push({
      from,
      to,
      promotion,
      isEnPassant: capture ? undefined : undefined,
    });
  }
}

function generatePiecePseudoMoves(state: GameState, from: Square): Move[] {
  const board = state.board;
  const piece = board[from];
  if (!piece) {
    return [];
  }

  const moves: Move[] = [];
  const file = fileOf(from);
  const rank = rankOf(from);

  if (piece.type === "p") {
    const dir = piece.color === "w" ? 1 : -1;
    const startRank = piece.color === "w" ? 1 : 6;
    const promotionRank = piece.color === "w" ? 7 : 0;

    const forwardRank = rank + dir;
    if (inBounds(file, forwardRank)) {
      const forwardSquare = toSquare(file, forwardRank);
      if (!board[forwardSquare]) {
        if (forwardRank === promotionRank) {
          addPromotionMoves(moves, from, forwardSquare);
        } else {
          moves.push({ from, to: forwardSquare });
        }

        if (rank === startRank) {
          const doubleRank = rank + dir * 2;
          const doubleSquare = toSquare(file, doubleRank);
          if (!board[doubleSquare]) {
            moves.push({ from, to: doubleSquare });
          }
        }
      }
    }

    for (const captureFile of [file - 1, file + 1]) {
      const captureRank = rank + dir;
      if (!inBounds(captureFile, captureRank)) {
        continue;
      }

      const captureSquare = toSquare(captureFile, captureRank);
      const target = board[captureSquare];
      if (target && target.color !== piece.color) {
        if (captureRank === promotionRank) {
          addPromotionMoves(moves, from, captureSquare, true);
        } else {
          moves.push({ from, to: captureSquare });
        }
      }

      if (state.enPassant !== null && state.enPassant === captureSquare) {
        moves.push({ from, to: captureSquare, isEnPassant: true });
      }
    }

    return moves;
  }

  if (piece.type === "n") {
    for (const [df, dr] of KNIGHT_DELTAS) {
      const x = file + df;
      const y = rank + dr;
      if (!inBounds(x, y)) {
        continue;
      }
      const to = toSquare(x, y);
      const target = board[to];
      if (!target || target.color !== piece.color) {
        moves.push({ from, to });
      }
    }
    return moves;
  }

  if (piece.type === "b" || piece.type === "r" || piece.type === "q") {
    const lines =
      piece.type === "b"
        ? BISHOP_LINES
        : piece.type === "r"
          ? ROOK_LINES
          : [...BISHOP_LINES, ...ROOK_LINES];

    for (const [df, dr] of lines) {
      let x = file + df;
      let y = rank + dr;
      while (inBounds(x, y)) {
        const to = toSquare(x, y);
        const target = board[to];
        if (!target) {
          moves.push({ from, to });
        } else {
          if (target.color !== piece.color) {
            moves.push({ from, to });
          }
          break;
        }
        x += df;
        y += dr;
      }
    }

    return moves;
  }

  for (const [df, dr] of KING_DELTAS) {
    const x = file + df;
    const y = rank + dr;
    if (!inBounds(x, y)) {
      continue;
    }
    const to = toSquare(x, y);
    const target = board[to];
    if (!target || target.color !== piece.color) {
      moves.push({ from, to });
    }
  }

  if (!isSquareAttacked(board, from, opposite(piece.color))) {
    if (piece.color === "w" && state.castling.wk) {
      const f1 = toSquare(5, 0);
      const g1 = toSquare(6, 0);
      if (!board[f1] && !board[g1] && !isSquareAttacked(board, f1, "b") && !isSquareAttacked(board, g1, "b")) {
        moves.push({ from, to: g1, isCastle: "kingside" });
      }
    }

    if (piece.color === "w" && state.castling.wq) {
      const d1 = toSquare(3, 0);
      const c1 = toSquare(2, 0);
      const b1 = toSquare(1, 0);
      if (!board[d1] && !board[c1] && !board[b1] && !isSquareAttacked(board, d1, "b") && !isSquareAttacked(board, c1, "b")) {
        moves.push({ from, to: c1, isCastle: "queenside" });
      }
    }

    if (piece.color === "b" && state.castling.bk) {
      const f8 = toSquare(5, 7);
      const g8 = toSquare(6, 7);
      if (!board[f8] && !board[g8] && !isSquareAttacked(board, f8, "w") && !isSquareAttacked(board, g8, "w")) {
        moves.push({ from, to: g8, isCastle: "kingside" });
      }
    }

    if (piece.color === "b" && state.castling.bq) {
      const d8 = toSquare(3, 7);
      const c8 = toSquare(2, 7);
      const b8 = toSquare(1, 7);
      if (!board[d8] && !board[c8] && !board[b8] && !isSquareAttacked(board, d8, "w") && !isSquareAttacked(board, c8, "w")) {
        moves.push({ from, to: c8, isCastle: "queenside" });
      }
    }
  }

  return moves;
}

export function generateLegalMoves(state: GameState, fromSquare?: Square): Move[] {
  const legal: Move[] = [];

  if (fromSquare !== undefined) {
    const piece = state.board[fromSquare];
    if (!piece || piece.color !== state.turn) {
      return legal;
    }
    for (const move of generatePiecePseudoMoves(state, fromSquare)) {
      if (isLegalAfterMove(state, move)) {
        legal.push(move);
      }
    }
    return legal;
  }

  for (let square = 0; square < 64; square += 1) {
    const piece = state.board[square];
    if (!piece || piece.color !== state.turn) {
      continue;
    }

    for (const move of generatePiecePseudoMoves(state, square)) {
      if (isLegalAfterMove(state, move)) {
        legal.push(move);
      }
    }
  }

  return legal;
}

function boardKey(board: ReadonlyArray<Piece | null>): string {
  let output = "";
  for (let rank = 7; rank >= 0; rank -= 1) {
    let empty = 0;
    for (let file = 0; file < 8; file += 1) {
      const piece = board[toSquare(file, rank)];
      if (!piece) {
        empty += 1;
        continue;
      }
      if (empty > 0) {
        output += String(empty);
        empty = 0;
      }
      output += piece.color === "w" ? piece.type.toUpperCase() : piece.type;
    }
    if (empty > 0) {
      output += String(empty);
    }
    if (rank > 0) {
      output += "/";
    }
  }
  return output;
}

function castlingKey(castling: CastlingRights): string {
  let key = "";
  if (castling.wk) key += "K";
  if (castling.wq) key += "Q";
  if (castling.bk) key += "k";
  if (castling.bq) key += "q";
  return key.length > 0 ? key : "-";
}

export function positionKey(state: Pick<GameState, "board" | "turn" | "castling" | "enPassant">): string {
  return `${boardKey(state.board)} ${state.turn} ${castlingKey(state.castling)} ${state.enPassant === null ? "-" : squareName(state.enPassant)}`;
}

function hasInsufficientMaterial(board: ReadonlyArray<Piece | null>): boolean {
  const white: PieceType[] = [];
  const black: PieceType[] = [];

  for (const piece of board) {
    if (!piece || piece.type === "k") {
      continue;
    }
    if (piece.color === "w") {
      white.push(piece.type);
    } else {
      black.push(piece.type);
    }
  }

  const hasMajor = [...white, ...black].some((type) => type === "q" || type === "r" || type === "p");
  if (hasMajor) {
    return false;
  }

  if (white.length === 0 && black.length === 0) {
    return true;
  }

  if (white.length <= 1 && black.length === 0 && (white[0] === "n" || white[0] === "b" || white[0] === undefined)) {
    return true;
  }

  if (black.length <= 1 && white.length === 0 && (black[0] === "n" || black[0] === "b" || black[0] === undefined)) {
    return true;
  }

  return false;
}

export function evaluateStatus(state: GameState): GameStatus {
  const legalMoves = generateLegalMoves(state);
  const inCheck = isInCheck(state, state.turn);

  if (legalMoves.length === 0) {
    return inCheck ? "checkmate" : "stalemate";
  }

  if (state.halfMoveClock >= 100) {
    return "draw";
  }

  const currentKey = positionKey(state);
  let repetitionCount = 0;
  for (const key of state.historyKeys) {
    if (key === currentKey) {
      repetitionCount += 1;
    }
  }
  if (repetitionCount >= 3) {
    return "draw";
  }

  if (hasInsufficientMaterial(state.board)) {
    return "draw";
  }

  return inCheck ? "check" : "active";
}

function sanLike(state: GameState, move: Move, piece: Piece): string {
  if (move.isCastle === "kingside") {
    return "O-O";
  }
  if (move.isCastle === "queenside") {
    return "O-O-O";
  }

  const targetPiece = state.board[move.to];
  const pieceLetter = piece.type === "p" ? "" : piece.type.toUpperCase();
  const capture = targetPiece || move.isEnPassant ? "x" : "-";
  const origin = piece.type === "p" && capture === "x" ? squareName(move.from)[0] : "";
  const promotion = move.promotion ? `=${move.promotion.toUpperCase()}` : "";
  return `${pieceLetter}${origin}${capture}${squareName(move.to)}${promotion}`;
}

export function applyMove(state: GameState, move: Move): GameState {
  const movingPiece = state.board[move.from];
  if (!movingPiece || movingPiece.color !== state.turn) {
    throw new Error("Illegal move source");
  }

  const legalMoves = generateLegalMoves(state, move.from);
  const exact = legalMoves.find(
    (candidate) =>
      candidate.from === move.from &&
      candidate.to === move.to &&
      candidate.promotion === move.promotion &&
      candidate.isEnPassant === move.isEnPassant &&
      candidate.isCastle === move.isCastle,
  );

  if (!exact) {
    throw new Error("Illegal move");
  }

  const preview = makePreview(state, exact);

  const nextBase: GameState = {
    ...state,
    board: preview.board,
    turn: preview.turn,
    castling: preview.castling,
    enPassant: preview.enPassant,
    halfMoveClock: preview.halfMoveClock,
    fullMoveNumber: preview.fullMoveNumber,
  };

  const key = positionKey(nextBase);
  const nextWithHistory: GameState = {
    ...nextBase,
    historyKeys: [...state.historyKeys, key],
    moveHistory: [
      ...state.moveHistory,
      {
        move: exact,
        sanLike: sanLike(state, exact, movingPiece),
        fenLike: key,
      },
    ],
  };

  return {
    ...nextWithHistory,
    status: evaluateStatus(nextWithHistory),
  };
}
