--
-- Created by IntelliJ IDEA.
-- User: Stijn
-- Date: 27/12/12
-- Time: 23:30
-- To change this template use File | Settings | File Templates.
--

include("sb/classes/BaseEnvironment.lua")

-- Lua Specific
local type = type

-- Gmod specific
local Entity = Entity
local CurTime = CurTime
local net = net

-- Class Specific
local C = CLASS
local sb = sb;
local core = sb.core

-- Function Refs
local funcRef = {
    isA = C.isA,
    init = C.init,
    sendContent = C._sendContent,
    receiveSignal = C.receive,
    onSave = C.onSave,
    onLoad = C.onLoad
}

function C:isA(className)
    return funcRef.isA(self, className) or className == "LegacyPlanet"
end

local function Extract_Bit(bit, field)
    if not bit or not field then return false end
    local retval = 0
    if ((field <= 7) and (bit <= 4)) then
        if (field >= 4) then
            field = field - 4
            if (bit == 4) then return true end
        end
        if (field >= 2) then
            field = field - 2
            if (bit == 2) then return true end
        end
        if (field >= 1) then
            field = field - 1
            if (bit == 1) then return true end
        end
    end
    return false
end

function C:addBasicResources(pOxygen, pCO2, pNitrogen, pHydrogen)
    local total = pOxygen + pCO2 + pNitrogen + pHydrogen
    if total > 100 then
       total = total - pHydrogen
       pHydrogen = 0
       if total < 100 then
          pHydrogen = 100 - total
          total = 100
       end
    end
    if total > 100 then
        total = total - pNitrogen
        pNitrogen = 0
        if total < 100 then
            pNitrogen = 100 - total
            total = 100
        end
    end
    if total > 100 then
        total = total - pCO2
        pCO2 = 0
        if total < 100 then
            pCO2 = 100 - total
            total = 100
        end
    end
    if total > 100 then
        total = 100
        pOxygen = 100
    end
    pOxygen = pOxygen / 100
    pCO2 = pCO2 / 100
    pNitrogen = pNitrogen / 100
    pHydrogen = pHydrogen / 100
    local maxAmount = self:getMaxAmountOfResources()
    self:convertResource(nil, "oxygen", math.Round(pOxygen * maxAmount))
    self:convertResource(nil, "co2", math.Round(pCO2 * maxAmount))
    self:convertResource(nil, "nitrogen", math.Round(pNitrogen * maxAmount))
    self:convertResource(nil, "hydrogen", math.Round(pHydrogen * maxAmount))
end

function C:ProcessSB1Flags(flags)
    if not flags then return end
    if Extract_Bit(1, flags) then
       self:addBasicResources(50, 30, 10, 10)
    else
        self:addBasicResources(4, 56, 20, 20)
    end
    if Extract_Bit(2, flags) then
        self:addAttribute("UNSTABLE")
    end
    if Extract_Bit(3, flags) then
        self:addAttribute("SUNBURN")
    end
end

function C:ProcessSB3Flags(flags)
    if not flags then return end
    if Extract_Bit(1, flags) then
        self:addAttribute("UNSTABLE")
    end
    if Extract_Bit(2, flags) then
        self:addAttribute("SUNBURN")
    end
end

function C:init(entid, data)
    funcRef.init(self, entid, data)
    self.name = "Planet "..tostring(entid)
    if data then
        if data[1] == "planet" then
            self.radius = tonumber(data[2])
            self.gravity = tonumber(data[3])
            self.atmosphere = tonumber(data[4])
            self.temperature = tonumber(data[5])
            self.hightemperature = tonumber(data[6])
            if string.len(data[7]) > 0 then
               self.color_id = data[7]
            end
            if string.len(data[8]) > 0 then
                self.bloom_id = data[8]
            end
            self:ProcessSB1Flags(tonumber(data[16]))
        elseif data[1] == "planet2" then
            self.radius = tonumber(data[2])
            self.gravity = tonumber(data[3])
            self.atmosphere = tonumber(data[4])
            -- Ignore data[5] (pressure)
            self.temperature = tonumber(data[5])
            self.hightemperature = tonumber(data[7])
            self:ProcessSB3Flags(tonumber(data[8]))
            local oxygenpercentage = tonumber(data[9])
            local co2percentage = tonumber(data[10])
            local nitrogenpercentage = tonumber(data[11])
            local hydrogenpercentage = tonumber(data[12])
            self:addBasicResources(oxygenpercentage, co2percentage, nitrogenpercentage, hydrogenpercentage)
            self.name = (string.len(data[13]) > 0 and data[13]) or self.name
            if string.len(data[15]) > 0 then
                self.color_id = data[15]
            end
            if string.len(data[16]) > 0 then
                self.bloom_id = data[16]
            end
        elseif data[1] == "star" then
            self.radius = 512
            self.gravity = 0
            self.atmosphere = 0
            self.temperature = 10000
            self.hightemperature = 10000
        elseif data[1] == "star2" then
            self.radius = tonumber(data[2])
            self.temperature = tonumber(data[3])
            self.hightemperature = tonumber(data[5])
            self.name = (string.len(data[6]) > 0 and data[6]) or self.name
        end
        self.entities = {}
    end
end

function C:getRadius()
   return self.radius
end

function C:getVolume()
    return math.Round((4/3) * math.pi * self.radius * self.radius)
end

function C:getTemperature(ent)
    --TODO
    return self.temperature
end

function C:getEnvironmentColor()
   return sb.getEnvironmentColor(self.color_id)
end

function C:getEnvironmentBloom()
   return sb.getEnvironmentBloom(self.bloom_id)
end

function C:hasName()
    return true
end

function C:getName()
    return self.name
end

function C:addEntity(ent)
    self.entities[ent:EntIndex()] = ent
end

function C:removeEntity(ent)
    if self.entities[ent:EntIndex()] then
        self:setEnvironmentOnEntity(ent, sb.getSpace())
        self.entities[ent:EntIndex()] = nil
    end
end

function C:hasEntity(ent)
   return self.entities[ent:EntIndex()] ~= nil
end

function C:getEntities()
   return self.entities
end

function C:setEnvironmentOnEntity(ent, environment)
   if ent.environment ~= environment then
       sb.callOnLeaveEnvironmentHook(ent.environment, ent)
       ent.environment = environment
       environment:updateEnvironmentOnEntity(ent)
       if ent.ls_suit then
           ent.ls_suit:setEnvironment(environment)
       end
       sb.callOnEnterEnvironmentHook(self, ent)
   end
end

function C:updateEntities()
   -- PhysicInitSphere doesn't create a real sphere, but a box, so we have to do a more accurate check here
   local envent = self:getEntity()
   for k, ent in pairs(self.entities) do
      if sb.isValidSBEntity(ent) and ent:GetPos():Distance(envent:GetPos()) < self.radius then
          if ent.environment ~= self then
              self:setEnvironmentOnEntity(ent, self)
          end
      else
          if ent.environment ~= sb.getSpace() then
              self:setEnvironmentOnEntity(ent, sb.getSpace())
          end

      end
   end
end

function C:_sendContent(modified)
    funcRef.sendContent(self, modified)
    net.WriteString(self.name)
    if self.color_id then
        core.net.writeBool(true)
        net.WriteString(self.color_id)
    else
       core.net.writeBool(false)
    end
    if self.bloom_id then
        core.net.writeBool(true)
        net.WriteString(self.bloom_id)
    else
        core.net.writeBool(false)
    end
end

function C:receive()
    funcRef.receiveSignal(self)
    self.name = net.ReadString()
    if core.net.readBool() then
       self.color_id = net.ReadString()
    end
    if core.net.readBool() then
        self.bloom_id = net.ReadString()
    end
end

