local beatclock = require 'beatclock'
local fn = include 'lib/functions'

local midi_controller = include 'lib/midi_controller'
local step_handler = include 'lib/step_handler'

local clock_controller = {}

local playing = false



local master_clock
local midi_transport

local function go(divisor, on_step) 
  while true do
    clock.sync(1/divisor)
    on_step()
  end
end

local function start_midi_transport(divisor) 
  clock.sync(1/divisor)
  print("start midi transport")
  midi_controller:start()
end



local function master_func() 

  step_handler:process_lengths()

  program.current_step = program.current_step + 1

  if program.current_step > program.sequencer_patterns[program.selected_sequencer_pattern].global_pattern_length then
    program.current_step = 1
  end
  fn.dirty_grid(true)
end


function clock_controller:start() 



  for i = 1, 16 do
    local clock_division = program.sequencer_patterns[program.selected_sequencer_pattern].channels[i].clock_division
    clock_controller["channel_"..i.."_clock"] = clock.run(go, clock_division, function () 

      local channel = program.sequencer_patterns[program.selected_sequencer_pattern].channels[i]
      local start_trig = fn.calc_grid_count(channel.start_trig[1], channel.start_trig[2])
      local end_trig = fn.calc_grid_count(channel.end_trig[1], channel.end_trig[2])
      local current_step = channel.current_step
    
      if channel.current_step < start_trig then
        channel.current_step = start_trig
        current_step = start_trig - 1
      end

      step_handler:handle(i, current_step)
    
      channel.current_step = current_step + 1
    
      if channel.current_step > end_trig then
        channel.current_step = start_trig
      end

    end)
  end
  master_clock = clock.run(go, 4, master_func)
  midi_transport = clock.run(start_midi_transport, 4)
  
  playing = true
end

function clock_controller:stop()

  if (playing) then

    clock.cancel(master_clock)
    clock.cancel(midi_transport)
    midi_controller:stop()
    for i = 1, 16 do
      clock.cancel(clock_controller["channel_"..i.."_clock"])
    end
    playing = false
  end
end

function clock_controller:is_playing()
  return playing
end

function clock_controller:reset() 
  for i = 1, 16 do
    program.sequencer_patterns[program.selected_sequencer_pattern].channels[i].current_step = 1
  end
  program.current_step = 1
end

return clock_controller