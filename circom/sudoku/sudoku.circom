pragma circom 2.1.6;

include "circomlib/poseidon.circom";
include "circomlib/circuits/comparators.circom";
// include "https://github.com/0xPARC/circom-secp256k1/blob/master/circuits/bigint.circom";

template CheckValidElement (n, num_of_bits) {
    // Check if each element in witness is valid, i.e. in the range [1, 9]
    signal input solution[n][n];
    signal output isValid;

    signal checkEle[n * n];
    signal prefixSum[n * n];
    component leq[n * n];
    component geq[n * n];

    for (var i = 0; i < n; i++) {
        for (var j = 0; j < n; j++) {
            leq[i * n + j] = LessEqThan(num_of_bits);
            leq[i * n + j].in[0] <== solution[i][j];
            leq[i * n + j].in[1] <== n;

            geq[i * n + j] = GreaterEqThan(num_of_bits);
            geq[i * n + j].in[0] <== solution[i][j];
            geq[i * n + j].in[1] <== 1;

            checkEle[i * n + j] <== leq[i * n + j].out * geq[i * n + j].out;
        }
    }

    prefixSum[0] <== checkEle[0];
    for (var i = 1; i < n * n; i++) {
        prefixSum[i] <== prefixSum[i - 1] + checkEle[i];
    }

    component checkEqual = IsEqual();
    checkEqual.in[0] <== prefixSum[n * n - 1];
    checkEqual.in[1] <== n * n;
    isValid <== checkEqual.out;
}

template checkValidRows(n) {
    signal input solution[n][n];
    signal output isValid;

    component checkEqual[n * n * (n - 1) / 2];
    signal check[n * n * (n - 1) / 2];
    signal prefixSum[n * n * (n - 1) / 2];

    var idx = 0;
    for (var row = 0; row < n; row++) {
        for (var i = 0; i < n; i++) {
            for (var j = i + 1; j < n; j++) {
                checkEqual[idx] = IsEqual();
                checkEqual[idx].in[0] <== solution[row][i];
                checkEqual[idx].in[1] <== solution[row][j];
                check[idx] <== checkEqual[idx].out;
                idx++;
            }
        }
    }

    prefixSum[0] <== check[0];
    for (var i = 1; i < n * n * (n - 1) / 2; i++) {
        prefixSum[i] <== prefixSum[i - 1] + check[i];
    }

    component iseq = IsEqual();
    iseq.in[0] <== prefixSum[n * n * (n - 1) / 2 - 1];
    iseq.in[1] <== 0;
    isValid <== iseq.out;
}

template checkValidCols(n) {
    signal input solution[n][n];
    signal output isValid;

    component checkEqual[n * n * (n - 1) / 2];
    signal check[n * n * (n - 1) / 2];
    signal prefixSum[n * n * (n - 1) / 2];

    var idx = 0;
    for (var col = 0; col < n; col++) {
        for (var i = 0; i < n; i++) {
            for (var j = i + 1; j < n; j++) {
                checkEqual[idx] = IsEqual();
                checkEqual[idx].in[0] <== solution[i][col];
                checkEqual[idx].in[1] <== solution[j][col];
                check[idx] <== checkEqual[idx].out;
                idx++;
            }
        }
    }

    prefixSum[0] <== check[0];
    for (var i = 1; i < n * n * (n - 1) / 2; i++) {
        prefixSum[i] <== prefixSum[i - 1] + check[i];
    }

    component iseq = IsEqual();
    iseq.in[0] <== prefixSum[n * n * (n - 1) / 2 - 1];
    iseq.in[1] <== 0;
    isValid <== iseq.out;
}

template checkValidSubBlock() {
    signal input solution[9][9];
    signal output isValid;

    signal modified_sudoku[9][9];

    var idx = 0;
    for (var block = 0; block < 9; block++) {
        for (var i = (block \ 3) * 3; i < (block \ 3 + 1) * 3; i++) {
            for (var j = (block % 3) * 3; j < (block % 3 + 1) * 3; j++) {
                modified_sudoku[block][idx] <== solution[i][j];
                idx++;
            }
        }
        idx = 0;
    }

    component check = checkValidRows(9);
    check.solution <== modified_sudoku;
    isValid <== check.isValid;
}

template checkExactSudoku(n) {
    signal input table[n][n];
    signal input solution[n][n];
    signal output isValid;

    signal checkEle[n * n];
    signal prefixSum[n * n];
    component iseq[n * n];
    component iszero[n * n];

    for (var i = 0; i < n; i++) {
        for (var j = 0; j < n; j++) {
            iszero[i * n + j] = IsZero();
            iszero[i * n + j].in <== table[i][j];

            iseq[i * n + j] = IsEqual();
            iseq[i * n + j].in[0] <== table[i][j];
            iseq[i * n + j].in[1] <== solution[i][j];

            checkEle[i * n + j] <== iszero[i * n + j].out + iseq[i * n + j].out;
        }
    }

    prefixSum[0] <== checkEle[0];
    for (var i = 1; i < n * n; i++) {
        prefixSum[i] <== prefixSum[i - 1] + checkEle[i];
    }

    component checkEqual = IsEqual();
    checkEqual.in[0] <== prefixSum[n * n - 1];
    checkEqual.in[1] <== n * n;
    isValid <== checkEqual.out;
}

template SudokuProblem() {
    signal input table[9][9];
    signal input solution[9][9];
    signal output isValid;

    signal check[5];
    signal prefixSum[5];

    component check1 = CheckValidElement(9, 5);
    check1.solution <== solution;
    check[0] <== check1.isValid;

    component check2 = checkValidRows(9);
    check2.solution <== solution;
    check[1] <== check2.isValid;

    component check3 = checkValidCols(9);
    check3.solution <== solution;
    check[2] <== check3.isValid;

    component check4 = checkValidSubBlock();
    check4.solution <== solution;
    check[3] <== check4.isValid;

    component check5 = checkExactSudoku(9);
    check5.table <== table;
    check5.solution <== solution;
    check[4] <== check5.isValid;

    prefixSum[0] <== check[0];
    for (var i = 1; i < 5; i++) {
        prefixSum[i] <== check[i] + prefixSum[i - 1];
    }

    component iseq = IsEqual();
    iseq.in[0] <== prefixSum[4];
    iseq.in[1] <== 5;
    log(check[4]);
    isValid <== iseq.out;
}

component main { public [ table ] } = SudokuProblem();

/* INPUT = {
    "table": [
        [6, 8, 0, 0, 0, 5, 4, 3, 1],
        [0, 0, 7, 9, 0, 4, 2, 6, 5],
        [4, 0, 5, 1, 0, 0, 0, 7, 9],
        [2, 5, 8, 4, 0, 0, 0, 9, 3],
        [0, 0, 0, 0, 9, 0, 1, 0, 4],
        [0, 0, 0, 8, 6, 3, 0, 0, 7],
        [7, 1, 3, 0, 0, 0, 9, 4, 0],
        [0, 9, 0, 6, 0, 0, 0, 0, 8],
        [8, 0, 0, 0, 0, 0, 7, 0, 2]
    ],
    "solution": [
        [6, 8, 9, 7, 2, 5, 4, 3, 1],
        [1, 3, 7, 9, 8, 4, 2, 6, 5],
        [4, 2, 5, 1, 3, 6, 8, 7, 9],
        [2, 5, 8, 4, 7, 1, 6, 9, 3],
        [3, 7, 6, 5, 9, 2, 1, 8, 4],
        [9, 4, 1, 8, 6, 3, 5, 2, 7],
        [7, 1, 3, 2, 5, 8, 9, 4, 6],
        [5, 9, 2, 6, 4, 7, 3, 1, 8],
        [8, 6, 4, 3, 1, 9, 7, 5, 2]
    ]
} */