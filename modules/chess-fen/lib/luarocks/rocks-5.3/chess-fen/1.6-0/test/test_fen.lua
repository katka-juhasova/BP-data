#!/usr/local/bin/lua
---------------------------------------------------------------------
--     This Lua5 script is Copyright (c) 2018, Peter J Billam      --
--                       www.pjb.com.au                            --
--  This script is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
local Version = '1.4  for Lua5'
local VersionDate  = '08sep2018';
local Synopsis = [[
test_fen.lua [options] [filenames]
]]

-- local FEN = require 'chess.fen'
local FEN = require 'fen'
local DBM = require 'gdbm'

---------------------------------------------------------------------
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
function warn(...)
    local a = {}
    for k,v in pairs{...} do table.insert(a, tostring(v)) end
    io.stderr:write(table.concat(a),'\n') ; io.stderr:flush()
end
function die(...) warn(...);  os.exit(1) end

local eps = .000000001
function equal(x, y)   -- print('#x='..#x..' #y='..#y)
	if #x ~= #y then return false end
	local i; for i=1,#x do
		if math.abs(x[i]-y[i]) > eps then return false end
	end
	return true
end
local Test = 12 ; local i_test = 0; local Failed = 0;
function ok(b,s)
	i_test = i_test + 1
	if b then
		io.write('ok '..i_test..' - '..s.."\n")
		return true
	else
		io.write('not ok '..i_test..' - '..s.."\n")
		Failed = Failed + 1
		return false
	end
end

---------------------------------------------------------------------

local iarg=1; while arg[iarg] ~= nil do
	if not string.find(arg[iarg], '^-[a-z]') then break end
	local first_letter = string.sub(arg[iarg],2,2)
	if first_letter == 'v' then
		local n = string.gsub(arg[0],"^.*/","",1)
		print(n.." version "..Version.."  "..VersionDate)
		os.exit(0)
	elseif first_letter == 'c' then
		whatever()
	else
		local n = string.gsub(arg[0],"^.*/","",1)
		print(n.." version "..Version.."  "..VersionDate.."\n\n"..Synopsis)
		os.exit(0)
	end
	iarg = iarg+1
end

local correct

local start = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
--local f = FEN.fenstr2tab(start)
local newfen = start
local msg
local function move (algebraic)
    newfen,msg = FEN.fenstr_move(newfen, algebraic)
	if not newfen then
		die('fenstr_move: algebraic=',algebraic,' msg=',msg)
	end
	print(algebraic)
    print(newfen)
    -- print(FEN.fen2asciidiag(newfen))
end

newfen = assert(FEN.fenstr_move(start, 'd2-d3'))
correct = 'rnbqkbnr/pppppppp/8/8/8/3P4/PPP1PPPP/RNBQKBNR b KQkq - 0 1'
if not ok(newfen == correct, 'd2-d3') then
	warn(newfen..' should be\n'..correct)
end

newfen = assert(FEN.fenstr_move(start, 'd3'))
correct = 'rnbqkbnr/pppppppp/8/8/8/3P4/PPP1PPPP/RNBQKBNR b KQkq - 0 1'
if not ok(newfen == correct, 'd3') then
	warn(newfen..' should be\n'..correct)
end

newfen = assert(FEN.fenstr_move(start, 'd2-d4'))
correct = 'rnbqkbnr/pppppppp/8/8/3P4/8/PPP1PPPP/RNBQKBNR b KQkq d3 0 1'
if not ok(newfen == correct, 'd2-d4') then
	warn(newfen..' should be\n'..correct)
end

newfen = assert(FEN.fenstr_move(start, 'd4'))
correct = 'rnbqkbnr/pppppppp/8/8/3P4/8/PPP1PPPP/RNBQKBNR b KQkq d3 0 1'
if not ok(newfen == correct, 'd4') then
	warn(newfen..' should be\n'..correct)
end

newfen = assert(FEN.fenstr_move(start, 'd4'))
newfen = assert(FEN.fenstr_move(newfen,'g6!?'))
correct = 'rnbqkbnr/pppppp1p/6p1/8/3P4/8/PPP1PPPP/RNBQKBNR w KQkq - 0 2'
if not ok(newfen == correct, 'd4 g6!?') then
	warn(newfen..' should be\n'..correct)
end

newfen = assert(FEN.fenstr_move(start, 'd4'))
newfen = assert(FEN.fenstr_move(newfen,'g5'))
correct = 'rnbqkbnr/pppppp1p/8/6p1/3P4/8/PPP1PPPP/RNBQKBNR w KQkq g6 0 2'
if not ok(newfen == correct, 'd4 g5') then
	warn(newfen..' should be\n'..correct)
end

newfen = assert(FEN.fenstr_move(start, 'Nc3'))
newfen = assert(FEN.fenstr_move(newfen,'Nf6'))
correct = 'rnbqkb1r/pppppppp/5n2/8/8/2N5/PPPPPPPP/R1BQKBNR w KQkq - 2 2'
if not ok(newfen == correct, 'Nc3 Nf6') then
	warn(newfen..' should be\n'..correct)
end

local pgn = '1. Nf3 d5 2. g3 d4 3. c4'
newfen = start
for v in FEN.pgn_moves(pgn) do newfen = assert(FEN.fenstr_move(newfen, v)) end
correct = 'rnbqkbnr/ppp1pppp/8/8/2Pp4/5NP1/PP1PPP1P/RNBQKB1R b KQkq c3 0 3'
if not ok(newfen == correct, pgn) then
	print( FEN.fenstr2asciidiag(newfen) )
	warn(newfen..' should be\n'..correct)
end

-- FEN.dbg = true
pgn = '1. Nf3 d5 2. g3 d4 3. c4 dc3'
newfen = start
for v in FEN.pgn_moves(pgn) do newfen = assert(FEN.fenstr_move(newfen, v)) end
correct = 'rnbqkbnr/ppp1pppp/8/8/8/2p2NP1/PP1PPP1P/RNBQKB1R w KQkq - 0 4'
if not ok(newfen == correct, pgn) then
	print( FEN.fenstr2asciidiag(newfen) )
	warn(newfen..' should be\n'..correct)
end
-- FEN.dbg = false

pgn = '1. e4 e6 2. d4 d5 3. e5 f5 4. exf6'
newfen = start
for v in FEN.pgn_moves(pgn) do newfen = assert(FEN.fenstr_move(newfen, v)) end
correct = 'rnbqkbnr/ppp3pp/4pP2/3p4/3P4/8/PPP2PPP/RNBQKBNR b KQkq - 0 4'
if not ok(newfen == correct, pgn) then
	print( FEN.fenstr2asciidiag(newfen) )
	warn(newfen..' should be\n'..correct)
end

pgn = '1. e4 e5 2. Bb5 Bb4 3. Ba4 Ba5 4. Bb3 Bb6 5.Bc4 Bc5'
newfen = start
for v in FEN.pgn_moves(pgn) do newfen = assert(FEN.fenstr_move(newfen, v)) end
correct = 'rnbqk1nr/pppp1ppp/8/2b1p3/2B1P3/8/PPPP1PPP/RNBQK1NR w KQkq - 8 6'
if not ok(newfen == correct, pgn) then
	print( FEN.fenstr2asciidiag(newfen) )
	warn(newfen..' should be\n'..correct)
end

pgn = '1. e4 c6 2. Qh5 Qa5 3. Qh3 Qa3 4. Qh6 Qa6 5.Qe3 Qc4 6.Qa3 Qe6'
newfen = start
for v in FEN.pgn_moves(pgn) do newfen = assert(FEN.fenstr_move(newfen, v)) end
correct = 'rnb1kbnr/pp1ppppp/2p1q3/8/4P3/Q7/PPPP1PPP/RNB1KBNR w KQkq - 10 7'
if not ok(newfen == correct, pgn) then
	print( FEN.fenstr2asciidiag(newfen) )
	warn(newfen..' should be\n'..correct)
end

pgn = [[1.e4 e5 2.Nf3 Nf6 3.Nxe5 d6 4.Nf3 Nxe4 5.Qe2 Qe7 6.Nc3 Nxc3
        7.dxc3 Qxe2+ 8.Bxe2 Nc6 9.Be3 Be7 10.O-O-O O-O 11.Rhe1]]
newfen = start
for v in FEN.pgn_moves(pgn) do newfen = assert(FEN.fenstr_move(newfen, v)) end
correct = 'r1b2rk1/ppp1bppp/2np4/8/8/2P1BN2/PPP1BPPP/2KRR3 b - - 1 11'
if not ok(newfen == correct,
'1.e4 e5 2.Nf3 Nf6 3.Nxe5 d6 ... 9.Be3 Be7 10.O-O-O O-O 11.Rhe1') then
	print( FEN.fenstr2asciidiag(newfen) )
	warn(newfen..' should be\n'..correct)
end

pgn = [[
[Event "Aeroflot Open A 2018"]
[Site "Moscow RUS"]
[Date "2018.02.26"]
[Round "7.22"]
[White "Mikaelyan, Arman"]
[Black "Aravindh, Chithambaram VR."]
[Result "0-1"]
[WhiteTitle "GM"]
[BlackTitle "GM"]
[WhiteElo "2486"]
[BlackElo "2617"]
[ECO "B06"]
[Opening "Robatsch (modern) defence"]
[WhiteFideId "13304852"]
[BlackFideId "5072786"]
[EventDate "2018.02.20"]

1. d4 g6 2. e4 Bg7 3. Nf3 d6 4. Bc4 Nf6 5. Qe2 O-O 6. O-O Bg4 7. e5 dxe5 8. dxe5
Nd5 9. Nbd2 c6 10. h3 Bf5 11. Nd4 Qc8 12. f4 Bd7 13. a4 Nb6 14. Bb3 c5 15. Nb5
Na6 16. c3 Be6 17. Bc2 Bf5 18. Bxf5 Qxf5 19. Ne4 Rfd8 20. a5 Nd5 21. Na3 Ndc7
22. Nc4 Rd5 23. Nf2 Rd7 24. Qf3 Qe6 25. b3 Rad8 26. Ne4 Rd3 27. Qe2 f5 28. Nf2
R3d7 29. Be3 Qc6 30. h4 Nd5 31. Bd2 Nac7 32. Qf3 Ne6 33. Nh3 Qb5 34. Rfb1 Ndc7
35. Qf2 Rd3 36. Ng5 Bh6 37. Ra2 Qa6 38. Rc2 b5 39. axb6 axb6 40. Re1 b5 41. Nb2
R3d7 42. Be3 Qa3 43. c4 Bxg5 44. hxg5 Qxb3 45. cxb5 Nxb5 46. Bxc5 Nxc5 47. Rxc5
Rd2 48. Re2 Qxb2 49. Rxd2 Rxd2 50. Rc8+ Kf7 51. Qh4 Ke6 52. Qxh7 Qd4+ 0-1
]]
newfen = start
for v in FEN.pgn_moves(pgn) do newfen = assert(FEN.fenstr_move(newfen, v)) end
correct = '2R5/4p2Q/4k1p1/1n2PpP1/3q1P2/8/3r2P1/6K1 w - - 1 53'
if not ok(newfen == correct, 'pgn_moves()') then
	warn(newfen..' should be\n'..correct)
end

local chk = '4k3/8/4R3/8/8/4R3/8/4K3 w KQkq - 0 3'
ok(FEN.is_check('k', FEN.fenstr2tab(chk)),'black is checked on a file')
chk = '4k3/8/4r3/8/8/4R3/8/4K3 w KQkq - 0 3'
ok(not FEN.is_check('k', FEN.fenstr2tab(chk)),'black is not checked on a file')
chk = '4k3/8/4r3/8/8/8/8/4K3 w KQkq - 0 3'
ok(FEN.is_check('K', FEN.fenstr2tab(chk)),'white is checked on a file')
chk = '4k3/8/4r3/8/8/8/8/3K4 w KQkq - 0 3'
ok(not FEN.is_check('K', FEN.fenstr2tab(chk)),'white is not checked on a file')

chk = '8/1K6/1R4k1/4r3/8/8/8/8 w KQkq - 0 3'
ok(FEN.is_check('k', FEN.fenstr2tab(chk)),'black is checked on a rank')
chk = '8/1K6/1R3Pk1/4r3/8/8/8/8 w KQkq - 0 3'
ok(not FEN.is_check('k', FEN.fenstr2tab(chk)),'black is not checked on a rank')
chk = '8/1k6/1r4K1/4R3/8/8/8/8 w KQkq - 0 3'
ok(FEN.is_check('K', FEN.fenstr2tab(chk)),'white is checked on a rank')
chk = '8/1k6/1r3PK1/4Q3/8/8/8/8 w KQkq - 0 3'
ok(not FEN.is_check('K', FEN.fenstr2tab(chk)),'white is not checked on a rank')

chk = '1K6/8/2k5/8/4B3/8/8/8 w KQkq - 0 3'
ok(FEN.is_check('k', FEN.fenstr2tab(chk)),'black is checked on a ++diagonal')
chk = '1K6/8/5Q2/8/3k4/8/8/8 w KQkq - 0 3'
ok(FEN.is_check('k', FEN.fenstr2tab(chk)),'black is checked on a +-diagonal')
chk = '1K6/8/2B5/8/4k3/8/8/8 w KQkq - 0 3'
ok(FEN.is_check('k', FEN.fenstr2tab(chk)),'black is checked on a --diagonal')
chk = '1K6/8/5k2/8/3Q4/8/8/8 w KQkq - 0 3'
ok(FEN.is_check('k', FEN.fenstr2tab(chk)),'black is checked on a -+diagonal')

pgn = '1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. e3 c5 5. Ne2'
newfen = start
for v in FEN.pgn_moves(pgn) do newfen = assert(FEN.fenstr_move(newfen, v)) end
correct = 'rnbqk2r/pp1p1ppp/4pn2/2p5/1bPP4/2N1P3/PP2NPPP/R1BQKB1R b KQkq - 1 5'
if not ok(newfen == correct,
  'frompiece2xy() rejects candidates that were pinned to the king') then
	warn(newfen..' should be\n'..correct)
end

local p1 = 'rnbqkbnr/pp1ppppp/8/2pP4/8/8/PPP1PPPP/RNBQKBNR w KQkq c6 0 3'
correct  = 'rnbqkbnr/pp1ppppp/8/2pP4/8/8/PPP1PPPP/RNBQKBNR w KQkq c6'
local key = FEN.fentab2key(FEN.fenstr2tab(p1))
ok(key == correct, 'key enpassant c6 as white')

p1       = 'rnbqkbnr/pppp1ppp/8/3Pp3/8/8/PPP1PPPP/RNBQKBNR w KQkq e6 0 3'
correct  = 'rnbqkbnr/pppp1ppp/8/3Pp3/8/8/PPP1PPPP/RNBQKBNR w KQkq e6'
key = FEN.fentab2key(FEN.fenstr2tab(p1))
ok(key == correct, 'key enpassant e6 as white')

p1 = 'rnbqkbnr/pp1ppppp/8/8/2pP4/8/PPP1PPPP/RNBQKBNR b KQkq d3 0 2'
correct  = 'rnbqkbnr/pp1ppppp/8/8/2pP4/8/PPP1PPPP/RNBQKBNR b KQkq d3'
key = FEN.fentab2key(FEN.fenstr2tab(p1))
ok(key == correct, 'key enpassant cd3 as black')

p1 = 'rnbqkbnr/pppp1ppp/8/8/3Pp3/8/PPP1PPPP/RNBQKBNR b KQkq d3 0 2'
correct  = 'rnbqkbnr/pppp1ppp/8/8/3Pp3/8/PPP1PPPP/RNBQKBNR b KQkq d3'
key = FEN.fenstr2key(p1)
ok(key == correct, 'key enpassant ed3 as black')

      p1 = 'rnbqkbnr/ppppp1pp/8/5p2/3P4/5N2/PPP1PPPP/RNBQKB1R b KQkq d3 0 2'
local p2 = 'rnbqkbnr/ppppp1pp/8/5p2/3P4/5N2/PPP1PPPP/RNBQKB1R b KQkq - 0 2'
local key1 = FEN.fenstr2key(p1)
local key2 = FEN.fenstr2key(p2)
ok(key1 == key2, 'key ignores enpassant when its not possible')

os.exit()

