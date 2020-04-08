describe( "Babel functionalities #lib", function()

    local babel

    --- Initialize babel and load test translations from the
    -- tests/translations folder.
    setup( function()

        babel = require "babel"
        babel.init( {
            locale = "fr_FR"
        } )

        ---
        -- Add local folder folder on demand
        babel.addLocalesFolder( "tests/translations" )

    end)

    ---
    -- Test that the functions are available
    describe( "Functions", function()

        it ( "_ shortcut is available in clean environement", function()
            assert.same( _, babel.translate )
        end)

    end)

    describe( "Load locale from OS", function()

        auto_babel = babel.init()

        -- Locale have been set to "eo_EO" in the .travis_setup.sh script 
        assert.same( babel.getOSLocale(), "eo_EO")

    end)

    describe( "Don't load translations on empty locale", function()
    
        local before = babel.dictionary
        
        babel.switchToLocale( "" )
        assert.same( babel.dictionary, before )

        babel.switchToLocale( false )
        assert.same( babel.dictionary, before )

        babel.switchToLocale( nil )
        assert.same( babel.dictionary, before )

    end)

end)
