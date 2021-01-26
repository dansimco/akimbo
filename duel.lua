-- dual. a dual looping delay

-- Two delay buffers, left and right.
-- Quantised buffer length, controlled by arc's 1 and two
-- feedback controllerd by three and four

-- params
-- buffer_i_length
-- buffer_i_start
-- buffer_i_feedback
-- buffer_i_filter
-- buffer_i_direction
-- buffer_i_hold
-- buffer_i_feed
-- buffer_i_scale (=, +16, /8)
--
-- xfade time
-- clock

-- buffer methods
-- reverse
-- set_feedback
-- set_feed
-- set_length
-- set_start
-- hold  

local lattice=require 'lattice'
local util=require 'util'
local tabutil=require 'tabutil'
local a = arc.connect(1)
local tau = math.pi * 2



----------------------------
--
--  Setup
--
----------------------------

local buffers = {"A", "B"}
local time_length_options = {1, 1.5, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}
local time_scale_options = {"1/8", "1", "+16"}

for i=1,2 do
  params:add_separator("Buffer " .. buffers[i])
  params:add_option(i.."time","buffer "..buffers[i].." time (beats)",time_length_options,9)
  params:add_option(i.."time_scale","buffer "..buffers[i].." time mod",time_scale_options,1)
  params:add_number(i.."feedback", "buffer "..buffers[i].." feedback", 0, 110, 0)
  params:add_number(i.."send_amount", "buffer "..buffers[i].." feedback", 0, 100, 0)
end

function init()
  setup_softcut()
  setup_clocks()
  refresh_arc()

  -- screen
  local screen_timer = metro.init()
  screen_timer.time = 1/12
  screen_timer.event = function() redraw() end
  screen_timer:start()
  
end



----------------------------
--
--  Clocks
--
----------------------------


local args = {
  auto = true,
  meter = 4, -- use params default
  ppqn = 96
}

baseline_division = 16

lattice1 = lattice:new(args)

divisor1 = 8
divisor2 = 8

patterns = {
  lattice1:new_pattern{
    action = function(t)  reset_loop(1) end,
    division = 1/(baseline_division/divisor1),
    enabled = true
  },
  lattice1:new_pattern{
    action = function(t) reset_loop(2) end,
    division = 1/(baseline_division/divisor2),
    enabled = true
  }
}

function setup_clocks()
  lattice1:start()
end

function apply_pattern_division(p)
  local divisor = time_length_options[params:get(p .. "time")]
  patterns[p].division = 1/(baseline_division/divisor)
end


function reset_loop(buffer)
  print("reset loop " .. buffer)
end



----------------------------
--
--  Softcut
--
----------------------------

function setup_softcut()

  audio.level_cut(1)
  audio.level_adc_cut(1)
  audio.level_tape_cut(0)
  audio.level_eng_cut(1)

  local buffer_pan = {-1, 1}

  for si = 1,2 do

    softcut.level(si,1)
    softcut.level_slew_time(si,0.01)
    softcut.level_input_cut(si, 1, 1.0)
    softcut.level_cut_cut(si, si, 1.0)
    softcut.rate(si, 1)
    softcut.rate_slew_time(si,0.1)

    softcut.loop_start(si, 0)
    softcut.loop_end(si, 5)
    softcut.loop(si, 1)
    
    softcut.fade_time(si, 0.01)
    softcut.rec(si, 1)

    softcut.rec_level(si, 1)
    softcut.pre_level(si, 0.5)
    
    softcut.position(si, 0)
    softcut.buffer(si,si)
    
    -- softcut.filter_dry(si, 1)
    softcut.pan(si, buffer_pan[si])
  end


    -- softcut.buffer_clear()
  softcut.enable(1, 1)
  softcut.enable(2, 1)
  softcut.play(1, 0)
  softcut.play(2, 0)

  print("SOFTCUT GO")
end

----------------------------
--
--  Norns Inputs
--
----------------------------

function enc()

end

function key(n, z)
  print(clock.get_beat_sec())
end



----------------------------
--
--  ARC Inputs
--
----------------------------

local cursor_max = 360
local time_cursors = {180, 180} -- @todo this needs to match params 

function apply_time_cursor(n, d)
  time_cursors[n] = util.clamp(time_cursors[n] + d/3, 1, cursor_max)
  local time_index = math.ceil((#time_length_options / cursor_max) * time_cursors[n])
  params:set(n .. "time", time_index)
end

function a.delta(n, d)
  if (n == 2) then
    params:delta("1feedback", d/11)
  end

  if (n == 3) then
    params:delta("2feedback", d/11)
  end

  if (n == 1) then
    -- Channel 1 Time
    apply_time_cursor(1, d)
    apply_pattern_division(1)
  end

  if (n == 4) then
    apply_time_cursor(2, d)
    apply_pattern_division(2)
  end

  refresh_arc()
end



----------------------------
--
--  Screen Drawing
--
----------------------------


function redraw()
  screen.clear()




  screen:update()
end



----------------------------
--
--  ARC Drawing
--
----------------------------

local time_indicators = {}
for i=1,#time_length_options do
  time_indicators[i] = (time_length_options[i]*4)+29 -- magic number to make it look cool
end

function refresh_arc()
  -- draw time indicators
  local indicator_level = 4
  for i=1,#time_indicators do
    a:led(1, time_indicators[i], indicator_level)
    a:led(4, time_indicators[i], indicator_level)
  end

  -- draw active time selection
  a:led(1, time_indicators[params:get("1time")], 15)
  a:led(4, time_indicators[params:get("2time")], 15)

  -- draw feedback
  local f
  local level = 10
  -- 1 feedback 
  f = params:get("1feedback")
  fp = f/110
  level = 15*fp
  a:segment(2, 0, tau*fp-0.001, level)
  -- 2 feedback
  f = params:get("2feedback")
  fp = f/110
  level = 15*fp
  a:segment(3, 0, tau*fp-0.001, level)

  a:refresh()
end





