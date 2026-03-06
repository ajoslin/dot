export type Color = "w" | "b";

export type PieceType = "p" | "n" | "b" | "r" | "q" | "k";

export interface Piece {
  readonly color: Color;
  readonly type: PieceType;
}

export type Square = number;

export interface CastlingRights {
  readonly wk: boolean;
  readonly wq: boolean;
  readonly bk: boolean;
  readonly bq: boolean;
}

export interface Move {
  readonly from: Square;
  readonly to: Square;
  readonly promotion?: Exclude<PieceType, "k" | "p">;
  readonly isEnPassant?: boolean;
  readonly isCastle?: "kingside" | "queenside";
}

export interface MoveRecord {
  readonly move: Move;
  readonly sanLike: string;
  readonly fenLike: string;
}

export type GameStatus = "active" | "check" | "checkmate" | "stalemate" | "draw";

export interface GameState {
  readonly board: ReadonlyArray<Piece | null>;
  readonly turn: Color;
  readonly castling: CastlingRights;
  readonly enPassant: Square | null;
  readonly halfMoveClock: number;
  readonly fullMoveNumber: number;
  readonly historyKeys: ReadonlyArray<string>;
  readonly moveHistory: ReadonlyArray<MoveRecord>;
  readonly status: GameStatus;
  readonly whiteMs: number;
  readonly blackMs: number;
}

export interface Coordinate {
  readonly file: number;
  readonly rank: number;
}
