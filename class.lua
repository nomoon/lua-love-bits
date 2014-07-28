local Class = {
    _VERSION     = '0.2.1',
    _DESCRIPTION = 'Very simple class definition helper',
    _URL         = 'https://github.com/nomoon',
    _LONGDESC    = [[

        Simply define a class with the syntax:
            `MyClass = Class(classname, [existing_table])`
        Classname must start with a letter and consist of letters and
        numbers with no spaces. If 'existing_table' is provided, class features
        will be added to that table.
        The class constructor returns `Class, Metatable`.

        Then, define a function `MyClass:new(params)`. When you call
        `MyClass(params)` an instance is created and `MyClass.new(self, params)`
        is called with the new instance. You need not return anything from
        .new(), as the constructor will return the object once the function is
        finished.

        For private(ish) class and instance variables, you can call
        Class:private() or self:private() to retrieve a table reference.
        Passing a table into the private() method will set the private store to
        that table.

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

-- Private list of all classes defined.
local classes_defined = {}

----------------------
-- Class Constructor
----------------------

setmetatable(Class, {__call = function(_, class_name, existing_table)
    if(not class_name:match("^%a%w*$")) then
        return nil, "Illegal class name."
    end
    class_name = class_name:gsub("^%l", string.upper)
    if classes_defined[class_name] then
        return nil, "A class with that name has already been defined."
    end

    -- Define a base class table.
    local base_class
    if(type(existing_table) == 'table') then
        base_class = existing_table
    else
        base_class = {}
    end

    function base_class.class() return base_class end
    function base_class.className() return class_name end
    function base_class.new() end

    -- Define the metatable for instances of the class.
    local metatable = {__index = base_class}
    function base_class.getMetatable() return metatable end

    -- Define a basic type checker
    function base_class.isInstance(obj)
        if(type(obj) == 'table' and type(obj.className) == 'function') then
            return (obj:className() == class_name)
        end
    end
    -- Alias type-checker to function .is{ClassName}()
    base_class['is'..class_name] = base_class.isInstance

    -- Define private store and accessor method
    local private = setmetatable({}, {__mode = "k"})
    private[base_class] = {}
    function base_class.private(instance, value)
        if(base_class.isInstance(instance) or instance == base_class) then
            if(value and type(value) == 'table') then
                private[instance] = value
            end
            return private[instance]
        end
    end

    -- Setup class metatable for Class(params) constructor
    setmetatable(base_class, {
        __call = function(_, ...)
            -- Instantiate new class and private table
            local new_instance = setmetatable({}, metatable)
            private[new_instance] = {}

            -- Run user-defined constructor
            base_class.new(new_instance, ...)

            -- Override .new on instance to prevent re-initializing
            new_instance.new = function() end
            return new_instance
        end
    })

    classes_defined[class_name] = true
    return base_class, metatable
end
})

---------------
-- Unit Tests
---------------
do
    local WrongClassName = Class('1Classname')
    assert(WrongClassName == nil)

    local Animal = Class('Animal')
    assert(Class('animal') == nil)

    function Animal:new(kind)
        self.kind = kind
    end

    function Animal:getKind()
        return self.kind
    end

    local mrEd = Animal('horse')
    assert(mrEd:getKind() == 'horse')

    assert(Animal.class() == Animal)
    assert(Animal:class() == Animal)
    assert(mrEd:class() == Animal)

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
