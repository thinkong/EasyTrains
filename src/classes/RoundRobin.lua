local RoundRobin = {}
RoundRobin.__index = RoundRobin

function RoundRobin.new(t)
    local self = setmetatable({}, RoundRobin)

    self.items = {}	
	if t then
		for _, value in pairs(t) do
			table.insert(self.items, value)
		end
	end

    return self
end

function RoundRobin:get_position(value)
    local position = 1
    for _, iterator_value in pairs(self.items) do
        if iterator_value == value then
            return position
        end
        position = position + 1
    end

    return nil
end

function RoundRobin:consume(value)
    self:remove(value)
    self:insert(value)
end

function RoundRobin:insert(value)
    table.insert(self.items, value)
end

function RoundRobin:remove(value)
    local position = self:get_position(value)

    if position ~= nil then
        table.remove(self.items, position)
    end
end

function RoundRobin:get()
    return self.items
end

return RoundRobin
