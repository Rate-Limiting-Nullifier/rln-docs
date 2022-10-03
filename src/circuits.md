# Circuits

*[zkSNARK](https://vitalik.ca/general/2022/06/15/using_snarks.html) is used in the **RLN** core. Therefore, we need to represent the protocol in R1CS (as we use Groth16). Circom DSL was chosen for this. This section provides an explanation of **RLN** circuits.*

___

**RLN** circuits implement the logic described in [previous topic](./protocol_spec.md).

## Merkle Tree circuit

One of the key component of **RLN** is *Incremental Merkle Tree*.
Let's look at the [implementation](https://github.com/privacy-scaling-explorations/rln/blob/master/circuits/incrementalMerkleTree.circom).

At the beginning of the file we denote that we use second version of Circom and include two helper *zk-gadgets*:
```
pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/mux1.circom";
```

*Poseidon* gadget is just the implementation of *Poseidon* hash function; *mux1* gadget will be described later.

Next, we can see two implemented gadgets:

```
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

These are helper gadgets to make the code more clean. *Poseidon* gadget is implemented with the ability to take a different number of arguments. We use `PoseidonHashT3()` to initialize it like a function with two arguments. And `HashLeftRight` use `PoseidonHashT3` in more "readable" way: it takes two inputs `left` and `right` and outputs the result of calculation.

Next comes the core of Merkle Tree gadget:
```
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

Here we have three inputs: `leaf`, `path_index` and `path_elements`