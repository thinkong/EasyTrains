local SupplierSorter = {}

function SupplierSorter:new(resource_suppliers)
  o = {}
  setmetatable(o, self)
  self.__index = self

  o.suppliers = {}

  for _, supplier_unit_number in pairs(resource_suppliers) do
    local supplier = global.conductor.train_stops[supplier_unit_number]

	if not is_train_stop_enabled(supplier) then
      if DEBUG_MODE then
        logger(string.format("Supplier stop %s is disabled", supplier.name))
      end
    elseif not supplier.entity.valid then
	  if DEBUG_MODE then
        logger(string.format("Supplier stop %s entity is no longer valid", consumer.name))
      end
	else
      table.insert(o.suppliers, supplier)
    end
  end
  return o
end

function SupplierSorter:iterate()
  local keys = {}

  for supplier_index, supplier in pairs(self.suppliers) do
    if supplier.assigned_trains >= supplier.max_number_of_trains then
      -- if supplier does not have available train slots, skip to next supplier
      if DEBUG_MODE then
        logger(
          string.format(
            " ... supplier %s already at [%d] maximum number of trains [%d]",
            supplier.name,
            supplier.assigned_trains,
            supplier.max_number_of_trains
          )
        )
      end
    else
      keys[#keys + 1] = {
        supplier_index = supplier_index,
        supplier = supplier,
		position = global.conductor.supplier_round_robin:get_position(supplier.unit_number)
      }
    end
  end

  table.sort(
    keys,
    function(left, right)
      if left.supplier.priority < right.supplier.priority then
        return true
      elseif left.supplier.priority > right.supplier.priority then
        return false
      end

      if left.supplier.assigned_trains < right.supplier.assigned_trains then
        return true
      elseif left.supplier.assigned_trains > right.supplier.assigned_trains then
        return false
      end

--      local left_position = global.conductor.supplier_round_robin:get_position(left.supplier.unit_number)
--      local right_position = global.conductor.supplier_round_robin:get_position(right.supplier.unit_number)
      return left.position < right.position
    end
  )

  local i = 0
  return function()
    i = i + 1
    if keys[i] then
      return keys[i].supplier_index, keys[i].supplier
    end
  end
end

function SupplierSorter:RemoveSupplier(index)
  table.remove(self.suppliers, index)
end

return SupplierSorter
