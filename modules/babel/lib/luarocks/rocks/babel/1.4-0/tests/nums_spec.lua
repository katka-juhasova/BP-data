describe( "Number formating using Babel #i10n", function()

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
    describe( "Simple numbers", function()

        it ( "< 1000 numbers", function()
            assert.same( babel.number( 123.4 ), "123,40" )
        end)

        it ( "> 1000 numbers", function()
            assert.same( babel.number( 12345.6 ), "12 345,60" )
        end)

        it ( "Negative numbers", function()
            assert.same( babel.number( -1234.5 ), "-1 234,50" )
        end)

    end)

    ---
    -- Prices (formating + symbol)
    describe( "Prices", function()

        it ( "Currency symbol is present", function()
            assert.same( babel.price( 5 ), "5,00 €" )
        end)

        it ( "Currency symbol is present and negativ numbers are displayed correctly", function()
            assert.same( babel.price( -23.4 ), "-23,40 €" )
        end)

    end)

end)
