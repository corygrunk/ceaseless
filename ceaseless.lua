--- ceaseless
--- shameless recreation of the OP1
--- endless sequencer

-- enc1:
-- enc2:
-- enc3:
-- key2: 
-- key3:

-- crow:
-- out 1:
-- out 2:
-- out 3: 
-- out 4: 

engine.name = 'PolyPerc'
s = require 'sequins'
m = midi.connect() -- if no argument is provided, we default to port 1

seq = s{999999} -- using 999999 as a number that will never exist
playing = false
counter = 0
counter_create = 0
mode = 'listen' -- 'create' or 'play'
new_seq = false
temp_table = {}

-- INIT
function init()
  screen.level(15)
  screen.aa(0)
  screen.line_width(1)

  main_clock = clock.run(clock_tick)
end

function midi_to_hz(note)
  local hz = (440 / 32) * (2 ^ ((note - 9) / 12))
  return hz
end

function play_notes()
  engine.hz(midi_to_hz(seq()))
end

-- MAIN CLOCK
function clock_tick()
  while true do
    clock.tempo = tempo
    clock.sync(1/2)

    if playing then
      move_seq()
    end 
  end
end

function move_seq()
  if seq[1] ~= 999999 then
    if seq[seq.ix] > 0 then
      play_notes()
    end
    counter = counter + 1
    if counter > seq.length then
      counter = 1
    end   
    redraw()
  end
end

function add_note(note)
  seq = s{note}
end

  
function redraw()
  screen.clear()

  if mode == 'listen' then
    screen.font_face(1)
    screen.font_size(8)
    screen.level(playing and 15 or 1)
    screen.move(125,10)
    screen.text_right('hold')
    
    screen.font_face(3)
    screen.font_size(30)
    screen.level(5)
    screen.move(60,40)
    screen.text_center(counter)
  else
    screen.font_face(1)
    screen.font_size(8)
    screen.level(playing and 15 or 1)
    screen.move(125,10)
    screen.text_right('hold')
    
    screen.font_face(3)
    screen.font_size(30)
    screen.level(15)
    screen.move(60,40)
    screen.text_center(seq[1] == 999999 and 0 or counter_create)
  end
  screen.update()
end

m.event = function(data)
  local d = midi.to_msg(data)
  if d.type == "note_on" then
    if mode == 'create' then
      new_seq = true
      seq[1] = 1
      engine.hz(midi_to_hz(d.note))
      table.insert(temp_table, d.note)
      counter_create = counter_create + 1
      redraw()
    elseif mode == 'listen' and playing == false then
      move_seq()
    else
      -- print(d.note)
      -- engine.hz(midi_to_hz(d.note))
    end
  end
end

function enc(n,z)
  if n==1 then
    -- enc1_val = util.clamp(enc1_val + z*1,0,100)
  elseif n==2 then
    -- enc2_val = util.clamp(enc2_val + z*1,0,10)
  elseif n==3 then
    if z > 0 then
      playing = true
    else
      playing = false
    end
  end
  redraw()
end 

function key(n,z)
  if n==2 and z==1 then
    mode = 'create'
    new_seq = false
    temp_table = {}
    counter_create = 0
  elseif n==2 and z==0 then
    mode = 'listen'
    if new_seq == true then 
      seq:settable(temp_table)
      seq:reset()
      new_seq = false
      counter = 1
    else

    end
    -- print(temp_table[1])
  elseif n==3 and z==1 then
    if mode == 'create' then
      
      print('shift + k3')
    else
       print('k3') 
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