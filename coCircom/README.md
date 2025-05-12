# Introduction to coCircom and snarkjs

## 1. SNARKs vs coSNARKs

- SNARKs include two parties P(x, w) and V(x), where x is a statement, and w is a witness. A witness w is secret and hold only by Prover.

    &rarr; In practice, a set of parties need to prove statement where secret witness is distributed or shared among them.

- Colabborative SNARKs (coSNARKs) generate a proof over the witnesses of multiple, mutually distrusting parties as $\vec{w} = (w_1, ..., w_N)$ distributed among N parties.

&rarr; A naive approach: present a zk-SNARKs proof generator as an arithmetic circuit, then (many) provers use MPC to jointly generate the desired proof without revealing anything else about their secret inputs (i.e. their witnesses).

## 2. How to run coCircom

(Reference: https://docs.taceo.io/docs/getting-started/quick-start-co-circom/)

**Prerequisites:** Following this [link](https://github.com/TaceoLabs/co-snarks/tree/main) (Section Installation)

**Problem:** Alice (whose value is a) and Bob (whose value is b), want to compute $H(a||b)$ where $H$ is a Poseidon hash function, satisfy the following requirements:
- Do not reveal each party's input
- Produce ZK proof to prove their computation is correct

**Solution:**
- Alice and Bob secret shared thier input value $a$ and $b$ into $n$ share values $(a_i, b_i)$ (associated with $n$ parties in MPC).
- $P_i$ has $(a_i, b_i)$ &rarr; Apply MPC &rarr; Each party $P_i$ obtains $w_i$ &rarr; Compute $H(a||b) = \sum w_i$.
- Compute a proof for their correctness computation.

### 2.1. Generate a circuit using circom

Write a Circom file (e.g. `circuits/multiplier2.circom`) to define our desired circuit

### 2.2. Compile the circuit

```
circom circuits/multiplication/multiplier2.circom --r1cs
```

### 2.3. Generate key

Generate prover's key as a file `multiplier2.zkey`

```
npx snarkjs groth16 setup multiplier2.r1cs powersOfTau28_hez_final_08.ptau multiplier2_0000.zkey  
npx snarkjs zkey contribute multiplier2_0000.zkey multiplier2.zkey --name="My Contribution" -v
```

Generate verifier's key as a file `verification_key.json`

```
npx snarkjs zkey export verificationkey multiplier2.zkey verification_key.json
```

### 2.4. Prepare the inputs

Prepare an input file `inputs.json` to define value in a circuit

### 2.5. Split the inputs

(Assume our MPC has 3 parties)

```
mkdir out
co-circom split-input --circuit multiplier2.circom --input input.json --protocol REP3 --curve BN254 --out-dir out/
```

### 2.6. Witness Extension

Configure network for every party (example only for party 0, other parties do the same). Generate `configs/party1.toml` as follow

```
[network]
my_id = 0
bind_addr = "0.0.0.0:10000"
key_path = "data/key0.der"
[[network.parties]]
id = 0
dns_name = "localhost:10000"
cert_path = "data/cert0.der"
[[network.parties]]
id = 1
dns_name = "localhost:10001"
cert_path = "data/cert1.der"
[[network.parties]]
id = 2
dns_name = "localhost:10002"
cert_path = "data/cert2.der"
```

Now, extract witness for each party by running the following command

```
P0 $ co-circom generate-witness --input out/inputs.json.0.shared --circuit circuits/multiplication/multiplier2.circom --protocol REP3 --curve BN254 --config configs/party1.toml --out out/witness.wtns.0.shared

P1 $ co-circom generate-witness --input out/inputs.json.1.shared --circuit circuits/multiplication/multiplier2.circom --protocol REP3 --curve BN254 --config configs/party2.toml --out out/witness.wtns.1.shared

P2 $ co-circom generate-witness --input out/inputs.json.2.shared --circuit circuits/multiplication/multiplier2.circom --protocol REP3 --curve BN254 --config configs/party3.toml --out out/witness.wtns.2.shared
```

### 2.7. Generate proof

Execute (parallel for each party) the following command

```
P0 $ co-circom generate-proof groth16 --witness out/witness.wtns.0.shared --zkey multiplier2.zkey --protocol REP3 --curve BN254 --config configs/party1.toml --out proof.0.json --public-input public_input.json

P1 $ co-circom generate-proof groth16 --witness out/witness.wtns.1.shared --zkey multiplier2.zkey --protocol REP3 --curve BN254 --config configs/party2.toml --out proof.1.json --public-input public_input.json

P2 $ co-circom generate-proof groth16 --witness out/witness.wtns.2.shared --zkey multiplier2.zkey --protocol REP3 --curve BN254 --config configs/party3.toml --out proof.2.json --public-input public_input.json
```

(`public_input.json` contains all public information to verify the proof)

### 2.8. Verify proof

```
co-circom verify groth16 --proof proof.0.json --vk verification_key.json --public-input public_input.json --curve BN254
snarkjs groth16 verify verification_key.json public_input.json proof.0.json
```