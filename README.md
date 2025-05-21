## TiQetV2 contract

Heart of the TiQet project's betting system

---
## Getting your hands dirty

#### 1. Clone the repository
```bash
git clone https://github.com/TiqetQl1/tiqet-v2-contract.git
cd tiqet-v2-contract
```

#### 2. Install dependencies
After making sure that you have `node` installed on your machine run the following command to install dependencies
```bash
npm install
```

#### 3.Compile the smart contracts
```bash
npx hardhat compile
```

### 4.1 Run tests

```bash
npx hardhat test
```

### 4.2. Run a local testnet

On the root of the project
```bash
npx hardhat node
```
And again on another terminal in the root folder of the project without closing the last terminal
```bash
npm run ignite
```

### 4.3 Generate docs

```bash
npx hardhat docgen
```
And documents will be available in `./docs` after that 

---
