# Technical side of RLN

*This topic is a less strict version of specifications. If you want more formal description, you can find specs in the [references](./references.md)*

___

As it's been said **RLN** consists of three parts:
* User registration
* User interaction (signalling)
* User removal (slashing) - additional part

Well, let's discuss them.

## User registration
First part of **RLN** is registration. There is nothing special in **RLN** registration; it's almost the same process as in other protocols/apps with anonymous environments: we need to create Merkle Tree and every participant must submit the `commitment` and place it in the Merkle Tree, and after that to interact with the app every participant will create zkProof's, that she is a *member of the tree*.

We'll use *Incremental Merkle Tree*, as it more *GAS-effective*.

The slight difference is that we must enable *secret sharing* scheme (to split the `commitment` into parts). Thus, generation of the `commitment` is different.

Each member randomly generate secret key, that is denoted by `a_0`. Identity commitment `q` is the hash (Poseidon) of the secret key: `q = Poseidon(a_0)`.

RLN would have no sense if there was no punishment for spam, that's why to become a member a user have to provide a certain form of stake.

# Diagram

```mermaid
flowchart TB

    subgraph Generate Secret Key
      random0(Random 32 bytes) --> a_0(Secret Key)
      random1(Random 32 bytes) --> a_0
    end

    subgraph RLN

      subgraph Identity Commitment
        a_0 --> h0(Poseidon Hash)
        h0 --> q(Identity Commitment)
      end

      subgraph Calculate Internal Nullifier
        a_0 --> h1(Poseidon Hash)
        epoch(Epoch) --> h1
        h1 --> a_1
        rln_identifier(RLN Identifier) --> h2(Poseidon Hash)
        a_1 --> h2
        h2 --> nullifier(RLN Internal Nullifier)
      end

      subgraph Merkle Tree
        q --> merkle_tree_inclusion_proof(Merkle Tree Inclusion Proof)
        merkle_tree_inclusion_proof --> root(ZKP of Merkle Tree Root)
      end

      subgraph Shamirs Secret Scheme
        a_0 --> plus(+)
        a_1 --> multiply(*)
        x(Hashed Messaage) --> multiply
        multiply --> plus
        plus --> share_y
      end

        nullifier --> proof(ZKP)
        root --> proof
        share_y --> proof
    end

```
