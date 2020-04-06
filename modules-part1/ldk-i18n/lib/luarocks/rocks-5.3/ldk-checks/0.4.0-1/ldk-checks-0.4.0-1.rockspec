rockspec_format = '3.0'

package = 'ldk-checks'
version = '0.4.0-1'
source = {
  url = 'git://github.com/luadevkit/ldk-checks.git',
  branch = '0.4.0'
}
description = {
  summary = 'Function argument checking',
  license = 'MIT',
  maintainer = 'info@luadevk.it'
}
dependencies = {
  'lua >= 5.3'
}
build = {
  modules = {
    ['ldk.checks'] = {
      'csrc/checks.c',
      'csrc/luax.c'
    }
  }
}
test = {
  type = 'busted'
}
