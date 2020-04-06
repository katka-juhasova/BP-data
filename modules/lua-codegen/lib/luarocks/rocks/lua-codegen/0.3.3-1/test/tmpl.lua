return require'CodeGen'{
    top = [[
begin
    ${data/inner()}
end
]],
    inner = [[
    print("${name()} = ${value}");
]],
}
