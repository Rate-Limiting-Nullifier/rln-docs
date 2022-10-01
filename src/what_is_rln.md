# What is Rate-Limiting Nullifier?

*This topic is a part of [complete overview](https://medium.com/privacy-scaling-explorations/rate-limiting-nullifier-a-spam-protection-mechanism-for-anonymous-environments-bbe4006a57d) by Blagoj*.

___

**RLN** is a construct based on zero-knowledge proofs that enables spam prevention mechanism for decentralized, anonymous environments. In anonymous environments, the identity of the entities is unknown.

The anonymity property opens up the possibility for spam attack and sybil attack vectors for certain applications, which could seriously degrade the user experience and the overall functioning of the application. For example, imagine a chat application, where users are anonymous. Now, everyone can write unlimited number of spam messages, while we don't have ability to kick this member, because the spammer is anonymous. 

**RLN** helps us identify and "kick" the spammer.

Moreover RLN can be useful not only to prevent a spam attacks, but in general, to limit users (in anonymous environments) in the number of actions (f.e. to vote or to make a bid).

## How it works

The RLN construct’s functionality consists of three parts, which when integrated together provide spam and sybil attack protection. These parts should be integrated by the upstream applications which require anonymity and spam protection. The applications can be centralized or decentralized. For decentralized applications, each user maintains a separate storage and compute resources for the application. The three parts are:
* User registration
* User interaction
* User removal (slashing)

### User registration

Before registering to the application the user needs to generate a secret key and derive an identity commitment from the secret key using the `Poseidon` hash function `identityCommitment = posseidonHash(secretKey)`.

The user registers to the application by providing a form of stake and their identity commitment, which is derived from the secret key. The application maintains a Merkle tree data structure (in the latest iteration of the RLN construct we use the Incremental Merkle Tree algorithm), which stores the identity commitments of the registered users. Upon successful registration the user’s identity commitment is stored in a leaf of the Merkle tree and an index is given to them, representing their position in the tree.

### User interaction
For each interaction that the user wants to make with the application, the user must generate a zero-knowledge proof which ensures the other participants (the verifiers) that they are a valid member of the application and their identity commitment is part of the membership Merkle tree.

The interactions are app specific, such as voting for voting application and message sending for chat applications. The verifier is usually a server for centralized applications, or the other users for decentralized applications.

So, as it's been said there is a problem with spam, therefore we introduced an "anti-spam rule". The rule is usually in the form of: 
`Users must not make more than X interactions per epoch`.

The epoch can be translated as time interval of `Y` units of time unit `Z`. For simplicity sake, let’s transform the rule into: `Users must not send more than 1 message per second`.

We can implement this using `Shamir's Secret Sharing` scheme ([*read more*](./sss.md)), which allows you to split a secret (f.e. to `n` parts) and recover it when any `m` of `n` parts (`m <= n`) are presented.

Thus, users have to split their `secret_key` into `n` parts and for every interaction they have to reveal the new part of the `secret_key`. So, in addition to proving the membership in the `Merkle Tree`, users have to prove that the revealed part is truly the part of their `secret_key`.

If they make more interactions than allowed per epoch their secret key can be fully reconstructed.

### User removal (slashing)
The final property of the RLN mechanism is that it allows for the users to be removed from the membership tree by anyone that knows their secret key. The membership tree contains the identity commitments of all registered users. User’s identity commitment is derived from their secret key, and the secret key of the user is only revealed in a spam event (except for the scenarios where the original users wants to remove themselves, which they can always do because they know their secret key). When an economic stake is present, the RLN mechanism can be implemented in a way that the spammer’s stake is sent to the first user that correctly reports the spammer by providing the reconstructed secret key of the spammer as a proof.


