async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const ThenianContract = await ethers.getContractFactory("Thenian");
  const Thenian = await ThenianContract.deploy(3000, '2000000000000000000', 1669993200);

  // Wait for this transaction to be mined
  await Thenian.deployed();

  console.log("Thenian address:", Thenian.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });