import { useEffect, useState } from "react";
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Typography,
  Card,
  TextField,
  Stack,
} from "@mui/material";
import RegisterForm from "../components/RegisterForm";
import { User } from "../domain/domain";
import {
  CognitoUserPool,
  CognitoUserAttribute,
  CognitoUser,
  AuthenticationDetails,
  CognitoUserSession,
  CognitoRefreshToken,
} from "amazon-cognito-identity-js";

const poolData = {
  UserPoolId: import.meta.env.VITE_USER_POOL_ID,
  ClientId: import.meta.env.VITE_CLIENT_ID,
};

export const UserPool = new CognitoUserPool(poolData);

interface Props {
  user?: User;
  setUser: (value: User) => void;
}

const LoginDialog = ({ user, setUser }: Props) => {
  const [register, setRegister] = useState(false);
  const [confirm, setConfirm] = useState("");
  const [confirmCode, setConfirmCode] = useState("");
  const [message, setMessage] = useState("");
  const [error, setError] = useState(false);

  useEffect(() => {
    handleLogin();
  }, []);

  const handleLogin = () => {
    const cognitoUser = UserPool.getCurrentUser();
    if (cognitoUser) {
      cognitoUser.getSession((err: any, session: CognitoUserSession) => {
        if (err) {
          console.error(err);
          return;
        }
        const accessToken = session.getAccessToken().getJwtToken();
        const refreshToken = session.getRefreshToken();
        const name = cognitoUser.getUsername();
        setUser({ name, email: "", password: "", token: accessToken });
        handleExpiration(session.getAccessToken().getExpiration(), refreshToken);
      });
    }
  }

  const handleConfirm = () => {
    var userData = {
      Username: confirm,
      Pool: UserPool,
    };

    var cognitoUser = new CognitoUser(userData);
    cognitoUser.confirmRegistration(confirmCode, true, function (err, result) {
      if (err) {
        alert(err.message || JSON.stringify(err));
        return;
      }
      console.log("call result: " + result);
      setConfirm("");
      setRegister(false);
    });
  };

  const handleSubmit = (user: User) => {
    setMessage("");
    setError(false);

    if (register) {
      UserPool.signUp(
        user.name,
        user.password,
        [new CognitoUserAttribute({ Name: "email", Value: user.email })],
        [],
        (err, data) => {
          if (err) {
            setError(true);
            setMessage(err.message);
            return;
          }
          console.log(data);
          setConfirm(user.name);
        }
      );
    } else {
      const cognitoUser = new CognitoUser({
        Username: user.email,
        Pool: UserPool,
      });
      const authDetails = new AuthenticationDetails({
        Username: user.email,
        Password: user.password,
      });
      cognitoUser.authenticateUser(authDetails, {
        onSuccess: (result) => {
          console.log(result);
          handleLogin();
        },
        onFailure: (err) => {
          setError(true);
          setMessage(err.message);
        },
      });
    }
  };

  const handleExpiration = (expiration: number, refreshToken: CognitoRefreshToken) => {
    const cognitoUser = UserPool.getCurrentUser();
      if (cognitoUser) {
        const time = Math.max(expiration * 1000 - Date.now(), 0);
        setTimeout(() => {
          cognitoUser.refreshSession(refreshToken, (err: any, session: CognitoUserSession) => {
            if (err) {
              console.error(err);
              return;
            }
            const accessToken = session.getAccessToken().getJwtToken();
            const refreshToken = session.getRefreshToken();
            const name = cognitoUser.getUsername();
            setUser({ name, email: "", password: "", token: accessToken });
            handleExpiration(session.getAccessToken().getExpiration(), refreshToken);
          });
        }, time);
      }
  }

  return (
    <Dialog open={!user} onClose={() => {}}>
      <Card>
        <Typography color={error ? "error" : undefined}>{message}</Typography>
      </Card>
      <DialogTitle>{register ? "Register" : "Login"}</DialogTitle>
      <DialogContent>
        <RegisterForm
          title={register ? "Register" : "Login"}
          onSubmit={handleSubmit}
          register={register}
        />
        {confirm && (
          <Stack alignItems="center" gap={1}>
            <TextField
              name="Confirmation Code"
              variant="outlined"
              fullWidth
              margin="normal"
              value={confirmCode}
              onChange={(event) => setConfirmCode(event.target.value)}
            />
            <Button variant="contained" onClick={handleConfirm}>
              Confirm
            </Button>
          </Stack>
        )}
      </DialogContent>
      <DialogActions>
        <Button onClick={() => setRegister((prev) => !prev)} variant="outlined">
          {register ? "Login" : "Register"}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default LoginDialog;
