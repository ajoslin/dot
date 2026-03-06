import type { GameState, MoveRecord } from "../chess/types";

interface ControlsOptions {
  readonly onNewGame: () => void;
  readonly onFlipBoard: () => void;
  readonly onBotEloChange: (elo: number) => void;
}

interface ControlsView {
  readonly element: HTMLElement;
  render(input: { readonly state: GameState; readonly botElo: number }): void;
}

function statusText(state: GameState): string {
  if (state.status === "check") {
    return `${state.turn === "w" ? "White" : "Black"} to move (check)`;
  }
  if (state.status === "checkmate") {
    return `${state.turn === "w" ? "Black" : "White"} wins by checkmate`;
  }
  if (state.status === "stalemate") {
    return "Draw by stalemate";
  }
  if (state.status === "draw") {
    return "Draw";
  }
  return `${state.turn === "w" ? "White" : "Black"} to move`;
}

function formatClock(ms: number): string {
  const totalSeconds = Math.ceil(ms / 1000);
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${minutes.toString().padStart(2, "0")}:${seconds.toString().padStart(2, "0")}`;
}

function renderMoves(moveHistory: ReadonlyArray<MoveRecord>): string {
  if (moveHistory.length === 0) {
    return "No moves yet.";
  }

  let output = "";
  for (let i = 0; i < moveHistory.length; i += 2) {
    const white = moveHistory[i];
    const black = moveHistory[i + 1];
    const num = Math.floor(i / 2) + 1;
    output += `${num}. ${white ? white.sanLike : ""}${black ? ` ${black.sanLike}` : ""}\n`;
  }
  return output.trimEnd();
}

export function createControlsView(options: ControlsOptions): ControlsView {
  const root = document.createElement("aside");
  root.className = "panel";

  const title = document.createElement("h1");
  title.textContent = "Board Zero";
  const subtitle = document.createElement("p");
  subtitle.className = "subtitle";
  subtitle.textContent = "Chess.com-inspired board with a 0 to 1,000,000 bot slider.";

  const whiteClock = document.createElement("div");
  whiteClock.className = "clock";
  const blackClock = document.createElement("div");
  blackClock.className = "clock";

  const status = document.createElement("p");
  status.className = "status";

  const sliderWrap = document.createElement("label");
  sliderWrap.className = "slider-wrap";
  sliderWrap.textContent = "Bot ELO";

  const slider = document.createElement("input");
  slider.type = "range";
  slider.min = "0";
  slider.max = "1000000";
  slider.step = "100";
  slider.value = "1200";

  const sliderValue = document.createElement("span");
  sliderValue.className = "slider-value";

  slider.addEventListener("input", () => {
    options.onBotEloChange(Number(slider.value));
  });

  const buttonRow = document.createElement("div");
  buttonRow.className = "buttons";

  const newGameButton = document.createElement("button");
  newGameButton.className = "cta";
  newGameButton.type = "button";
  newGameButton.textContent = "New Game";
  newGameButton.addEventListener("click", options.onNewGame);

  const flipButton = document.createElement("button");
  flipButton.className = "secondary";
  flipButton.type = "button";
  flipButton.textContent = "Flip Board";
  flipButton.addEventListener("click", options.onFlipBoard);

  buttonRow.append(newGameButton, flipButton);

  const moveHeader = document.createElement("h2");
  moveHeader.className = "moves-title";
  moveHeader.textContent = "Move List";

  const moveList = document.createElement("pre");
  moveList.className = "moves";

  sliderWrap.append(slider, sliderValue);
  root.append(title, subtitle, whiteClock, blackClock, status, sliderWrap, buttonRow, moveHeader, moveList);

  return {
    element: root,
    render({ state, botElo }) {
      whiteClock.textContent = `White ${formatClock(state.whiteMs)}`;
      blackClock.textContent = `Black ${formatClock(state.blackMs)}`;
      status.textContent = statusText(state);
      slider.value = String(botElo);
      sliderValue.textContent = botElo.toLocaleString();
      moveList.textContent = renderMoves(state.moveHistory);
    },
  };
}
