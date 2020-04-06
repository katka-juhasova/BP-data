-- JWK to PEM

-- Dependencies
local cjson = require "cjson";
local b64 = require "mime".b64;
local unb64 = require "mime".unb64;

-- From Prosodys util.x509
local wrap = ('.'):rep(64);
local envelope = "-----BEGIN %s-----\n%s\n-----END %s-----\n"

local function der2pem(data, typ)
	typ = typ and typ:upper() or "CERTIFICATE";
	data = b64(data);
	return string.format(envelope, typ, data:gsub(wrap, '%0\n', (#data-1)/64), typ);
end

-- Base64url decode
local b64map = { ['-'] = '+', ['_'] = '/' };
local function unb64url(s)
	return (unb64(s:gsub("[-_]", b64map) .. "=="));
end

-- Encoder for a small subset of DER
local function encode_length(length)
	if length < 0x80 then
		return string.char(length);
	elseif length < 0x100 then
		return string.char(0x81, length);
	elseif length < 0x10000 then
		return string.char(0x82, math.floor(length/0x100), length%0x100);
	end
	error("Can't encode lengths over 65535");
end

local function encode_binary_integer(bytes)
	if bytes:byte(1) > 128 then
		-- We currenly only use this for unsigned integers,
		-- however since the high bit is set here, it would look
		-- like a negative signed int, so prefix with zeroes
		bytes = "\0" .. bytes;
	end
	return "\2" .. encode_length(#bytes) .. bytes;
end

local function encode_integer(number)
	if number == 0 then
		return "\2\1\0";
	end
	local bytes = {};
	while number > 0 do
		table.insert(bytes, 1, string.char(number % 0x100));
		number = math.floor(number / 0x100);
	end
	bytes = table.concat(bytes);
	return "\2" .. encode_length(#bytes) .. bytes;
end

local function encode_sequence(array, of)
	local encoded_array = array;
	if of then
		encoded_array = {};
		for i = 1, #array do
			encoded_array[i] = of(array[i]);
		end
	end
	encoded_array = table.concat(encoded_array);

	return string.char(0x30) .. encode_length(#encoded_array) .. encoded_array;
end

local function encode_string(str, typ)
	if str:byte(1) > 128 then str = "\0" .. str; end
	return string.char(typ) .. encode_length(#str) .. str;
end

local function encode_octet_string(str)
	return encode_string(str, 0x04);
end

local function encode_sequence_of_integer(array)
	return encode_sequence(array, encode_binary_integer);
end

-- END OF UTILS

local algorithms = {
	RSA = {
		OID = "\006\009\042\134\072\134\247\013\001\001\001";
		field_order = { 'n', 'e', 'd', 'p', 'q', 'dp', 'dq', 'qi', };
		start = { "\0" };
		parameters = "\5\0";
	};
};
-- TODO other key types

local jwk = cjson.decode(io.read("*a"));
assert(jwk.kty, "Key type must have a 'kty' field specifying key type");
local info = assert(algorithms[jwk.kty], "Unsupported key type");

local der_key = info.start or {};

for _, field in ipairs(info.field_order) do
	if jwk[field] then
		table.insert(der_key, unb64url(jwk[field]));
	else
		io.stderr:write("field ", field, " is missing\n")
		return os.exit(1);
	end
end

-- SEQUENCE of INTEGER
local encoded_key = encode_sequence_of_integer(der_key);

if not info.OID then
	io.write(der2pem(encoded_key, jwk.kty .. " PRIVATE KEY"));
else
	-- SEQUENCE of OID, ANY (NULL for RSA)
	local header = encode_sequence({ info.OID, info.parameters });

	-- SEQUENCE of above SEQUENCE, BIT STRING
	local output = encode_sequence({ encode_integer(0), header, encode_octet_string(encoded_key) });
	-- Is the (int)0 a version number?

	io.write(der2pem(output, "PRIVATE KEY"));
end
