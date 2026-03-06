import { opposite } from "./coords";
import { applyMove, generateLegalMoves } from "./movegen";
import { createInitialState } from "./state";
import type { Color, GameState, Move, PieceType, Square } from "./types";

interface Snapshot {
  readonly state: GameState;
  readonly orientation: Color;
  readonly selected: Square | null;
  readonly legalTargets: ReadonlyArray<Move>;
  readonly botElo: number;
}

type Listener = (snapshot: Snapshot) => void;

const PIECE_VALUE: Record<PieceType, number> = {
  p: 100,
  n: 320,
  b: 330,
  r: 500,
  q: 900,
  k: 0,
};

function depthForElo(elo: number): number {
  if (elo < 400) return 0;
  if (elo < 2_500) return 1;
  if (elo < 25_000) return 2;
  if (elo < 250_000) return 3;
  return 4;
}

function evaluateMaterial(state: GameState, perspective: Color): number {
  let score = 0;
  for (const piece of state.board) {
    if (!piece) continue;
    const value = PIECE_VALUE[piece.type];
    score += piece.color === perspective ? value : -value;
  }
  return score;
}

function scoreState(state: GameState, perspective: Color): number {
  if (state.status === "checkmate") {
    return state.turn === perspective ? -100_000 : 100_000;
  }
  if (state.status === "draw" || state.status === "stalemate") {
    return 0;
  }
  const mobility = generateLegalMoves(state).length;
  const signedMobility = state.turn === perspective ? mobility : -mobility;
  return evaluateMaterial(state, perspective) + signedMobility;
}

function minimax(
  state: GameState,
  depth: number,
  alpha: number,
  beta: number,
  perspective: Color,
): { readonly score: number; readonly move: Move | null } {
  const legalMoves = generateLegalMoves(state);
  if (depth === 0 || legalMoves.length === 0 || state.status === "draw" || state.status === "checkmate" || state.status === "stalemate") {
    return {
      score: scoreState(state, perspective),
      move: null,
    };
  }

  const maximizing = state.turn === perspective;
  let bestMove: Move | null = null;

  if (maximizing) {
    let bestScore = Number.NEGATIVE_INFINITY;
    let nextAlpha = alpha;
    for (const move of legalMoves) {
      const child = applyMove(state, move);
      const result = minimax(child, depth - 1, nextAlpha, beta, perspective);
      if (result.score > bestScore) {
        bestScore = result.score;
        bestMove = move;
      }
      nextAlpha = Math.max(nextAlpha, bestScore);
      if (beta <= nextAlpha) break;
    }
    return { score: bestScore, move: bestMove };
  }

  let bestScore = Number.POSITIVE_INFINITY;
  let nextBeta = beta;
  for (const move of legalMoves) {
    const child = applyMove(state, move);
    const result = minimax(child, depth - 1, alpha, nextBeta, perspective);
    if (result.score < bestScore) {
      bestScore = result.score;
      bestMove = move;
    }
    nextBeta = Math.min(nextBeta, bestScore);
    if (nextBeta <= alpha) break;
  }
  return { score: bestScore, move: bestMove };
}

function chooseBotMove(state: GameState, elo: number): Move | null {
  const legalMoves = generateLegalMoves(state);
  if (legalMoves.length === 0) {
    return null;
  }

  const depth = depthForElo(elo);
  if (depth === 0) {
    return legalMoves[Math.floor(Math.random() * legalMoves.length)] ?? null;
  }

  const result = minimax(state, depth, Number.NEGATIVE_INFINITY, Number.POSITIVE_INFINITY, state.turn);
  return result.move;
}

export class ChessController {
  private state: GameState = createInitialState();

  private orientation: Color = "w";

  private selected: Square | null = null;

  private legalTargets: ReadonlyArray<Move> = [];

  private botElo = 1_200;

  private readonly listeners = new Set<Listener>();

  private readonly humanColor: Color = "w";

  private botTimer: number | null = null;

  private lastTick = performance.now();

  subscribe(listener: Listener): () => void {
    this.listeners.add(listener);
    listener(this.snapshot());
    return () => {
      this.listeners.delete(listener);
    };
  }

  private snapshot(): Snapshot {
    return {
      state: this.state,
      orientation: this.orientation,
      selected: this.selected,
      legalTargets: this.legalTargets,
      botElo: this.botElo,
    };
  }

  private emit(): void {
    const shot = this.snapshot();
    for (const listener of this.listeners) {
      listener(shot);
    }
  }

  reset(): void {
    this.clearBotTimer();
    this.state = createInitialState();
    this.selected = null;
    this.legalTargets = [];
    this.lastTick = performance.now();
    this.emit();
    this.maybePlayBot();
  }

  setBotElo(value: number): void {
    this.botElo = Math.max(0, Math.min(1_000_000, Math.round(value)));
    this.emit();
    this.maybePlayBot();
  }

  flipBoard(): void {
    this.orientation = opposite(this.orientation);
    this.emit();
  }

  clickSquare(square: Square): void {
    if (this.isGameOver() || this.state.turn !== this.humanColor) {
      return;
    }

    const piece = this.state.board[square];

    if (this.selected !== null) {
      const matching = this.legalTargets.filter((move) => move.to === square);
      if (matching.length > 0) {
        const queenPromo = matching.find((move) => move.promotion === "q");
        const move = queenPromo ?? matching[0];
        if (move) {
          this.play(move);
          return;
        }
      }
    }

    if (piece && piece.color === this.humanColor && piece.color === this.state.turn) {
      this.selected = square;
      this.legalTargets = generateLegalMoves(this.state, square);
    } else {
      this.selected = null;
      this.legalTargets = [];
    }

    this.emit();
  }

  tick(now: number): void {
    const elapsed = now - this.lastTick;
    this.lastTick = now;
    if (elapsed <= 0 || this.isGameOver()) {
      return;
    }

    if (this.state.turn === "w") {
      const whiteMs = Math.max(0, this.state.whiteMs - elapsed);
      const status = whiteMs === 0 ? "checkmate" : this.state.status;
      this.state = {
        ...this.state,
        whiteMs,
        status,
      };
    } else {
      const blackMs = Math.max(0, this.state.blackMs - elapsed);
      const status = blackMs === 0 ? "checkmate" : this.state.status;
      this.state = {
        ...this.state,
        blackMs,
        status,
      };
    }

    this.emit();
  }

  private clearBotTimer(): void {
    if (this.botTimer !== null) {
      window.clearTimeout(this.botTimer);
      this.botTimer = null;
    }
  }

  private maybePlayBot(): void {
    this.clearBotTimer();
    if (this.isGameOver()) {
      return;
    }

    const botColor = opposite(this.humanColor);
    if (this.state.turn !== botColor) {
      return;
    }

    this.botTimer = window.setTimeout(() => {
      const move = chooseBotMove(this.state, this.botElo);
      this.botTimer = null;
      if (!move) {
        return;
      }
      this.play(move);
    }, 140);
  }

  private play(move: Move): void {
    this.state = applyMove(this.state, move);
    this.selected = null;
    this.legalTargets = [];
    this.emit();
    this.maybePlayBot();
  }

  private isGameOver(): boolean {
    return this.state.status === "checkmate" || this.state.status === "stalemate" || this.state.status === "draw";
  }
}
