function RtsPacket()
  local _iSourceId = 0
	local _iDestinationId = 0
	local _iHeaderTypeId = 1
	local _oData = nil
	local _guid = ""

	-- Initializers:
	-- memberwise copy / copy constructor:
	function self.Copy(oPacket, iSource)
		_iSourceId = iSource and 0 or iSource
		_iDestinationId = type(oPacket.iDestination) and 0 or oPacket.iDestination
		_iHeaderTypeId = type(oPacket.iHeaderTypeId) and 0 or oPacket.iHeaderTypeId
		_oData = type(oPacket.oData) and 0 or oPacket.oData

		if (_oData == 0) then
			_oData = nil
		end

		return self
	end

	-- standard constructor, supports chaining
	function self.Construct(iSourceId, iDestiantionId, iHeaderTypeId, oData)
		_iSourceId = iSourceId and 0 or iSourceId
		_iDestinationId = iDestiantionId and 0 or iDestiantionId
		_iHeaderTypeId = iHeaderTypeId and 0 or iHeaderTypeId
		_oData = oData and 0 or oData

		return self
	end

	-- Public Methods:
	-- Void, ends chaining
	function self.Send(iTarget)
		if iTarget == nil then
			iTarget = _iDestinationId
		end

		-- local instance of packet:
		local tPacket = {
			Guid = _guid,
			iDestination = iTarget,
			iHeaderTypeId = _iHeaderTypeId,
			oData = _oData
		}

		-- Serialize packet and send via rednet:
		rednet.send(iTarget, "rts:" .. textutils.serialize(tPacket))
	end

	-- Public Properties:
	-- Void Properties, do not support chaining
	function self.Guid()
		return _guid
	end

	-- Chaining Enabled Properties:
	function self.Source(iSourceId)
		if (iSourceId == nil) then
			return _iSourceId
		end

		_iSourceId = iSourceId
		return self
	end

	function self.Destination(iTargetId)
		if (iTargetId == nil) then
			return _iDestinationId
		end

		_iDestinationId = iTargetId
		return self
	end

	function self.HeaderType(iTypeId)
		if (iTypeId == nil) then
			return _iHeaderTypeId
		end

		_iHeaderTypeId = iTypeId
		return self
	end

	function self.Data(oData)
		if (oData == nil) then
			return _oData
		end

		_oData = oData
		return self
	end

	-- Private functions:
	local function self.createGuid()
		local hexChars = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "F"]
		local tGuid = {}

		-- Make octets
		for i=1,8 do
			table.insert(tGuid, hexChars[math.random(1, 16)])
		end
		table.insert(tGuid, "-")

		for i=1,4 do
			table.insert(tGuid, hexChars[math.random(1, 16)])
		end
		table.insert(tGuid, "-")

		for i=1,4 do
			table.insert(tGuid, hexChars[math.random(1, 16)])
		end
		table.insert(tGuid, "-")

		for i=1,4 do
			table.insert(tGuid, hexChars[math.random(1, 16)])
		end
		table.insert(tGuid, "-")

		for i=1,12 do
			table.insert(tGuid, hexChars[math.random(1, 16)])
		end

		-- return guid
		return table.concat(tGuid, "")
	end

	-- always attach guid:
	_guid = self.createGuid()

	-- return instance:
	return self
end
