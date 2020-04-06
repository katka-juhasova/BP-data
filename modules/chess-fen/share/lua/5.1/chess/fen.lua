---------------------------------------------------------------------
--     This Lua5 module is Copyright (c) 2018, Peter J Billam      --
--                       www.pjb.com.au                            --
--  This module is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------

local M = {} -- public interface
M.Version = '1.6'
M.VersionDate = '20191013'

------------------------------ private ------------------------------
function warn(...)
    local a = {}
    for k,v in pairs{...} do table.insert(a, tostring(v)) end
    io.stderr:write(table.concat(a),'\n') ; io.stderr:flush()
end
function die(...) warn(...);  os.exit(1) end
function qw(s)  -- t = qw[[ foo  bar  baz ]]
    local t = {} ; for x in s:gmatch("%S+") do t[#t+1] = x end ; return t
end
local function round(x) return math.floor(x+0.5) end
local function split(s, pattern, maxNb) -- http://lua-users.org/wiki/SplitJoin
	if not s or string.len(s)<2 then return {s} end
	if not pattern then return {s} end
	if maxNb and maxNb <2 then return {s} end
	local result = { }
	local theStart = 1
	local theSplitStart,theSplitEnd = string.find(s,pattern,theStart)
	local nb = 1
	while theSplitStart do
		table.insert( result, string.sub(s,theStart,theSplitStart-1) )
		theStart = theSplitEnd + 1
		theSplitStart,theSplitEnd = string.find(s,pattern,theStart)
		nb = nb + 1
		if maxNb and nb >= maxNb then break end
	end
	table.insert( result, string.sub(s,theStart,-1) )
	return result
end
local function deepcopy(object)  -- http://lua-users.org/wiki/CopyTable
	local lookup_table = {}
	local function _copy(object)
		if type(object) ~= "table" then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end
		local new_table = {}
		lookup_table[object] = new_table
		for index, value in pairs(object) do
			new_table[_copy(index)] = _copy(value)
		end
		return setmetatable(new_table, getmetatable(object))
	end
	return _copy(object)
end

------------------------------ public ------------------------------
function M.doc() return([[
https://en.wikipedia.org/wiki/Forsyth%E2%80%93Edwards_Notation
A FEN record contains six fields.
The separator between fields is a space. The fields are:
1) Piece placement (from white's perspective). Each rank is described,
  starting with rank 8 and ending with rank 1; within each rank, the
  contents of each square are described from file "a" through file "h".
  White pieces are designated using upper-case letters ("PNBRQK") while
  black pieces use lowercase ("pnbrqk"). Empty squares are noted using
  digits 1 through 8 (the number of empty squares); "/" separates ranks.
2) Active color. "w" means White moves next, "b" means Black.
3) Castling availability. If neither side can castle, this is "-".
  Otherwise, this has one or more letters: "K" (White can castle
  kingside), "Q" (White can castle queenside), "k" (Black can castle
  kingside), and/or "q" (Black can castle queenside).
4) En passant target square in algebraic notation.  If there's no
  en passant target square, this is "-".  If a pawn has just made
  a two-square move, this is the position "behind" the pawn.
  This is recorded regardless of whether there is a pawn
  in position to make an en passant capture.[2]
5) Halfmove clock: This is the number of halfmoves since the last
  capture or pawn advance. This is used to determine if a draw can
  be claimed under the fifty-move rule.
6) Fullmove number: The number of the full move.
  It starts at 1, and is incremented after Black's move.
]])
end

function M.fenstr2tab(fenstr)
	local fields = string.gmatch(fenstr, '[^ \t]+')
	local fentab = {}
	-- fentab['posstr']    = fields()
	local posstr        = fields()
	fentab['active']    = fields()
	fentab['castling']  = fields()
	fentab['enpassant'] = fields()
	fentab['fiftymove'] = fields()
	fentab['movenum']   = fields()
	-- fentab['postab']    = M.posstr2postab( fentab['posstr'] )
	-- fentab['posstr']    = nil
	fentab['postab']    = M.posstr2postab( posstr )
	return fentab
end

function M.fentab2str(f)
	f['posstr'] = M.postab2posstr(f['postab'])
	return table.concat(table.pack
		(f['posstr'], f['active'],   f['castling'],
		 f['enpassant'],f['fiftymove'],f['movenum']),
	' ')
end

function M.fentab2key(f)
	if f['enpassant'] ~= '-' then
		local ic, ir = sq2xy(f['enpassant'])
		-- warn(f['active'],' ic=',ic,' ir=',ir)
		local postab = f['postab']
		local isenpassant = false
		if f['active'] == 'w' then
			if ic>1 and postab[ic-1][5] == 'P' then
				isenpassant = true
			elseif ic<8 and postab[ic+1][5] == 'P' then
				isenpassant = true
			end
		else  -- black is to move
			if ic>1 and postab[ic-1][4] == 'p' then
				isenpassant = true
			elseif ic<8 and postab[ic+1][4] == 'p' then
				isenpassant = true
			end
		end
		-- warn('isenpassant is ',isenpassant)
		if not isenpassant then f['enpassant'] = '-' end
	end
	local posstr = M.postab2posstr(f['postab'])
	return table.concat(table.pack
		( posstr, f['active'],  f['castling'], f['enpassant'] ),
	' ')
end
function M.fenstr2key(s)
	return M.fentab2key(M.fenstr2tab(s))
end

function M.posstr2postab(pos)
	local ranks = string.gmatch(pos, '[^/]*')
	local postab = { {}, {}, {}, {}, {}, {}, {}, {} }
	for ir = 8, 1, -1 do
		local rank = ranks()
		local t = {}
		if #rank == 0 then  -- empty rank, not in fact legal FEN
			t = {' ',' ',' ',' ',' ',' ',' ',' '}
		else
			for ic = 1, string.len(rank) do
				local c = string.sub(rank,ic,ic)
				if string.match(c,'%d') then
					for i = 1, tonumber(c) do t[#t+1] = " " end
				else
					t[#t+1] = c
				end
			end
		end
		for ic = 1, 8 do postab[ic][ir] = t[ic] end
	end
	return postab
end

function M.postab2posstr(postab)
	local ranks = {}
	for ir = 8, 1, -1 do  -- rank 8 appears first in the posstr string
		local orank = {}
		local nspaces = 0
		for ic = 1 , 8 do
			local c = postab[ic][ir]
			if c == ' ' then
				nspaces = nspaces + 1
			else
				if nspaces > 0 then
					orank[#orank+1] = tostring(nspaces)
					nspaces = 0
				end
				orank[#orank+1] = c
			end
		end
		if nspaces > 0 then orank[#orank+1] = tostring(nspaces) end
		ranks[#ranks+1] = table.concat(orank)
	end
	return table.concat(ranks,'/')
end

function M.fenstr2asciidiag(fen)
	if type(fen) == 'string' then fen = M.fenstr2tab(fen) end
	local postab = fen['postab']
	local asciidiag = {}
	for ir = 1, 8 do
		local rank = {}
		for ic = 1, 8 do
			rank[ic] = postab[ic][ir]
		end
		asciidiag[10-ir] = '| ' .. table.concat(rank,' ') .. ' |\n'
	end
	if fen['active'] == 'w' then
		asciidiag[1] ="+-----------------+\n"
		asciidiag[10]=
		  "+-----------------+  W  move "..tostring(fen['movenum']).."\n"
	else
		asciidiag[1] =
		  "+-----------------+  B  move "..tostring(fen['movenum']).."\n"
		asciidiag[10]="+-----------------+\n"
	end
	return table.concat(asciidiag,'')
end

function sq2xy (square)
	local colstr, rankstr = string.match(square, '^([a-h])([1-8])$')
	local ah_to_18 = {a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8}
	if not colstr then return nil, 'bad square: '..square end
if M.dbg then warn('colstr=',colstr,' rankstr=',rankstr) end
	return ah_to_18[colstr], tonumber(rankstr)
end

function xy2sq (x, y)
	local col18_to_ah = {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'}
	local col = col18_to_ah[tonumber(x)]
	if not col then
		return nil, 'bad square: '..tostring(x)..', '..tostring(y)
	end
if M.dbg then warn('col=',col,' y=',y) end
	return col .. tostring(y)
end

function kingsquare (kingpiece, fentab)   -- 1.5
	if string.lower(kingpiece) ~= 'k' then
		return nil," kingsquare: kingpiece was not a king: "..kingpiece
	end
	local postab = fentab['postab']
	local x, y
	for x = 1,8 do
		for y = 1,8 do
			if postab[x][y] == kingpiece then return x, y end
		end
	end
end

function M.is_check (kingpiece, fentab)   -- 1.5
	if string.lower(kingpiece) ~= 'k' then
		return nil," kingsquare: kingpiece was not a king: "..kingpiece
	end
	local postab = fentab['postab']
	local x_king, y_king = kingsquare (kingpiece, fentab)
	local x_tmp ; local y_tmp
	local is_checker = function (p)
		if kingpiece == 'K' and (p == 'q' or p == 'r') then return true
		elseif kingpiece == 'k' and (p=='Q' or p=='R') then return true
		else return false
		end
	end
	-- seek along a file
	for y_tmp = (y_king-1), 1, -1 do
		local p = postab[x_king][y_tmp]
		if is_checker(p) then return true elseif p~=' ' then break end
	end
	for y_tmp = y_king+1, 8, 1 do
		local p = postab[x_king][y_tmp]
		if is_checker(p) then return true elseif p~=' ' then break end
	end
	-- seek along a rank
	for x_tmp = x_king-1, 1, -1 do
		local p = postab[x_tmp][y_king]
		if is_checker(p) then return true elseif p~=' ' then break end
	end
	for x_tmp = x_king+1, 8, 1 do
		local p = postab[x_tmp][y_king]
		if is_checker(p) then return true elseif p~=' ' then break end
	end
	-- seek along the diagonals
	is_checker = function (p)
		if kingpiece == 'K' and (p == 'q' or p == 'b') then return true
		elseif kingpiece == 'k' and (p=='Q' or p=='B') then return true
		else return false
		end
	end
	local delta = 1 ; while true do  -- check the ++ diagonal
		x_tmp = x_king + delta ; y_tmp = y_king + delta 
		if x_tmp > 8 or y_tmp > 8 then break end
		local p = postab[x_tmp][y_tmp]
		-- print('x_tmp,y_tmp =',x_tmp,y_tmp,' delta =',delta,' p ="'..p..'"')
		if is_checker(p) then return true elseif p~=' ' then break end
		delta = delta + 1
	end
	delta = 1 ; while true do  -- check the +- diagonal
		x_tmp = x_king + delta ; y_tmp = y_king - delta 
		if x_tmp > 8 or y_tmp < 1 then break end
		local p = postab[x_tmp][y_tmp]
		if is_checker(p) then return true elseif p~=' ' then break end
		delta = delta + 1
	end
	delta = 1 ; while true do  -- check the -- diagonal
		x_tmp = x_king - delta ; y_tmp = y_king - delta 
		if x_tmp < 1 or y_tmp < 1 then break end
		local p = postab[x_tmp][y_tmp]
		if is_checker(p) then return true elseif p~=' ' then break end
		delta = delta + 1
	end
	delta = 1 ; while true do  -- check the -+ diagonal
		x_tmp = x_king - delta ; y_tmp = y_king + delta 
		if x_tmp < 1 or y_tmp > 8 then break end
		local p = postab[x_tmp][y_tmp]
		if is_checker(p) then return true elseif p~=' ' then break end
		delta = delta + 1
	end
	-- seek a knight check (not needed for pinned pieces moving)
	-- seek a pawn check (not needed for pinned pieces moving)
	-- seek a king check (only needed to check viability of a king move)
	return false
end

--[[
function M.is_pinned (x, y, fentab)
-- AARGHhhh :-(  ... if a piece is pinned, it can still move in either
-- direction down the file, rank or diagonal along which is is pinned !
	local postab = fentab['postab']
	local piece = postab[x][y]
	if piece == ' ' or piece == 'K' or piece == 'k'then
		return nil, "is_pinned piece='"..piece.."'"
	end
	local kingpiece = 'K'
	if piece == string.lower(piece) then kingpiece = 'k' end
	local x_king, y_king = kingsquare(kingpiece, fentab)
print('   x,y =',x,y,kingpiece..' is at',x_king, y_king)
	if x == x_king and y == y_king then
		return nil, "a king can't be pinned to itself"
	end
	local delta_x, delta_y  -- to increment from the king towards x,y
	local is_possible_pinner = function (p)   -- for a rank or file
		if kingpiece == 'K' and (p == 'q' or p == 'r') then return true
		elseif kingpiece == 'k' and (p=='Q' or p=='R') then return true
		else return false
		end
	end
	if x == x_king then  -- pinned along a file ?
print('   pinned along a file')
		delta_x = 0
		if y < y_king then delta_y = -1 else delta_y = 1 end
	elseif y == y_king then  -- pinned along a rank ?
print('   pinned along a rank')
		if x < x_king then delta_x = -1 else delta_x = 1 end
		delta_y = 0
	elseif (x-x_king)==(y-y_king) or (x-x_king)==(y_king-y) then -- diagonal ?
		if x < x_king then delta_x = -1 else delta_x = 1 end
		if y < y_king then delta_y = -1 else delta_y = 1 end
		is_possible_pinner = function (p)   -- override for diagonal
			if kingpiece == 'K' and (p == 'q' or p == 'b') then return true
			elseif kingpiece == 'k' and (p=='Q' or p=='B') then return true
			else return false
			end
		end
	else return false  -- not pinned
	end
	local x_tmp = x_king + delta_x
	local y_tmp = y_king + delta_y   -- start from the king
	local is_found = false  -- have we found the piece yet ?
	while x_tmp>=1 and x_tmp<=8 and y_tmp>=1 and y_tmp<=8 do
-- print('x_tmp,y_tmp =',x_tmp,y_tmp)
		if x_tmp==x and y_tmp==y then is_found = true
		elseif postab[x_tmp][y_tmp] == ' ' then  -- skip over space
		else   -- there's a piece on this square ...
			if not is_found then return false end  -- a piece was in the way
			return is_possible_pinner( postab[x_tmp][y_tmp] )
		end
		x_tmp = x_tmp + delta_x
		y_tmp = y_tmp + delta_y
	end
end
]]

function frompiece2xy(frompiece, tox,toy, fentab, clue, move)
	local casepiece = frompiece
	local postab = fentab['postab']
	if fentab['active'] == 'b' then casepiece = string.lower(frompiece) end
	local candidates = {}  -- array of {tox,toy} squares
	local insert = table.insert
	if frompiece == 'R' then
		local x = tox
		while true do
			x = x-1
			if x<1 then break end
			if postab[x][toy] == casepiece then insert(candidates,{x,toy}) end
			if postab[x][toy] ~= ' ' then break end
		end
		x = tox
		while true do
			x = x+1
			if x>8 then break end
			if postab[x][toy] == casepiece then insert(candidates,{x,toy}) end
			if postab[x][toy] ~= ' ' then break end
		end
		local y = toy
		while true do
			y = y-1
			if y<1 then break end
			if postab[tox][y] == casepiece then insert(candidates,{tox,y}) end
			if postab[tox][y] ~= ' ' then break end
		end
		y = toy
		while true do
			y = y+1
			if y>8 then break end
			if postab[tox][y] == casepiece then insert(candidates,{tox,y}) end
			if postab[tox][y] ~= ' ' then break end
		end
	elseif frompiece == 'N' then
		local x = tox ; local y = toy
		local moves = {{1,2},{2,1},{2,-1},{1,-2},{-1,-2},{-2,-1},{-2,1},{-1,2}}
		for i,v in ipairs(moves) do
			x = tox + v[1] ; y = toy + v[2]
			if x>0 and y>0 and x<9 and y<9 then
				if postab[x][y]==casepiece then insert(candidates,{x,y}) end
			end
		end
	elseif frompiece == 'B' then
		local x = tox ; local y = toy
		while true do
			x = x-1 ; y = y-1
			if x<1 or y<1 then break end
			if postab[x][y] == casepiece then insert(candidates,{x,y}) end
			if postab[x][y] ~= ' ' then break end
		end
		x = tox ; y = toy
		while true do
			x = x-1 ; y = y+1
			if x<1 or y>8 then break end
			if postab[x][y] == casepiece then insert(candidates,{x,y}) end
			if postab[x][y] ~= ' ' then break end
		end
		x = tox ; y = toy
		while true do
			x = x+1 ; y = y-1
			if x>8 or y<1 then break end
			if postab[x][y] == casepiece then insert(candidates,{x,y}) end
			if postab[x][y] ~= ' ' then break end
		end
		x = tox ; y = toy
		while true do
			x = x+1 ; y = y+1
			if x>8 or y>8 then break end
			if postab[x][y] == casepiece then insert(candidates,{x,y}) end
			if postab[x][y] ~= ' ' then break end
		end

	elseif frompiece == 'Q' then
		local x = tox ; local y = toy
		while true do
			x = x-1 ; y = y-1
			if x<1 or y<1 then break end
			if postab[x][y] == casepiece then insert(candidates,{x,y}) end
			if postab[x][y] ~= ' ' then break end
		end
		x = tox ; y = toy
		while true do
			x = x-1 ; y = y+1
			if x<1 or y>8 then break end
			if postab[x][y] == casepiece then insert(candidates,{x,y}) end
			if postab[x][y] ~= ' ' then break end
		end
		x = tox ; y = toy
		while true do
			x = x+1 ; y = y-1
			if x>8 or y<1 then break end
			if postab[x][y] == casepiece then insert(candidates,{x,y}) end
			if postab[x][y] ~= ' ' then break end
		end
		x = tox ; y = toy
		while true do
			x = x+1 ; y = y+1
			if x>8 or y>8 then break end
			if postab[x][y] == casepiece then insert(candidates,{x,y}) end
			if postab[x][y] ~= ' ' then break end
		end
		x = tox
		while true do
			x = x-1
			if x<1 then break end
			if postab[x][toy] == casepiece then insert(candidates,{x,toy}) end
			if postab[x][toy] ~= ' ' then break end
		end
		x = tox
		while true do
			x = x+1
			if x>8 then break end
			if postab[x][toy] == casepiece then insert(candidates,{x,toy}) end
			if postab[x][toy] ~= ' ' then break end
		end
		y = toy
		while true do
			y = y-1
			if y<1 then break end
			if postab[tox][y] == casepiece then insert(candidates,{tox,y}) end
			if postab[tox][y] ~= ' ' then break end
		end
		y = toy
		while true do
			y = y+1
			if y>8 then break end
			if postab[tox][y] == casepiece then insert(candidates,{tox,y}) end
			if postab[tox][y] ~= ' ' then break end
		end
	elseif frompiece == 'K' then
		local x = tox ; local y = toy
		local moves = {{1,1},{1,0},{1,-1},{0,-1},{-1,-1},{-1,0},{-1,1},{0,1}}
		for i,v in ipairs(moves) do
			x = tox + v[1] ; y = toy + v[2]
			if x>0 and y>0 and x<9 and y<9 then
				if postab[x][y]==casepiece then insert(candidates,{x,y}) end
			end
		end
	else
	  return nil, 'unrecognised frompiece '..frompiece
	end
	if string.match(clue, '[a-h]') then
		local abcdefgh2x = {a=1,b=2,c=3,d=4,e=5,f=6,g=7,h=8}
		local clue_x = abcdefgh2x[clue]
		local tmp = {}
		for i,xy in ipairs(candidates) do
			if xy[1] == clue_x then insert(tmp, xy) end
		end
		candidates = tmp
	elseif string.match(clue, '[1-8]') then
		local clue_y = tonumber(clue)
		local tmp = {}
		for i,xy in ipairs(candidates) do
			if xy[2] == clue_y then insert(tmp, xy) end
		end
		candidates = tmp
	end
	-- reject any candidates that illegally put the king in check 1.5
	local legals = {}
	for i,xy in ipairs(candidates) do   -- 1.5
		local fentab_copy = deepcopy(fentab)
		fentab_copy['postab'][tox][toy] = postab[xy[1]][xy[2]]
		fentab_copy['postab'][xy[1]][xy[2]] = ' '
		local kingpiece = 'K'
		if fentab['active'] == 'b' then kingpiece = 'k' end
		if not M.is_check(kingpiece, fentab_copy) then
			table.insert(legals, xy)
		end
	end
	-- check that there's just one candidate move
	local function move_msg ()   -- 1.5
		local msg = 'move ' .. fentab['movenum'] .. '.'
		if fentab['active'] == 'b' then msg = msg .. '..' end
		return msg..' '..move..' is '
	end
	if     #legals == 0 then return nil, move_msg() .. 'impossible'
	elseif #legals == 1 then return legals[1][1], legals[1][2]
	else   return nil, move_msg() .. 'ambiguous'
	end
end

function M.fenstr_move (fenstr, move)
	local fentab = M.fenstr2tab(fenstr)
	-- local postab = M.posstr2postab(fentab['posstr'])
	local postab = fentab['postab']
	local fromx, fromy, tox, toy, frompiece, topiece
	local promotion = nil
	local pawncapture = false
	-- tolerate trailing + ! ? ?
	if not move then return nil, 'fenstr_move move=nil' end
	move = string.gsub(move, '[+!?]+$', '') --  1.4
	move = string.gsub(move, '[%s\n\r]+', '')
	local i,j = string.find(move,'=[RNBQ]')
	if i then -- detect a promotion and remember it for later
		promotion = string.sub(move, i+1, i+1)
		move      = string.sub(move,  1,  i-1)
	end	
	if string.match(move, '^([a-h][1-8])[-x]([a-h][1-8])$') then   -- e2-e4
		local from, to = string.match(move, '^([a-h][1-8])[-x]([a-h][1-8])$')
		fromx, fromy = sq2xy(from)
		tox,   toy   = sq2xy(to)
		frompiece = postab[fromx][fromy]
		topiece   = postab[tox][toy]
		if frompiece == ' ' then
			return nil, move..' but '..from..' was empty'
		end
	elseif string.match(move, '^([RNBQK])([a-h1-8]?)x?([a-h][1-8])$') then
		local clue, to     -- Nc3
		frompiece, clue, to
		  = string.match(move, '^([RNBQK])([a-h1-8]?)x?([a-h][1-8])$')
-- print('frompiece =',frompiece)
		tox,  toy   = sq2xy(to)
		--fromx,fromy=assert(frompiece2xy(frompiece,tox,toy,fentab,clue,move))
		fromx,fromy = frompiece2xy(frompiece,tox,toy,fentab,clue,move)
		if not fromx then return nil, fromy end
		topiece   = postab[tox][toy]
		frompiece = postab[fromx][fromy]
	elseif string.match(move, '^([a-h][1-8])$') then   -- e4 pawn-move
		local to = string.match(move, '^([a-h][1-8])$')
		tox,   toy   = sq2xy(to)
		topiece   = postab[tox][toy]
		fromx = tox
		if topiece ~= ' ' then return nil, move..' square is not empty' end
		if fentab['active'] == 'w' then
			fromy = toy - 1
			frompiece = postab[fromx][fromy]
			if frompiece == ' ' then
				if fromy == 3 then
					fromy = 2
					frompiece = postab[fromx][fromy]
				end
			end
			if frompiece ~= 'P' then
				return nil, 'there was no pawn for '..move
			end
		else   -- black to move
			fromy = toy + 1
			frompiece = postab[fromx][fromy]
			if frompiece == ' ' then
				if fromy == 6 then
					fromy = 7
					frompiece = postab[fromx][fromy]
				end
			end
			if frompiece ~= 'p' then
				return nil, 'there was no pawn for '..move
			end
		end
	elseif string.match(move, '^([a-h])x?([a-h][1-8])$') then   -- exd5, ed5
		local from, to = string.match(move, '^([a-h])x?([a-h][1-8])$')
		fromx, fromy = sq2xy(from..'1')
if M.dbg then warn('1 fromx=',fromx,' fromy=',fromy) end
		tox,   toy   = sq2xy(to)
if M.dbg then warn('2 tox=',tox,' toy=',toy) end
		if fentab['active'] == 'w' then fromy=toy-1 else fromy=toy+1 end
if M.dbg then warn('3 fromx=',fromx,' fromy=',fromy) end
		frompiece = postab[fromx][fromy]
		topiece   = postab[tox][toy]
if M.dbg then warn('3 frompiece=',frompiece,' topiece="',topiece,'"') end
		-- could check that if active=='w' then frompiece=='P' and bzw.
		-- could check that if active=='w' then topiece is [prnbqk] and bzw.
		if frompiece == ' ' then
			return nil, move..' but '..from..' was empty 1'
		end
		if frompiece ~= 'P' and frompiece ~= 'p' then
			return nil, move..' but '..from..' was not a pawn'
		end
		if topiece == ' ' and fentab['enpassant'] == '-' then
			return nil, move..' but '..to..' was empty 2'
		end	
		pawncapture = true
	elseif string.match(move, '^O%-?O%-?O$') then   -- O-O-O
		if fentab['active']=='w' then
			fentab['castling'] = string.gsub(fentab['castling'], 'KQ', '')
			if postab[2][1] ~= ' ' or postab[3][1] ~= ' '
			  or postab[4][1] ~= ' ' then
				return nil, move..' but b1 c1 and d1 not empty'
			end
			if postab[5][1] ~= 'K' or postab[1][1] ~= 'R' then
				return nil, move..' but e1 and h1 not present'
			end
			postab[5][1] = ' ' ; postab[4][1] = 'R'
			postab[3][1] = 'K' ; postab[1][1] = ' '
		else
			if postab[2][8] ~= ' ' or postab[3][8] ~= ' '
			  or postab[4][2] ~= ' ' then
				return nil, move..' but b8 c8 and d8 not empty'
			end
			if postab[5][8] ~= 'k' or postab[1][8] ~= 'r' then
				return nil, move..' but a8 and e8 not present'
			end
			postab[5][1] = ' ' ; postab[4][8] = 'r'
			postab[3][8] = 'k' ; postab[1][8] = ' '
			fentab['castling'] = string.gsub(fentab['castling'], 'kq', '')
		end
	elseif string.match(move, '^O%-?O$') then   -- O-O
		if fentab['active']=='w' then
			fentab['castling'] = string.gsub(fentab['castling'], 'KQ', '')
			if postab[6][1] ~= ' ' or postab[7][1] ~= ' ' then
				return nil, move..' but f1 and g1 not empty'
			end
			if postab[5][1] ~= 'K' or postab[8][1] ~= 'R' then
				return nil, move..' but e1 and h1 not present'
			end
			postab[5][1] = ' ' ; postab[6][1] = 'R'
			postab[7][1] = 'K' ; postab[8][1] = ' '
		else
			if postab[6][8] ~= ' ' or postab[7][8] ~= ' ' then
				return nil, move..' but f8 and g8 not empty'
			end
			if postab[5][8] ~= 'k' or postab[8][8] ~= 'r' then
				return nil, move..' but e8 and h8 not present'
			end
			postab[5][8] = ' ' ; postab[6][8] = 'r'
			postab[7][8] = 'k' ; postab[8][8] = ' '
			fentab['castling'] = string.gsub(fentab['castling'], 'kq', '')
		end
	elseif string.match(move, '^0%-1$') or string.match(move, '^1%-0$')
	  or string.match(move, '^1/2$') then
		return M.fentab2str(fentab)
	else
		return nil, 'unrecognised move #('..move..')#'
	end
	if frompiece and topiece then
		if fentab['active']=='w' and not string.match(frompiece,'[PRNBQK]') or
	   	fentab['active']=='b' and not string.match(frompiece,'[prnbqk]') then
			return nil, move..' wrong colour, wrong player on move'
		end
		if fentab['active']=='w' and string.match(topiece,'[PRNBQK]') or
	   	fentab['active']=='b' and string.match(topiece,'[prnbqk]') then
			return nil, move.." ".." can't take your own piece "..topiece
		end
		if (pawncapture or string.find(move,'x')) and topiece == ' ' then
			if frompiece == 'P' or frompiece == 'p' then  -- en passant ?
				tox, toy = sq2xy(fentab['enpassant'])
--[[
-- if M.dbg then warn(
print('move =', move)
print(M.fentab2str(fentab))
print(M.fenstr2asciidiag(M.fentab2str(fentab)))
print(
  '4 enpassant=',fentab['enpassant'],' tox=',tox,' toy=',toy,' fromy=',fromy
) -- end
]]
				postab[tox][fromy] = ' '  -- should check legality
			else
				return nil, move.." can't take an empty square"  -- XXX
			end
		end
		if     frompiece == 'P' and fromy == 2 and toy == 4 then
			fentab['enpassant'] = xy2sq(tox, 3)
		elseif frompiece == 'p' and fromy == 7 and toy == 5 then
			fentab['enpassant'] = xy2sq(tox, 6)
		else
			fentab['enpassant'] = '-'
		end
		if promotion then
			if fentab['active'] == 'w' then
				if frompiece ~= 'P' then
					return nil, "can't promote a "..frompiece
				end
				if toy ~= 8 then
					return nil, "can't promote on rank"..tostring(toy)
				end
				frompiece = promotion
			else
				if frompiece ~= 'p' then
					return nil, "can't promote a "..frompiece
				end
				if toy ~= 1 then
					return nil, "can't promote on rank"..tostring(toy)
				end
				frompiece = string.lower(promotion)
			end
		end
		postab[tox][toy] = frompiece
		postab[fromx][fromy] = ' '
	end
	--fentab['posstr'] = M.postab2posstr(postab)
	if fentab['castling'] == '' then fentab['castling'] = '-' end
	if fentab['active'] == 'w' then fentab['active'] = 'b'
	else
		fentab['active'] = 'w'
		fentab['movenum'] = round(fentab['movenum'] + 1)
	end
	if frompiece == 'p' or frompiece =='P' or topiece ~= ' ' then
		fentab['fiftymove'] = '0'
	else
		fentab['fiftymove']=tostring(round(tonumber(fentab['fiftymove'])+1))
	end
	return M.fentab2str(fentab)
end

function M.pgn_moves(pgntext)
	pgntext = string.gsub(pgntext, '%[.*%]', '')
	pgntext = string.gsub(pgntext, '%d+%. ?', '')
	pgntext = string.gsub(pgntext, '^%s+', '')
	pgntext = string.gsub(pgntext, '%s+$', '')
	local moves = split(pgntext, '%s+')
	local i = 0
	return function()
		i = i + 1
		return moves[i]
	end
end

--[[

-- =item I<posstr2postab (pos)>

-- This splits the C<fentab['posstr']> string into a 2D array of the
-- squares of the position.
-- Both the rank index and the column index are numbers:
-- C<postab[ncol][nrank]>

-- =item I<postab2posstr (postab)>

-- This reverse the previous function, returning a string
-- which can be used to update the C<fentab['posstr']> value.

]]

return M

--[=[

=pod

=head1 NAME

fen.lua - This module manipulates FEN files.

=head1 SYNOPSIS

 local FEN = require 'chess.fen'
 french = 'rnbqkbnr/ppp2ppp/4p3/3p4/3PP3//PPP2PPP/RNBQKNR w KQkq - 0 3'
 newfen = FEN.fenstr_move(french, 'Nc3')
 print(newfen)
 print(FEN.fenstr2asciidiag(newfen))

 f = FEN.fenstr2tab(french)
 print(FEN.fentab2str(f))

=head1 DESCRIPTION

This module manipulates chess positions in FEN notation.

It is used by B<pgn2eco> to look for positions arising in
C</home/eco/ECOMast.txt> and report their ECO numbers,
by keeping fenstr==>eco database of positions and their ECO numbers.
B<pgn2eco> can be used, for example, to find the ECO numbers
corresponding to positions that arise in opening-repertoire books.

=head1 FUNCTIONS

=over 3

=item I<doc ()>

This returns a multi-line string documenting the FEN notation.


=item I<fenstr2asciidiag (fenstr)>

This accepts a position in FEN format
and returns a multiline string which can be printed on C</dev/tty>

=item I<fenstr_move (fenstr, move)>

This accepts a position in FEN format,
and an individual move in PGN syntax,
then applies the move to the position
and returns the resulting FEN string.

=item I<fenstr2key(fenstr)>

This accepts a position in FEN format,
and returns a somewhat simplified version of it.
Specifically, the move-number and the fifty-move-number are ommitted,
and the enpassant square is reset to '-' if there is no opposing
pawn available to capture on that square.

The returned string can be used as a B<key>
to index the position in a database,
for example of opening variations or endgame positions,
where it matters not if the position has arisen after 9 moves or after 8
(eg: the Sveshnikov)
or has arisen by C<1.d4 f5 2.g3> or by C<1.g3 f5 2.d4>

=item I<pgn_moves (pgntext)>

This accepts a game, or segment of a game, in PGN notation,
and returns an array of the moves.

=back

=head2 LOWER-LEVEL FUNCTIONS

=over 3

=item I<fenstr2tab (fenstr)>

This splits a FEN string into a table of its fields, and returns the table.
These table values are all strings; their keys are
C<'postab', 'active', 'castling', 'enpassant', 'fiftymove', 'movenum'>

The key called C<'postab'> splits the position-string
into a 2D array of the squares of the position.
Both the rank index and the column index are numbers:
C<postab[ncol][nrank]>

=item I<fentab2str (fentab)>

This performs the reverse conversion, returning the FEN string.
During this conversion, the contents of the C<fentab['postab']>
are converted back into position-string.

=back

=head1 FEN NOTATION
 
    https://en.wikipedia.org/wiki/Forsyth%E2%80%93Edwards_Notation
    A FEN record contains six fields.
    The separator between fields is a space. The fields are:
    1) Piece placement (from white's perspective). Each rank is described,
      starting with rank 8 and ending with rank 1; within each rank, the
      contents of each square are described from file "a" through file "h".
      White pieces are designated using upper-case letters ("PNBRQK") while
      black pieces use lowercase ("pnbrqk"). Empty squares are noted using
      digits 1 through 8 (the number of empty squares); "/" separates ranks.
    2) Active color. "w" means White moves next, "b" means Black.
    3) Castling availability. If neither side can castle, this is "-".
      Otherwise, this has one or more letters: "K" (White can castle
      kingside), "Q" (White can castle queenside), "k" (Black can
	  castle kingside), and/or "q" (Black can castle queenside).
    4) En passant target square in algebraic notation. If there's no
      en passant target square, this is "-". If a pawn has just made
      a two-square move, this is the position "behind" the pawn.
      This is recorded regardless of whether there is
	  a pawn in position to make an en passant capture.
    5) Halfmove clock: This is the number of halfmoves since the
	  last capture or pawn advance. This is used to determine
	  if a draw can be claimed under the fifty-move rule.
    6) Fullmove number: The number of the full move.
	  It starts at 1, and is incremented after Black's move.

=head1 INSTALLATION

This module is available as a I<luarock> and should be
installed by

  luarocks install chess-fen

=head1 CHANGES

 20181012 1.5 frompiece2xy() rejects candidates if pinned to the king
 20180908 1.4 fenstr_move() allows +?!
 20180901 1.3 fenstr_move() reports impossible moves better
 20180408 1.2 first released version
 20180407 1.1 add fenstr2key()
 20180315 1.0 initial prototype

=head1 AUTHOR

Peter J Billam, http://www.pjb.com.au/comp/contact.html

=head1 SEE ALSO

 http://en.wikipedia.org/wiki/Forsyth-Edwards_Notation
 http://www.pjb.com.au/comp/lua/fen.html
 http://www.pjb.com.au/comp/lua/free/pgn2fen
 http://www.pjb.com.au/comp/lua/free/pgn2eco
 http://www.pjb.com.au/comp/free/fen2img
 https://github.com/jhlywa/chess.js/blob/master/README.md
 http://homepages.di.fc.ul.pt/~jpn/gv/pstools.htm
 http://homepages.di.fc.ul.pt/~jpn/gv/tabs/chessfont.zip
 http://www.pjb.com.au/

=cut

]=]


