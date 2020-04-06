local _M = require('middleclass')('Test.Class')

local tb = require('Test.Builder').new()

local test_classes = {}

function _M.static:subclassed(class)
  table.insert(test_classes, class)
end

function _M:initialize(method_regex)
  self.method_regex = method_regex
end

function _M.run_tests(arg)
  arg = arg or {}
  for i = 1, #test_classes do
    local test_class = test_classes[i]
    test_class:new(arg.include):run_test_class_instance()
  end
  tb:done_testing()
end

function _M:test_startup()
  -- Empty base method
end

function _M:test_shutdown()
  -- Empty base method
end

function _M:test_setup()
  -- Empty base method
end

function _M:test_teardown()
  -- Empty base method
end

function _M:run_test_class_instance()
  local test_class       = self.class
  local all_test_methods = self:_get_all_test_methods()

  tb:note('Running tests for ' .. test_class.name)
  tb:note("\n")
  tb:subtest(
    test_class.name,
    function()
      -- Run test_startup() before all test methods
      self:test_startup()

      -- Iterate over all methods of test class searching for those starting with 'test_'
      for _, test_method in ipairs(all_test_methods) do
        self:_run_test_method(test_class, test_method)
      end

      -- Run test_shutdown() after all test methods
      self:test_shutdown()
    end
  )
end

local function reverse(array)
  local reversed_array = {}
  local length = #array
  for i = length, 1, -1 do
      reversed_array[length - i + 1] = array[i]
  end
  return reversed_array
end

function _M:_get_class_hierarchy()
  local class_hierarchy = { }
  local class = self.class
  while class.super and class.name ~= 'Test.Class' do
    table.insert(class_hierarchy, class)
    class = class.super
  end
  class_hierarchy = reverse(class_hierarchy)
  return class_hierarchy
end

function _M:_get_test_methods(test_class)
  local test_methods = {}
  for method_name, method_body in pairs(test_class.__declaredMethods) do
    if type(method_body) == 'function'
      and string.match(method_name, '^test_')
      and method_name ~= 'test_startup' and method_name ~= 'test_shutdown'
      and method_name ~= 'test_setup'   and method_name ~= 'test_teardown'
      and (not self.method_regex or string.match(method_name, self.method_regex))
    then
      table.insert(test_methods, method_name)
    end
  end
  return test_methods
end

-- Get test methods of all classes in the hierarchy
function _M:_get_all_test_methods()
  local class_hierarchy = self:_get_class_hierarchy()

  local unique_test_methods = {}
  for _, class in ipairs(class_hierarchy) do
    local test_methods = self:_get_test_methods(class)
    for _, test_method in ipairs(test_methods) do
      unique_test_methods[test_method] = true
    end
  end

  local all_test_methods = {}
  for test_method, _ in pairs(unique_test_methods) do
    table.insert(all_test_methods, test_method)
  end

  table.sort(all_test_methods)

  return all_test_methods
end

function _M:_run_test_method(test_class, method_name)
  -- Setup a particular test
  self.current_method = method_name
  self:test_setup()

  -- Run test method as a subtest
  tb:note(test_class.name .. '.' .. method_name .. '()')
  tb:subtest(
    method_name,
    function()
      local is_success, result = pcall(self[method_name], self)
      if not is_success then
        tb:diag(result)
      end
    end
  )

  -- Teardown a particular test
  self:test_teardown()
end

function _M.load_classes(dir)
  local finder = require('File.Find')
  local module_files = finder.find_lua_files(dir)
  for i = 1, #module_files do
    local module_name = module_files[i]
      :gsub(dir .. '/?', '')
      :gsub('[.]lua$', '')
      :gsub('/', '.')
    require(module_name)
  end
end

return _M
