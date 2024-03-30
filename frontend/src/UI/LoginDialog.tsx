import { useState } from "react";
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  Box,
} from "@mui/material";

interface Props {
  user: string;
  setUser: (value: string) => void;
}

const LoginDialog = ({ user, setUser }: Props) => {
  const [value, setValue] = useState("");

  return (
    <Dialog open={!user} onClose={() => {}}>
      <DialogTitle>Login</DialogTitle>
      <DialogContent>
        <Box
          sx={{
            "& > :not(style)": { m: 1, width: "25ch" },
          }}
        >
          <TextField
            label="Username"
            variant="outlined"
            value={value}
            onChange={(e) => setValue(e.target.value)}
          />
        </Box>
      </DialogContent>
      <DialogActions>
        <Button
          onClick={() => setUser(value)}
          variant="contained"
          color="primary"
        >
          Login
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default LoginDialog;
