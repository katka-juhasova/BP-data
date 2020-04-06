describe( "Text translation using Babel #i18n", function()

    local babel

    --- Initialize babel and load test translations from the
    -- tests/translations folder.
    setup( function()

        babel = require "babel"
        babel.init( {
            locale = "fr_FR",
            locales_folders = { "tests/translations" }
        } )

    end)

    ---
    -- Test simple texts (just static content)
    describe( "Simple text", function()

        it("translate simple text", function()
            assert.same( babel.translate( "Hello World" ), "Bonjour Le Monde" )
        end)

        it("use the text that should have been translated is not translation is found", function()
            assert.same( babel.translate( "Hello Kitty" ), "Hello Kitty" )
        end)

    end)

    ---
    -- Test texts with variables inside.
    describe( "use variables in translations", function()

        it("correctly insert the variable in the translation", function()
            assert.same( babel.translate( "Hello %name%", { name = "Kitty" } ), "Hello Kitty" )
        end)

    end)

end)
