# Formal spec of circom-rln

- [Utils](#utils-templates)
    - [MerkleTreeInclusionProof](#merkletreeinclusionproof)
    - [RangeCheck](#rangecheck)
- [RLN](#rln)
- [Withdrawal](#withdrawal)

___

## Utils

[utils.circom](https://github.com/Rate-Limiting-Nullifier/circom-rln/blob/main/circuits/utils.circom) is a set of templates/gadgets that the RLN circuit uses.

These are: 
* MerkleTreeInclusionProof - Merkle tree inclusion check, used like set membership check;
* RangeCheck - used for range check.

Their description is given below.

### MerkleTreeInclusionProof

**MerkleTreeInclusionProof(DEPTH)** template used for verification of inclusion in full binary incremental merkle tree. The implementation is a fork of https://github.com/privacy-scaling-explorations/incrementalquintree, and changed to *binary* tree and refactored to *Circom 2.1.0*.

**Parameters**:
* **DEPTH** - depth of the Merkle Tree.

**Inputs**:
* \\(leaf\\) - \\(Poseidon(elem)\\), where \\(elem\\) is the element that's checked for inclusion;
* \\(pathIndex[DEPTH]\\) - array of length = \\(DEPTH\\), consists of \\(0 | 1\\), represents Merkle proof path. 
Basically, it says how to calculate Poseidon hash, e.g. for two inputs \\(input1\\), \\(input2\\), if the \\(pathIndex[i] = 0\\) it shoud be calculated as \\(Poseidon(input1, input2)\\), otherwise \\(Poseidon(input2, input1)\\);
* \\(pathElements[DEPTH]\\) - array of length = \\(DEPTH\\), represents elements of the Merkle proof.

**Outputs**:
* \\(root\\) - Root of the merkle tree.

**Templates used**:
* [mux1.circom](https://github.com/iden3/circomlib/blob/master/circuits/mux1.circom) from circomlib;
* [poseidon.circom](https://github.com/iden3/circomlib/blob/master/circuits/poseidon.circom) from circomlib.

### RangeCheck

**RangeCheck(LIMIT_BIT_SIZE)** template used for range check, e.g. \\(x \le y \le z\\).

**Parameters**:
* \\(LIMIT\\_BIT\\_SIZE\\) - maximum bit size of numbers that are used in range check, f.e. for the \\(LIMIT\\_BIT\\_SIZE = 16\\), input numbers allowed to be in the interval \\([0, 65536)\\).

**Inputs**:
* \\(messageId\\) - denotes counter value, that'll be described further;
* \\(limit\\) - maximum value.

**Templates used**:
* [LessThan(n)](https://github.com/iden3/circomlib/blob/master/circuits/comparators.circom#L105) from circomlib;
* [Num2Bits(n)](https://github.com/iden3/circomlib/blob/master/circuits/bitify.circom#L25) from circomlib.

**Logic/Constraints**:
Checked that \\(0 \le messageId < limit\\). 

___

## RLN

[rln.circom](https://github.com/Rate-Limiting-Nullifier/circom-rln/blob/main/circuits/rln.circom) is a template that's used for RLN protocol. 

**Parameters**:
* \\(DEPTH\\) - depth of a Merkle Tree. Described [here](#merkletreeinclusionproof);
* \\(LIMIT\\_BIT\\_SIZE\\) - maximum bit size of numbers that are used in range check. Described [here](#rangecheck).

**Private inputs**:
* \\(identitySecret\\) - randomly generated number in \\(\\mathbb{F_p}\\), used as a private key;
* \\(userMessageLimit\\) - message limit of the user;
* \\(messageId\\) - id of the message;
* \\(pathElements[DEPTH]\\) - pathElements[DEPTH], described [here](#merkletreeinclusionproof);
* \\(identityPathIndex[DEPTH]\\) - pathIndex[DEPTH], described [here](#merkletreeinclusionproof).

**Public inputs**:
* \\(x\\) - \\(Hash(signal)\\), where \\(signal\\) is for example message, that was sent by user;
* \\(externalNullifier\\) - \\(Hash(epoch, rln_identifier)\\).

**Outputs**:
* \\(y\\) - calculated first-degree linear polynomial \\((y = kx + b)\\);
* \\(root\\) - root of the Merkle Tree;
* \\(nullifier\\) - internal nullifier/pseudonym of the user in anonyomus environment.

**Logic/Constraints**:
1. Merkle tree membership check:
    * \\(identityCommitment = Poseidon(identitySecret)\\) calculation;
    * \\(rateCommitment = Poseidon(identityCommitment, userMessageLimit)\\) calculation;
    * [Merkle tree inclusion check](#merkletreeinclusionproof) for the \\(rateCommitment\\).
2. Range check:
    * [Range check](#rangecheck) that \\(0 \le messageId < limit\\).
3. Polynomial share calculation:
    * \\(a_1 = Poseidon(identitySecret, externalNullifier, messageId)\\);
    * \\(y = identitySecret + a_1 * x\\).
4. Output of calculated \\(root\\), \\(y = share\\) and \\(nullifier = Poseidon(a_1)\\) values.

___

### Withdrawal

[withdraw.circom](https://github.com/Rate-Limiting-Nullifier/circom-rln/blob/main/circuits/withdraw.circom) is a circuit that's used for the withdrawal/slashing and is needed to prevent frontrun while withdrawing the stake from the smart-contract/registry. 

**Private inputs**:
* \\(identitySecret\\) - randomly generated number in \\(\\mathbb{F_p}\\), used as private key.

**Public inputs**:
* \\(address\\) - \\(\\mathbb{F_p}\\) scalar field element; denotes ETH address that'll receive stake. 

**Outputs**:
* \\(identityCommitment = Poseidon(identitySecret)\\).