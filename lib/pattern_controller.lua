local pattern_controller = {}

function pattern_controller.sync_pattern_values(merged_pattern, pattern, s)
  merged_pattern.lengths[s] = pattern.lengths[s]
  merged_pattern.velocity_values[s] = pattern.velocity_values[s]
  merged_pattern.note_values[s] = pattern.note_values[s]
  return merged_pattern
end

function pattern_controller.get_and_merge_patterns(channel, trig_merge_mode, note_merge_mode, velocity_merge_mode, length_merge_mode)

  local selected_sequencer_pattern = program.get().selected_sequencer_pattern
  local merged_pattern = program.initialise_default_pattern()
  local skip_bits = program.initialise_64_table(0)
  local only_bits = program.initialise_64_table(0)

  local pattern_channel = program.get_selected_sequencer_pattern().channels[channel]
  local patterns = program.get_selected_sequencer_pattern().patterns

  local notes = program.initialise_64_table({})
  local lengths = program.initialise_64_table({})
  local velocities = program.initialise_64_table({})

  for i = 1, 64 do
    notes[i] = {}
    lengths[i] = {}
    velocities[i] = {}
  end

  -- local sorted_note_values = {} -- Moved the sorted_note_values table inside this loop

  for pattern_number, pattern_enabled in pairs(pattern_channel.selected_patterns) do
    if (pattern_enabled) then
      local pattern = patterns[pattern_number]
      for s = 1, 64 do
        local is_pattern_trig_one = pattern.trig_values[s] == 1

        if trig_merge_mode == "skip" then
          if is_pattern_trig_one and merged_pattern.trig_values[s] < 1 and skip_bits[s] < 1 then
            merged_pattern = pattern_controller.sync_pattern_values(merged_pattern, pattern, s)
            merged_pattern.trig_values[s] = 1
          elseif is_pattern_trig_one and merged_pattern.trig_values[s] == 1 then
            merged_pattern.trig_values[s] = 0
            skip_bits[s] = 1
          end
        elseif trig_merge_mode == "only" then
          if is_pattern_trig_one and merged_pattern.trig_values[s] < 1 and only_bits[s] == 0 then
            only_bits[s] = 1
            merged_pattern.trig_values[s] = 0
          elseif is_pattern_trig_one and only_bits[s] == 1 then
            merged_pattern.trig_values[s] = 1
          end
        elseif trig_merge_mode == "all" then
          if is_pattern_trig_one then
            merged_pattern.trig_values[s] = 1
            -- merged_pattern = pattern_controller.sync_pattern_values(merged_pattern, pattern, s)
          end
        end


        if note_merge_mode and string.match(note_merge_mode, "pattern_number_") then

          if note_merge_mode == "pattern_number_" .. pattern_number then
            
            merged_pattern.note_values[s] = patterns[pattern_number].note_values[s]
            -- merged_pattern = pattern_controller.sync_pattern_values(merged_pattern, pattern, s)
            
          end
        elseif note_merge_mode == "up" or note_merge_mode == "down" or note_merge_mode == "average" then
          if is_pattern_trig_one then
            table.insert(notes[s], patterns[pattern_number].note_values[s])
          end

        end
          
        if velocity_merge_mode and string.match(velocity_merge_mode, "pattern_number_") then

          if velocity_merge_mode == "pattern_number_" .. pattern_number then
            merged_pattern.velocity_values[s] = patterns[pattern_number].velocity_values[s]
            -- merged_pattern = pattern_controller.sync_pattern_values(merged_pattern, pattern, s)
          end
        elseif velocity_merge_mode == "up" or velocity_merge_mode == "down" or velocity_merge_mode == "average" then
          if is_pattern_trig_one then
            table.insert(velocities[s], patterns[pattern_number].velocity_values[s])
          end
        end

        if length_merge_mode and string.match(length_merge_mode, "pattern_number_") then

          if length_merge_mode == "pattern_number_" .. pattern_number then
            merged_pattern.lengths[s] = patterns[pattern_number].lengths[s]
            -- merged_pattern = pattern_controller.sync_pattern_values(merged_pattern, pattern, s)
          end
        elseif length_merge_mode == "up" or length_merge_mode == "down" or length_merge_mode == "average" then
          if is_pattern_trig_one then
            table.insert(lengths[s], patterns[pattern_number].lengths[s])
          end
        end

      end
    end

  end

  for s = 1, 64 do
    table.sort(notes[s])
    table.sort(lengths[s])
    table.sort(velocities[s])

    if note_merge_mode == "up" or note_merge_mode == "down" or note_merge_mode == "average" then
      if notes[s][1] == nil then 
        merged_pattern.note_values[s] = 0
      elseif fn.table_has_one_item(notes[s]) then
        merged_pattern.note_values[s] = notes[s][1]
      elseif note_merge_mode == "up" then
        merged_pattern.note_values[s] = (fn.average_table_values(notes[s]) - notes[s][1]) + notes[s][#notes[s]]
      elseif note_merge_mode == "down" then
        merged_pattern.note_values[s] = notes[s][1] - ((fn.average_table_values(notes[s]) - notes[s][1]))
      elseif note_merge_mode == "average" then
        merged_pattern.note_values[s] = fn.average_table_values(notes[s])
      end
    end

    if velocity_merge_mode == "up" or velocity_merge_mode == "down" or velocity_merge_mode == "average" then
      if velocities[s][1] == nil then
        merged_pattern.velocity_values[s] = 0
      elseif velocity_merge_mode == "up" then
        merged_pattern.velocity_values[s] = (fn.average_table_values(velocities[s]) - velocities[s][1]) + velocities[s][#velocities[s]]
      elseif velocity_merge_mode == "down" then
        merged_pattern.velocity_values[s] = velocities[s][1] - ((fn.average_table_values(velocities[s]) - velocities[s][1]))
      elseif velocity_merge_mode == "average" then
        merged_pattern.velocity_values[s] = fn.average_table_values(velocities[s])
      end
    end

    if length_merge_mode == "up" or length_merge_mode == "down" or length_merge_mode == "average" then
      if lengths[s][1] == nil then
        merged_pattern.lengths[s] = 0
      elseif length_merge_mode == "up" then
        merged_pattern.lengths[s] = (fn.average_table_values(lengths[s]) - lengths[s][1]) + lengths[s][#lengths[s]]
      elseif length_merge_mode == "down" then
        merged_pattern.lengths[s] = lengths[s][1] - ((fn.average_table_values(lengths[s]) - lengths[s][1]))
      elseif length_merge_mode == "average" then
        merged_pattern.lengths[s] = fn.average_table_values(lengths[s])
      end
    end
  end

  return merged_pattern
end




  -- local selected_sequencer_pattern = program.get().selected_sequencer_pattern
  -- local merged_pattern = program.initialise_default_pattern()
  -- local skip_bits = program.initialise_64_table(0)
  -- local average_length_accumulator = program.initialise_64_table(0)
  -- local average_velocity_accumulator = program.initialise_64_table(0)
  -- local average_note_accumulator = program.initialise_64_table(0)
  -- local average_count = program.initialise_64_table(0)

  -- local pattern_channel = program.get_selected_sequencer_pattern().channels[channel]
  -- local patterns = program.get_selected_sequencer_pattern().patterns

  -- local sorted_note_values = {} -- Moved the sorted_note_values table inside this loop

  -- for pattern_number, _ in pairs(pattern_channel.selected_patterns) do
  --   local pattern = patterns[pattern_number]

  --   for s = 1, 64 do
  --     table.insert(sorted_note_values, pattern.note_values[s]) -- Insert note values into the table
  --   end

  --   table.sort(
  --     sorted_note_values,
  --     function(a, b)
  --       return a > b
  --     end
  --   ) -- Sort the note values in descending order

  --   for s = 1, 64 do
  --     local is_pattern_trig_one = pattern.trig_values[s] == 1

  --     local pattern_note_value = pattern.note_values[s] == -1 and 0 or pattern.note_values[s]
  --     local merged_pattern_note_value = merged_pattern.note_values[s] == 0 or merged_pattern.note_values[s]
  --     local pattern_length = pattern.lengths[s] == -1 and 0 or pattern.lengths[s]
  --     local merged_pattern_length = merged_pattern.lengths[s] == -1 and 0 or merged_pattern.lengths[s]
  --     local pattern_velocity_value = pattern.velocity_values[s] == -1 and 0 or pattern.velocity_values[s]
  --     local merged_pattern_velocity_value =
  --       merged_pattern.velocity_values[s] == -1 and 0 or merged_pattern.velocity_values[s]

  --     if merge_mode == "skip" then
  --       if is_pattern_trig_one and merged_pattern.trig_values[s] < 1 and skip_bits[s] < 1 then
  --         merged_pattern = pattern_controller.sync_pattern_values(merged_pattern, pattern, s)
  --       elseif is_pattern_trig_one and merged_pattern.trig_values[s] == 1 then
  --         merged_pattern.trig_values[s] = 0
  --         skip_bits[s] = 1
  --       end
  --     elseif string.match(merge_mode, "pattern_number_") then
  --       if is_pattern_trig_one then
  --         merged_pattern.trig_values[s] = 1
  --       end
  --       if merge_mode == "pattern_number_" .. pattern_number then
  --         merged_pattern.lengths[s] = pattern.lengths[s]
  --         merged_pattern.velocity_values[s] = pattern.velocity_values[s]
  --         merged_pattern.note_values[s] = pattern.note_values[s]
  --       end
  --     elseif merge_mode == "add" or merge_mode == "subtract" or merge_mode == "average" then
  --       if is_pattern_trig_one then
  --         average_length_accumulator[s] = average_length_accumulator[s] + pattern_length
  --         average_velocity_accumulator[s] = average_velocity_accumulator[s] + pattern_velocity_value
  --         average_note_accumulator[s] = average_note_accumulator[s] + pattern_note_value
  --         average_count[s] = average_count[s] + 1
  --         merged_pattern.trig_values[s] = 1
  --       end
  --     elseif not string.match(merge_mode, "pattern_number_") then
  --       if is_pattern_trig_one then
  --         merged_pattern.trig_values[s] = 1
  --       end
  --     end
  --   end
  -- end

  -- for s = 1, 64 do
  --   local average_note = math.ceil(average_note_accumulator[s] / (average_count[s] or 1))
  --   if merge_mode == "add" or merge_mode == "subtract" or merge_mode == "average" then
  --     merged_pattern.lengths[s] = math.ceil(average_length_accumulator[s] / (average_count[s] or 1))
  --     merged_pattern.velocity_values[s] = math.ceil(average_velocity_accumulator[s] / (average_count[s] or 1))
  --     if merge_mode == "add" and merged_pattern.trig_values[s] then
  --       if average_count[s] > 1 then
  --         merged_pattern.note_values[s] = (sorted_note_values[1] or program.get().root_note) + average_note
  --       else
  --         merged_pattern.note_values[s] = average_note
  --       end
  --     elseif merge_mode == "subtract" and merged_pattern.trig_values[s] then
  --       if average_count[s] > 1 then
  --         merged_pattern.note_values[s] = (sorted_note_values[1] or program.get().root_note) - average_note
  --       else
  --         merged_pattern.note_values[s] = average_note
  --       end
  --     elseif merge_mode == "average" then
  --       if average_count[s] > 1 then
  --         merged_pattern.note_values[s] = math.ceil(average_note_accumulator[s] / (average_count[s] or 1))
  --       else
  --         merged_pattern.note_values[s] = average_note
  --       end
  --     end
  --   end
  -- end

  -- return merged_pattern
-- end

function pattern_controller.update_working_patterns()
  local selected_sequencer_pattern = program.get().selected_sequencer_pattern
  local sequencer_patterns = program.get_selected_sequencer_pattern().channels

  for c = 1, 16 do
    local merge_mode = sequencer_patterns[c].merge_mode
    local working_pattern = pattern_controller.get_and_merge_patterns(c, merge_mode)
    sequencer_patterns[c].working_pattern = working_pattern
  end
end

return pattern_controller
