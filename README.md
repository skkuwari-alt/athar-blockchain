Fine, here’s a **clean, professional, README-ready version** that won’t embarrass you when Prof. Aazam opens your repo.
It’s crisp, formatted, structured, and actually readable.
Paste this straight into your `README.md`.

---

# Athar — Sadu Heritage Registry (Sepolia PoC)

A blockchain-based provenance system for documenting and validating Qatari Sadu cultural artifacts.
This project combines role-based validation, decentralized storage references, and a minimal UI prototype for creators and institutional validators.

Private keys and sensitive values are excluded for security.

---

## Deployment (Sepolia)

The following contracts are currently deployed on the Sepolia testnet:

```
REGISTRY_ADDRESS = 0x8AC07001FC2d4eEf98f19AD70D66b88085530426
LICENSE_ADDRESS   = <your-latest-license-address>
```

### Validator Wallets

```
Qatar Museums (QM):        0x99ACCaf6f29bdEDad6BB058E70223Eb76dCCaC33
Ministry of Culture (MoC): 0x368EefF6277abC2A5D6E70e57294C7DA650365aa
```

Role assignments use OpenZeppelin AccessControl:

* **DEFAULT_ADMIN_ROLE** → Deployment admin
* **QM_VALIDATOR** → Qatar Museums
* **MOC_VALIDATOR** → Ministry of Culture

---

## Granting Validator Roles

*(Admin only — private keys stored locally in `.env`)*

### Grant Qatar Museums Validator Role

```sh
cast send 0x8AC07001FC2d4eEf98f19AD70D66b88085530426 \
"grantRole(bytes32,address)" \
$(cast keccak "QM_VALIDATOR") \
0x99ACCaf6f29bdEDad6BB058E70223Eb76dCCaC33 \
--private-key $PRIVATE_KEY \
--rpc-url https://ethereum-sepolia.publicnode.com
```

### Grant Ministry of Culture Validator Role

```sh
cast send 0x8AC07001FC2d4eEf98f19AD70D66b88085530426 \
"grantRole(bytes32,address)" \
$(cast keccak "MOC_VALIDATOR") \
0x368EefF6277abC2A5D6E70e57294C7DA650365aa \
--private-key $PRIVATE_KEY \
--rpc-url https://ethereum-sepolia.publicnode.com
```

---

## Verifying Role Assignments

### Qatar Museums

```sh
cast call 0x8AC07001FC2d4eEf98f19AD70D66b88085530426 \
"hasRole(bytes32,address)(bool)" \
$(cast keccak "QM_VALIDATOR") \
0x99ACCaf6f29bdEDad6BB058E70223Eb76dCCaC33 \
--rpc-url https://ethereum-sepolia.publicnode.com
```

### Ministry of Culture

```sh
cast call 0x8AC07001FC2d4eEf98f19AD70D66b88085530426 \
"hasRole(bytes32,address)(bool)" \
$(cast keccak "MOC_VALIDATOR") \
0x368EefF6277abC2A5D6E70e57294C7DA650365aa \
--rpc-url https://ethereum-sepolia.publicnode.com
```

Expected output:

```
true
```

---

## Sprint 3 Development Commands

These are the commands **actually used** to deploy, test, debug, generate metrics, and run the UI for Sprint 3 requirements.

---

### Deployment

Deploy the full Athar system:

```sh
forge script script/DeployAthar.s.sol:DeployAthar \
--rpc-url $SEPOLIA_RPC_URL \
--broadcast \
--private-key $PRIVATE_KEY
```

### Happy Path Script

*(Executed 3× to gather latency metrics)*

```sh
forge script script/HappyPath.s.sol:HappyPath \
--rpc-url $SEPOLIA_RPC_URL \
--broadcast \
--private-key $PRIVATE_KEY
```

---

### 🛠 Testing & Metrics

**Run smart contract tests**

```sh
forge test
```

**Generate coverage summary**

```sh
forge coverage > sprint3evidence/coverage-summary.txt
```

**Generate gas report**

```sh
forge snapshot > sprint3evidence/gas-snapshot.txt
```

---

### On-Chain Debugging Commands

Check next artifact ID:

```sh
cast call <REGISTRY_ADDRESS> "nextId()(uint256)" --rpc-url $SEPOLIA_RPC_URL
```

Fetch artifact struct:

```sh
cast call <REGISTRY_ADDRESS> \
"artifacts(uint256)(address,string,bool,bool,bool,bool,bool,string,string,uint256)" \
<id> \
--rpc-url $SEPOLIA_RPC_URL
```

Manual validator approval:

```sh
cast send <REGISTRY_ADDRESS> "approve(uint256)" <id> \
--private-key $VALIDATOR_PK \
--rpc-url $SEPOLIA_RPC_URL
```

Manual reject:

```sh
cast send <REGISTRY_ADDRESS> "reject(uint256,string)" <id> "Invalid metadata" \
--private-key $VALIDATOR_PK \
--rpc-url $SEPOLIA_RPC_URL
```

---

## Running the Frontend (Local Testing)

Serve UI locally:

```sh
python3 -m http.server 8080
```

Open:

```
http://localhost:8080/frontend/index.html
```

---

## Foundry Tooling

Foundry contains four main tools:

* **Forge** – testing, deployment, gas analysis
* **Cast** – low-level EVM interaction

### Common Commands

```sh
forge build
forge fmt
forge snapshot
cast <command>
```

Docs: [https://book.getfoundry.sh/](https://book.getfoundry.sh/)

