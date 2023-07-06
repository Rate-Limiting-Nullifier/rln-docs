# What is Rate-Limiting Nullifier?


**RLN** is a zero-knowledge gadget that enables spam prevention in anonymous environments.

The anonymity property opens up the possibility for spam, which could seriously degrade the user experience and the overall functioning of the application. For example, imagine a chat application where users are anonymous. Now, everyone can write an unlimited number of spam messages, but we don't have the ability to kick this member because the spammer is anonymous. 

**RLN** helps us identify and "kick" the spammer.

Moreover, **RLN** can be useful not only to prevent spam attacks but, in general, to limit users (in anonymous environments) in the number of actions (f.e. to vote or to make a bid).

## How it works

The **RLN** construct's functionality consists of three parts These parts should be integrated by the upstream applications, that require anonymity and spam protection. The applications can be centralized or decentralized. For decentralized applications, each user maintains separate storage and compute resources for the application. 

The three parts are:
* registration;
* interaction;
* withdrawal (or slashing);

### Registration

Before registering to the application, the user needs to generate a secret key and derive an identity commitment from the secret key using the Poseidon hash function: 

\\[identityCommitment = Poseidon(secretKey)\\]

The user registers to the application by providing a form of stake and their identity commitment, which is derived from the secret key. The application maintains a Merkle tree data structure (in the latest iteration of **RLN**, we use an Incremental Merkle Tree algorithm for gas efficiency, but the Merkle tree does not have to be on-chain), which stores the identity commitments of the registered users. Upon successful registration, the user's identity commitment is stored in a leaf of the Merkle tree, and an index is given to them, representing their position in the tree.

### Interaction
For each interaction that the user wants to make with the application, the user must generate a zero-knowledge proof ensuring that their identity commitment is part of the membership Merkle tree.

There are a number of use-cases for **RLN**, such as voting applications (1 vote per election), chat (one message per second), and rate-limiting cache access (CDN denial of service protection). The verifier can be a server for centralized applications or the other users for decentralized applications.

The general anti-spam rule is usually in the form of: 
`Users must not make more than X interactions per epoch.`

The epoch can be translated as a time interval of `Y` units of time unit `Z`. For simplicity's sake, let's transform the rule into: `Users must not send more than one message per second.

We can implement this using *Shamir's Secret Sharing* scheme ([*read more*](./sss.md)), which allows you to split a secret (f.e. to `n` parts) and recover it when any `m` of `n` parts `(m <= n)` are presented.

Thus, users have to split their `secret_key` into `n` parts, and for every interaction, they have to reveal the new part of the `secret_key.` So, in addition to proving the membership in the *Merkle Tree*, users have to prove that the revealed part is truly the part of their `secret_key.`

If they make more interactions than allowed per epoch, their secret key can be fully reconstructed.

### Withdrawal (or slashing)
The final property of the **RLN** mechanism is that it allows for the users to be removed from the membership tree by anyone that knows their secret key. The membership tree contains the identity commitments of all registered users. Users' identity commitment is derived from their secret key, and the secret key of the user is only revealed in a spam event (except for the scenarios where the original users want to remove themselves, which they can always do because they know their secret key). When an economic stake is present, the **RLN** mechanism can be implemented in a way that the spammer's stake is sent to the first user that correctly reports the spammer by providing the reconstructed secret key of the spammer as proof.
