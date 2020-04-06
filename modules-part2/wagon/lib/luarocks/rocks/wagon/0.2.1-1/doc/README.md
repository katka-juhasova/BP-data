
# Wagon

Wagon is a minimalist bundler for Lua rocks. It sets up a local rocktree
in the current directory and directs both Lua and LuaRocks to use that as a
working path for adding and searching for rocks.

Wagon relies on bash to work, which means it's likely only useful on UNIX
systems.

## Similar projects

+ [Moonbox](https://github.com/kernelp4nic/moonbox), which is better written
  and more feature-comprehensive. The only cons are that it does not support
  Lua >= 5.3 and that it uses its own file format for bundling (whereas
  Wagon relies on the community-wide luarocks spec format).

