import "./styles.css";
import { ChessController } from "./chess/rules";
import { createBoardView } from "./ui/board";
import { createControlsView } from "./ui/controls";

const app = document.querySelector<HTMLDivElement>("#app");

if (!app) {
  throw new Error("Missing #app root element");
}

const controller = new ChessController();

const boardView = createBoardView({
  onSquareClick: (square) => {
    controller.clickSquare(square);
  },
});

const controlsView = createControlsView({
  onNewGame: () => controller.reset(),
  onFlipBoard: () => controller.flipBoard(),
  onBotEloChange: (elo) => controller.setBotElo(elo),
});

const layout = document.createElement("main");
layout.className = "layout";
layout.append(boardView.element, controlsView.element);
app.append(layout);

controller.subscribe((snapshot) => {
  boardView.render({
    state: snapshot.state,
    selected: snapshot.selected,
    legalTargets: snapshot.legalTargets,
    orientation: snapshot.orientation,
  });
  controlsView.render({
    state: snapshot.state,
    botElo: snapshot.botElo,
  });
});

function frame(now: number): void {
  controller.tick(now);
  window.requestAnimationFrame(frame);
}

window.requestAnimationFrame(frame);
