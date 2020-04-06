require "tests.love_mocks"

print(love.filesystem.exists())

describe("Fake Löve2D", function()
    
    local babel

    setup( function()
        babel = require "babel"
        babel.init( {
            locale = "fr_FR",
            locales_folders = { "tests/translations" }
        } )

    end)

    describe( "Simple text", function()

        -- Using empty functions, we must not
        -- have entries in the dictionnary.
        assert.same( babel.dictionary, {} )

    end)
    
end)
