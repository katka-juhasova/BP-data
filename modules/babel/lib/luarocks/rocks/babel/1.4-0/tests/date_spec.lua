describe( "Date format using Babel #date", function()

    local babel
    local test_date

    --- Initialize babel and load test translations from the
    -- tests/translations folder.
    setup( function()

        babel = require "babel"
        babel.init( {
            locale = "fr_FR",
            locales_folders = { "tests/translations" }
        } )

        test_date = {

            day   = 17,
            month = 2,
            year  = 1984,
            hour  = 10,
            min   = 42,
            sec   = 3,
            wday   = 5

        }

    end)

    ---
    -- Date and time formating
    describe( "Date and time", function()

        pending ( "Use predefined date/time formats", function()
            assert.same( babel.dateTime( "long_date_time", test_date ), "vendredi 17 février 1984 10:42:03" )
        end)

        it ( "Use custom format from translation file", function()
            assert.same( babel.dateTime( "busted_test", test_date ), "vendredi 17" )
        end)

        it ( "Use custom format on the fly", function()
            assert.same( babel.dateTime( "%Y", test_date ), "1984" )
        end)

        pending ( "Verify all the date/time 'tags'", function() end)

    end)

end)
