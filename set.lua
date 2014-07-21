local Set = {
    _VERSION     = 'set.lua 0.1',
    _DESCRIPTION = 'Simple Set operations for Lua',
    _URL         = 'https://github.com/nomoon',
    _LONGDESC    = [[
        To create a set:
            Set(items...) or Set.new(items...)

        To modify a set:
            Set:add(items...) or Set:remove(items...)

        To retrieve the set's contents:
            Set() or Set:items()

        To test whether thing(s) is/are in a set:
            Set(items...) or Set:contains(items...) or Set:containsAll(items...)

        To test whether some thing(s) is/are in a set:
            Set:containsAny(items...)

        To compute the union of a set (returns new set):
            Set:union(other_set) or Set + other_set

        To compute the intersection of a set (returns new set):
            Set:intersect(other_set) or Set * other_set

        The + and - operators may also be used to add items to a set, but in
         this case a new set will be created and returned.

        The == and ~= operators will compare whether the sets contain exactly
          the same members.

        SOME EXAMPLES:

        > set = Set("first", "second", "third") -> S{"first", "second", "third"}
        > set:contains("first") -> TRUE
        > set:contains("first", "second") -> TRUE
        > set:contains("first", "second", "fourth") -> FALSE
        > set:containsAny("first", "second", "fourth") -> TRUE
        > new_set = set + "fourth" -> S{"first", "second", "third", "fourth"}
        > set == new_set -> FALSE
        > set:add("fourth") -> S{"first", "second", "third", "fourth"}
        > set == new_set -> TRUE
        > new_set:remove("first") -> S{"second", "third", "fourth"}
        > set * new_set -> S{"second", "third", "fourth"}

        NOTES:

        Items can any value or list of values, including nested tables.
        Keys are ignored, as well as any value not permitted as a table key,
          such as nil, NaN, and infinity.

        Methods are also documented below.
    ]],
    _LICENSE = [[
        Copyright 2014 Tim Bellefleur

        Licensed under the Apache License, Version 2.0 (the "License");
        you may not use this file except in compliance with the License.
        You may obtain a copy of the License at

           http://www.apache.org/licenses/LICENSE-2.0

        Unless required by applicable law or agreed to in writing, software
        distributed under the License is distributed on an "AS IS" BASIS,
        WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
        See the License for the specific language governing permissions and
        limitations under the License.
    ]]
}

--
--  Stash for private instance variables.
--
local _private = setmetatable({}, {__mode = "k"})

--
--  Private Helper functions
--

--  Flattens/sanitizes a table into its values.
local function flatten(tbl)
    local insert = table.insert
    local result = {}

    local function rFlatten(tbl)
        for k, v in pairs(tbl) do
            if (type(v) == "table") then
                rFlatten(v)
            elseif (v == nil or v ~= v or v == math.huge or v == -math.huge) then
                -- no-op, illegal table keys so can't go in set
            else
                insert(result, v)
            end
        end
    end

    rFlatten(tbl)
    return result
end

--
--  Class constructor:
--  Set.new(items...) or Set(items...)
--
function Set.new(...)
    local self = {}
    setmetatable(self, Set.mt)

    local list = flatten({...})

    _private[self] = {}
    _private[self].items = {}
    _private[self].size = 0

    self:add(list)

    return self
end

--
--  Set:items() or Set()
--    Returns a table of all items in the set.
--
function Set:items()
    local items = {}
    for k, v in pairs(_private[self].items) do table.insert(items, k) end
    return items
end

--
--  Set:contains(items...) or Set:containsAll(items...) or Set(items...)
--    Returns true if set contains [all of] the item(s), false otherwise.
--
function Set:contains(...)
    local items = flatten({...})
    local some_found, none_not = false, true
    for i, v in ipairs(items) do
        if _private[self].items[v] then some_found = true
        else none_not = false end
    end
    return (some_found and none_not)
end
Set.containsAll = Set.contains

--
--  Set:containsAny(items...)
--    Returns true if set contains [any of] the item(s), false otherwise.
--
function Set:containsAny(...)
    local items = flatten({...})
    for i, v in ipairs(items) do
        if _private[self].items[v] then return true end
    end
    return false
end

--
--  Set:add(items...)
--    Adds the item(s) to the set, then returns the set.
--
function Set:add(...)
    local items = flatten({...})
    for i, v in ipairs(items) do
        if _private[self].items[v] == nil then
            _private[self].size = _private[self].size + 1
            _private[self].items[v] = true
        end
    end
    return self
end

--
--  Set:remove(items...)
--    Removes the item(s) from the set, then returns the set.
--
function Set:remove(...)
    local items = flatten({...})
    for i, v in ipairs(items) do
        if _private[self].items[v] ~= nil then
            _private[self].size = _private[self].size - 1
            _private[self].items[v] = nil
        end
    end
    return self
end

--
--  Set:union(other_set)
--    Returns a new set with all the values of both sets.
--
function Set:union(other)
    local result = Set.new()
    result:add(self:items())
    result:add(other:items())
    return result
end

--
--  Set:intersect(other_set)
--    Returns a new set with only the values shared between both sets.
--
function Set:intersect(other)
    local result = Set.new()
    local self_items = self:items()
    for i,v in ipairs(self_items) do
        if other:containsAny(v) then result:add(v) end
    end
    return result
end

--
--  Set:size()
--    Returns the number of elements in the set
--
function Set:size()

    return _private[self].size
end

--
--  Instance Metamethods
--
Set.mt = {}
Set.mt.__index = Set

--
--  Calling a Set instance with no parameters aliases :items(), and with
--    parameters aliases :contains(items...)
--
function Set.mt:__call(...)
    if (#{...} > 0) then return self:contains(...)
    else return self:items() end
end

--
--  Using the + operator calls :union(param) if the parameter looks
--    like a set, or otherwise creates a new set containing all the items in
--    the first and calls :add(param) on it before returning.
--
function Set.mt:__add(param)
    if param.items then
        return self:union(other_set)
    else
        local result = Set.new()
        result:add(self:items())
        result:add(param)
        return result
    end
end

--
--  Using the - operator creates a new set containing all the items in
--    the first and if the parameter looks like a set it calls
--    :remove(param:items()), or otherwise :remove(params) before returning.
--
function Set.mt:__sub(param)
    local result = Set.new()
    if param.items then
        result:add(self:items())
        result:remove(param:items())
    else
        result:add(self:items())
        result:remove(param)
    end
    return result
end

--
--  The * operator will attempt to return an intersection.
--
Set.mt.__mul = Set.intersect

--
--  The equality operator will attempt to function on other sets.
--
function Set.mt:__eq(param)
    if param.items then
        return self:contains(param:items())
    else
        return false
    end
end

--
--  Some pretty printing
--
function Set.mt:__tostring()
    local items = self:items()
    for i,v in ipairs(items) do
        if(type(v) == "string") then
            v = v:gsub('\\', '\\\\'):gsub('"', '\\"')
            items[i] = table.concat({'"',v,'"'})
        end
    end

    return 'S{ ' .. table.concat(items, ', ') .. ' }'
end

--
-- Class metatable set to allow constructor without .new()
--
setmetatable(Set, { __call = function(_, ...) return Set.new(...) end })

--
--

-- create the empty set
set = Set()
assert(set:size() == 0)

-- remove from the empty set
set:remove("anything")
assert(set:size() == 0)

-- create a set with arguments
set = Set("first", "second", "third", "third")
assert(set:size() == 3)

-- create a set from a table
tset = Set({"first", "second", "third", "third"})
assert(tset:size() == 3)

-- contains
assert(set:contains("first"))
assert(set:contains("first", "second"))
assert(not set:contains("first", "second", "fourth"))

-- contains any
assert(set:containsAny("first", "second", "fourth"))

-- union
new_set = set + "fourth"

assert(new_set:size() == 4)

-- add the same element twice
set:add("fourth")
assert(set:size() == 4)
assert(set == new_set)

set:add("fourth")
print(set)
assert(set:size() == 4)
assert(set == new_set)

-- remove the same element twice
set:remove("first")
assert(set:size() == 3)

set:remove("first")
assert(set:size() == 3)

-- intersection
bob = Set("fourth", "whatever", "grand") * set
assert(bob:size() == 1)

-- relative complement
set = set - bob
assert(set:size() == 2)
assert(set:contains("fourth") == false)

return Set
