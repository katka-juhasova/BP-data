#!/usr/local/bin/lua

local dbobj = require"dado.object"
local dado = require"dado"
local dbname = arg[1] or "luasql-test"
local user = arg[2]
local pass = arg[3]
local driver = arg[4]

local db = assert (dado.connect (dbname, user, pass, driver))

-- Apagando eventuais sobras
db.conn:execute ("drop table professor")
db.conn:execute ("drop table pessoa")
io.write"."

-- Criando a tabela no banco
assert (db:assertexec ([[
create table pessoa (
	id integer,
	nome varchar(200),
	email varchar(200),
	primary key (id)
)]]))
db:insert ("pessoa", { id = 1, nome = "Fulano", email = "fulano@cafundo.com", })
db:insert ("pessoa", { id = 2, nome = "Beltrano", email = "beltrano@cafundo.com", })
io.write"."

-- Definindo a classe
Pessoa = dbobj:class {
	table_name = "pessoa",
	key_name = { "id" },
	alternate_keys = {
		{ "email" },
	},
	db_fields = { nome = true, email = true, id = true, },

	signature = function (self)
		return self.nome.." ("..self.email..")"
	end,
}
io.write"."

-- Criando uma instancia
local pessoa = Pessoa:new (db, { id = 1 })
assert (rawget (pessoa, "nome") == nil)
assert (rawget (pessoa, "email") == nil)
assert (pessoa.nome == "Fulano")
assert (rawget (pessoa, "nome") == "Fulano")
assert (rawget (pessoa, "email") == "fulano@cafundo.com")
assert (pessoa:signature() == "Fulano (fulano@cafundo.com)")
io.write"."

local p = Pessoa:new (db, { email = "beltrano@cafundo.com" })
assert (rawget (p, "nome") == nil)
assert (rawget (p, "id") == nil)
assert (p.nome == "Beltrano")
assert (rawget (p, "nome") == "Beltrano")
assert (tostring (rawget (p, "id")) == "2")
assert (p:signature() == "Beltrano (beltrano@cafundo.com)")
io.write"."

-- Tentando acrescentar um registro sem chave ao banco
local p = Pessoa:new (db, { nome = "Outro", email = "outro@qualquer.com", })
assert (pcall (p.save, p) == false)
p.id = 3
assert (p:save () == true)
io.write"."

-- Criando outra tabela no banco
assert (db:assertexec ([[
create table professor (
	id integer,
	id_pessoa integer,
	titulacao varchar(100),
	primary key (id),
	foreign key (id_pessoa) references pessoa
)]]))
db:insert ("professor", { id = 1, id_pessoa = "1", titulacao = "Doutor" })
db:insert ("professor", { id = 2, id_pessoa = "2", titulacao = "Mestre" })
io.write"."

-- Definindo outra classe
local function get_nome_email (self, attr)
	self.nome, self.email = self.__dado:select ("nome, email", "pessoa", "id = "..self.id_pessoa)()
	return rawget (self, attr)
end
Professor = Pessoa:class {
	table_name = "professor",
	key_name = { "id" },
	alternate_keys = {
		{ "id_pessoa" },
		{ "nome" },
	},
	db_fields = {
		id = true,
		id_pessoa = true,
		nome = get_nome_email,
		email = get_nome_email,
	},
}
io.write"."

-- Criando uma instancia
local prof = Professor:new (db, { id = 1 })
assert (rawget (prof, "nome") == nil)
assert (rawget (prof, "email") == nil)
assert (prof.nome == "Fulano")
assert (rawget (prof, "nome") == "Fulano")
assert (rawget (prof, "email") == "fulano@cafundo.com")
assert (prof:signature() == "Fulano (fulano@cafundo.com)")
io.write"."

-- Criando outra instancia com atualizacao via chave alternativa
local prof = Professor:new (db, { id_pessoa = "2" })
assert (rawget (prof, "nome") == nil)
assert (rawget (prof, "email") == nil)
assert (prof.nome == "Beltrano")
assert (rawget (prof, "nome") == "Beltrano")
assert (rawget (prof, "email") == "beltrano@cafundo.com")
assert (prof:signature() == "Beltrano (beltrano@cafundo.com)")
io.write"."

print(' '..dbobj._VERSION.." Ok!")
