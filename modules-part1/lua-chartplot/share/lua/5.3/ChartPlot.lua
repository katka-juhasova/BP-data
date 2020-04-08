
--
-- lua-ChartPlot : <https://fperrad.frama.io/lua-ChartPlot/>
--

local error = error
local pairs = pairs
local setmetatable = setmetatable
local tostring = tostring
local type = type
local unpack = table.unpack or unpack
local floor = math.floor
local log = math.log
local max = math.max
local min = math.min

local gd = require'gd'

local _ENV = nil
local m = {}
local mt = {}

function m.new (x, y)
    x = x or 400
    y = y or 300
    local im = gd.create(x, y)
    local colors = {
        white = im:colorAllocate(255, 255, 255),
        black = im:colorAllocate(0, 0, 0),
        red = im:colorAllocate(255, 0, 0),
        green = im:colorAllocate(0, 255, 0),
        blue = im:colorAllocate(0, 0, 255),
    }
    im:colorTransparent(colors.white)
    im:rectangle(0, 0, x-1, y-1, colors.black)
    local obj = {
        _imx = x,
        _imy = y,
        _im = im,

        horGraphOffset = 50,
        vertGraphOffset = 50,

        _xdata = {},
        _xdatamax = 0.0,
        _xdatamin = 0.0,
        _ydata = {},
        _ydatamax = 0.0,
        _ydatamin = 0.0,
        _datastyle = {},
        _tags = {},

        _xmin = 0,
        _xmax = 0,
        _ymin = 0,
        _ymax = 0,
        _xslope = 0,
        _yslope = 0,
        _ax = 0,
        _ay = 0,
        _xstep = 0,
        _ystep = 0,
        _validMinMax = false,

        horAxisLabel = false,
        vertAxisLabel = false,
        title = false,
        _vertTitle = 0,

        xTickLabels = false,
        yTickLabels = false,

        colors = colors,
    }
    return setmetatable(obj, { __index = mt })
end

function mt:setData (xdata, ydata, style)
    style = style and style:lower() or 'line points'
    if #xdata ~= #ydata then
        error("The dataset does not contain an equal number of x and y values.")
    end
    self._xdatamax = max(self._xdatamax, unpack(xdata))
    self._xdatamin = min(self._xdatamin, unpack(xdata))
    self._xdata[#self._xdata+1] = xdata
    self._ydatamax = max(self._ydatamax, unpack(ydata))
    self._ydatamin = min(self._ydatamin, unpack(ydata))
    self._ydata[#self._ydata+1] = ydata
    self._datastyle[#self._datastyle+1] = style
    self._validMinMax = false
end

function mt:setTag (tags)
    self._tags[#self._datastyle] = tags
end

function mt:setGraphOptions (tbl)
    for k, v in pairs(tbl) do
        self[k] = v
        if k:match'^[xy]TickLabels$' then
            for tick in pairs(v) do
                if type(tick) ~= 'number' then
                    error("The axis tick label position " .. tostring(tick) .. " is not a number.")
                end
            end
        end
    end
end

function mt._getScale (n1, n2)
    local _min, _max = 0.0, 0.0
    local step1, step2 = 0.0, 0.0
    if n1 < 0.0 then
        n1 = -n1
        local e = floor(10 * log(n1) / log(10))
        local om = 10.0 ^ floor((e - 4) / 10)
        _min = 10.0 ^ ((e + 1)/10)
        step1 = (_min/om > 15) and 5 * om or om
        _min = -_min
    end
    if n2 > 0.0 then
        local e = floor(10 * log(n2) / log(10))
        local om = 10.0 ^ floor((e - 4) / 10)
        _max = 10.0 ^ ((e + 1)/10)
        step2 = (_max/om > 15) and 5 * om or om
    end
    return max(step1, step2), _min, _max
end

function mt:_getMinMax ()
    if not self._validMinMax then
        self._xstep, self._xmin, self._xmax = self._getScale(self._xdatamin, self._xdatamax)
        self._ystep, self._ymin, self._ymax = self._getScale(self._ydatamin, self._ydatamax)

        self._xslope = (self._imx - 2 * self.horGraphOffset) / (self._xmax - self._xmin)
        self._yslope = (self._imy - 2 * (self.vertGraphOffset + self._vertTitle)) / (self._ymax - self._ymin)
        self._ax = self.horGraphOffset
        self._ay = self._imy - (self.vertGraphOffset + self._vertTitle)

        self._validMinMax = true
    end
end

function mt:data2px (x, y)
    return floor(self._ax + (x - self._xmin) * self._xslope),
           floor(self._ay - (y - self._ymin) * self._yslope)
end

function mt:getBounds ()
    self:_getMinMax()
    return self._xmin, self._ymin, self._xmax, self._ymax
end

function mt:_drawTitle ()
    if self.title then
        local w = 7     -- gd.FONT_MEDIUM.width
        local h = 13    -- gd.FONT_MEDIUM.heigth
        self._vertTitle = 2 * h
        local px = self._imx / 2
        local py = self._imy - (self.vertGraphOffset + self._vertTitle) / 2
        self._im:string(gd.FONT_MEDIUM, floor(px - self.title:len() * w/2), floor(py + h/2), self.title, self.colors.black)
    end
end

function mt:_drawAxes ()
    local w = 6     -- gd.FONT_SMALL .width
    local h = 13    -- gd.FONT_SMALL .heigth
    local black = self.colors.black

    local p1x, p1y = self:data2px(self._xmin, 0)
    local p2x, p2y = self:data2px(self._xmax, 0)
    self._im:line(p1x, p1y, p2x, p2y, black)
    if self.horAxisLabel then
        local len = w * self.horAxisLabel:len()
        local xStart = (p2x+len/2 > self._imx-10) and self._imx-10-len or p2x-len/2
        self._im:string(gd.FONT_SMALL, floor(xStart), floor(p2y+3*h/2), self.horAxisLabel, black)
    end
    if self.xTickLabels then
        for x, label in pairs(self.xTickLabels) do
            local px, py = self:data2px(x, 0)
            self._im:line(px, py-2, px, py+2, black)
            self._im:string(gd.FONT_SMALL, floor(px-label:len()*w/2), floor(py+h/2), label, black)
        end
    else
        for x = -self._xstep, self._xmin, -self._xstep do
            local px, py = self:data2px(x, 0)
            self._im:line(px, py-2, px, py+2, black)
            local label = tostring(x)
            self._im:string(gd.FONT_SMALL, floor(px-label:len()*w/2), floor(py+h/2), label, black)
        end
        for x = self._xstep, self._xmax, self._xstep do
            local px, py = self:data2px(x, 0)
            self._im:line(px, py-2, px, py+2, black)
            local label = tostring(x)
            self._im:string(gd.FONT_SMALL, floor(px-label:len()*w/2), floor(py+h/2), label, black)
        end
    end

    p1x, p1y = self:data2px(0, self._ymin)
    p2x, p2y = self:data2px(0, self._ymax)
    self._im:line(p1x, p1y, p2x, p2y, black)
    if self.vertAxisLabel then
        local len = w * self.vertAxisLabel:len()
        local xStart = floor(p2x - len/2)
        self._im:string(gd.FONT_SMALL, (xStart > 10) and xStart or 10, floor(p2y-2*h), self.vertAxisLabel, black)
    end
    if self.yTickLabels then
        for y, label in pairs(self.yTickLabels) do
            local px, py = self:data2px(0, y)
            self._im:line(px-2, py, px+2, py, black)
            self._im:string(gd.FONT_SMALL, floor(px-(1+label:len())*w), floor(py-h/2), label, black)
        end
    else
        for y = -self._ystep, self._ymin, -self._ystep do
            local px, py = self:data2px(0, y)
            self._im:line(px-2, py, px+2, py, black)
            local label = tostring(y)
            self._im:string(gd.FONT_SMALL, floor(px-(1+label:len())*w), floor(py-h/2), label, black)
        end
        for y = self._ystep, self._ymax, self._ystep do
            local px, py = self:data2px(0, y)
            self._im:line(px-2, py, px+2, py, black)
            local label = tostring(y)
            self._im:string(gd.FONT_SMALL, floor(px-(1+label:len())*w), floor(py-h/2), label, black)
        end
    end
end

function mt:_getColor (style)
    for k, v in pairs(self.colors) do
        if style:match(k) then
            return v
        end
    end
    return self.colors.black
end

function mt:_drawData ()
    for i = 1, #self._datastyle do
        local style = self._datastyle[i]
        local xdata = self._xdata[i]
        local ydata = self._ydata[i]
        local color = self:_getColor(style)
        local colorline = color
        if style:match'dashed' then
            local white = self.colors.white
            self._im:setStyle({ color, color, color, white, white, white })
            colorline = gd.STYLED
        end
        local prevpx, prevpy = self:data2px(xdata[1], ydata[1])
        if not style:match'nopoint' then
            self._im:filledEllipse(prevpx, prevpy, 4, 4, color)
        end
        for j = 2, #xdata do
            local px, py = self:data2px(xdata[j], ydata[j])
            if not style:match'noline' then
                self._im:line(prevpx, prevpy, px, py, colorline)
            end
            if not style:match'nopoint' then
                self._im:filledEllipse(prevpx, prevpy, 4, 4, color)
                self._im:filledEllipse(px, py, 4, 4, color)
            end
            prevpx, prevpy = px, py
        end
    end
end

function mt:_drawTags ()
    for i = 1, #self._datastyle do
        local style = self._datastyle[i]
        local xdata = self._xdata[i]
        local ydata = self._ydata[i]
        local tags = self._tags[i]
        if tags then
            local color = self:_getColor(style)
            local up = style:match'up'
            for j = 1, #xdata do
                local tag = tags[j]
                if tag then
                    local px, py = self:data2px(xdata[j], ydata[j])
                    if up then
                        self._im:stringUp(gd.FONT_TINY , px-8, py-5, tag, color)
                    else
                        self._im:string(gd.FONT_TINY , px+5, py-4, tag, color)
                    end
                end
            end
        end
    end
end

function mt:draw (fmt)
    fmt = fmt or 'png'
    self:_drawTitle()
    self:_getMinMax()
    self:_drawAxes()
    self:_drawData()
    self:_drawTags()
    local meth = self._im[fmt .. 'Str']
    if not meth then
        error("The image format " .. tostring(fmt) ..  " is not supported by this version " .. gd.VERSION .. " of GD")
    end
    return meth(self._im)
end

function mt:getGDobject ()
    return self._im
end

m._NAME = ...
m._VERSION = "0.1.0"
m._DESCRIPTION = "lua-ChartPlot : plot two dimensional data in an image"
m._COPYRIGHT = "Copyright (c) 2019 Francois Perrad"
return m
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
