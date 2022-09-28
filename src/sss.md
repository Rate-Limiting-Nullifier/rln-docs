# Shamirs Secret Sharing Scheme

*Shamirs Secret Sharing* allows to split the secret to `n` parts and restore it upon presentation any `m` parts (`m <= n`)

[Sharmir's Secret Sharing wikipedia](https://en.wikipedia.org/wiki/Shamir%27s_Secret_Sharing) is a good reference to understand the concept.

Reconstruction 1: https://github.com/akinovak/semaphore-lib/blob/5b9bb3210192c8e508eced7ef6579fd56e635ed0/src/rln.ts#L31
```js
retrievePrivateKey(x1: bigint, x2:bigint, y1:bigint, y2:bigint): Buffer | ArrayBuffer {
        const slope = Fq.div(Fq.sub(y2, y1), Fq.sub(x2, x1))
        const privateKey = Fq.sub(y1, Fq.mul(slope, x1));
        return bigintConversion.bigintToBuf(Fq.normalize(privateKey));
    }
```

Reconstruction 2: https://github.com/akinovak/semaphore-lib/blob/rln_signature_changes/test/index.ts#L250

```js
async function testRlnSlashingSimulation() {
    RLN.setHasher('poseidon');
    const identity = RLN.genIdentity();
    const privateKey = identity.keypair.privKey;

    const leafIndex = 3;
    const idCommitments: Array<any> = [];

    for (let i=0; i<leafIndex;i++) {
      const tmpIdentity = OrdinarySemaphore.genIdentity();
      const tmpCommitment: any = RLN.genIdentityCommitment(identity.keypair.privKey);
      idCommitments.push(tmpCommitment);
    }

    idCommitments.push(RLN.genIdentityCommitment(privateKey))

    const signal = 'hey hey';
    const x1: bigint = OrdinarySemaphore.genSignalHash(signal);
    const epoch: string = OrdinarySemaphore.genExternalNullifier('test-epoch');

    const vkeyPath: string = path.join('./rln-zkeyFiles', 'verification_key.json');
    const vKey = JSON.parse(fs.readFileSync(vkeyPath, 'utf-8'));

    const wasmFilePath: string = path.join('./rln-zkeyFiles', 'rln.wasm');
    const finalZkeyPath: string = path.join('./rln-zkeyFiles', 'rln_final.zkey');

    const witnessData: IWitnessData = await RLN.genProofFromIdentityCommitments(privateKey, epoch, signal, wasmFilePath, finalZkeyPath, idCommitments, 15, BigInt(0), 2);

    const a1 = RLN.calculateA1(privateKey, epoch);
    const y1 = RLN.calculateY(a1, privateKey, x1);
    const nullifier = RLN.genNullifier(a1);

    const pubSignals = [y1, witnessData.root, nullifier, x1, epoch];

    let res = await RLN.verifyProof(vKey, { proof: witnessData.fullProof.proof, publicSignals: pubSignals })
    if (res === true) {
        console.log("Verification OK");
    } else {
        console.log("Invalid proof");
        return;
    }

    const signalSpam = "let's try spamming";
    const x2: bigint = OrdinarySemaphore.genSignalHash(signalSpam);

    const witnessDataSpam: IWitnessData = await RLN.genProofFromIdentityCommitments(privateKey, epoch, signalSpam, wasmFilePath, finalZkeyPath, idCommitments, 15, BigInt(0), 2);

    const a1Spam = RLN.calculateA1(privateKey, epoch);
    const y2 = RLN.calculateY(a1Spam, privateKey, x2);
    const nullifierSpam = RLN.genNullifier(a1Spam);

    const pubSignalsSpam = [y2, witnessDataSpam.root, nullifierSpam, x2, epoch];

    res = await RLN.verifyProof(vKey, { proof: witnessDataSpam.fullProof.proof, publicSignals: pubSignalsSpam })
    if (res === true) {
        console.log("Spam proof Verification OK");
    } else {
        console.log("Invalid proof");
        return;
    }

    const identitySecret = RLN.calculateIdentitySecret(privateKey);

    const retreivedPkey = bigintConversion.bufToBigint(RLN.retrievePrivateKey(x1, x2, y1, y2));


    if(Fq.eq(identitySecret, retreivedPkey)) {
        console.log("PK successfully reconstructed");
    } else {
        console.log("Error while reconstructing private key")
    }

    // TODO: Add removal from tree example
}
```
