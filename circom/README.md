# Introduction to Circom and snarkjs (backend)

Read the following instruction to run your SNARKs, where a circuit is written in Circom (`sudoku/sudoku.circom` and `isSquareValue/first_circuit.circom` in this repo)

Need to install Circom before. You can read the instruction [here](https://docs.circom.io/getting-started/installation/).

## 1. Compile circuit

Write your first circuit using circom and compile circuit 

```
circom first_circuit.circom --r1cs --wasm --sym
```

## 2. Setup parameters

The following bash needs to input a random text. You can enter anything you want to

```
npx snarkjs groth16 setup first_circuit.r1cs powersOfTau28_hez_final_08.ptau first_circuit_0000.zkey  
npx snarkjs zkey contribute first_circuit_0000.zkey first_circuit_final.zkey --name="My Contribution" -v
```

## 3. Generate witness

Given `inputs.json`, generate witness file as `witness.wtns`

```
node first_circuit_js/generate_witness.js first_circuit_js/first_circuit.wasm inputs.json witness.wtns
```

## 4. Export verification key

```
npx snarkjs zkey export verificationkey first_circuit_final.zkey verification_key.json
```

## 5. Run a Prove system 
```
npx snarkjs groth16 prove first_circuit_final.zkey witness.wtns proof.json public.json
```

## 6. Verify a proof
```
npx snarkjs groth16 verify verification_key.json public.json proof.json
```