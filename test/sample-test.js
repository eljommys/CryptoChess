const { expect } = require("chai");
const { ethers, waffle } = require("hardhat");
const provider = waffle.provider;

describe("CryptoChess tester", async function () {
	const [player1, player2] = await ethers.getSigners();

	const ChessFactory = await ethers.getContractFactory("CryptoChess");
	const Chess = await ChessFactory.deploy(20);
	await Chess.deployed();

	it("Should add a new player", async function () {
		await Chess.join();
		expect(await Chess.join()).to.equal("Hello, world!");

		const setGreetingTx = await Chess.setGreeting("Hola, mundo!");

		// wait until the transaction is mined
		await setGreetingTx.wait();

		expect(await Chess.greet()).to.equal("Hola, mundo!");
	});
});
