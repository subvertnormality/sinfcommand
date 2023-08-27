fn = {}

function fn.init()
  fn.id_prefix = "sinf-"
  fn.id_counter = 1000
end


function fn.cleanup()
  _midi.all_off()
  g.cleanup()
  clock.cancel(redraw_clock_id)
  clock.cancel(grid_clock_id)

end


function fn.dirty_grid(bool)
  if bool == nil then return grid_dirty end
  grid_dirty = bool
  return grid_dirty
end

function fn.dirty_screen(bool)
  if bool == nil then return screen_dirty end
  screen_dirty = bool
  return screen_dirty
end

function fn.remove_table_by_id(t, target_id)
  for i=#t, 1, -1 do
      if t[i].id == target_id then
          table.remove(t, i)
      end
  end
end

function fn.id_appears_in_table(t, target_id)
  for i=#t, 1, -1 do
      if t[i].id == target_id then
          return true
      end
  end
end

function fn.get_by_id(t, target_id)
  for i=#t, 1, -1 do 
      if t[i].id == target_id then
          return t[i]
      end
  end
end

function fn.get_index_by_id(t, target_id)
  for i=#t, 1, -1 do 
      if t[i].id == target_id then
          return i
      end
  end
end


function fn.table_to_string(tbl)
    local result = "{"
    for k, v in pairs(tbl) do
        -- serialize the key
        if type(k) == "string" then
            result = result .. "[\"" .. k .. "\"]" .. "="
        else
            result = result .. "[" .. k .. "]" .. "="
        end
        -- serialize the value
        if type(v) == "table" then
            result = result .. fn.table_to_string(v) .. ","
        else
            if type(v) == "string" then
            result = result .. "\"" .. v .. "\"" .. ","
            else
            result = result .. v .. ","
            end
        end
    end
    result = result .. "}"
    return result
end

function fn.print_table(t, indent)
  indent = indent or ''
  for k, v in pairs(t) do
      if type(v) == 'table' then
          print(indent .. k .. ' :')
          fn.print_table(v, indent .. '  ')
      else
          print(indent .. k .. ' : ' .. tostring(v))
      end
  end
end

function fn.merge_tables(t1, t2)
  for k, v in pairs(t2) do
      t1[k] = v
  end
  return t1
end

function fn.string_to_table(str)
    return load("return " .. str)()
end

function fn.deep_copy(original)
  local copy
  if type(original) == 'table' then
      copy = {}
      for original_key, original_value in next, original, nil do
          copy[fn.deep_copy(original_key)] = fn.deep_copy(original_value)
      end
      setmetatable(copy, fn.deep_copy(getmetatable(original)))
  else -- number, string, boolean, etc
      copy = original
  end
  return copy
end


function fn.table_count(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

function fn.shift_table_left(t)
  local first_val = table.remove(t, 1)
  table.insert(t, first_val)

  return t
end

function fn.shift_table_right(t)
  local last_val = table.remove(t)
  table.insert(t, 1, last_val)

  return t
end

function fn.find_index_in_table_by_id(table, object)
  for i, o in ipairs(table) do
    if o.id == object.id then
      return i
    end
  end
  return nil
end

function fn.find_index_in_table_by_value(table, object)
  for i, o in ipairs(table) do
    if o.value == object.value then
      return i
    end
  end
  return nil 
end

function fn.find_key(tbl, value)
  for k, v in pairs(tbl) do
    if v == value then
      return k
    end
  end
  return nil
end

function fn.tables_are_equal(t1, t2)
  for k, v in pairs(t1) do
      if v ~= t2[k] then
          return false
      end
  end

  for k, v in pairs(t2) do
      if v ~= t1[k] then
          return false
      end
  end

  return true
end

function fn.remove_table_from_table(t, object)
  for i, v in ipairs(t) do
      if fn.tables_are_equal(v, object) then
          table.remove(t, i)
          return
      end
  end
end

function fn.scale(num, old_min, old_max, new_min, new_max)
  return ((num - old_min) / (old_max - old_min)) * (new_max - new_min) + new_min
end

function fn.add_to_set(set, value)
  set[value] = true
end

function fn.is_in_set(set, value)
  return set[value] ~= nil
end

function fn.remove_from_set(set, value)
  set[value] = nil
end

function fn.value_from_note(note)
  return 14 - note
end

function fn.note_from_value(val)
  return 14 - val
end


function fn.round(num) 
  return math.floor(num + 0.5)
end

function fn.round_to_decimal_places(num, num_decimal_places)
  local mult = 10^(num_decimal_places or 0)
  return math.floor(num * mult + 0.5) / mult
end


function fn.calc_grid_count(x, y)
  return ((y - 4) * 16) + x
end

function fn.rotate_table_left(t)
  -- Create a new table by copying the original table
  local new_table = {table.unpack(t)}
  
  -- Rotate elements of the new table
  local first_item = table.remove(new_table, 1)
  new_table[7] = first_item
  return new_table
end

return fn