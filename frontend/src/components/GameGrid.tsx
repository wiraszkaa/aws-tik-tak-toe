import { Box, Grid, Stack, Typography } from "@mui/material";
import { useEffect, useState } from "react";

interface Props {
  values: number[][];
  onClick: (row: number, column: number) => void;
}

const GameGrid = ({ values, onClick }: Props) => {
  const [windowSize, setWindowSize] = useState(0);
  const size = values.length;

  useEffect(() => {
    setWindowSize(Math.min(window.innerWidth, window.innerHeight));
  });

  const flattenValues: number[] = [];
  values.forEach((row) => flattenValues.push(...row));

  return (
    <Box width={windowSize * 0.8}>
      <Grid container>
        {flattenValues.map((value, index) => (
          <Grid
            key={index}
            item
            xs={12 / size}
            component={Stack}
            onClick={
              value === 0
                ? () => onClick(Math.floor(index / size), index % size)
                : undefined
            }
            sx={{
              cursor: value === 0 ? "pointer" : undefined,
              border: "1px solid black",
              height: (windowSize * 0.8) / size,
            }}
            justifyContent="center"
            alignItems="center"
          >
            <Typography sx={{ fontSize: windowSize * 0.2 }}>
              {getSymbol(value)}
            </Typography>
          </Grid>
        ))}
      </Grid>
    </Box>
  );
};

const getSymbol = (value: number) => {
  switch (value) {
    case 1:
      return "X";
    case 2:
      return "O";
    default:
      return "";
  }
};

export default GameGrid;
