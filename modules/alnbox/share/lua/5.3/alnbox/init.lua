-- alnbox, alignment viewer based on the curses library
-- Copyright (C) 2015 Boris Nagaev
-- See the LICENSE file for terms of use

return {
    runAlnbox = require 'alnbox.runAlnbox',
    alnwindow = require 'alnbox.alnwindow',
    navigate = require 'alnbox.navigate',
    makePair = require 'alnbox.makePair',
    initializeCurses = require 'alnbox.initializeCurses',
    initializeColors = require 'alnbox.initializeColors',
    putCell = require 'alnbox.putCell',
    cleanChar = require 'alnbox.cleanChar',
    readFasta = require 'alnbox.readFasta',
    alignmentParameters = require 'alnbox.alignmentParameters',
    columnDigit = require 'alnbox.columnDigit',
    dnaCells = require 'alnbox.dnaCells',
    consensusChar = require 'alnbox.consensusChar',
    makeAlignment = require 'alnbox.makeAlignment',
}
