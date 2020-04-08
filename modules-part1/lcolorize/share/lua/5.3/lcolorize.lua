--[[
    Author: Marek K.

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

    Dieses Programm ist Freie Software: Sie koennen es unter den Bedingungen
    der GNU General Public License, wie von der Free Software Foundation,
    Version 3 der Lizenz oder (nach Ihrer Wahl) jeder neueren
    veroeffentlichten Version, weiter verteilen und/oder modifizieren.

    Dieses Programm wird in der Hoffnung bereitgestellt, dass es nuetzlich sein wird, jedoch
    OHNE JEDE GEWAEHR,; sogar ohne die implizite
    Gewaehr der MARKTFAEHIGKEIT oder EIGNUNG FUER EINEN BESTIMMTEN ZWECK.
    Siehe die GNU General Public License fuer weitere Einzelheiten.

    Sie sollten eine Kopie der GNU General Public License zusammen mit diesem
    Programm erhalten haben. Wenn nicht, siehe <http://www.gnu.org/licenses/>.
--]]

local lcolorize = {}

lcolorize.colors = {
	none = 0,
	black = 30,
	red = 31,
	green = 32,
	yellow = 33,
	blue = 34,
	magenta = 35,
	cyan = 36,
	white = 37
}

function lcolorize.setcolor(o, color, background)
	if color ~= 0 and (color < 30 or color > 37) then
		error("Invalid color! color ~= 0 and (color < 30 or color > 37)") end
	if background ~= 0 and (background < 30 or background > 37) then
		error("Invalid background! background ~= 0 and (background < 30 or background > 37)") end
	if background ~= 0 then background = background + 10 end
	o.write(string.char(27) .. "[" .. color .. ";" .. background .. "m")
end

function lcolorize.reset(o)
	o.write(string.char(27) .. "[0m")
end

return lcolorize