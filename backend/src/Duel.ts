export default class Duel {
  private values: number[][];
  private p1: string;
  private p2?: string;
  private turn: string;
  private winner?: number;

  constructor(p1: string) {
    this.values = [
      [0, 0, 0],
      [0, 0, 0],
      [0, 0, 0],
    ];
    this.p1 = p1;
    this.turn = this.p1;
  }

  getWinnner() {
    if (this.winner) {
      return this.winner;
    }

    this.winner = handleCheckWin(this.values);
    return this.winner;
  }

  makeMove(player: string, row: number, column: number) {
    if (this.winner) return;
    if (this.values.length <= column) return;
    if (this.values.length <= row) return;

    if (this.turn === player && this.values[row][column] === 0) {
      this.values[row][column] = player === this.p1 ? 1 : 2;
      this.turn = player === this.p1 ? this.p2! : this.p1;
    }
  }

  surrender(player: string) {
    if (player === this.p1) {
      this.winner = 2;
    } else {
      this.winner = 1;
    }

    return this.winner;
  }

  setPlayer2(p2: string) {
    this.p2 = p2;
  }

  isTurn(player: string) {
    return this.turn === player;
  }

  getPlayer1() {
    return this.p1;
  }

  getPlayer2() {
    return this.p2;
  }

  getValues() {
    return this.values;
  }
}

function handleCheckWin(values: number[][]) {
  if (checkPlayerWin(values, true)) {
    return 1;
  }

  if (checkPlayerWin(values, false)) {
    return 2;
  }

  return undefined;
}

function checkPlayerWin(values: number[][], player: boolean) {
  return (
    checkRow(values, 0, player) ||
    checkRow(values, 1, player) ||
    checkRow(values, 2, player) ||
    checkColumn(values, 0, player) ||
    checkColumn(values, 1, player) ||
    checkColumn(values, 2, player) ||
    checkDiagonal(values, player) ||
    checkAntidiagonal(values, player)
  );
}

function checkRow(values: number[][], row: number, player: boolean) {
  const playerValue = player ? 1 : 2;
  return values[row].every((value: number) => value === playerValue);
}

function checkColumn(values: number[][], column: number, player: boolean) {
  const playerValue = player ? 1 : 2;
  return values.every((row: number[]) => row[column] === playerValue);
}

function checkDiagonal(values: number[][], player: boolean) {
  const playerValue = player ? 1 : 2;
  return values.every(
    (row: number[], index: number) => row[index] === playerValue
  );
}

function checkAntidiagonal(values: number[][], player: boolean) {
  const playerValue = player ? 1 : 2;
  return values.every(
    (row: number[], index: number) => row[2 - index] === playerValue
  );
}
