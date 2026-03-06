import { fileOf, rankOf, toSquare } from "../chess/coords";
import type { Color, GameState, Move, Piece, Square } from "../chess/types";

interface BoardViewOptions {
  readonly onSquareClick: (square: Square) => void;
}

interface RenderBoardInput {
  readonly state: GameState;
  readonly selected: Square | null;
  readonly legalTargets: ReadonlyArray<Move>;
  readonly orientation: Color;
}

interface BoardView {
  readonly element: HTMLElement;
  render(input: RenderBoardInput): void;
}

const PIECE_SYMBOLS: Record<Color, Record<Piece["type"], string>> = {
  w: {
    k: "♔",
    q: "♕",
    r: "♖",
    b: "♗",
    n: "♘",
    p: "♙",
  },
  b: {
    k: "♚",
    q: "♛",
    r: "♜",
    b: "♝",
    n: "♞",
    p: "♟",
  },
};

function squareColor(square: Square): "light" | "dark" {
  return (fileOf(square) + rankOf(square)) % 2 === 0 ? "dark" : "light";
}

function boardOrder(orientation: Color): Square[] {
  const order: Square[] = [];
  const ranks = orientation === "w" ? [7, 6, 5, 4, 3, 2, 1, 0] : [0, 1, 2, 3, 4, 5, 6, 7];
  const files = orientation === "w" ? [0, 1, 2, 3, 4, 5, 6, 7] : [7, 6, 5, 4, 3, 2, 1, 0];

  for (const rank of ranks) {
    for (const file of files) {
      order.push(toSquare(file, rank));
    }
  }
  return order;
}

export function createBoardView(options: BoardViewOptions): BoardView {
  const boardEl = document.createElement("div");
  boardEl.className = "board";

  const squares = new Map<Square, HTMLButtonElement>();
  for (let square = 0; square < 64; square += 1) {
    const button = document.createElement("button");
    button.className = `square ${squareColor(square)}`;
    button.type = "button";
    button.addEventListener("click", () => {
      options.onSquareClick(square);
    });
    squares.set(square, button);
  }

  function render(input: RenderBoardInput): void {
    boardEl.replaceChildren();
    const legalSet = new Set(input.legalTargets.map((move) => move.to));

    for (const square of boardOrder(input.orientation)) {
      const button = squares.get(square);
      if (!button) {
        continue;
      }

      button.classList.toggle("selected", input.selected === square);
      button.classList.toggle("target", legalSet.has(square));

      const piece = input.state.board[square];
      button.textContent = piece ? PIECE_SYMBOLS[piece.color][piece.type] : "";
      boardEl.append(button);
    }
  }

  return {
    element: boardEl,
    render,
  };
}
