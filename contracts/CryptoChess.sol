//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract CryptoChess {
	//enum	Pieces	{PAWN, CASTLE, BISHOP, KNIGHT, QUEEN, KING}
	//				1		2		3		4		5		6
	address[2] players;
	bool[2] isFirstMove;

	uint256 [8][8] board;

	uint256 enteringPrice;
	uint256 lastTime;
	uint256[2] playersTimeLeft;

	uint256 turnIndex;


	modifier onlyTurn {
		_refresh_timer();
		if (playersTimeLeft[turnIndex] == 0)
			_end_game(turnIndex == 1 ? 0 : 1);
		if (players[0] == msg.sender)
			require(turnIndex == 0);
		else if (players[1] == msg.sender)
			require(turnIndex == 1);
		else
			revert("You're not playing!");
		_;
	}

	constructor(uint256 _enteringPrice) {
		enteringPrice = _enteringPrice;
		_reset_game();
	}

	function join() public payable {
		require(lastTime == 0, "The game is in progress!");
		require(msg.value == enteringPrice, "Please enter the exact entering price!");

		for (uint256 i = 0; i < 2; i++)
			if (players[i] == address(0)) {
				players[i] = msg.sender;
				return ;
			}
		revert("The game is full!");
	}

	function move(uint256[2] memory _from, uint256[2] memory _to) public {
		require(_from[0] < 8 && _from[1] < 8 && _to[0] < 8 && _to[1] < 8, "Out of bounds!");
		require (check_move(_from, _to) == true, "This move is not valid!");
		if (board[_to[0]][_to[1]] == 5)
			_end_game(turnIndex);

		uint256 piece = board[_from[0]][_from[1]]; //origin in top left
		board[_from[0]][_from[1]] = 0;
		board[_to[0]][_to[1]] = piece;
		if (isFirstMove[turnIndex] == true)
			isFirstMove[turnIndex] = false;
		_next_turn();
	}

	function get_board() public view returns(uint256[8][8] memory) {
		return board;
	}

	function check_move(uint256[2] memory _from, uint256[2] memory _to) public view returns(bool) {
		uint256 piece = board[_from[0]][_from[1]];

		if (piece == 1)
			return _check_pawn(_from, _to);
		else if (piece == 2)
			_check_castle(_from, _to);
		else if (piece == 3)
			_check_bishop(_from, _to);
		else if (piece == 4)
			_check_knight(_from, _to);
		else if (piece == 5)
			_check_queen(_from, _to);
		else if (piece == 6)
			_check_king(_from, _to);
	}

//============================================================================================

	function _refresh_timer() internal {
		if (playersTimeLeft[turnIndex] > 0) {
			int256 timeLeft = int256(block.timestamp - lastTime - playersTimeLeft[turnIndex]);
			if (timeLeft < 0)
				timeLeft = 0;
			playersTimeLeft[turnIndex] = uint256(timeLeft);
		}
	}

	function _next_turn() internal {
		turnIndex = turnIndex == 1 ? 0 : 1;
		lastTime = block.timestamp;
	}

	function _reset_game() internal {
		_reset_players();
		_reset_timer();
		_reset_board();
	}

	function _reset_board() internal {
		board =	[	[2, 4, 3, 5, 6, 3, 4, 2],
					[1, 1, 1, 1, 1, 1, 1, 1],
					[0, 0, 0, 0, 0, 0, 0, 0],
					[0, 0, 0, 0, 0, 0, 0, 0],
					[0, 0, 0, 0, 0, 0, 0, 0],
					[0, 0, 0, 0, 0, 0, 0, 0],
					[1, 1, 1, 1, 1, 1, 1, 1],
					[2, 4, 3, 5, 6, 3, 4, 2]];
	}

	function _reset_timer() internal {
		lastTime = 0;
		playersTimeLeft[0] = 5 minutes;
		playersTimeLeft[1] = 5 minutes;
	}

	function _reset_players() internal {
		for (uint256 i = 0; i < 2; i++) {
			players[i] = address(0);
			isFirstMove[i] = false;
		}
	}

	function _end_game(uint256 _winner) internal {
		(bool success, ) = players[_winner].call{value: address(this).balance}("");
		require(success, "transaction failed");
		_reset_game();
	}
}
