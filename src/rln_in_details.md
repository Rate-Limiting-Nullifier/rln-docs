# Technical side of RLN

*If you're unfamiliar with Shamir's Secret Sharing scheme, you can [read it here](./sss.md).*

___

**RLN** consists of three parts:
* User registration
* User interaction (signaling)
* User removal/withdrawal (slashing) - additional part

Well, let's discuss them.

## User registration

The first part of **RLN** is registration. There is nothing special in **RLN** registration; it's almost the same process as in other protocols/apps with anonymous environments: we need to create a Merkle tree, and every participant must submit an \\(identityCommitment\\) and place it in the Merkle Tree, and after that to interact with the app every participant will create a zk proof's, that they are a *member of the tree*.

So, each member generates a secret key, denoted by \\(a_0\\). Identity commitment is the Poseidon hash of the secret key: 
\\[identityCommitment = Poseidon(a_0)\\]

**RLN** wouldn't work if there were no punishment for spam; that's why to become a member, a user has to register and provide something at stake. So, whoever has our \\(a_0\\) can "slash" us. 

The slight difference is that we must enable a *secret sharing* scheme (to split the \\(a_0\\) into parts). We need to come up with a polynomial. For simplicity we use linear polynomial - \\(f(x) = kx + b\\). Therefore, with two points we can reconstruct the polynomial and recover the secret. 

## Signalling

Now that users are registered, they want to interact with the system. Imagine that the system is an *anonymous chat* and the interaction is the sending of messages. 
So, to send a message users have to come up with *share* - the point \\((x, y)\\) on their polynomial. 
We denote: 
\\[x = Poseidon(message)\\] 
\\[y = A(x)\\]

Thus, if during the same epoch user sends more than one message, their polynomial and, therefore, their secret - \\(a_0\\) can be recovered.

Of course, we somehow must prove that our *share* = \\((x, y)\\) is valid (that this is really a point on our polynomial), as well as we must prove other things are valid too, that's why we use zkSNARK.

### Range check trick and resulting polynomial

As it was said - we use first-degree polynomial for simplicity of the protocol and circuits. But you may ask - does it limit the system to only one message per epoch? Yes, and it's really undesirable, cause we want to have higher rate-limits. What we can do is to use polynomial of higher degree, but we also can do a clever trick: we can introduce an additional circuit input: \\(messageId\\), that will serve us as a simple counter. 

Let's say we make \\(messageLimit = n\\). Then for each message we send (during the same epoch) - we also need an additional input \\(messageId\\). This value will be range checked that it's less than \\(messageLimit\\) (to be more precise: \\(0 \le messageId < messageLimit\\)). And our polynomial will depend on this input as well, so that for each message - different \\(messageId\\) will be used, therefore the resulting polynomials will be different. 

Our polynomial will be: 
\\[A(x) = a_1 * x + a_0\\]
\\[a_1 = Poseidon(a_0, externalNullifier, messageId)\\]

The meaning of \\(externalNullifier\\) is described [below](#nullifiers).

It's sound, because if we use the same \\(messageId\\) twice - we'll share two different points from our first-degree polynomial, therefore it'll be possible to recover the secret key. And at the same time user also cannot input \\(messageId\\) value that's bigger than the \\(messageLimit\\), because of the range check.

### Different rate-limits for different users

It's also may be desired to have different rate-limits for different users, for example based on their stake amount. We can also achieve that by calculating \\(userMessageLimit\\) value and then deriving \\(rateCommitment\\):
\\[rateCommitment = Poseidon(identityCommitment, rateCommitment)\\]
during the registration phase.

And it's the \\(rateCommitment\\) values that are stored in the membership Merkle tree.

Therefore, in the circuit users will have to prove that the: 
\\[identityCommitment = Poseidon(identitySecret)\\]
\\[rateCommitment = Poseidon(identityCommitment, userMessageLimit)\\]
\\[0 \le messageId < userMessageLimit\\]

We use the scheme with \\(userMessageLimit\\) as it more general, though it's not necessarily to have different rate-limits for different users. We can enforce that the users will have the same rate-limit during the registration. For more information on that read [smart-contract explanation](./smart_contract.md#registration).

## Slashing
As it's been said, if a user sends more than one message, everyone else will be able to recover his secret, slash them and take their stake. Based on [\\(nullifier\\)](#nullifiers) we can find the spammer, and therefore use polynomial interpolation using their shares. More information can be found in [smart-contract explanation](./smart_contract.md).

## Nullifiers
There are also \\(nullifier\\) and \\(externalNullifier\\), which can be found in the **RLN** protocol/circuits.

\\(externalNullifier = Poseidon(epoch, rln\\_identifier)\\), where \\(rln\\_identifier\\) is a random finite field value, unique per RLN app.

The \\(externalNullifier\\) is required so that the user can securely use the same private key \\(a_0\\) across different **RLN** apps - in different applications (and in different eras) with the same secret key, the user will have different values ​​of the coefficient \\(a_1\\).

Now, imagine there are a lot of users sending messages, and after each received message, we need to check if any member can be slashed. To do this, we can use all combinations of received *shares* and try to recover the polynomial, but this is a naive and non-optimal approach. Suppose we have a mechanism that will tell us about the connection between a person and their messages while not revealing their identity. In that case, we can solve this without brute-forcing all possibilities by using a public \\(nullifier = Poseidon(a_1)\\), so if a user sends more than one message, it will be immediately visible to everyone.
