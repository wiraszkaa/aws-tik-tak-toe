import { randomUUID } from "crypto";
import { createServer } from "http";
import { WebSocketServer, WebSocket } from "ws";
import dotenv from "dotenv";
import Duel from "./Duel";

dotenv.config();

const port = process.env.PORT || "4000";

const app = createServer();
const wsServer = new WebSocketServer({ server: app });
const clients = new Map<string, { socket: WebSocket; name?: string }>();
let duels: Duel[] = [];

function notifyPlayers(duel: Duel) {
  const p1 = clients.get(duel.getPlayer1());
  const p2 = clients.get(duel.getPlayer2()!);

  if (!p1 || !p2) {
    return;
  }

  const id1 = duel.getPlayer1();
  const id2 = duel.getPlayer2();

  p1.socket.send(JSON.stringify({ type: "enemy", data: p2.name || id2 }));
  p2.socket.send(JSON.stringify({ type: "enemy", data: p1.name || id1 }));

  p1.socket.send(JSON.stringify({ type: "turn", data: duel.isTurn(id1) }));
  p1.socket.send(JSON.stringify({ type: "move", data: duel.getValues() }));

  p2.socket.send(JSON.stringify({ type: "turn", data: duel.isTurn(id2!) }));
  p2.socket.send(JSON.stringify({ type: "move", data: duel.getValues() }));
}

function notifyWin(duel: Duel, winner: boolean) {
  const p1 = clients.get(duel.getPlayer1());
  const p2 = clients.get(duel.getPlayer2()!);

  if (p1) {
    p1.socket.send(JSON.stringify({ type: "win", data: winner }));
  }
  if (p2) {
    p2.socket.send(JSON.stringify({ type: "win", data: !winner }));
  }
}

wsServer.on("connection", (socket: WebSocket) => {
  const userId = randomUUID();
  console.log(`Client ${userId} connected`);
  clients.set(userId, { socket });

  let duel = duels.find((duel) => !duel.getPlayer2());
  if (duel) {
    duel.setPlayer2(userId);
    notifyPlayers(duel);
    console.log("Assigning to duel");
  } else {
    console.log("Creating duel");
    duel = new Duel(userId);
    duels.push(duel);
  }

  socket
    .on("close", () => {
      console.log(`Client ${userId} disconnected`);
      clients.delete(userId);

      const duel = duels.find(
        (duel) => duel.getPlayer1() === userId || duel.getPlayer2() === userId
      );
      if (!duel) return;

      const winner = duel.surrender(userId);
      notifyWin(duel, winner === 1);
    })
    .on("message", (message) => {
      const data = JSON.parse(message.toString());
      console.log("Data received:\n", data);

      const duel = duels.find(
        (duel) => duel.getPlayer1() === userId || duel.getPlayer2() === userId
      );

      if (data.type === "move" && duel) {
        duel.makeMove(userId, data.row, data.column);
        notifyPlayers(duel);
        const winner = duel.getWinnner();
        if (winner) {
          notifyWin(duel, winner === 1);
          duels = duels.filter((currDuel) => currDuel !== duel);
        }
      } else if (data.type === "name") {
        clients.get(userId)!.name = data.data;
        if (duel) notifyPlayers(duel);
      }
    });
});

const server = app.listen(port, () => {
  console.log(`WebSocket server started on: ${port}`);
});

process.on("SIGINT", () => {
  console.log("Shutting down server");
  server.close();
  wsServer.close();
  process.exit(0);
});
