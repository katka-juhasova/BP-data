helloworld = {}
helloworld.__index = helloworld

function helloworld.test()
	return "Hello World!"
end

function helloworld.testSource()
	print("Hi")
end

return helloworld
