--====================================
-- Digital_Light_TSL2561
-- A library for TSL2561 for NodeMCU
--
-- Copyright (c) 2015 NodeMCU Team
-- Author     : Martin
-- Create Time:
-- Change Log :  
--
-- The MIT License (MIT)
--====================================

local moduleName = ... 
local M = {}
_G[moduleName] = M

local TSL2561_ADDR = 0x29
local TSL2561_Ctrl = 0x80
local TSL2561_Timing = 0x81
local TSL2561_Int = 0x86
local TSL2561_CHN = {0x8c,0x8d,0x8e,0x8f}
local LUX_SCALE = 14           
local RATIO_SCALE = 9          
local CH_SCALE = 10            
local CHSCALE_TINT0 = 0x7517   


local init_stu = false
local i2c_ID = 0

--local CH0,CH1

local K1T = 0x0040   -- 0.125 * 2^RATIO_SCALE
local B1T = 0x01f2   -- 0.0304 * 2^LUX_SCALE
local M1T = 0x01be   -- 0.0272 * 2^LUX_SCALE
local K2T = 0x0080   -- 0.250 * 2^RATIO_SCA
local B2T = 0x0214   -- 0.0325 * 2^LUX_SCALE
local M2T = 0x02d1   -- 0.0440 * 2^LUX_SCALE
local K3T = 0x00c0   -- 0.375 * 2^RATIO_SCALE
local B3T = 0x023f   -- 0.0351 * 2^LUX_SCALE
local M3T = 0x037b   -- 0.0544 * 2^LUX_SCALE
local K4T = 0x0100   -- 0.50 * 2^RATIO_SCALE
local B4T = 0x0270   -- 0.0381 * 2^LUX_SCALE
local M4T = 0x03fe   -- 0.0624 * 2^LUX_SCALE
local K5T = 0x0138   -- 0.61 * 2^RATIO_SCALE
local B5T = 0x016f   -- 0.0224 * 2^LUX_SCALE
local M5T = 0x01fc   -- 0.0310 * 2^LUX_SCALE
local K6T = 0x019a   -- 0.80 * 2^RATIO_SCALE
local B6T = 0x00d2   -- 0.0128 * 2^LUX_SCALE
local M6T = 0x00fb   -- 0.0153 * 2^LUX_SCALE
local K7T = 0x029a   -- 1.3 * 2^RATIO_SCALE
local B7T = 0x0018   -- 0.00146 * 2^LUX_SCALE
local M7T = 0x0012   -- 0.00112 * 2^LUX_SCALE
local K8T = 0x029a   -- 1.3 * 2^RATIO_SCALE
local B8T = 0x0000   -- 0.000 * 2^LUX_SCALE
local M8T = 0x0000   -- 0.000 * 2^LUX_SCALE

function M.init(sda,scl)
    i2c.setup(i2c_ID, sda, scl, i2c.SLOW)
    init_stu = true

    writeRegister(TSL2561_Ctrl, 0x03) -- Power Up
    writeRegister(TSL2561_Timing, 0x00) --No High Gain
    writeRegister(TSL2561_Int, 0x00)
    writeRegister(TSL2561_Ctrl, 0x00) -- power Down
end

function M.readVisibleLux()
    writeRegister(TSL2561_Ctrl, 0x03)
    tmr.delay(14000)

    local CH0_LOW,CH0_HIGH,CH1_LOW,CH1_HIGH
 
    CH0_LOW = readRegister(TSL2561_CHN[1],1)
    CH0_HIGH = readRegister(TSL2561_CHN[2],1)
    CH1_LOW = readRegister(TSL2561_CHN[3],1)
    CH1_HIGH = readRegister(TSL2561_CHN[4],1)

    CH0 = CH0_HIGH * 256 + CH0_LOW
    CH1 = CH1_HIGH * 256 + CH1_LOW

    writeRegister(TSL2561_Ctrl, 0x00)

    if CH0 / CH1 < 2 and CH0 > 4900 then
        return -1
    end

    CH0 = (CH0 * 0x7517 * 2^4) * 2 ^ 10
    CH1 = (CH1 * 0x7517 * 2^4) * 2 ^ 10

    local ratio1 = 0

    if CH0 ~= 0 then
        ratio1 = CH1 * 2 ^ (9+1) / CH0
    end

    local ratio = (ratio1 + 1 ) * 2 ^ -1

    local b,m

    if ratio >= 0  and ratio <= K1T then
        b = B1T
        m = M1T
    elseif ratio <= K2T then
        b = B2T
        m = M2T
    elseif ratio <= K3T then
        b = B3T
        m = M3T
    elseif ratio <= K4T then
        b = B4T
        m = M3T
    elseif ratio <= K5T then
        b = B5T
        m = M5T
    elseif ratio <= K6T then
        b = B6T
        m = M5T
    elseif ratio <= K7T then
        b = B7T
        m = M7T 
    elseif ratio > K8T then
        b = B8T
        m = M8T
    end

    local temp = CH0 * b - CH1 * m
    if temp < 0 then
        temp = 0
    end

    temp = temp + 1 * 2 ^ (LUX_SCALE-1)

    local lux = temp * 2 ^ (-LUX_SCALE)

    print(temp,lux,temp,ratio,ratio1)
    
    return lux

end


function readRegister(ADDR,LENGTH)
    i2c.start(i2c_ID)
    i2c.address(i2c_ID, TSL2561_ADDR, i2c.TRANSMITTER)
    i2c.write(i2c_ID, ADDR)
    i2c.stop(i2c_ID)
    i2c.start(i2c_ID)
    i2c.address(i2c_ID, TSL2561_ADDR, i2c.RECEIVER)
    tmr.delay(20000)
    local rt = i2c.read(i2c_ID, LENGTH)
    return string.byte(rt)
end

function writeRegister(ADDR, VAL)
    i2c.start(i2c_ID)
    i2c.address(i2c_ID, TSL2561_ADDR, i2c.TRANSMITTER)
    i2c.write(i2c_ID,ADDR)
    i2c.write(i2c_ID,VAL)
    i2c.stop(i2c_ID)
end

return M
