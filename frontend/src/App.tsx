import { useEffect, useState } from "react";
import LoginDialog, { UserPool } from "./UI/LoginDialog";
import { Toolbar, AppBar, Typography, Button, Stack } from "@mui/material";
import GameGrid from "./components/GameGrid";
import useWebSocket from "react-use-websocket";
import { User } from "./domain/domain";

const WS_URL = import.meta.env.VITE_WS_URL;

function App() {
  const [user, setUser] = useState<User>();
  const [values, setValues] = useState([]);
  const [enemy, setEnemy] = useState("");
  const [turn, setTurn] = useState(false);
  const [playing, setPlaying] = useState(false);

  const { sendJsonMessage, lastJsonMessage } = useWebSocket(WS_URL, {
    share: true,
    shouldReconnect: () => true,
  });

  const handleLogout = () => {
    sendJsonMessage({ type: "surrender", token: user?.token });
    UserPool.getCurrentUser()?.signOut();
    setUser(undefined);
  };

  const handlePlay = () => {
    setPlaying(true);
    sendJsonMessage({ type: "play", token: user?.token });
  };

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
        setPlaying(false);
        break;
    }
  }, [lastJsonMessage]);

  useEffect(() => {
    if (user) {
      sendJsonMessage({ type: "name", data: user.name, token: user.token });
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
            <Button color="inherit" onClick={handleLogout}>
              Logout
            </Button>
          </Toolbar>
        </AppBar>
        {!enemy && <Typography variant="h4">Waiting for enemy...</Typography>}
        {!playing && (
          <Button onClick={handlePlay} variant="contained">
            Play
          </Button>
        )}
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
                sendJsonMessage({
                  type: "move",
                  row,
                  column,
                  token: user?.token,
                })
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
