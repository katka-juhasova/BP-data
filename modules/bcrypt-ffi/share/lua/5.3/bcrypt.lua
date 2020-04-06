local ffi = require "ffi"
local ffi_str = ffi.string
local ffi_new = ffi.new

local BCRYPT_MAXSALT = 16
local _PASSWORD_LEN = 256

ffi.cdef [[
void bcrypt_gensalt(uint8_t log_rounds, char *gsalt);

void bcrypt(const char *key, const char *salt, char *encrypted);
]]

local saltbuf = ffi_new("char[?]", 7 + ( BCRYPT_MAXSALT * 4 + 2 ) / 3 + 1)
local digestbuf = ffi_new("char[?]", _PASSWORD_LEN)

local lib = ffi.load "luabcrypt.so"

local _M = {
  _VERSION = "1.0.0",
  _AUTHOR = "Max Metral",
  _LICENSE = "MIT",
  _URL = "https://github.com/gas-buddy/lua-bcrypt-ffi",
}

function _M.digest(plainPassword, rounds)
  if type(plainPassword) ~= "string" then
    error("bad argument #1 to 'digest' (string expected, got "..type(plainPassword)..")", 2)
  elseif type(rounds) ~= "number" then
    error("bad argument #2 to 'digest' (number expected, got "..type(rounds)..")", 2)
  end

  lib.bcrypt_gensalt(rounds, saltbuf)
  lib.bcrypt(plainPassword, saltbuf, digestbuf);

  return ffi_str(digestbuf)
end

function _M.verify(plainPassword, digest)
  if type(plainPassword) ~= "string" then
    error("bad argument #1 to 'verify' (string expected, got "..type(plainPassword)..")", 2)
  elseif type(digest) ~= "string" then
    error("bad argument #2 to 'verify' (string expected, got "..type(digest)..")", 2)
  end

  lib.bcrypt(plainPassword, digest, digestbuf)
  local finalDigest = ffi_str(digestbuf)

  return finalDigest == digest
end

return _M