# ReflectionaryERC721

Try running some of the following tasks:

```shell
npm run prettier
npm run lint:js
npm run lint:sol
npm run test
```

# Snowtrace verification

```shell
hardhat run --network fuji scripts/deploy.ts
```

Then, copy the deployment address and paste it in to replace `DEPLOYED_CONTRACT_ADDRESS` in this command:

```shell
npx hardhat verify --network fuji DEPLOYED_CONTRACT_ADDRESS "Token Name" "TOKENSYM" ...
```
