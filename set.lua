local Set = {
    _VERSION     = 'set.lua 0.3.2',
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

-- Import reused functions into local scope!
local insert = table.insert
local concat = table.concat
local inf = math.huge
local neg_inf = -math.huge

-------------------
--  Private Stuff
-------------------

--
--  Stash for private instance variables and metatable
--
local private = setmetatable({}, {__mode = "k"})
local cmt, imt = {}, {} -- Defined below public methods

--
--  Helper: Flattens/sanitizes a table into its values.
--
local function flatten(...)
    local result = {}

    local function rFlatten(tbl)
        for _, v in pairs(tbl) do
            if (type(v) == "table") then
                rFlatten(v)
            elseif (v == nil or v ~= v or v == inf or v == neginf) then
                -- no-op, illegal table keys so can't go in set
            else
                insert(result, v)
            end
        end
    end

    rFlatten({...})
    return result
end

------------------
--  Public Stuff
------------------

--
--  Class constructor:
--  Set.new(items...) or Set(items...)
--
function Set.new(...)
    local self = setmetatable({}, imt)

    private[self] = {
        items = {},
        size  = 0
    }

    return self:add(...)
end

--
--  Set:items() or Set()
--    Returns a table of all items in the set.
--
function Set:items()
    local pitems = private[self].items
    local result = {}
    for k in pairs(pitems) do insert(result, k) end
    return result
end

--
--  Set:contains(items...) or Set:containsAll(items...) or Set(items...)
--    Returns true if set contains [all of] the item(s), false otherwise.
--
function Set:contains(...)
    local pitems = private[self].items
    local items = flatten(...)
    local some_found, none_not = false, true
    for _, v in ipairs(items) do
        if pitems[v] then some_found = true else none_not = false end
    end
    return (some_found and none_not)
end
Set.containsAll = Set.contains

--
--  Set:containsAny(items...)
--    Returns true if set contains [any of] the item(s), false otherwise.
--
function Set:containsAny(...)
    local pitems = private[self].items
    local items = flatten(...)
    for _, v in ipairs(items) do
        if pitems[v] then return true end
    end
    return false
end

--
--  Set:add(items...)
--    Adds the item(s) to the set, then returns the set.
--
function Set:add(...)
    local p = private[self]
    local items = flatten(...)
    for _, v in ipairs(items) do
        if(p.items[v] == nil) then
            p.size = p.size + 1
            p.items[v] = true
        end
    end
    return self
end

--
--  Set:remove(items...)
--    Removes the item(s) from the set, then returns the set.
--
function Set:remove(...)
    local p = private[self]
    local pitems = p.items
    local items = flatten(...)
    for _, v in ipairs(items) do
        if(pitems[v] ~= nil) then
            p.size = p.size - 1
            pitems[v] = nil
        end
    end
    return self
end

--
--  Set:union(second)
--    Returns a new set with all the values of both sets.
--    If the parameter is not a set, will return new set with parameter added
--    to the contents of the first set.
--
function Set:union(second)
    local result = Set.new(self:items())
    if(getmetatable(self) == getmetatable(second)) then
        result:add(second:items())
    else
        result:add(second)
    end
    return result
end

--
--  Set:complement(second)
--    Returns a new set with values from the second set removed from the first.
--    If the parameter is not a set, will return new set with parameter removed
--    from the data of the first set.
--
function Set:complement(second)
    local result = Set.new(self:items())
    if(getmetatable(self) == getmetatable(second)) then
        result:remove(second:items())
    else
        result:remove(second)
    end
    return result
end

--
--  Set:intersect(second)
--    Returns a new set with only the values shared between both sets.
--    If the parameter is not a set, will return an empty set.
--
function Set:intersect(second)
    local result = Set.new()
    if(getmetatable(self) == getmetatable(second)) then
        local items = self:items()
        for _,v in ipairs(items) do
            if second:containsAny(v) then result:add(v) end
        end
    end
    return result
end

--
--  Set:size()
--    Returns the number of elements in the set
--
function Set:size()
    return private[self].size
end

--
--  Set:class()
--    Returns the class.
--
function Set:class()
    return Set
end

--------------------
-- Class Metatable
--------------------

cmt.__index = Set
cmt.__call = function(_, ...) return Set.new(...) end
setmetatable(Set, cmt)

------------------------
--  Instance Metatable
------------------------

imt.__index = Set

--
--  Calling a Set instance with no parameters aliases :items(), and with
--    parameters aliases :contains(items...)
--
imt.__call = function(self, param, ...)
    if param then return self:contains(param, ...)
    else return self:items() end
end

--
--  The equality operator will attempt to function on other sets.
--
imt.__eq = function(self, param)
    if(getmetatable(self) == getmetatable(param))then
        return self:contains(param:items())
    else
        return false
    end
end

--
--  Some pretty printing
--
imt.__tostring = function(self)
    local items = self:items()
    for i,v in ipairs(items) do
        if(type(v) == "string") then
            v = v:gsub('\\', '\\\\'):gsub('"', '\\"')
            items[i] = concat({'"',v,'"'})
        end
    end

    return 'S{' .. concat(items, ', ') .. '}'
end

--
--  Operator shorthand metamethods for various operations
--
imt.__add = Set.union
imt.__sub = Set.complement
imt.__mul = Set.intersect
imt.__len = Set.size

---------------
-- Unit Tests
---------------
do
    -- create the empty set
    local set = Set()
    assert(set:size() == 0)

    -- remove from the empty set
    set:remove("anything")
    assert(set:size() == 0)

    -- create a set with arguments
    set = Set("first", "second", "third", "third")
    assert(set:size() == 3)

    -- create a set from a table
    local tset = Set({"first", "second", "third", "third"})
    assert(tset:size() == 3)

    -- contains
    assert(set:contains("first"))
    assert(set:contains("first", "second"))
    assert(not set:contains("first", "second", "fourth"))

    -- contains any
    assert(set:containsAny("first", "second", "fourth"))

    -- union
    local new_set = set + "fourth"
    assert(new_set:size() == 4)
    assert(new_set:contains("fourth"))

    -- add the same element twice
    set:add("fourth")
    assert(set:size() == 4)
    assert(set == new_set)

    set:add("fourth")
    assert(set:size() == 4)
    assert(set == new_set)

    -- remove the same element twice
    set:remove("first")
    assert(set:size() == 3)
    assert(set ~= new_set)

    set:remove("first")
    assert(set:size() == 3)
    assert(set ~= new_set)

    -- intersection
    local bob = Set("fourth", "whatever", "grand") * set
    assert(bob:size() == 1)

    -- relative complement
    local lset = set - bob
    assert(lset:size() == 2)
    assert(not lset:contains("fourth"))
end

---------------------
-- Return the Class
---------------------

return Set
