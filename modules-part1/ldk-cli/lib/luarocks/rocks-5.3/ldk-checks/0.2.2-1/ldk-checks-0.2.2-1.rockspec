rockspec_format = '3.0'

package = 'ldk-checks'
version = '0.2.2-1'
source = {
  url = 'git://github.com/luadevkit/ldk-checks.git',
  branch = '0.2.2'
}
description = {
  summary = 'LDK - function arguments type checking',
  license = 'MIT',
  maintainer = 'info@luadevk.it'
}
dependencies = {
  'lua >= 5.3'
}
build = {
  modules = {
    ['ldk.checks'] = 'csrc/checks.c',
  }
}
