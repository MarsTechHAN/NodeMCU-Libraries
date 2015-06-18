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

local init_stu = false
local i2c_ID = 0

local CH0,CH1

function M.init(sda,scl)
	i2c.setup(TSL2561_ADDR, sda, scl, i2c.SLOW)
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
	CH0_LOW = readRegister(TSL2561_CHN[0])
	CH0_HIGH = readRegister(TSL2561_CHN[1])
	CH1_LOW = readRegister(TSL2561_CHN[2])
	CH0_HIGH = readRegister(TSL2561_CHN[3])

	CH0 = CH0_HIGH * 256 + CH0_LOW
	CH1 = CH1_HIGH * 256 + CH1_LOW

	writeRegister(TSL2561_Ctrl, 0x00)

	if CH0 / CH1 < 2 && CH0 > 4900 then
		return -1
	end

	CH0 = (CH0 * 0x7517 * 2^4) * 2 ^ 10
	CH1 = (CH1 * 0x7517 * 2^4) * 2 ^ 10

	if  (100 * CH1)/CH0 > 0 and (100 * CH1)/CH0 <= 50 then
		return (304 * CH0 - 620 * CH0 * (100 * CH1)/CH0 / 4) / 100000
	end

	if (100 * CH1)/CH0 > 50 and (100 * CH1)/CH0 <= 61 then
		return ((224 * CH0) - 310 * CH1) / 1000
	end

	if (100 * CH1)/CH0 > 61 and (100 * CH1)/CH0 <= 80 then
		return ((128 * CH0) - 153 * CH1) / 1000
	end

	if (100 * CH1)/CH0 > 80 and (100 * CH1)/CH0 <= 130 then
		return (146 * CH0 - 11 * CH1)
	end

	return 0 
end


local function readRegister(ADDR,LENGTH)
	i2c.start(i2c_ID)
	i2c.address(i2c_ID, TSL2561_ADDR, i2c.TRANSMITTER)
	i2c.write(i2c_ID, CMD)
	i2c.stop(i2c_ID)
	i2c.start(i2c_ID)
	i2c.address(i2c_ID, TSL2561_ADDR, i2c.RECEIVER)
	tmr.delay(200000)
	local rt = i2c.read(i2c_ID, LENGTH)
	return rt
end

local function writeRegister(ADDR, VAL)
	i2c.start(i2c_ID)
	i2c.address(i2c_ID, TSL2561_ADDR, i2c.TRANSMITTER)
	i2c.write(ADDR)
	i2c.write(VAL)
	i2c.stop(i2c_ID)
end
