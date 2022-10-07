# Circuits

*[zkSNARK](https://vitalik.ca/general/2022/06/15/using_snarks.html) is used in the **RLN** core. Therefore, we must represent the protocol in [R1CS](https://www.zeroknowledgeblog.com/index.php/the-pinocchio-protocol/r1cs) (as we use [Groth16](https://www.zeroknowledgeblog.com/index.php/groth16)). [Circom](https://docs.circom.io/) was chosen for this. This section explains **RLN** circuits for the linear polynomial case (one message per epoch). You can find implementation for the general case [here](https://github.com/privacy-scaling-explorations/rln/blob/master/circuits/nrln-base.circom)*

___

**RLN** circuits implement the logic described in [previous topic](./protocol_spec.md).

## Merkle Tree circuit

One of the critical components of **RLN** is the *Incremental Merkle Tree* for the membership tree. Any Merkle tree can be used, but we have chosen the Incremental Merkle Tree for gas efficiency.
Let's look at the [implementation](https://github.com/privacy-scaling-explorations/rln/blob/master/circuits/incrementalMerkleTree.circom).

At the beginning of the file, we denote that we use Circom 2.0 and include two helper *zk-gadgets*:
```circom
pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/mux1.circom";
```

*Poseidon* gadget is just the implementation of the *Poseidon* hash function; the *mux1* gadget will be described later.

Next, we can see two implemented gadgets:

```circom
template PoseidonHashT3() {
    var nInputs = 2;
    signal input inputs[nInputs];
    signal output out;

    component hasher = Poseidon(nInputs);
    for (var i = 0; i < nInputs; i ++) {
        hasher.inputs[i] <== inputs[i];
    }
    out <== hasher.out;
}

template HashLeftRight() {
    signal input left;
    signal input right;

    signal output hash;

    component hasher = PoseidonHashT3();
    left ==> hasher.inputs[0];
    right ==> hasher.inputs[1];

    hash <== hasher.out;
}
```

These are helper gadgets to make the code more clean. *Poseidon* gadget is implemented with the ability to take a different number of arguments. We use `PoseidonHashT3()` to initialize it like a function with two arguments. And `HashLeftRight` use `PoseidonHashT3` in a more "readable" way: it takes two inputs, `left` and `right,` and outputs the result of the calculation.

Next comes the core of the Merkle Tree gadget:
```circom
template MerkleTreeInclusionProof(n_levels) {
    signal input leaf;
    signal input path_index[n_levels];
    signal input path_elements[n_levels][1];
    signal output root;

    component hashers[n_levels];
    component mux[n_levels];

    signal levelHashes[n_levels + 1];
    levelHashes[0] <== leaf;

    ...

    root <== levelHashes[n_levels];
}
```

Here we have three inputs: `leaf,` `path_index,` and `path_elements.` 

`path_index` is the position of the leaf represented in binary. We need the binary representation of the position in the Merkle tree to understand the hashing path from the leaf to the root (more on that *["3. Recursive Incremental Merkle Tree Algorithm, page 4"]()*). 

`path_elements` are sibling leaves that are part of Merkle Proof.

`leaf = Poseidon(identity_secret)`, so it's just *identity commitment*.

There is a Merkle Tree hashing algorithm in the omitted part, no more than that.

## RLN core
RLN circuit is the implementation of **RLN** logic itself (which in turn uses the *Merkle Tree* gadget). You can find the implementation [here](https://github.com/privacy-scaling-explorations/rln/blob/master/circuits/rln-base.circom).

So, let's start with helper gadgets:
```circom
template CalculateIdentityCommitment() {
    signal input identity_secret;
    signal output out;

    component hasher = Poseidon(1);
    hasher.inputs[0] <== identity_secret;

    out <== hasher.out;
}

template CalculateA1() {
    signal input a_0;
    signal input epoch;

    signal output out;

    component hasher = Poseidon(2);
    hasher.inputs[0] <== a_0;
    hasher.inputs[1] <== epoch;

    out <== hasher.out;
}

template CalculateNullifier() {
    signal input a_1;
    signal input rln_identifier;
    signal output out;

    component hasher = Poseidon(2);
    hasher.inputs[0] <== a_1;
    hasher.inputs[1] <== rln_identifier;

    out <== hasher.out;
}
```

It's easy to understand these samples: `CalculateIdentityCommitment()` is used to calculate the identity commitment. It takes secret and outputs the commitment. `CalculateA1()` and `CalculateNullifier()` are used to calculate `a_1` and `nullifier` (internal nullifier); they are implemented as it's described in [previous topic](./protocol_spec.md).

Now, let's look at the core logic of the **RLN** circuit. 
```circom
...

    signal input identity_secret;
    signal input path_elements[n_levels][LEAVES_PER_PATH_LEVEL];
    signal input identity_path_index[n_levels];

    signal input x;
    signal input epoch;
    signal input rln_identifier;

    signal output y;
    signal output root;
    signal output nullifier;

...
```

So, here we have many inputs. Private inputs are: `identity_secret` (basically `a_0` from the polynomial), `path_elements[][]`, `identity_path_index[]`. Public inputs are: `x` (actually just the hash of a signal), `epoch,` `rln_identifier.` Outputs are: `y' (share of the secret), `root` of a Merkle Tree, and `nullifier.`

**RLN** circuit consists of two checks:
* Membership in Merkle Tree
* Correctness of secret share

### Membership in Merkle Tree
To check membership in a Merkle Tree, we can simply use the previously described Merkle Tree gadget:
```circom
...

    component identity_commitment = CalculateIdentityCommitment();
    identity_commitment.identity_secret <== identity_secret;

    var i;
    var j;
    component inclusionProof = MerkleTreeInclusionProof(n_levels);
    inclusionProof.leaf <== identity_commitment.out;

    for (i = 0; i < n_levels; i++) {
      for (j = 0; j < LEAVES_PER_PATH_LEVEL; j++) {
        inclusionProof.path_elements[i][j] <== path_elements[i][j];
      }
      inclusionProof.path_index[i] <== identity_path_index[i];
    }

...
```
Here we are calculating the `identity_commitment` and passing it along with sibling leaves and binary representation of the position to a Merkle Tree gadget. It gives us the calculated root as an output, and we can put the constraint on that:

```circom
root <== inclusionProof.root;
```

### Correctness of secret share
As we use linear polynomial we need to check that `y = a_1 * x + a_0` (`a_0` is identity secret). For that, we need these constraints:
```circom
...

    component a_1 = CalculateA1();
    a_1.a_0 <== identity_secret;
    a_1.epoch <== epoch;

    y <== identity_secret + a_1.out * x;

...
```

To calculate and reveal the `nullifier`:
```circom
...

    component calculateNullifier = CalculateNullifier();
    calculateNullifier.a_1 <== a_1.out;
    calculateNullifier.rln_identifier <== rln_identifier;

    nullifier <== calculateNullifier.out;

...
```

## Main runner of the circuits
Now the Circuits can be used as gadgets. If we want to use it in our app, we need to initialize it and have a *main* - starting point function. It can be found [here](https://github.com/privacy-scaling-explorations/rln/blob/master/circuits/rln.circom).

The implementation is super basic:
```circom
pragma circom 2.0.0;

include "./rln-base.circom";

component main {public [x, epoch, rln_identifier ]} = RLN(15);
```
That's the whole **RLN** Circom Circuit :) Here we just need to list all public inputs (`x,` `epoch,` `rln_identifier`; the rest of the inputs are private). Also, we set the depth of the Merkle Tree = 15 (max of 32768 members).
