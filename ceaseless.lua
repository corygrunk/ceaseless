--- ceaseless
--- recreation of the OP1
--- endless sequencer

-- enc1: Speed
-- enc2: TODO: Patterns
-- enc3: Hold / Direction (Shift)
-- key2: -> Add blank notes to pattern
-- key3: Create

-- TODOS:
-- Triplets
-- Patterns (E2)
-- Note Lengths during create
-- Chords???

----------------------
-- BUGS BUGS BUGS
----------------------
-- MIDI
-- 1. Start Ceaseless, then plug in MIDI controller
-- 2. MIDI won't work
----------------------
-- SEQUENCE STOPS WHEN...
-- 1. If you're holding a key and change the direction or engage/disengage hold, 
-- the sequence stops when you release K3
----------------------
-- HOLD GETS STUCK IF YOU
-- 1. Enter sequence
-- 2. Engage Hold
-- 3. Hold E3 and turn K3 (shift)
-- 4. Press a key and it will lock as if hold is still engaged.
-- 5. Engage and Disengage Hold to fix


engine.name = 'PolyPerc'
s = require 'sequins'
tab = require('tabutil')

seq = s{0}
shift_func = false
enc1_div = 5
enc1_div_max_entries = 6
div = {1/32,1/16,1/8,1/4,1/2,1}
div_names = {'1/32','1/16','1/8','1/4','1/2','1'}
enc3_direction = 1
enc3_direction_max_entries = 3
direction = {'FWD','REV','RND'}
note_name = '--'
offset = 60 -- this is the main note
playing = false
counter = 0
counter_create = 0
mode = 'play' -- 'create' or 'play' or 'hold'
prev_mode = mode
new_seq = false
temp_table = {}
note_on_tracker = 0 -- using to track keypresses

-- MIDI WIP STUFF - Not sure why this can't live in INIT?

midi_device = {} -- container for connected midi devices
midi_device_names = {}
midi_target_in = 1
midi_target_out = 1
current_midi_in_channel = 1
current_midi_out_channel = 1
for i = 1,#midi.vports do -- query all ports
  midi_device[i] = midi.connect(i) -- connect each device
  local full_name =
  table.insert(midi_device_names,"port "..i..": "..util.trim_string_to_width(midi_device[i].name,40)) -- register its name
end

-- midi in options
params:add_separator("MIDI IN")
params:add_option("device", "device", midi_device_names, 1)
params:set_action("device", function(x) midi_target_in = x end)
params:add{type = "number", id = "midi_in_channel", name = "midi in channel",
  min = 1, max = 16, default = 1, action = function(value) current_midi_in_channel = value end}

-- midi out options
params:add_separator("MIDI OUT")
params:add_option("device", "device", midi_device_names, 1)
params:set_action("device", function(x) midi_target_out = x end)
params:add{type = "number", id = "midi_out_channel", name = "midi out channel",
  min = 1, max = 16, default = 1, action = function(value) current_midi_out_channel = value end}


-- INIT
function init()
  screen.level(15)
  screen.aa(0)
  screen.line_width(1)
  main_clock = clock.run(clock_tick)
end

-- MIDI WIP STUFF

midi_device[midi_target_in].event = function(data)
  local d = midi.to_msg(data)

  if d.type == 'note_on' then
    if mode == 'hold' then
      offset = d.note
      note_on_tracker = 1
    end

    if mode == 'play' then
      note_on_tracker = note_on_tracker + 1
      if note_on_tracker == 1 then
        seq.ix = seq.length
        counter = 0
      end
      offset = d.note
      playing = true
    end

    if mode == 'create' then
      build_seq(d.note)
    end
  end

  if d.type == 'note_off' and mode ~= 'hold' then
    note_on_tracker = note_on_tracker - 1
    if note_on_tracker == 0 then
      playing = false
    end
  end

end



function midi_to_hz(note)
  local hz = (440 / 32) * (2 ^ ((note - 9) / 12))
  return hz
end

prev_note = 0 -- used for turning notes off

function play_notes(note)
  -- not sure if I need this note off logic. hmmmm?
  print('device: ' .. midi_target_out .. '     port: ' .. current_midi_out_channel)
  if prev_note ~= 0 then
    midi_device[midi_target_out]:note_off(prev_note, 100, current_midi_out_channel)
  end
  prev_note = note

  if note ~= 0 then
    -- engine.hz(midi_to_hz(note))
    midi_device[midi_target_out]:note_on(note, 100, current_midi_out_channel)
  end
end

-- MAIN CLOCK
function clock_tick()
  while true do
    clock.tempo = tempo
    clock.sync(div[enc1_div])
    if playing then
      move_seq()
    end 
  end
end

function move_seq()
  if enc3_direction == 1 then seq:step(1) end -- forward
  if enc3_direction == 2 then seq:step(-1) end -- reverse
  local note = seq()
  local random_note_ix = math.random(1,seq.length)
  if enc3_direction == 3 then -- random
    note = seq[random_note_ix] 
  end

  if note ~= 0 then
    play_notes(note + offset - 60)
    note_name = note + offset - 60
  end
  if enc3_direction ~= 3 then
    counter = counter + 1
    if counter > seq.length then
      counter = 1
    end
  else
    counter = random_note_ix
  end
  redraw()
end

function add_note(note)
  seq = s{note}
end

function build_seq(note)
  new_seq = true
  seq[1] = 1
  if note ~= 0 then play_notes(note) end
  table.insert(temp_table, note)
  note_name = note
  counter_create = counter_create + 1
  note_on_tracker = 1
  redraw()
end

  
function redraw()
  screen.clear()

  if mode == 'play' or mode == 'hold' then
    screen.font_face(1)
    screen.font_size(8)
    screen.level(mode == 'hold' and 15 or 1)
    screen.move(125,10)
    screen.text_right('hold')

    screen.level(1)
    screen.move(0,10)
    screen.text(div_names[enc1_div])

    screen.level(1)
    screen.move(125,60)
    screen.text_right(direction[enc3_direction])

    screen.level(1)
    screen.move(0,60)
    screen.text(note_name)
    
    if seq[1] == 0 and seq.length == 1 then
      screen.font_face(1)
      screen.font_size(8)
      screen.level(5)
      screen.move(60,35)
      screen.text_center('Hold k3 + Enter a note')
    else
      screen.font_face(3)
      screen.font_size(30)
      screen.level(5)
      screen.move(60,40)
      screen.text_center(counter)
    end
  else
    screen.font_size(8)
    screen.font_face(1) 
    screen.level(15)
    screen.move(125,60)
    screen.text_right(direction[enc3_direction])

    screen.font_face(3)
    screen.font_size(30)
    screen.level(15)
    screen.move(60,40)
    screen.text_center(seq[1] == 999999 and 0 or counter_create) -- NEED TO FIX

    screen.font_face(1)
    screen.font_size(8)
    screen.level(1)
    screen.move(0,60)
    screen.text(note_name)
  end
  screen.update()
end

function enc(n,z)
  if shift_func then
    -- manually wrapping - I think modulus could be used to clean this up
    enc3_direction = util.clamp(enc3_direction + z*1, 0, enc3_direction_max_entries + 1)
    if enc3_direction == 0 then enc3_direction = enc3_direction_max_entries end
    if enc3_direction == enc3_direction_max_entries + 1 then enc3_direction = 1 end
  else
    if n==1 then
      enc1_div = util.clamp(enc1_div + z*1, 1, enc1_div_max_entries)
    elseif n==2 then
      print('nothing yet')
    elseif n==3 then
      if z > 0 then
        mode = 'hold'
        note_on_tracker = 1
        playing = true
      else
        mode = 'play'
        note_on_tracker = 0
        playing = false
      end
    end
  end
  redraw()
end 


function key(n,z)
  if n==2 and z==1 then
    if mode == 'create' then
      -- print('shift + k2')
      build_seq(0)
      -- TODO: Should this note tracker business be moved elsewhere? 
      -- I'm using it to track when multiple keys are held down at once 
      -- so I know when all come up and I can release the sequence.
      note_on_tracker = note_on_tracker - 1
      if note_on_tracker == 0 then
        playing = false
      end
    else
      -- print('k2')
    end
  elseif n==3 and z==1 then
    prev_mode = mode -- save the mode that we're in when E3 was pressed down
    shift_func = true
    mode = 'create'
    new_seq = false
    temp_table = {}
    counter_create = 0
  elseif n==3 and z==0 then
    shift_func = false
    mode = prev_mode -- switch back to the previous mode so the hold feature works
    if mode == 'play' then playing = false end
    if mode == 'hold' then playing = true end
    if new_seq == true then 
      seq:settable(temp_table)
      seq:reset()
      new_seq = false
      counter = 1
    end
  end
  redraw()
end





-- UTILITY TO RESTART SCRIPT FROM MAIDEN
function r() -- shortcut
  rerun()
end
function rerun()
  norns.script.load(norns.state.script)
end