lua-gainer-lib
==============

![GAINER board](gainer-without-goldpins.png "GAINER board")

A simple LuaJIT library to control GAINER - an USB I/O board for educational purpose. It uses serial port connection and simple commands
allowing for easily use digital input and analog input from environment or
control any devices like LEDs or servos by digital and analog outputs.
For now only Unix-like systems are supported. Tested on GNU/Linux but it should also work on any *BSD system.

Simple documentation is available in docs folder. It can be generated using LDoc script like this:

<code>
    cd lua-gainer-lib
    ldoc -c docs/config.ld lib/gainer.lua 
</code>

To test examples:

<code>
    cd lua-gainer-lib/lib
    luajit ../examples/blink.lua
</code>


Only LuaJIT is supported now because of C FFI that is used to communicate to tremios C library to connect to serial port.

GAINER board uses Cypress CY8C29466 microcontroller which has amazing amount of digital and analog peripherals. To use full potential GAINER firmware uses different configurations that are changing amount or type of inputs or outputs.

<code>

    .....................................................................................................................
    
    : Configuration : Analog inputs : Digital inputs : Analog outputs : Digital outputs :           Comments            :
    
    :...............:...............:................:................:.................:...............................:


    :             0 :             0 :              0 :              0 :               0 : configuration after reboot    :
    
    :             1 :             4 :              4 :              4 :               4 : default configuration         :
    
    :             2 :             8 :              0 :              4 :               4 : -                             :
    
    :             3 :             4 :              4 :              8 :               0 : -                             :
    
    :             4 :             8 :              0 :              8 :               0 : -                             :
    
    :             5 :             0 :             16 :              0 :               0 : -                             :
    
    :             6 :             0 :              0 :              0 :              16 : -                             :
    
    :             7 :             0 :              8 :              8 :               0 : matrix LED control            :
    
    :             8 :             0 :              8 :              0 :               8 : capacitive sensing (ain pins) :
    
    :...............:...............:................:................:.................:...............................:

</code>

For convenience lua-gainer-lib uses different port numbers than original.

<code>

    ....................................................
    
    : Label on board  :  Port           :  Port number :
    
    :.................:.................:..............:
    
    : ain             :  Analog input   :  1           :
    
    : din             :  Digital input  :  2           :
    
    : aout            :  Analog output  :  3           :
    
    : dout            :  Digital output :  4           :
    
    :.................:.................:..............:
    
</code>

If using configuration that has more than 4 pins of 1 type of I/O ports from next port are used.

TODO:
----

- Add experimental functions like setting PWM parameters, notifying on change of pins

- Add support for Windows

- Test on *BSD and Mac

- Add tests

- Clean up firmware

License
-------

MIT

Author: galion (galion at sdf org)