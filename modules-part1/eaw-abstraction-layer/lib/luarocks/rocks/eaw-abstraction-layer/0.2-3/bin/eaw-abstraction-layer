if #arg < 1 then
    local usage_str = [[
        eaw-abstraction-layer usage:
        --new-project     launches project setup
    ]]
    print(usage_str)
    os.exit(1)
end

if arg[1] == "--new-project" then
    require "eaw-abstraction-layer.cli.create_test_env"
    os.exit(0)
end
