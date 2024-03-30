import { useEffect, useState } from "react";
import LoginDialog from "./UI/LoginDialog";
import { Toolbar, AppBar, Typography, Button, Stack } from "@mui/material";
import GameGrid from "./components/GameGrid";
import useWebSocket from "react-use-websocket";

const WS_URL = import.meta.env.VITE_WS_URL;

function App() {
  const [user, setUser] = useState("");
  const [values, setValues] = useState([]);
  const [enemy, setEnemy] = useState("");
  const [turn, setTurn] = useState(false);
  const { sendJsonMessage, lastJsonMessage } = useWebSocket(WS_URL, {
    share: true,
    shouldReconnect: () => true,
  });

  useEffect(() => {
    const message: any = lastJsonMessage;
    switch (message?.type) {
      case "enemy":
        setEnemy(message.data);
        break;
      case "turn":
        setTurn(message.data);
        break;
      case "move":
        setValues(message.data);
        break;
      case "win":
        alert(message.data ? "You win!" : "You lose!");
        setEnemy("");
        break;
    }
  }, [lastJsonMessage]);

  useEffect(() => {
    if (user) {
      sendJsonMessage({ type: "name", data: user });
    }
  }, [user]);

  return (
    <>
      <Stack
        sx={{ flexGrow: 1 }}
        width="100vw"
        height="100vh"
        alignItems="center"
      >
        <AppBar position="static">
          <Toolbar>
            <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
              Tik Tak Toe
            </Typography>
            <Button color="inherit" onClick={() => setUser("")}>
              Change Name
            </Button>
          </Toolbar>
        </AppBar>
        {!enemy && <Typography variant="h4">Waiting for enemy...</Typography>}
        {enemy && (
          <Stack justifyContent="center" alignItems="center" pt={5}>
            <Typography>
              <b>Enemy: {enemy}</b>
            </Typography>
            <Typography color={turn ? "green" : "red"}>
              Turn: {turn ? "Your" : "Enemy"}
            </Typography>
            <GameGrid
              values={values}
              onClick={(row, column) =>
                sendJsonMessage({ type: "move", row, column })
              }
            />
          </Stack>
        )}
      </Stack>
      <LoginDialog user={user} setUser={setUser} />
    </>
  );
}

export default App;
