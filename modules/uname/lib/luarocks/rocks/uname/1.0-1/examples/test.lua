package.cpath = '../?.so' -- set path for C modules
local b = require 'uname'
print(b)

print("-------------- STRINGS --------------")
local sysname, nodename = uname('sysname', 'nodename')
local release, version, machine = uname('release', 'version', 'machine')
print('Sysname', sysname)
print('Nodename', nodename)
print('Release', release)
print('Version', version)
print('Machine', machine)

print()

local distro = uname()
print("-------------- TABLE --------------")
print('Sysname', distro.sysname)
print('Nodename', distro.nodename)
print('Release', distro.release)
print('Version', distro.version)
print('Machine', distro.machine)
