--====================================================
--AirQuality library ver 0.9 for NodeMCU
--2015 Copyright (c) NodeMCU Team  All right reserved.
-- 
--Original Author: Martin.Han
--Based on MIT Linences  
--===================================================


local moduleName = ...
local M = {}
_G[moduleName] = M

local B_AqiInitOK = false
local _pin = 0

local first_vol = 0
local last_vol = 0
local stardand_vol = 0
local _stardand_vol = 0
local counter = 0

local RAdc = adc.read
function M.init()

  print("System Starting...Please Wait")

  tmr.alarm(6,10000,1,function()

      local raw_adc_input = RAdc(_pin)

      if raw_adc_input <= 10 or raw_adc_input > 798 then
        print("Wating for Sensor Heating Up")
      else
        first_vol = raw_adc_input
        last_vol = raw_adc_input
        stardand_vol = raw_adc_input
        print("System Start OK")
        B_AqiInitOK = true
        tmr.stop(6)
        
        tmr.alarm(5,2000,1,function() 
          first_vol = last_vol
          last_vol = RAdc(_pin)

          if counter ~= 150 then
          counter = counter + 1
          _stardand_vol = _stardand_vol + last_vol
        else
          counter = 0
          stardand_vol = _stardand_vol / 150
        end

          end)
      end
      
    end)
end


function M.getSensorValue()
  if B_AqiInitOK then
    return first_vol
  else
    return -1
  end

end

function M.getRealValue()
  if B_AqiInitOK then
    return first_vol - stardand_vol
  else
    return -1
  end

end

function M.getSlope()

    local abs = math.abs

  if B_AqiInitOK then
    if abs(first_vol-last_vol) > 100 or first_vol>700 then
     return "High Pollution! Sensor Data invaild",3
    end
    
    if (abs(first_vol-last_vol)>400 and first_vol<700) or abs(first_vol-stardand_vol)>150 then
      return "High Pollution!",2
    end

    if (abs(first_vol-last_vol)>200 or first_vol<700) and abs(first_vol - stardand_vol) >50 then
      return "Low Pollution",1
   end
  
    return "Air Fresh",0
  else
    return -1
  end
end

return M
