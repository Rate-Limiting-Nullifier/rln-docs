![RLN Logo](./images/logo.svg)

**RLN** (Rate-Limiting Nullifier) is a zk-gadget/protocol that enables spam prevention mechanism for anonymous environments.

## RLN Components, Tools, and Libraries

|           | Version | Stable | In Development | Notes | URL |
|--------------|-----:|:-:|:--:|-|-|
| RLN Circuits |  1.0 | ✅ | ✅ | [Current Circuit](https://github.com/Rate-Limiting-Nullifier/rln-circuits/blob/master/circuits/rln-base.circom) |[main branch](https://github.com/Rate-Limiting-Nullifier/rln-circuits/)|
|              |  2.0 | ❌ | ✅ | [v2 Proposal](https://hackmd.io/@curryrasul/SJH8kP8hi) |[v2 issue](https://github.com/Rate-Limiting-Nullifier/rln-circuits/issues/3)|
| RLNjs        |  1.0 | ✅ | ❌ | Supports RLN v1 circuits | [v1 commit](https://github.com/Rate-Limiting-Nullifier/rlnjs/tree/35b9d21c7d97289ef10c018c7e214d00fa779976)|
|              |  2.0 | ❌ | ✅ | Rewrite, added Registry/Cache, Supports v1 circuits |[main branch](https://github.com/Rate-Limiting-Nullifier/rlnjs/tree/main)|
|              |  2.1 | ❌ | ✅ | Will support v2 circuits |[v2.1 Issue](https://github.com/Rate-Limiting-Nullifier/rlnjs/issues/17)|
| RLN-CLI      |  0.1 | ❌ | ✅ | Rust |[main branch](https://github.com/Rate-Limiting-Nullifier/rln-cli)|
| PMTree       |  0.1 | ❌ | ✅ | Rust |[main branch](https://github.com/Rate-Limiting-Nullifier/pmtree)|

> **RLN** is part of (**PSE**) [Privacy & Scaling Explorations](https://appliedzkp.org), a multidisciplinary team supported by the Ethereum Foundation. PSE explores new use cases for zero-knowledge proofs and other cryptographic primitives.

