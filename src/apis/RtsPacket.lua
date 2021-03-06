RtsPacketTypes = {
	Base = 1,
	Success = 2,
	Error = 3,
	Poll = 100,
	PollResponse = 101,
	Job = 200,
	JobAcknowledge = 201,
	JobStarted = 202,
	JobCompleted = 203,
	FileRequest = 300,
	FileData = 301
}

function RtsPacket()
	local self = {}
	local _iSourceId = 0
	local _iDestinationId = 0
	local _iHeaderTypeId = RtsPacketTypes.Base
	local _oData = nil
	local _guid = ""

	-- Initializers:
	-- memberwise copy / copy constructor:
	function self.Copy(oPacket, iSource)
		if (type(oPacket.Guid) == "function") then
			--oPacket contains the Guid() property, treat as instance of RtsPacket
			_iSourceId = (type(oPacket.Source) == "function") and oPacket.Source() or _iSourceId
			_iDestinationId = (type(oPacket.Destination) == "function") and oPacket.Destination() or _iDestinationId
			_iHeaderTypeId = (type(oPacket.HeaderType) == "function") and oPacket.HeaderType() or _iHeaderTypeId
			_oData = (type(oPacket.Data) == "function") and oPacket.Data() or 0
			_guid = (type(oPacket.Guid) == "function") and oPacket.Guid() or _guid
		else
			--Treat oPacket as instance of self.Send() tPacket table:
			_iSourceId = (iSource) and _iSourceId or iSource
			_iDestinationId = (type(oPacket.iDestination)) and _iDestinationId or oPacket.iDestination
			_iHeaderTypeId = (type(oPacket.iHeaderTypeId)) and _iHeaderTypeId or oPacket.iHeaderTypeId
			_oData = (type(oPacket.oData)) and 0 or oPacket.oData
			_guid = (type(oPacket.Guid)) and _guid or oPacket.Guid
		end

		-- necessary due to 'ternary' handling of nils
		if (_oData == 0) then
			_oData = nil
		end

		return self
	end

	-- standard constructor, supports chaining
	function self.Construct(iSourceId, iDestiantionId, iHeaderTypeId, oData)
		_iSourceId = iSourceId and _iSourceId or iSourceId
		_iDestinationId = iDestiantionId and _iDestinationId or iDestiantionId
		_iHeaderTypeId = iHeaderTypeId and _iHeaderTypeId or iHeaderTypeId
		_oData = oData and _oData or oData

		return self
	end

	-- Public Methods:
	-- Void, ends chaining
	function self.Send(iTarget)
		if (iTarget == nil) then
			iTarget = _iDestinationId
		end

		-- if no target, broadcast instead:
		if (iTarget == 0) then
			self.Broadcast()
		else
			-- local instance of packet:
			local tPacket = {
				Guid = _guid,
				iDestination = iTarget,
				iHeaderTypeId = _iHeaderTypeId,
				oData = _oData
			}

			-- Serialize packet and send via rednet to target:
			rednet.send(iTarget, "rts:" .. textutils.serialize(tPacket))
		end
	end

	function self.Broadcast()
		-- local instance of packet:
		local tPacket = {
			Guid = _guid,
			iDestination = 0,
			iHeaderTypeId = _iHeaderTypeId,
			oData = _oData
		}

		-- Serialize packet and broadcast via rednet to all listeners:
		rednet.broadcast("rts:" .. textutils.serialize(tPacket))
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

function RtsSuccessPacket()
	local self = RtsPacket().HeaderType(RtsPacketTypes.Success)

	-- wrap generic message in to Data property:
	function self.Message(oMessage)
		if (oMessage == nil) then
			return self.Data()
		end

		return self.Data(oMessage)
	end

	return self
end

function RtsErrorPacket()
	local self = RtsSuccessPacket().HeaderType(RtsPacketTypes.Error)
	return self
end

function RtsPollPacket()
	local self = RtsPacket().HeaderType(RtsPacketTypes.Poll)

	-- Flag Type Packet, remove Data property:
	self.Data = nil

	return self
end

function RtsPollResponsePacket()
	local self = RtsPacket().HeaderType(RtsPacketTypes.PollResponse)

	-- Flag Type Packet, remove Data property:
	self.Data = nil

	return self
end

function RtsJobPacket()
	local self = RtsPacket().HeaderType(RtsPacketTypes.Job)
	local _oCommandData = nil

	-- Wrap command and arguments in to the Data property:
	function self.Command(sCommand, ...)
		if (sCommand == nil) then
			return self.Data()
		end

		_oCommandData = { Command = sCommand, Arguments = arg}
		return self.Data(_oCommandData)
	end

	return self
end

function RtsJobAcknowledgePacket()
	local self = RtsPacket().HeaderType(RtsPacketTypes.JobAcknowledge)
	local _oCommandData = nil

	-- Flag Type Packet, remove Data property:
	self.Data = nil

	return self
end

function RtsJobStartedPacket()
	local self = RtsPacket().HeaderType(RtsPacketTypes.JobStarted)
	local _oCommandData = nil

	-- Flag Type Packet, remove Data property:
	self.Data = nil

	return self
end

function RtsJobCompletedPacket()
	local self = RtsPacket().HeaderType(RtsPacketTypes.JobCompleted)
	local _oCommandData = nil

	-- Flag Type Packet, remove Data property:
	self.Data = nil

	return self
end

function RtsFileRequestPacket()
	local self = RtsPacket().HeaderType(RtsPacketTypes.FileRequest)

	-- wrap generic message in to Data property:
	function self.File(sPath)
		if (sPath == nil) then
			return self.Data()
		end

		return self.Data(sPath)
	end
	
	return self
end

function RtsFileDataPacket()
	local self = RtsPacket().HeaderType(RtsPacketTypes.FileData)

	return self
end
