local Class = {
    _VERSION     = '0.1.6',
    _DESCRIPTION = 'Very simple class definition helper',
    _URL         = 'https://github.com/nomoon',
    _LONGDESC    = [[

        Simply define a class with the syntax: `MyClass = Class(classname)`.
        Classname must start with a letter and consist of letters and
        numbers with no spaces.

        Then define a function `MyClass:new(params, [existing_table])`.
        If 'existing_table' is provided, class features will be added to that
        table. The class constructor returns `Class, Metatable`.

        When you call `MyClass(params)`, an instance is created and
        `MyClass.new(self, params)` is called with the new instance.
        You need not return anything from .new(), as the constructor will
        return the object once the function is finished.

        Complete Example:
            local Class = require('class')
            local Animal = Class('animal')

            function Animal:new(kind)
                self.kind = kind
            end

            function Animal:getKind()
                return self.kind
            end

            local mrEd = Animal("horse") -> Instance of Animal
            mrEd:getKind() -> "horse"

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

----------------------
-- Class Constructor
----------------------

setmetatable(Class, {__call = function(_, name, existing_table)
    if(not string.match(name,"^%a%w*$")) then
        return nil, "Illegal ClassName"
    end

    -- Define a base class table.

    local base_class
    if(type(existing_table) == 'table') then
        base_class = existing_table
    else
        base_class = { }
    end

    -- Define the metatable for instances of the class.
    local metatable = {__index = base_class}

    base_class.new = function() end
    base_class.className = function() return name end
    base_class.getMetatable = function() return metatable end

    -- Define a basic type checker
    function base_class.isInstance(obj)
        return (getmetatable(obj) == metatable)
    end
    -- Alias type-checker to function .is{ClassName}()
    base_class['is'..name:gsub("^%l", string.upper)] = base_class.isInstance

    -- Setup class metatable for Class(params) constructor
    setmetatable(base_class, {
        __call = function(_, ...)
            local new_instance = setmetatable({}, metatable)
            base_class.new(new_instance, ...)
            new_instance.new = function() end -- Prevent re-initializing object.
            return new_instance
        end
    })

    return base_class, metatable
end
})

--
--  Helper to initialize a weak-key store for private class data.
--
function Class.initPrivate()
    return setmetatable({}, {__mode = "k"})
end

---------------
-- Unit Tests
---------------
do
    local WrongClassName = Class('1Classname')
    assert(WrongClassName == nil)

    local Animal = Class('Animal')

    function Animal:new(kind)
        self.kind = kind
    end

    function Animal:getKind()
        return self.kind
    end

    local mrEd = Animal('horse')
    assert(mrEd:getKind() == 'horse')

    assert(Animal.isInstance(mrEd))
    assert(Animal.isAnimal(mrEd))
    assert(mrEd:className() == "Animal")

    local gunther = Animal('penguin')
    assert(gunther:new() == nil)
    assert(gunther:getKind() == 'penguin')

    local Plant = Class('Plant')

    function Plant:new(edible)
        self.edible = edible
    end

    function Plant:isEdible()
        return self.edible
    end

    local stella = Plant(false)
    assert(not stella:isEdible())
    assert(not stella.getKind)
    assert(not Animal.isInstance(stella))
    assert(Plant.isPlant(stella))
end

--

return Class
