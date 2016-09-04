-- Non-game-specific value classes,
-- and their supporting functions.

package.loaded.utils = nil
local utils = require "utils"
local subclass = utils.subclass
package.loaded.utils_math = nil
local utils_math = require "utils_math"
local Vector3 = utils_math.Vector3

local valuetypes = {}



local Block = {}
Block.values = {}
-- TODO: Check if needed
-- Block.valuesToInitialize = {}
-- Block.ValueClass = nil
Block.nextAutomaticKeyNumber = 1
valuetypes.Block = Block

function Block:init()
  -- self.a = new object of class self.values.a, whose init() must take 0 args.
  -- init() might require game or block to be set, so set first, then init().
  for key, value in pairs(self.values) do
    self[key] = subclass(value)
    self[key].game = self.game
    self[key].block = self
    self[key]:init()
  end
end

function Block:addWithAutomaticKey(value)
  -- This works as long as no manually-specified keys are named _1, _2, etc.
  local key = '_'..tostring(self.nextAutomaticKeyNumber)
  self.values[key] = value
  self.nextAutomaticKeyNumber = self.nextAutomaticKeyNumber + 1
  return key
end



function valuetypes.V(valueClass, ...)
  local newValue = subclass(valueClass)
  
  newValue.init = utils.curryInstance(valueClass.init, ...)
  
  return newValue
end

function valuetypes.MV(label, offset, valueClass, typeMixinClass, extraArgs)
  local newValue = subclass(valueClass, typeMixinClass)
  
  local function f(
      newV_, label_, offset_, valueClass_, typeMixinClass_, extraArgs_)
    valueClass_.init(newV_, label_, offset_)
    typeMixinClass_.init(newV_, extraArgs_)
  end
  
  newValue.init = utils.curryInstance(
    f, label, offset, valueClass, typeMixinClass, extraArgs)
    
  return newValue
end

-- TODO: Check if needed

-- function Block:init()
--   for _, value in pairs(self.valuesToInitialize) do
--     value.obj.game = self.game
--     value.obj.block = self
--     value.initCallable()
--   end
-- end

-- function Block:addV(valueClass, ...)
--   local newValue = subclass(valueClass)
--   local initCallable = utils.curry(valueClass.init, newValue, ...)
  
--   -- Save the object in a table.
--   -- Later, when we have an initialized Block object,
--   -- we'll iterate over this table, set the game attribute for each object,
--   -- and call each object's initialization callable.
--   table.insert(
--     self.valuesToInitialize, {obj=newValue, initCallable=initCallable})
--   return newValue
-- end

-- function Block:addMV(label, offset, valueClass, typeMixinClass, extraArgs)
--   local newValue = subclass(valueClass, typeMixinClass)
  
--   local function f(
--       newV_, label_, offset_, valueClass_, typeMixinClass_, extraArgs_)
--     valueClass_.init(newV_, label_, offset_)
--     typeMixinClass_.init(newV_, extraArgs_)
--   end
  
--   local initCallable = utils.curry(
--     f, newValue, label, offset, valueClass, typeMixinClass, extraArgs)
  
--   -- Save the object in a table.
--   -- Later, when we have an initialized Block object,
--   -- we'll iterate over this table, set the game attribute for each object,
--   -- and call each object's initialization callable.
--   table.insert(
--     self.valuesToInitialize, {obj=newValue, initCallable=initCallable})
    
--   return newValue
-- end



Value = {}
valuetypes.Value = Value
Value.label = "Label not specified"
Value.initialValue = nil
Value.invalidDisplay = "<Invalid value>"

function Value:init()
  self.value = self.initialValue
  self.lastUpdateFrame = self.game:getFrameCount()
end

function Value:updateValue()
  -- Subclasses should implement this function to update self.value.
  error("Function not implemented")
end

function Value:update()
  -- Generally this shouldn't be overridden.
  local currentFrame = self.game:getFrameCount()
  if self.lastUpdateFrame == currentFrame then return end
  self.lastUpdateFrame = currentFrame
  
  self:updateValue()
end

function Value:get()
  self:update()
  return self.value
end

function Value:isValid()
  -- Is there currently a valid value here? Or is there a problem which could
  -- make the standard value-getting functions return something nonsensical
  -- (or trigger an error)?
  -- For example, if there is a memory value whose pointer becomes
  -- invalid sometimes, then it can return false in those cases.
  return true
end

function Value:displayValue(options)
  -- Subclasses with non-float values should override this.
  -- This is separate from display() for ease of overriding this function.
  return utils.floatToStr(self.value, options)
end

function Value:getLabel()
  -- If there is anything dynamic about a Value's label display,
  -- this function can be overridden to accommodate that.
  return self.label
end

function Value:display(passedOptions)
  self:update()
  
  local options = {}
  -- First apply default options
  if self.displayDefaults then
    utils.updateTable(options, self.displayDefaults)
  end
  -- Then apply passed-in options, replacing default options of the same keys
  if passedOptions then
    utils.updateTable(options, passedOptions)
  end
  
  local valueDisplay = nil
  local valueDisplayFunction =
    options.valueDisplayFunction or utils.curry(self.displayValue, self)
    
  if self:isValid() then
    valueDisplay = valueDisplayFunction(options)
  else
    valueDisplay = self.invalidDisplay
  end
  
  if options.nolabel then
    return valueDisplay
  else
    local label = options.label or self:getLabel()
    if options.narrow then
      return label..":\n "..valueDisplay
    else
      return label..": "..valueDisplay
    end
  end
end


-- TODO: Move to layouts?
function valuetypes.openEditWindow(mvObj, updateDisplayFunction)
  -- mvObj = MemoryValue object

  local font = nil
  
  -- Create an edit window
  local window = createForm(true)
  window:setSize(400, 50)
  window:centerScreen()
  window:setCaption(mvObj:getEditWindowTitle())
  font = window:getFont()
  font:setName("Calibri")
  font:setSize(10)
  
  -- Add a text box with the current value
  local textField = createEdit(window)
  textField:setPosition(70, 10)
  textField:setSize(200, 20)
  textField.Text = mvObj:getEditFieldText()
  
  -- Put an OK button in the window, which would change the value
  -- to the text field contents, and close the window
  local okButton = createButton(window)
  okButton:setPosition(300, 10)
  okButton:setCaption("OK")
  okButton:setSize(30, 25)
  local confirmValueAndCloseWindow = function(mvObj, window, textField)
    local newValue = mvObj:strToValue(textField.Text)
    if newValue == nil then return end
    mvObj:set(newValue)
    
    -- Delay for a bit first, because it seems that the
    -- write to the memory address needs a bit of time to take effect.
    -- TODO: Use Timer instead of sleep?
    sleep(50)
    -- Update the display.
    updateDisplayFunction()
    -- Close the edit window.
    window:close()
  end
  
  local okAction = utils.curry(confirmValueAndCloseWindow, mvObj, window, textField)
  okButton:setOnClick(okAction)
  
  -- Put a Cancel button in the window, which would close the window
  local cancelButton = createButton(window)
  cancelButton:setPosition(340, 10)
  cancelButton:setCaption("Cancel")
  cancelButton:setSize(50, 25)
  local closeWindow = function(window)
    window:close()
  end
  cancelButton:setOnClick(utils.curry(closeWindow, window))
  
  -- Add a reset button, if applicable
  if mvObj.getResetValue then
    local resetButton = createButton(window)
    resetButton:setPosition(5, 10)
    resetButton:setCaption("Reset")
    resetButton:setSize(50, 25)
    local resetValue = function(textField)
      textField.Text = mvObj:toStrForEditField(mvObj:getResetValue())
    end
    resetButton:setOnClick(utils.curry(resetValue, textField))
  end
  
  -- Put the initial focus on the text field.
  textField:setFocus()
end


-- TODO: Move to layouts?
function valuetypes.addAddressToList(mvObj, args)
  -- mvObj = MemoryValue object
  -- args = table of custom arguments for the address list entry, otherwise
  -- it's assumed that certain fields of the mvObj should be used
  
  local addressList = getAddressList()
  local memoryRecord = addressList:createMemoryRecord()
  
  local address = mvObj:getAddress()
  if args.address then address = args.address end
  
  local description = mvObj.label
  if args.description then description = args.description end
  
  local displayType = mvObj.addressListType
  
  -- setAddress doesn't work for some reason, despite being in the Help docs?
  memoryRecord.Address = utils.intToHexStr(address)
  memoryRecord:setDescription(description)
  memoryRecord.Type = displayType
  
  if displayType == vtCustom then
  
    local customTypeName = mvObj.addressListCustomTypeName
    memoryRecord.CustomTypeName = customTypeName
    
  elseif displayType == vtBinary then
  
    -- TODO: Can't figure out how to set the start bit and size.
    -- And this entry is useless if it's a 0-sized Binary display (which is
    -- default). So, best we can do is to make this entry a Byte...
    memoryRecord.Type = vtByte
    
    local binaryStartBit = mvObj.binaryStartBit
    if args.binaryStartBit then binaryStartBit = args.binaryStartBit end
    
    local binarySize = mvObj.binarySize
    if args.binarySize then binarySize = args.binarySize end
    
    -- This didn't work.
    --memoryRecord.Binary.Startbit = binaryStartBit
    --memoryRecord.Binary.Size = binarySize
    
  end
end



local MemoryValue = subclass(Value)
valuetypes.MemoryValue = MemoryValue

function MemoryValue:init(label, offset)
  Value.init(self)

  -- These parameters are optional; will be nil if unspecified.
  self.label = label
  self.offset = offset
end

function MemoryValue:getAddress()
  error("Must be implemented by subclass")
end

function MemoryValue:updateValue()
  self.value = self:read(self:getAddress())
end
function MemoryValue:set(v)
  self:write(self:getAddress(), v)
end

function MemoryValue:getEditFieldText()
  return self:toStrForEditField(self:get())
end
function MemoryValue:getEditWindowTitle()
  return string.format("Edit: %s", self.label)
end

function MemoryValue:addAddressesToList()
  -- TODO: Where is this function from now?
  addAddressToList(self, {})
end



-- Not considered a descendant of MemoryValue, but can be used
-- as a mixin class when initializing a MemoryValue.
local TypeMixin = {}
function TypeMixin:init() end
function TypeMixin:read(address)
  error("Must be implemented by subclass")
end
function TypeMixin:write(address, v)
  error("Must be implemented by subclass")
end
function TypeMixin:strToValue(s)
  error("Must be implemented by subclass")
end
function TypeMixin:displayValue(v, options)
  error("Must be implemented by subclass")
end
function TypeMixin:toStrForEditField(v, options)
  error("Must be implemented by subclass")
end
function TypeMixin:equals(obj2)
  return self:get() == obj2:get()
end

-- TODO: Consider renaming the following classes: FloatValue -> FloatType, etc.
local FloatValue = subclass(TypeMixin)
valuetypes.FloatValue = FloatValue
function FloatValue:read(address)
  return utils.readFloatBE(address, self.numOfBytes)
end
function FloatValue:write(address, v)
  return utils.writeFloatBE(address, v, self.numOfBytes)
end
function FloatValue:strToValue(s) return tonumber(s) end
function FloatValue:displayValue(options)
  return utils.floatToStr(self.value, options)
end
function FloatValue:toStrForEditField(v, options)
  -- Here we have less concern of looking good, and more concern of
  -- giving more info.
  options.afterDecimal = options.afterDecimal or 10
  options.trimTrailingZeros = options.trimTrailingZeros or false
  return utils.floatToStr(v, options)
end
FloatValue.numOfBytes = 4
-- For the memory record type constants, look up defines.lua in
-- your Cheat Engine folder.
FloatValue.addressListType = vtCustom
FloatValue.addressListCustomTypeName = "Float Big Endian"

local IntValue = subclass(TypeMixin)
valuetypes.IntValue = IntValue
function IntValue:read(address)
  return utils.readIntBE(address, self.numOfBytes)
end
function IntValue:write(address, v)
  return utils.writeIntBE(address, v, self.numOfBytes)
end
function IntValue:strToValue(s) return tonumber(s) end
function IntValue:displayValue() return tostring(self.value) end
IntValue.toStrForEditField = IntValue.displayValue 
IntValue.numOfBytes = 4
IntValue.addressListType = vtCustom
IntValue.addressListCustomTypeName = "4 Byte Big Endian"

local ShortValue = subclass(IntValue)
valuetypes.ShortValue = ShortValue
ShortValue.numOfBytes = 2
ShortValue.addressListType = vtCustom
ShortValue.addressListCustomTypeName = "2 Byte Big Endian"

local ByteValue = subclass(IntValue)
valuetypes.ByteValue = ByteValue
ByteValue.numOfBytes = 1
ByteValue.addressListType = vtByte

-- Floats are interpreted as signed by default, while integers are interpreted
-- as unsigned by default. We'll define a few classes to interpret integers
-- as signed.
local function readSigned(self, address)
  local v = utils.readIntBE(address, self.numOfBytes)
  return utils.unsignedToSigned(v, self.numOfBytes)
end
local function writeSigned(self, address, v)
  local v2 = utils.signedToUnsigned(v, self.numOfBytes)
  return utils.writeIntBE(address, v2, self.numOfBytes)
end

valuetypes.SignedIntValue = subclass(IntValue)
valuetypes.SignedIntValue.read = readSigned
valuetypes.SignedIntValue.write = writeSigned

valuetypes.SignedShortValue = subclass(ShortValue)
valuetypes.SignedShortValue.read = readSigned
valuetypes.SignedShortValue.write = writeSigned

valuetypes.SignedByteValue = subclass(ByteValue)
valuetypes.SignedByteValue.read = readSigned
valuetypes.SignedByteValue.write = writeSigned


local StringValue = subclass(TypeMixin)
valuetypes.StringValue = StringValue
function StringValue:init(extraArgs)
  TypeMixin.init(self)
  self.maxLength = extraArgs.maxLength
    or error("Must specify a max string length")
end
function StringValue:read(address)
  return readString(address, self.maxLength)
end
function StringValue:write(address, text)
  writeString(address, text)
end
function StringValue:strToValue(s) return s end
function StringValue:displayValue() return self.value end
StringValue.toStrForEditField = StringValue.displayValue 
StringValue.addressListType = vtString
-- TODO: Figure out the remaining details of adding a String to the
-- address list. I think there's a couple of special fields for vtString?
-- Check Cheat Engine's help.



local BinaryValue = subclass(TypeMixin)
valuetypes.BinaryValue = BinaryValue
BinaryValue.addressListType = vtBinary
BinaryValue.initialValue = {}

function BinaryValue:init(extraArgs)
  TypeMixin.init(self)
  self.binarySize = extraArgs.binarySize
    or error("Must specify size of the binary value (number of bits)")
  -- Possible binaryStartBit values from left to right: 76543210
  self.binaryStartBit = extraArgs.binaryStartBit
    or error("Must specify binary start bit (which bit within the byte)")
end

function BinaryValue:read(address)
  -- address is the byte address
  -- Returns: a table of the bits
  -- For now, we only support binary values contained in a single byte.
  local byte = utils.readIntBE(address, 1)
  local endBit = self.binaryStartBit - self.binarySize + 1
  local bits = {}
  for bitNumber = self.binaryStartBit, endBit, -1 do
    -- Check if the byte has 1 or 0 in this position.
    if 2^bitNumber == bAnd(byte, 2^bitNumber) then
      table.insert(bits, 1)
    else
      table.insert(bits, 0)
    end
  end
  return bits
end

function BinaryValue:write(address, v)
  -- v is a table of the bits
  -- For now, we only support binary values contained in a single byte.
  
  -- Start with the current byte value. Then write the bits that need to
  -- be written.
  local byte = utils.readIntBE(address, 1)
  local endBit = self.binaryStartBit - self.binarySize + 1
  local bitCount = 0
  for bitNumber = self.binaryStartBit, endBit, -1 do
    bitCount = bitCount + 1
    if v[bitCount] == 1 then
      byte = bOr(byte, 2^bitNumber)
    else
      byte = bAnd(byte, 255 - 2^bitNumber)
    end
  end
  utils.writeIntBE(address, byte, 1)
end

function BinaryValue:strToValue(s)
  local bits = {}
  -- Iterate over string characters (http://stackoverflow.com/a/832414)
  for singleBitStr in s:gmatch"." do
    if singleBitStr == "1" then
      table.insert(bits, 1)
    elseif singleBitStr == "0" then
      table.insert(bits, 0)
    else
      return nil
    end
  end
  if self.binarySize ~= #bits then return nil end
  return bits
end

function BinaryValue:displayValue()
  -- self.value is a table of bits
  local s = ""
  for _, bit in pairs(self.value) do
    s = s .. tostring(bit)
  end
  return s
end
BinaryValue.toStrForEditField = BinaryValue.displayValue

function BinaryValue:equals(obj2)
  -- Lua doesn't do value-based equality of tables, so we need to compare
  -- the elements one by one.
  local v1 = self:get()
  local v2 = obj2:get()
  for index = 1, #v1 do
    if v1[index] ~= v2[index] then return false end
  end
  -- Also compare table lengths; this accounts for the case where v1 is just
  -- the first part of v2.
  return #v1 == #v2
end



local Vector3Value = subclass(Value)
valuetypes.Vector3Value = Vector3Value
Vector3Value.initialValue = "Value field not used"

function Vector3Value:init(x, y, z)
  Value.init(self)
  self.x = x
  self.y = y
  self.z = z
end

function Vector3Value:get()
  self:update()
  return Vector3:new(self.x:get(), self.y:get(), self.z:get())
end

function Vector3Value:set(vec3)
  self.x:set(vec3.x)
  self.y:set(vec3.y)
  self.z:set(vec3.z)
end

function Vector3Value:isValid()
  return (self.x:isValid() and self.y:isValid() and self.z:isValid()) 
end

function Vector3Value:update()
  self.x:update()
  self.y:update()
  self.z:update()
end

function Vector3Value:display(passedOptions)
  local options = {}
  -- First apply default options
  if self.displayDefaults then
    for key, value in pairs(self.displayDefaults) do
      options[key] = value
    end
  end
  -- Then apply passed-in options, replacing default options of the same keys
  if passedOptions then
    for key, value in pairs(passedOptions) do
      options[key] = value
    end
  end
  
  local label = options.label or self.label

  local format = nil
  if options.narrow then
    format = "%s:\n X %s\n Y %s\n Z %s"
  else
    format = "%s: X %s | Y %s | Z %s"
  end
  
  self:update()
  return string.format(
    format,
    label,
    self.x:displayValue(options),
    self.y:displayValue(options),
    self.z:displayValue(options)
  )
end



local RateOfChange = subclass(Value)
valuetypes.RateOfChange = RateOfChange
RateOfChange.label = "Label to be passed as argument"
RateOfChange.initialValue = 0.0

function RateOfChange:init(baseValue, label)
  Value.init(self)
  
  self.baseValue = baseValue
  self.label = label
  -- Display the same way as the base value
  self.displayValue = baseValue.displayValue
end

function RateOfChange:updateValue()
  -- Update prev and curr stat values
  self.prevStat = self.currStat
  self.baseValue:update()
  self.currStat = self.baseValue.value
  
  -- Update rate of change value
  if self.prevStat == nil then
    self.value = 0.0
  else
    self.value = self.currStat - self.prevStat
  end
end



local ResettableValue = subclass(Value)
valuetypes.ResettableValue = ResettableValue

function ResettableValue:init(resetButton)
  Value.init(self)
  
  -- Default reset button is D-Pad Down, which is assumed to be represented
  -- with 'v'.
  -- TODO: Allow each game to define a default reset button.
  self.resetButton = resetButton or 'v'
end

function ResettableValue:reset()
  error(
    "Reset function not implemented in value of label: "..self.baseValue.label)
end

function ResettableValue:update()
  -- Do an initial reset, if we haven't already.
  -- We don't do this in init() because the reset function may depend on
  -- looking up other Values, which may require that those Values be
  -- initialized. And there is no guarantee about the initialization
  -- order of Values.
  if not self.initialResetDone then
    self:reset()
    self.initialResetDone = true
  end

  Value.update(self)
  
  -- If the reset button is being pressed, call the reset function.
  if self.game.buttons:get(self.resetButton) == 1 then self:reset() end
end



local MaxValue = subclass(ResettableValue)
valuetypes.MaxValue = MaxValue
MaxValue.label = "Label to be passed as argument"
MaxValue.initialValue = 0.0

function MaxValue:init(baseValue, resetButton)
  ResettableValue.init(self, resetButton)
  
  self.baseValue = baseValue
  self.label = "Max "..baseValue.label
  -- Display the same way as the base value
  self.displayValue = baseValue.displayValue
end

function MaxValue:updateValue()
  self.baseValue:update()

  if self.baseValue.value > self.value then
    self.value = self.baseValue.value
  end
end

function MaxValue:reset()
  -- Set max value to (essentially) negative infinity, so any valid value
  -- is guaranteed to be the new max
  self.value = -math.huge
end



local AverageValue = subclass(ResettableValue)
valuetypes.AverageValue = AverageValue
AverageValue.label = "Label to be passed as argument"
AverageValue.initialValue = 0.0

function AverageValue:init(baseValue)
  ResettableValue.init(self, resetButton)
  
  self.baseValue = baseValue
  self.label = "Avg "..baseValue.label
  -- Display the same way as the base value
  self.displayValue = baseValue.displayValue
end

function AverageValue:updateValue()
  self.baseValue:update()
  self.sum = self.sum + self.baseValue.value
  self.numOfDataPoints = self.numOfDataPoints + 1

  self.value = self.sum / self.numOfDataPoints
end

function AverageValue:reset()
  self.sum = 0
  self.numOfDataPoints = 0
end



local Buttons = subclass(Value)
valuetypes.Buttons = Buttons

function Buttons:get(button)
  -- button is a string code representing a button, such as 'A', 'B', or '>'.
  -- Return 1 if the button is currently being pressed, 0 otherwise.
  error("Not implemented")
end

function Buttons:display(options)
  if not options.button then error("Must specify a button") end
  if self:get(options.button) == 1 then
    return options.button
  else
    return " "
  end
end



return valuetypes

