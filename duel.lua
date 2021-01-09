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


local a = arc.connect(1)
local tau = math.pi * 2

local buffers = {"A", "B"}
local time_length_options = {1, 1.5, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}
local time_switch_options = {"1/8", "1", "+16"}
local beat_time = 0 -- ms of a beat from clock time


-- Params
for i=1,2 do
  params:add_separator("Buffer " .. buffers[i])
  params:add_option(i.."time","buffer "..buffers[i].." time (beats)",time_length_options,9)
  params:add_option(i.."time_mod","buffer "..buffers[i].." time mod",time_switch_options,1)
  params:add_number(i.."feedback", "buffer "..buffers[i].." feedback", 0, 110, 0)
end


function init()
  local screen_timer = metro.init()
  screen_timer.time = 1/15
  screen_timer.event = function() redraw() end
  screen_timer:start()

  
  -- softcut setup
  softcut.buffer_clear()
  audio.level_cut(1)
  audio.level_adc_cut(1)
  audio.level_tape_cut(0)
  audio.level_eng_cut(0)
  local buffer_pan = {-1, 1}
  audio.level_cut(1)
  audio.level_adc_cut(1)
  audio.level_eng_cut(1)
  -- softcut voices
  for si = 1,2 do
    softcut.level(si,1)
    softcut.level_slew_time(si,0.01)
    softcut.level_input_cut(si, si, 1.0)
    softcut.rate(si, 1)
    softcut.rate_slew_time(si,0.1)
    softcut.loop_start(si, 0)
    softcut.loop_end(si, 5)
    softcut.loop(si, 1)
    softcut.fade_time(si, 0.01)
    softcut.rec(si, 1)
    softcut.rec_level(si, 1)
    softcut.pre_level(si, 0)
    softcut.position(si, 0)
    softcut.buffer(si,si)
    softcut.enable(si, 1)
    softcut.filter_dry(si, 1)
    softcut.pan(si, buffer_pan[si])
  end
  
  refresh_arc()
  
end

function enc()

end

function key(n, z)

end

local time_cursor_1 = 1

function a.delta(n, d)
  if (n == 2) then
    params:delta("1feedback", d/11)
  end

  if (n == 3) then
    params:delta("2feedback", d/11)
  end



  if (n == 1) then
    -- Channel 1 Time
    params:delta("1time", d/5)
  end

  if (n == 4) then
    params:delta("2time", d/5)
  end


  refresh_arc()
end


function redraw()
end


function refresh_arc()
  -- Draw Screen

  -- Draw Arc
  local f
  local level = 10


  -- time

  for i=1,#time_length_options do
    level = 4
    if (time_length_options[i]) == params:get("1time") then level = 15 end
    a:led(1,(time_length_options[i]*4)+29,level) -- maaagic numberrrr
  end

  for i=1,#time_length_options do
    level = 4
    if (time_length_options[i]) == params:get("2time") then level = 15 end
    a:led(4,(time_length_options[i]*4)+29,level) -- maaagic numberrrr
  end


  f = params:get("1feedback")
  fp = f/110
  level = 15*fp
  a:segment(2, 0, tau*fp-0.001, level)

  f = params:get("2feedback")
  fp = f/110
  level = 15*fp
  a:segment(3, 0, tau*fp-0.001, level)

  a:refresh()
end
