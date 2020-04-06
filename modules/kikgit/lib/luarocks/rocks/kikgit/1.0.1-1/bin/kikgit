local command, capture
do
  local _obj_0 = require("lrunkit.v3")
  command, capture = _obj_0.command, _obj_0.capture
end
local argparse = require("argparse")
local args
do
  local _with_0 = argparse()
  _with_0:name("kikgit")
  _with_0:description("Git, but quicker")
  _with_0:epilog("Homepage - https://github.com/daelvn/kikgit")
  _with_0:command_target("command")
  do
    local _with_1 = _with_0:command("push p", "Pushes a simple commmit to the remote")
    do
      local _with_2 = _with_1:option("-r --remote", "Remote to perform the push on")
      _with_2:default("origin")
    end
    do
      local _with_2 = _with_1:option("-b --branch", "Branch to perform the push on")
      _with_2:default("master")
    end
    do
      local _with_2 = _with_1:option("-m --message", "Optional commit message")
      _with_2:args("?")
    end
    _with_1:flag("-j --just-push", "Just push")
    _with_1:flag("-p --pull", "Pull before pushing")
  end
  do
    local _with_1 = _with_0:command("release r", "Releases a new version to the remote")
    do
      local _with_2 = _with_1:option("-r --remote", "Remote to perform the push on")
      _with_2:default("origin")
    end
    do
      local _with_2 = _with_1:option("-b --branch", "Branch to perform the push on")
      _with_2:default("master")
    end
    do
      local _with_2 = _with_1:option("-m --message", "Optional commit message")
      _with_2:args("?")
    end
    do
      local _with_2 = _with_1:argument("tag", "Tag to release the commits with")
      _with_2:args(1)
    end
    _with_1:flag("-p --pull", "Pull before pushing")
    _with_1:flag("-j --just-release", "Just tag and push")
  end
  args = _with_0:parse()
end
local pull = command("git pull")
local add = command("git add -A")
local commit = command("git commit")
local tag = command("git tag -a")
local push = command("git push")
local _exp_0 = args.command
if "push" == _exp_0 then
  if not (args.just_push) then
    if args.pull then
      print(":: Pulling from " .. tostring(args.remote) .. "/" .. tostring(args.branch))
    end
    if args.pull then
      pull(args.remote, args.branch)
    end
    print(":: Adding files")
    add()
    print(":: Commiting changes" .. tostring(args.message and " -> " .. tostring(args.message[1]) or ""))
    commit((args.message and "-m \"" .. tostring(args.message[1]) .. "\"" or nil))
  end
  print(":: Pushing changes to " .. tostring(args.remote) .. "/" .. tostring(args.branch))
  return push(args.remote, args.branch)
elseif "release" == _exp_0 then
  if not (args.just_release) then
    if args.pull then
      print(":: Pulling from " .. tostring(args.remote) .. "/" .. tostring(args.branch))
    end
    if args.pull then
      pull(args.remote, args.branch)
    end
    print(":: Adding files")
    add()
    print(":: Commiting changes" .. tostring(args.message and " -> " .. tostring(args.message[1]) or ""))
    commit((args.message and "-m \"" .. tostring(args.message[1]) .. "\"" or nil))
  end
  print(":: Tagging " .. tostring(args.tag))
  tag(args.tag)
  print(":: Pushing changes to " .. tostring(args.remote) .. "/" .. tostring(args.branch))
  return push(args.remote, args.branch, "--tags")
end
