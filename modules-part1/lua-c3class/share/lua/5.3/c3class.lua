--  TODO:
--  构造函数 不能调用 super
--  __tostring 实现 metamethod, 和相关继承
--  instance of
--------------------------------------------------------------------------------
--  local variables and util functions
local function callable(v)
    local type_v = type(v)
    if type_v == "function" then
        return true
    end
    repeat
        if type_v ~= "table" then
            break
        end
        local meta = getmetatable(v)
        if not meta then
            break
        end
        return callable(meta.__call)
    until true
    return false
end

local dummy_func = function()
    print("----- dummy func called at", debug.traceback())
end
local abstruct_func = function(self)
end

local function make_message(...)
    local strs = table.pack(...)
    for i = 1, select("#", ...) do
        strs[i] = tostring(strs[i])
    end
    return table.concat(strs, "\t")
end

local function debug_table(t, level)
    level = level or 0
    local prefix = {}
    for i = 1, level do
        prefix[i] = "\t"
    end
    prefix = table.concat(prefix, "")
    for k, v in pairs(t) do
        local kt, vt = type(k), type(v)
        if kt == "table" then
            print(prefix, "\tkey:", k)
            debug_table(k, level + 1)
            print(prefix, "\tvalue:", v)
            if vt == "table" then
                debug_table(v, level + 2)
            end
        else
            print(prefix, k .. ":", v)
            if vt == "table" then
                debug_table(v, level + 1)
            end
        end
    end
end

--  key: class name, value: class; anonymous class in array part.
local class_map = {}

local function get_class_name(class)
    return getmetatable(class).name or "<anonymous>"
end

--  操作 mros 中的数组中的元素时，使用增加数组偏移量的方式来避免移动数组中的元素
--  mros's element style: { idx: <start index>, num: <class num>, arr: <origin array> }
local function merge_mro(out, mros)
    local n = #mros
    if n == 0 then
        return out
    end
    local in_tail = false
    local mro, h, m, i, j
    i = 1
    while i < n do
        repeat
            --  取出第i个tail中的第一个元素
            mro = mros[i]
            if mro.num == 0 then
                --  此 mro 已空了，取下一个的
                break
            end
            --  取出第 i 个 mro 中的头
            h = mro.arr[mro.idx]
            --  判断其它 mro 中是否有 h 在 tail 中
            j = 1
            while j <= n do
                if i == j then
                    if j == n then
                        break
                    else
                        j = j + 1
                    end
                end
                m = mros[j]
                j = j + 1
                local arr = m.arr
                local v = m.idx + m.num
                for u = m.idx + 1, v do
                    if arr[u] == h then
                        in_tail = true
                        break
                    end
                end

                if in_tail then
                    break
                end
            end
            --  如果  在其它 mro 的 tail 中，取下一个 mro 的 h
            if in_tail then
                in_tail = false
                break
            end
            --  输出 h
            out[#out + 1] = h
            --  删除 mros 中所有 h
            for k = 1, n do
                mro = mros[k]
                if mro.num > 0 and mro.arr[mro.idx] == h then
                    mro.idx = mro.idx + 1
                    mro.num = mro.num - 1
                end
            end
            i = 0
        until true
        i = i + 1
    end
    --  如果遍历完了 mros 但是还是有 h 在别的 mro 的 tail 中，说明无法 merge
    if in_tail then
        return nil
    else
        return out
    end
end

local function instance_of_class(instance, class)
    --  TODO
    return true
end

--------------------------------------------------------------------------------
--  super functions
local function super_newindex(t, k, v)
    error(make_message("super can't set new key value pair:", k, type(v)))
end

local function super_make(class, mro)
    return function(instance, cls)
        if instance == null or not instance_of_class(instance, class) then
            error(make_message("invalid instance", instance, "of", class))
        end
        if cls == nil then
            cls = class
        end
        local base_num = #mro
        local idx = 1
        repeat
            local base_class = mro[idx]
            idx = idx + 1
            if base_class == cls then
                break
            end
        until idx > base_num
        if idx > base_num then
            return nil
        end

        local super_instance = {}
        return setmetatable(
            super_instance,
            {
                __index = function(_, k)
                    -- print("---- super find:", k, class)
                    for i = idx, #mro do
                        local val = getmetatable(mro[i]).members[k]
                        if val ~= nil then
                            if type(val) == "function" then
                                local f = val
                                -- print("---- found in base", mro[i])
                                val = function(self, ...)
                                    --  如果通过super instance 调用方法,则把 super instance 替换为 类的 instance
                                    if self == super_instance then
                                        -- print("---- call func with", instance)
                                        return f(instance, ...)
                                    else
                                        -- print("---- call func with self:", self)
                                        return f(self, ...)
                                    end
                                end
                            end
                            return val
                        end
                    end
                    return nil
                end,
                __newindex = super_newindex
            }
        )
    end
end

--------------------------------------------------------------------------------
--  instance functions
local function instance_tostring(instance)
    local instance_meta = getmetatable(instance)
    local class_meta = getmetatable(instance_meta.class)
    local custom_tostring = class_meta.find_member("toString")

    if custom_tostring then
        return custom_tostring(instance)
    end

    local class_name = class_meta.name or class_meta.address
    local instance_meta_tostring = instance_meta.__tostring
    --  get instance address
    local address = instance_meta.address
    if not address then
        instance_meta.__tostring = nil
        address = string.sub(tostring(instance), 8)
        instance_meta.address = address
        instance_meta.__tostring = instance_meta_tostring
    end

    return string.format("instance of %s: %s", class_name, address)
end

--------------------------------------------------------------------------------
--  class functions
local function class_register(class, name)
    if name ~= nil then
        class_map[name] = class
    else
        class_map[#class_map + 1] = class
    end
end

local function class_is_class(c)
    local is_class = false
    repeat
        if type(c) ~= "table" then
            break
        end
        local meta = getmetatable(c)
        if not meta then
            break
        end
        if type(meta.mro) ~= "table" then
            break
        end
        if meta.name then
            is_class = class_map[meta.name] and true or false
            break
        end
        for i = 1, #class_map do
            if c == class_map[i] then
                is_class = true
                break
            end
        end
    until true
    return is_class
end

local function class_set_member(class, k, v)
    getmetatable(class).members[k] = v
end

local function class_is_abstract(class)
    local mro = getmetatable(class).mro
    --  从基类开始合并所有的成员函数
    local funcs = {}
    for i = #mro, 1, -1 do
        for k, v in pairs(getmetatable(mro[i]).members) do
            if type(v) == "function" then
                funcs[k] = v
            end
        end
    end
    local af = abstruct_func
    --  判断最终的所有成员函数中是否有 abstruct 函数
    for _, f in pairs(funcs) do
        if f == af then
            return true
        end
    end
    return false
end

local function class_tostring(class)
    return string.format("class: %s", getmetatable(class).name or getmetatable(class).address)
end

local function class_on_instantiate(instance, args)
    if args ~= nil and type(args) == "table" then
        for k, v in pairs(args) do
            local type_v = type(v)
            if type_v == "boolean" or type_v == "number" or type_v == "string" then
                instance[k] = v
            end
        end
    end
end

local function class_make_construct(class)
    local mro = getmetatable(class).mro
    local ctors = {}
    local ctor
    for i = #mro, 1, -1 do
        ctor = getmetatable(mro[i]).members.ctor
        if ctor then
            ctors[#ctors + 1] = ctor
        end
    end
    return function(instance, args)
        local cs = ctors
        for i = 1, #cs do
            cs[i](instance, args)
        end
        class_on_instantiate(instance, args)
    end
end

--  https://en.wikipedia.org/wiki/C3_linearization
local function class_make(name, extends, members)
    --  先声明类
    local class = {}
    local class_meta = {}
    --  构建 MRO 序列
    local tail_mros = {}
    local base_num = #extends
    for i = 1, base_num do
        local base_mro = getmetatable(extends[i]).mro
        tail_mros[i] = {
            idx = 1,
            num = #base_mro,
            arr = base_mro
        }
        tail_mros[base_num + i] = {
            idx = i,
            num = 1,
            arr = extends
        }
    end
    local mro = merge_mro({class}, tail_mros)
    if mro == nil then
        local base_names = {}
        for i = 1, #extends do
            base_names[i] = get_class_name(extends[i])
        end
        error(
            make_message("can't create a consistent method resolution order (MRO) for bases", table.unpack(base_names))
        )
    end
    local find_member = function(k)
        for i = 1, #mro do
            local val = getmetatable(mro[i]).members[k]
            if val ~= nil then
                return val
            end
        end
        return nil
    end
    --  构造 instance metatable
    local instance_meta = {
        class = class,
        __index = function(inst, k)
            local v = find_member(k)
            if v ~= nil then
                inst[k] = v
            end
            return v
        end,
        __tostring = instance_tostring
    }
    --  init class_meta
    class_meta.address = string.sub(tostring(class), 8)
    class_meta.find_member = find_member
    class_meta.instance_meta = instance_meta
    class_meta.members = members
    class_meta.mro = mro
    class_meta.name = name
    class_meta.super = super_make(class, mro)
    class_meta.__newindex = class_set_member
    class_meta.__tostring = class_tostring

    class_meta.__call = function(_, args)
        local clazz = class
        local meta = class_meta
        local abstract = meta.abstract
        if abstract == nil then
            abstract = class_is_abstract(clazz)
            meta.abstract = abstract
        end
        if abstract == true then
            error(make_message("can't instantiate abstract class", get_class_name(clazz)))
        end

        local instance = setmetatable({}, instance_meta)
        local construct = meta.construct
        if not construct then
            construct = class_make_construct(clazz)
            meta.construct = construct
        end
        construct(instance, args)
        return instance
    end

    return setmetatable(class, class_meta), class_meta.super
end

--------------------------------------------------------------------------------
--  module exports
local M = {}

M.debug_table = debug_table
M.ABSTRACT_FUNCTION = abstruct_func

M.IsClass = class_is_class
M.InstanceOf = instance_of_class

M.OnInstantiate = class_on_instantiate

function M.Static(Class, name, val)
    rawset(Class, name, val)
end

function M.debug()
    print("--------- debug class: ---------")
    for _, class in pairs(class_map) do
        local meta = getmetatable(class)
        print("Class " .. (meta.name or "<anonymous>") .. ":", class)
        debug_table(meta, 1)
    end
end

return setmetatable(
    M,
    {
        __call = function(_, ...)
            local args, extends, members = table.pack(...), {}, {}
            local arg, arg_type, name
            for i = 1, args.n do
                arg = args[i]
                repeat
                    if arg == nil then
                        break
                    end
                    arg_type = type(arg)
                    if arg_type == "string" then
                        if name then
                        --  已经有名称了？
                        end
                        assert(#arg > 0)
                        --  检查此名称是否已被使用
                        name = arg
                        break
                    end
                    if arg_type ~= "table" then
                        break
                    end
                    if not class_is_class(arg) then
                        --  此 arg 不是类，认为是定义类成员的 table，把 members 合并到 members 变量
                        for k, v in pairs(arg) do
                            members[k] = v
                        end
                        break
                    end
                    if extends[arg] ~= nil then
                        --  重复了？
                        break
                    end
                    extends[arg] = true
                    extends[#extends + 1] = arg
                until true
            end
            if name ~= nil and class_map[name] then
                error(make_message("there is class registered with this name", name, class_map[name]))
            end
            local class, super = class_make(name, extends, members)
            class_register(class, name)
            return class, super
        end
    }
)
