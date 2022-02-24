//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract CryptoChess {
	//enum	Pieces	{PAWN, CASTLE, BISHOP, KNIGHT, QUEEN, KING}
	//				1		2		3		4		5		6
	address[2] players;
	bool[2] isFirstMove;

	uint256 [8][8] boardPieces; //index Y, X
	uint256 [8][8] boardColors;

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

	function move(uint256[2] memory _from, uint256[2] memory _to) public onlyTurn {
		require(_from[0] < 8 && _from[1] < 8 && _to[0] < 8 && _to[1] < 8, "Out of bounds!");
		require (check_move(_from, _to) == true, "This move is not valid!");
		if (boardPieces[_to[0]][_to[1]] == 5)
			_end_game(turnIndex);

		uint256 piece = boardPieces[_from[0]][_from[1]]; //origin in top left
		boardPieces[_from[0]][_from[1]] = 0;
		boardPieces[_to[0]][_to[1]] = piece;

		uint256 color = boardColors[_from[0]][_from[1]]; //origin in top left
		boardColors[_from[0]][_from[1]] = 0;
		boardColors[_to[0]][_to[1]] = color;

		if (isFirstMove[turnIndex] == true)
			isFirstMove[turnIndex] = false;
		_create_queen();
		_next_turn();
	}

	function get_boardPieces() public view returns(uint256[8][8] memory) {
		return boardPieces;
	}

	function check_move(uint256[2] memory _from, uint256[2] memory _to) public view returns(bool) {
		uint256 piece = boardPieces[_from[0]][_from[1]];
		uint256 colorFrom = boardColors[_from[0]][_from[1]];
		uint256 colorTo = boardColors[_to[0]][_to[1]];

		int256 x = int256(_to[0]) - int256(_from[0]);
		int256 y = int256(_to[1]) - int256(_from[1]);

		if (piece == 1)
			return _check_pawn(x, y, colorFrom, colorTo);
		else if (piece == 2)
			return _check_castle(x, y, colorFrom, colorTo, _to);
		else if (piece == 3)
			return _check_bishop(x, y, colorFrom, colorTo, _to);
		else if (piece == 4)
			return _check_knight(x, y, colorFrom, colorTo);
		else if (piece == 5)
			return (_check_bishop(x, y, colorFrom, colorTo, _to) != _check_castle(x, y, colorFrom, colorTo, _to));
		else if (piece == 6)
			return _check_king(x, y, colorFrom, colorTo);
		return false;
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
		boardPieces =	[	[2, 4, 3, 5, 6, 3, 4, 2],
							[1, 1, 1, 1, 1, 1, 1, 1],
							[0, 0, 0, 0, 0, 0, 0, 0],
							[0, 0, 0, 0, 0, 0, 0, 0],
							[0, 0, 0, 0, 0, 0, 0, 0],
							[0, 0, 0, 0, 0, 0, 0, 0],
							[1, 1, 1, 1, 1, 1, 1, 1],
							[2, 4, 3, 5, 6, 3, 4, 2]];

		boardColors =	[	[1, 1, 1, 1, 1, 1, 1, 1],
							[1, 1, 1, 1, 1, 1, 1, 1],
							[0, 0, 0, 0, 0, 0, 0, 0],
							[0, 0, 0, 0, 0, 0, 0, 0],
							[0, 0, 0, 0, 0, 0, 0, 0],
							[0, 0, 0, 0, 0, 0, 0, 0],
							[2, 2, 2, 2, 2, 2, 2, 2],
							[2, 2, 2, 2, 2, 2, 2, 2]];
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

	//==============================================================================================

	function _check_pawn(	int256 _x,
							int256 _y,
							uint256 _colorFrom,
							uint256 _colorTo)
						internal view returns(bool) {

		if (_x == 0 && _colorTo == 0 && //forward
				((_colorFrom == 1 && (_y == 1 || (_y == 2 && isFirstMove[_colorFrom - 1] == true))) ||
				(_y == -1 || (_y == -2 && isFirstMove[_colorFrom - 1] == true))))
			return true;
		else if ((_x == 1 || _x == -1) && //eat
					((_colorFrom == 1 && _colorTo == 2 && _y == 1) ||
					(_colorTo == 1 && _y == -1)))
			return true;
		return false;
	}

	function _check_castle(	int256 _x,
							int256 _y,
							uint256 _colorFrom,
							uint256 _colorTo,
							uint256[2] memory _to)
						internal view returns(bool) {

		if (((_x == 0 && _y != 0) || (_x != 0 && _y == 0)) &&
				_is_free_way(_x, _y, _to) &&
				_colorTo != _colorFrom)
			return true;
		return false;
	}

	function _check_bishop(	int256 _x,
							int256 _y,
							uint256 _colorFrom,
							uint256 _colorTo,
							uint256[2] memory _to)
						internal view returns(bool) {

		if (_y < 0)
			_y *= -1;
		if (_x < 0)
			_x *= -1;

		if (_x == _y && _is_free_way(_x, _y, _to) &&
				_colorTo != _colorFrom)
			return true;
		return false;
	}

	function _check_knight(	int256 _x,
							int256 _y,
							uint256 _colorFrom,
							uint256 _colorTo)
						internal pure returns(bool) {

		if ((_y == 2 || _y == -2) && (_x == 1 || _x == -1) && _colorTo != _colorFrom)
			return true;
		return false;
	}

	function _check_king(	int256 _x,
							int256 _y,
							uint256 _colorFrom,
							uint256 _colorTo)
						internal pure returns(bool) {
		if ((_x == 1 || _x == -1 || _y == 1 || _y == -1) && _colorFrom != _colorTo)
			return true;
		return false;
	}

	//==============================================================================================

	function _create_queen() internal {
		for (uint256 i = 0; i < 8; i++){
			if (boardPieces[0][i] == 1 && boardColors[0][i] == 2)
				boardPieces[0][i] = 5;
			if (boardPieces[7][i] == 1 && boardColors[7][i] == 1)
				boardPieces[7][i] = 5;
		}
	}

	//use only in horizontal, vertical or diagonal moves
	//returns true only if theres is no pieces between coordinates
	function _is_free_way(	int256 _x,
							int256 _y,
							uint256[2] memory _to)
						internal view returns(bool) {

		while (true) {
			if (_x < 0)
				_x++;
			else if (_x > 0)
				_x--;
			if (_y < 0)
				_y++;
			else if (_y > 0)
				_y--;

			if (_x == 0 && _y == 0)
				return true;
			if (boardPieces[uint256(int256(_to[0]) - _y)][uint256(int256(_to[1]) - _x)] != 0)
				return false;
		}
		return false;
	}
}
