# love-ora

A library for loading [OpenRaster](https://en.wikipedia.org/wiki/OpenRaster) files into [LÖVE](http://www.love2d.org/) games.

OpenRaster files are basically just a .zip of several images as layers of a single composition, plus metadata about those layers. GIMP supports a basic export from their native .xcf to OpenRaster. There is also a [GIMP plugin](https://github.com/clofresh/gimp-ora-plus) that can export custom layer and path attributes as well as paths in your GIMP file.

Note: currently love-ora can only read unzipped OpenRaster directories, so export as unzipped or unzip before running your game.

## Motivation

Having a direct export of a level you've set up in GIMP directly into LÖVE makes it much easier to iterate over your work. [Tiled](http://www.mapeditor.org/) offers a similar workflow for tile-based games, but I couldn't find anything for setting up arbitrary images. Since I was already creating and laying out the level images in GIMP, and GIMP had such a flexible plugin system, I figured it would be a perfect level editor, reducing the steps to get art and level asserts into the game and improving the iteration feedback loop.

## Usage

```lua
local Ora = require('ora')

function love.load()
    -- Load the unzipped OpenRaster directory
    scene = Ora.load('tests/test-cases')
end

function love.draw()
    love.graphics.setBackgroundColor(255, 255, 255)
    local startX = scene.w / 2
    local startY = scene.h / 2

    -- Draw each layer
    for i, layer in pairs(scene.layers) do
        if layer.foo == 'a' then
            love.graphics.setColor(255, 0, 0)
        else
            love.graphics.setColor(0, 0, 255)
        end
        love.graphics.draw(layer.image, startX + layer.x, startY + layer.y)
        startX = startX + scene.w
    end

    startX = scene.w / 2
    startY = scene.h * 1.5

    -- Draw each path as either a line, if there's only 2 vertices,
    -- or a polygon if there's more than 3 vertices
    for i, path in pairs(scene.paths) do
        love.graphics.push()
        love.graphics.translate(startX, startY)

        -- Use a custom attribute to determine the color
        if path.a == 'z' then
            love.graphics.setColor(255, 0, 0)
        else
            love.graphics.setColor(0, 255, 0)
        end
        if #path.vertices == 4 then
            love.graphics.line(path.vertices)
        else
            love.graphics.polygon('line', path.vertices)
        end
        startX = startX + scene.w
        love.graphics.pop()
    end
end

```
