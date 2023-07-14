# What is Rate-Limiting Nullifier?

**RLN** is a zero-knowledge gadget that enables spam prevention in anonymous environments.

The anonymity property opens up the possibility for spam, which could seriously degrade the user experience and the overall functioning of the application. For example, imagine a chat application where users are anonymous. Now, everyone can write an unlimited number of spam messages, but we don't have the ability to kick this member because the spammer is anonymous. 

**RLN** helps us identify and "kick" the spammer.

Moreover, **RLN** can be useful not only to prevent spam attacks but, in general, to limit users (in anonymous environments) in the number of actions (f.e. to vote or to make a bid).

## How it works

The **RLN** construct functionality consists of three parts. These parts should be integrated by the upstream applications, that require anonymity and spam protection. The applications can be centralized or decentralized. For decentralized applications, each user maintains separate storage and compute resources for the application. 

The three parts are:
* registration;
* interaction;
* withdrawal (or slashing);

### Registration

Before registering to the application, the user needs to generate a secret key and derive an identity commitment from the secret key using the Poseidon hash function: 

\\[identityCommitment = Poseidon(secretKey)\\]

The user registers to the application by providing a form of stake and their identity commitment, which is derived from the secret key. The application maintains a Merkle tree data structure (in the latest iteration of **RLN**, we use an Incremental Merkle Tree algorithm for gas efficiency, but the Merkle tree does not have to be on-chain), which stores the identity commitments of the registered users. Based on the stake amount apps can derive what's the messageLimit (\\(userMessageLimit\\)) for a user. Then the rateCommitment:

\\[rateCommitment = Poseidon(identitytCommitment, userMessageLimit)\\]

will be stored in the membership Merkle tree.

### Interaction
For each interaction that the user wants to make with the application, the user must generate a zero-knowledge proof ensuring that their identity commitment (or specifically rate commitment) is the part of the membership Merkle tree.

There are a number of use-cases for **RLN**, such as voting applications (1 vote per election), chat (one message per second), and rate-limiting cache access (CDN denial of service protection). The verifier can be a server for centralized applications or the other users for decentralized applications.

The general anti-spam rule is usually in the form of: *users must not make more than X interactions per epoch*.

The epoch can be translated as a time interval of \\(Y\\) units of time unit \\(Z\\). For simplicity's sake, let's transform the rule into: *users must not send more than one message per second*.

We can implement this using [*Shamir's Secret Sharing (SSS)* scheme](./sss.md), which allows you to split a secret to \\(n\\) parts and recover it when any \\(m\\) of \\(n\\) parts \\(m \le n\\) are presented.

Thus, users have to split their secret key into \\(n\\) parts, and for each interaction, they have to reveal the new part of the secret key. So, in addition to proving the membership, users have to prove that the revealed part is truly the part of their secret key.

If they make more interactions than allowed per epoch, their secret key can be fully reconstructed.

### Withdrawal (or slashing)
The final property of the **RLN** mechanism is that it allows for the users to be removed from the 
membership tree by anyone that knows their secret key. Thus, if someone spams, it'll be possible to recover the secret key and withdraw the stake (or *slash*) of a spammer - that's why it's economically inefficient for users to spam.
