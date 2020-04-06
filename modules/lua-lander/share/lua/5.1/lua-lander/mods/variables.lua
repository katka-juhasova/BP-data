--
-- Variables
--

--
-- Constants
--
_.PRECISION = 6

--
-- Native Lua functions
-- .. preloaded for speed and version compatibility
--
_.__re      = require 're'     -- Regex module
_.__type    = type
_.__next    = next
--
_.__abs     = math.abs
_.__ceil    = math.ceil
_.__cos     = math.cos
_.__deg     = math.deg
_.__floor   = math.floor
_.__huge    = math.huge
_.__max     = math.max
_.__min     = math.min
_.__pi      = math.pi
_.__rad     = math.rad
_.__sin     = math.sin
_.__sqrt    = math.sqrt
_.__random  = math.random
--
_.__find    = string.find      -- returns position of first pattern in string
_.__format  = string.format
_.__gsub    = string.gsub
_.__len     = string.len       -- returns string length
_.__lower   = string.lower     -- returns string with all chars lowercase
_.__match   = string.match
_.__upper   = string.upper     -- returns string with all chars uppercase
_.__rep     = string.rep       -- returns string of repeating chars
_.__reverse = string.reverse   -- returns string in reverse
_.__sub     = string.sub       -- Returns the substring of s that starts at i and continues until j; i and j can be negative.
_.__gmatch  = string.gmatch
--
_.__insert  = table.insert
_.__remove  = table.remove
_.__sort    = table.sort
--
if _VERSION == 'Lua 5.1' then
    _.__unpack = unpack
else
    _.__unpack = table.unpack
end

--
-- Default Color Palette
-- Inspired by `tailwindcss`
--
_.C = {}
-- Common
_.C['white'] = { 1.0, 1.0, 1.0 }
_.C['black'] = { 0.0, 0.0, 0.0 }
-- Grey
_.C['gray-100'] = { 0.968627, 0.980392, 0.988235 }
_.C['gray-200'] = { 0.929412, 0.949020, 0.968627 }
_.C['gray-300'] = { 0.886275, 0.909804, 0.941176 }
_.C['gray-400'] = { 0.796078, 0.835294, 0.878431 }
_.C['gray-500'] = { 0.627451, 0.682353, 0.752941 }
_.C['gray-600'] = { 0.443137, 0.501961, 0.588235 }
_.C['gray-700'] = { 0.290196, 0.333333, 0.407843 }
_.C['gray-800'] = { 0.176471, 0.215686, 0.282353 }
_.C['gray-900'] = { 0.101961, 0.125490, 0.172549 }
-- Red
_.C['red-100'] = { 1.000000, 0.960784, 0.960784 }
_.C['red-200'] = { 0.996078, 0.843137, 0.843137 }
_.C['red-300'] = { 0.996078, 0.698039, 0.698039 }
_.C['red-400'] = { 0.988235, 0.505882, 0.505882 }
_.C['red-500'] = { 0.960784, 0.396078, 0.396078 }
_.C['red-600'] = { 0.898039, 0.243137, 0.243137 }
_.C['red-700'] = { 0.772549, 0.188235, 0.188235 }
_.C['red-800'] = { 0.607843, 0.172549, 0.172549 }
_.C['red-900'] = { 0.454902, 0.164706, 0.164706 }
-- Orange
_.C['orange-100'] = { 1.000000, 0.980392, 0.941176 }
_.C['orange-200'] = { 0.996078, 0.921569, 0.784314 }
_.C['orange-300'] = { 0.984314, 0.827451, 0.552941 }
_.C['orange-400'] = { 0.964706, 0.678431, 0.333333 }
_.C['orange-500'] = { 0.929412, 0.537255, 0.211765 }
_.C['orange-600'] = { 0.866667, 0.419608, 0.125490 }
_.C['orange-700'] = { 0.752941, 0.337255, 0.129412 }
_.C['orange-800'] = { 0.611765, 0.258824, 0.129412 }
_.C['orange-900'] = { 0.482353, 0.203922, 0.117647 }
-- Yellow
_.C['yellow-100'] = { 1.000000, 1.000000, 0.941176 }
_.C['yellow-200'] = { 0.996078, 0.988235, 0.749020 }
_.C['yellow-300'] = { 0.980392, 0.941176, 0.537255 }
_.C['yellow-400'] = { 0.964706, 0.878431, 0.368627 }
_.C['yellow-500'] = { 0.925490, 0.788235, 0.294118 }
_.C['yellow-600'] = { 0.839216, 0.619608, 0.180392 }
_.C['yellow-700'] = { 0.717647, 0.474510, 0.121569 }
_.C['yellow-800'] = { 0.592157, 0.352941, 0.086275 }
_.C['yellow-900'] = { 0.454902, 0.258824, 0.062745 }
-- Green
_.C['green-100'] = { 0.941176, 1.000000, 0.956863 }
_.C['green-200'] = { 0.776471, 0.964706, 0.835294 }
_.C['green-300'] = { 0.603922, 0.901961, 0.705882 }
_.C['green-400'] = { 0.407843, 0.827451, 0.568627 }
_.C['green-500'] = { 0.282353, 0.733333, 0.470588 }
_.C['green-600'] = { 0.219608, 0.631373, 0.411765 }
_.C['green-700'] = { 0.184314, 0.521569, 0.352941 }
_.C['green-800'] = { 0.152941, 0.403922, 0.286275 }
_.C['green-900'] = { 0.133333, 0.329412, 0.239216 }
-- Blue
_.C['blue-100'] = { 0.921569, 0.972549, 1.000000 }
_.C['blue-200'] = { 0.745098, 0.890196, 0.972549 }
_.C['blue-300'] = { 0.564706, 0.803922, 0.956863 }
_.C['blue-400'] = { 0.388235, 0.701961, 0.929412 }
_.C['blue-500'] = { 0.258824, 0.600000, 0.882353 }
_.C['blue-600'] = { 0.192157, 0.509804, 0.807843 }
_.C['blue-700'] = { 0.168627, 0.423529, 0.690196 }
_.C['blue-800'] = { 0.172549, 0.321569, 0.509804 }
_.C['blue-900'] = { 0.164706, 0.262745, 0.396078 }
-- Purple
_.C['purple-100'] = { 0.980392, 0.960784, 1.000000 }
_.C['purple-200'] = { 0.913725, 0.847059, 0.992157 }
_.C['purple-300'] = { 0.839216, 0.737255, 0.980392 }
_.C['purple-400'] = { 0.717647, 0.580392, 0.956863 }
_.C['purple-500'] = { 0.623529, 0.478431, 0.917647 }
_.C['purple-600'] = { 0.501961, 0.352941, 0.835294 }
_.C['purple-700'] = { 0.419608, 0.274510, 0.756863 }
_.C['purple-800'] = { 0.333333, 0.235294, 0.603922 }
_.C['purple-900'] = { 0.266667, 0.200000, 0.478431 }

--
-- Default values table
--
_.D = {}
_.D['boolean']  = false
_.D['string']   = ''
_.D['number']   = 0
_.D['function'] = (function(v) return v end)
_.D['iteratee'] = (function(v, k) return v end)

--
-- Event listeners
--
_.E = {}

--
-- Increment/decrement table
--
_.I = {}


--
-- Hex/Bin conversion table
--
_.HB = {
    ['0'] = '0000',
    ['1'] = '0001',
    ['2'] = '0010',
    ['3'] = '0011',
    ['4'] = '0100',
    ['5'] = '0101',
    ['6'] = '0110',
    ['7'] = '0111',
    ['8'] = '1000',
    ['9'] = '1001',
    ['a'] = '1010',
    ['b'] = '1011',
    ['c'] = '1100',
    ['d'] = '1101',
    ['e'] = '1110',
    ['f'] = '1111',
    ['0000'] = '0',
    ['0001'] = '1',
    ['0010'] = '2',
    ['0011'] = '3',
    ['0100'] = '4',
    ['0101'] = '5',
    ['0110'] = '6',
    ['0111'] = '7',
    ['1000'] = '8',
    ['1001'] = '9',
    ['1010'] = 'A',
    ['1011'] = 'B',
    ['1100'] = 'C',
    ['1101'] = 'D',
    ['1110'] = 'E',
    ['1111'] = 'F'
}