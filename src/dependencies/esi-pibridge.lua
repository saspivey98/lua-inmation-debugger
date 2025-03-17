-- esi-pibridge
local J = require('rapidjson')
local socket = require('socket')

--Tries to convert the given string to a number or a boolean. If not possible, returns the string originally passed.
local function LUATYPE(arg)
	--ignore numbers,booleans, nils,
	if type(arg) == "string" then
		--if number convert
		if tonumber(arg) ~= nil then
			return tonumber(arg)
		--if boolean convert
		elseif arg:lower() == "true" then
			return true
		elseif arg:lower() == "false" then
			return false
		--else return string
		else
			return arg
		end
	elseif type(arg) == "boolean" or type(arg) == "number" then
		return arg
	else
		return "Invalid type passed: "..type(arg)
	end
end

local lib = {
	-- external libraries
	-- global values
	starttime = nil,
	tcp = nil,
	tcpexception = nil,
	tcpconfig = {},
	buffersize = 2048,
	alias = {
		["PIPoint"] = "P", -- old "PIPoint"
		["Values"] = "V", -- old "Values"
		["AFtime"] = "t", -- old "AFtime"
		["Value"] = "v", -- old "Value"
		["SystemState"] = "s",
		["maxhistorypoints"] = 10000,
		["piserver"] = "PI-Default",
		["AFBufferOption"] = 1,
		["AFUpdateOption"] = 0
	}
}
function lib.INFO(_)
	return {
		version = {
			major = 1,
			minor = 88,
			revision = 1
		},
		contacts = {
			{
				name = "Florian Seidl",
				email = "florian.seidl@cts-gmbh.de"
			},
			{
				name = "David Denk",
				email = "david.denk@cts-gmbh.de"
			},
			{
				name = "Clemens Schadner",
				email = "clemens.schadner@cts-gmbh.de"
			}
		},
		library = {
			modulename = "esi-pibridge"
		},
		dependencies = {
			{
				modulename = "rapidjson",
				version = {
					major = 0,
					minor = 7,
					revision = 1
				}
			},
			{
				modulename = "socket",
				version = {
					major = 3,
					minor = 0,
					revision = 0
				}
			}
		}
	}
end

function lib:SETALIAS(args)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("SETALIAS should be called using colon ':' notation", 2)
	end

	if type(args) == "table" then
		for k, v in pairs(args) do
			self.alias[k] = v
		end
	end
end
-- @md
function lib:SETCONNECTION(args)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("SETCONNECTION should be called using colon ':' notation", 2)
	end

	if type(args) ~= "table" then
		error(("Parameter #1 has the wrong type. Expected: %q; actual: %q"):format("table", type(args)), 2)
	end

	self.starttime = self.starttime or syslib.now()
	if type(args) == "table" then
		self.alias = args.alias or self.alias
		self.tcpconfig.host = args.host or "127.0.0.1"
		self.tcpconfig.port = args.port or 5959
		self.tcpconfig.timeout = args.timeout or 3
		self.buffersize = args.buffersize or 2048
	end
end
-- initial function to connect to the PI bridge and get the status from the bridge
function lib:_ensureconnect()
	if type(self.tcp) == "nil" then
		self.tcp = assert(socket.tcp())
		if self.tcpconfig == nil or self.tcpconfig.host == nil or self.tcpconfig.port == nil then
			error("SETCONNECTION not called", 4)
		end
		self.tcp:connect(self.tcpconfig.host, self.tcpconfig.port)
		self.tcp:settimeout(self.tcpconfig.timeout)
		local call = {
			["sys"] = "inmationPIBridge",
			["func"] = "GetStatus",
			["farg"] = {}
		}
		self:_send(call)
		local _, exception = self:_tcpreceive()

		if type(exception) ~= "nil" then
			return false, exception
		end
	end
	return true
end
--@md
function lib:CONNECTTOPI(args)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("CONNECTTOPI should be called using colon ':' notation", 2)
	end
	local rt = syslib.now()
	local call = {
		["sys"] = "OSI",
		["func"] = "ConnectToPI",
		["piserver"] = args["piserver"] or self.alias.piserver
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()
		local info= {
			PISDKVersion = result["PISDKVersion"],
			AFSDKVersion = result["AFSDKVersion"]
		}
		result = result or {["Connected"] = false}
		return result["Connected"], exception, {["runtime"] = syslib.now() - rt},info
	end
	return nil, tcpex
end
--@md
function lib:CONNECTTOAF(args)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("CONNECTTOAF should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "ConnectToAF",
		["afserver"] = args["afserver"] or ""
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()
		return result["Connected"], exception
	end
	return nil, tcpex
end
--@md
function lib:GETSTATUS()
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("GETSTATUS should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "inmationPIBridge",
		["func"] = "GetStatus",
		["farg"] = {}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()
		if type(result) == "table" then
			if type(result["farg"]) == "table" then
				return result["farg"], exception
			end
		end
		return result, exception
	end
	return nil, tcpex
end
-- @md
function lib:CLOSECONNECTION()
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("CLOSECONNECTION should be called using colon ':' notation", 2)
	end
	local result = {
		["wasConnected"] = false,
		["connectionClosed"] = false
	}
	if self.tcp then
		result["wasConnected"] = true
		local ok, _ = pcall(self.tcp.close, self.tcp)--was local ok, re
		if ok then
			self.tcp = nil
		end
	end

	if self.tcp == nil then
		result["connectionClosed"] = true
	end
	if self.starttime then
		result["endtime"] = syslib.now() - self.starttime
	end

	return result
end
-- @md
function lib:TESTCONNECTION()
  if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("TESTCONNECTION should be called using colon ':' notation", 2)
  end
  --local response = {}
  local call = {
		["sys"] = "OSI",
		["func"] = "TestConnection",
		["farg"] = {}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local _, exception = self:_tcpreceive()--was local result, exception
		if exception == nil then
			return {["Connected"] = true}, nil
		else
			return {["Connected"] = false}, tcpex
		end
	else
		return {["Connected"] = false}, tcpex
	end
end
-- @md
function lib:CURRENTVALUES(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("CURRENTVALUES should be called using colon ':' notation", 2)
	end
	local response = {}
	local call = {
		["sys"] = "OSI",
		["func"] = "CurrentValues",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["farg"] = {
			["P"] = {}
		}
	}
	if type(arg["tags"]) == "nil" then
		return nil, {["msg"] = "Warning: Function argument 'tags' is nil!"}
	end
	for _, tagpath in pairs(arg["tags"]) do
		local tagname = self:_gettagname(arg.disluaclean or false,tagpath,"\\")
		table.insert(call["farg"]["P"], tagname)
	end
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local dataresponse, ex = self:_tcpreceive()

		arg["response"] = arg["response"] or "inmation"
		if arg["response"] == "raw" then
			response = dataresponse["farg"]["valuesToRead"]
			return response, ex
		elseif arg["response"] == "inmation" then
			if dataresponse["farg"] ~= nil and dataresponse["farg"]["valuesToRead"] ~= nil then
				for _, value in pairs(dataresponse["farg"]["valuesToRead"]) do
					if type(value["s"]) == "nil" then
						-- no error -> set quality to 0
						table.insert(
							response,
							{
								{
									["V"] = {value["v"]},
									["Q"] = {0},
									["T"] = {value["t"]},
									["P"] = value["P"]
								}
							}
						)
					else
						table.insert(
							response,
							{
								{
									["V"] = {value["v"]},
									["Q"] = {self:_piqualitiesintoopcqualities(value["s"])},
									["T"] = {value["t"]},
									["P"] = value["P"]
								}
							}
						)
					end
				end
			end
			return response, ex
		elseif arg["response"] == "bridge" then
			for _, value in pairs(dataresponse["farg"]["valuesToRead"]) do
				table.insert(
					response,
					{
						["P"] = value["P"],
						["V"] = {
							["t"] = value["t"],
							["v"] = value["v"],
							["s"] = value["s"]
						}
					}
				)
			end
			return response, ex
		else
			return dataresponse, {["msg"] = "Warning: no valid response type! Standard response was returned."}
		end
	end
	return nil, tcpex
end
-- @md
function lib:RECORDEDVALUES(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("RECORDEDVALUES should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "RecordedValues",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["farg"] = {
			["ValuesToRead"] = {},
			["DirectionConstants"] = arg.DirectionConstants or 0
		}
	}
	if type(arg["tags"]) == "table" or type(arg["tagstimes"]) == "table" then
		if arg["count"] ~= nil and type(arg["tagstimes"]) == "nil" then
			if type(arg["count"]) == "table" and type(arg["StartTime"]) == "number" then
				for index, tagpath in ipairs(arg["tags"]) do
					local tagname = self:_gettagname(arg.disluaclean or false,tagpath,"\\")
					table.insert(
						call["farg"]["ValuesToRead"],
						{
							["P"] = tagname,
							["C"] = arg["count"][index] or nil,
							["T"] = {
								["t1"] = arg["StartTime"],
								--["t2"] = arg["EndTime"]
							},
							["boundarytype"] = arg["boundarytype"] or 0
						}
					)
				end
			else
				if type(arg["StartTime"]) ~= "number" then
					return nil, {
						["msg"] = "'StartTime' must be specified and of type number! Current type: " .. type(arg["StartTime"])
					}
				end
				return nil, {["msg"] = "'count' must be a table! Current type: " .. type(arg["count"])}
			end
		elseif type(arg["StartTime"]) == "number" and type(arg["EndTime"]) == "number" then
			for _, tagpath in ipairs(arg["tags"]) do
				local tagname = self:_gettagname(arg.disluaclean or false,tagpath,"\\")
				table.insert(
					call["farg"]["ValuesToRead"],
					{
						["P"] = tagname,
						["T"] = {
							["t1"] = arg["StartTime"],
							["t2"] = arg["EndTime"]
						},
						["boundarytype"] = arg["boundarytype"] or 0
					}
				)
				-- end
			end
		elseif type(arg["tagstimes"]) == "table" then
			for i = 1, #arg["tagstimes"] do
				if arg["count"] ~= nil then
					if type(arg["count"]) == "table" then
						table.insert(
							call["farg"]["ValuesToRead"],
							{
								["P"] = arg["tagstimes"][i]["tag"],
								["C"] = arg["count"][i] or nil,
								["T"] = {["t1"] = arg["tagstimes"][i]["StartTime"]},
								["boundarytype"] = arg["boundarytype"][i] or 0,
							}
						)
					else
						return nil, {["msg"] = "'count' must be a table! Current type: " .. type(arg["count"])}
					end
				else
					table.insert(
						call["farg"]["ValuesToRead"],
						{
							["P"] = arg["tagstimes"][i]["tag"],
							["T"] = {
								["t1"] = arg["tagstimes"][i]["StartTime"],
								["t2"] = arg["tagstimes"][i]["EndTime"]
							},
							["boundarytype"] = arg["tagstimes"][i]["boundarytype"] or 0,
						}
					)
				end
			end
		else
			return nil, {["msg"] = "Wrong table names! Check mandatory function parameters!"}
		end
		local ok, tcpex = self:_tcpsend(call)
		if ok then
			local dataresponse, exception = self:_tcpreceive()
			if exception == nil then
				if type(dataresponse["farg"]) == "table" then
					arg["response"] = arg["response"] or "inmation"
					if arg["response"] == "raw" and type(dataresponse["farg"]) == "table" then
						return dataresponse["farg"]["ValuesToRead"]
					elseif arg["response"] == "inmation" then
						local response = {}
						local responseindex = 1
						for _, tagandvalue in ipairs(dataresponse["farg"]["ValuesToRead"]) do
							local tag = tagandvalue["P"]
							local count = tagandvalue["C"] or 0
							local valuetable = {}
							local qualitytable = {}
							local timestamptable = {}
							for _, value in ipairs(tagandvalue["V"]) do
								if type(value["s"]) == "nil" then
									-- no error -> set quality to 0
									table.insert(valuetable, value["v"])
									table.insert(qualitytable, 0)
								else
									table.insert(valuetable, value["v"])
									table.insert(qualitytable, self:_piqualitiesintoopcqualities(value["s"]))
								end
								table.insert(timestamptable, value["t"])
							end
							if type(arg["tags"]) == "table" then
								for i = responseindex, #arg["tags"] do
									-- local tagparts = syslib.split(arg["tags"][i], "\\")
									-- local tagname = tagparts[#tagparts]
									local tagname = self:_gettagname(arg.disluaclean or false,arg["tags"][i],"\\")
									if tagname ~= tag then
										table.insert(
											response,
											{
												{
													["V"] = {},
													["Q"] = {},
													["T"] = {}
												}
											}
										)
									else
										table.insert(
											response,
											{
												["P"] = tag,
												["C"] = count,
												{
													["V"] = valuetable,
													["Q"] = qualitytable,
													["T"] = timestamptable
												}
											}
										)
										responseindex = i + 1
										break
									end
								end
							elseif type(arg["tagstimes"]) == "table" then
								for i = responseindex, #arg["tagstimes"] do
									--TODO
									if LUATYPE(arg["tagstimes"][i]["tag"]) ~= LUATYPE(tag) then
										table.insert(
											response,
											{
												["V"] = {},
												["Q"] = {},
												["T"] = {}
											}
										)
									else
										table.insert(
											response,
											{
												["V"] = valuetable,
												["Q"] = qualitytable,
												["T"] = timestamptable
											}
										)
										responseindex = i + 1
										break
									end
								end
							else
								--dataresponse = nil
								return nil, {["msg"] = "Wrong table names! Check mandatory function parameters!"}
							end
						end
						--dataresponse = nil
						return response
					else
						return dataresponse, {["msg"] = "Warning: no valid response type! Standard response was returned."}
					end
				end
			else
				return dataresponse, exception
			end
		end
		return nil, tcpex
	end
	return nil, {["msg"] = "Error call arguments"}
end

function lib:INTERPOLATEDVALUES(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("INTERPOLATEDVALUES should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "InterpolatedValues",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["farg"] = {
			["ValuesToRead"] = {}
		}
	}
	if type(arg["tags"]) == "table" or type(arg["tagstimes"]) == "table" then
		if arg["count"] ~= nil and type(arg["tagstimes"]) == "nil" and type(arg["timerange"]) == "string" then
			if type(arg["count"]) == "table" and type(arg["StartTime"]) == "number" then
				for index, tagpath in ipairs(arg["tags"]) do
					local tagname = self:_gettagname(arg.disluaclean or false,tagpath,"\\")
					table.insert(
						call["farg"]["ValuesToRead"],
						{
							["P"] = tagname,
							["C"] = arg["count"][index] or nil,
							["T"] = {
								["t1"] = arg["StartTime"],
								["t2"] = arg["EndTime"]
							},
							["timerange"] = arg["timerange"]
						}
					)
				end
			else
				if type(arg["StartTime"]) ~= "number" then
					return nil, {
						["msg"] = "'StartTime' must be specified and of type number! Current type: " .. type(arg["StartTime"])
					}
				end
				return nil, {["msg"] = "'count' must be a table! Current type: " .. type(arg["count"])}
			end
		elseif type(arg["StartTime"]) == "number" and type(arg["EndTime"]) == "number" and type(arg["timerange"]) == "string" then
			for _, tagpath in ipairs(arg["tags"]) do
				local tagname = self:_gettagname(arg.disluaclean or false,tagpath,"\\")
				table.insert(
					call["farg"]["ValuesToRead"],
					{
						["P"] = tagname,
						["T"] = {
							["t1"] = arg["StartTime"],
							["t2"] = arg["EndTime"]
						},
						["timerange"] = arg["timerange"]
					}
				)
				-- end
			end
		elseif type(arg["tagstimes"]) == "table" then
			for i = 1, #arg["tagstimes"] do
				if arg["count"] ~= nil then
					if type(arg["count"]) == "table" then
						table.insert(
							call["farg"]["ValuesToRead"],
							{
								["P"] = arg["tagstimes"][i]["tag"],
								["C"] = arg["count"][i] or nil,
								["T"] = {
									["t1"] = arg["tagstimes"][i]["StartTime"],
									["t2"] = arg["tagstimes"][i]["EndTime"]
								},
								["timerange"] = arg["tagstimes"][i]["timerange"]
							}
						)
					else
						return nil, {["msg"] = "'count' must be a table! Current type: " .. type(arg["count"])}
					end
				else
					table.insert(
						call["farg"]["ValuesToRead"],
						{
							["P"] = arg["tagstimes"][i]["tag"],
							["T"] = {
								["t1"] = arg["tagstimes"][i]["StartTime"],
								["t2"] = arg["tagstimes"][i]["EndTime"]
							},
							["timerange"] = arg["tagstimes"][i]["timerange"]
						}
					)
				end
			end
		else
			return nil, {["msg"] = "Wrong table names! Check mandatory function parameters!"}
		end
		local ok, tcpex = self:_tcpsend(call)
		if ok then
			local dataresponse, exception = self:_tcpreceive()
			if exception == nil then
				if type(dataresponse["farg"]) == "table" then
					arg["response"] = arg["response"] or "inmation"
					if arg["response"] == "raw" and type(dataresponse["farg"]) == "table" then
						return dataresponse["farg"]["ValuesToRead"]
					elseif arg["response"] == "inmation" then
						local response = {}
						local responseindex = 1
						for _, tagandvalue in ipairs(dataresponse["farg"]["ValuesToRead"]) do
							local tag = tagandvalue["P"]
							local count = tagandvalue["C"] or 0
							local valuetable = {}
							local qualitytable = {}
							local timestamptable = {}
							for _, value in ipairs(tagandvalue["V"]) do
								if type(value["s"]) == "nil" then
									-- no error -> set quality to 0
									table.insert(valuetable, value["v"])
									table.insert(qualitytable, 0)
								else
									table.insert(valuetable, value["v"])
									table.insert(qualitytable, self:_piqualitiesintoopcqualities(value["s"]))
								end
								table.insert(timestamptable, value["t"])
							end
							if type(arg["tags"]) == "table" then
								for i = responseindex, #arg["tags"] do
									-- local tagparts = syslib.split(arg["tags"][i], "\\")
									-- local tagname = tagparts[#tagparts]
									local tagname = self:_gettagname(arg.disluaclean or false,arg["tags"][i],"\\")
									if tagname ~= tag then
										table.insert(
											response,
											{
												{
													["V"] = {},
													["Q"] = {},
													["T"] = {}
												}
											}
										)
									else
										table.insert(
											response,
											{
												["P"] = tag,
												["C"] = count,
												{
													["V"] = valuetable,
													["Q"] = qualitytable,
													["T"] = timestamptable
												}
											}
										)
										responseindex = i + 1
										break
									end
								end
							elseif type(arg["tagstimes"]) == "table" then
								for i = responseindex, #arg["tagstimes"] do
									if LUATYPE(arg["tagstimes"][i]["tag"]) ~= LUATYPE(tag) then
										table.insert(
											response,
											{
												["V"] = {},
												["Q"] = {},
												["T"] = {}
											}
										)
									else
										table.insert(
											response,
											{
												["V"] = valuetable,
												["Q"] = qualitytable,
												["T"] = timestamptable
											}
										)
										responseindex = i + 1
										break
									end
								end
							else
								--dataresponse = nil
								return nil, {["msg"] = "Wrong table names! Check mandatory function parameters!"}
							end
						end
						--dataresponse = nil
						return response
					else
						return dataresponse, {["msg"] = "Warning: no valid response type! Standard response was returned."}
					end
				end
			end
			return nil, {
				["tcp"] = exception,
				["msg"] = "Warning: no valid response type! Standard response was returned.",
				["dataresponse"] = dataresponse
			}
		end
		return nil, tcpex
	end
	return nil, {["msg"] = "Error call arguments"}
end

-- @md
function lib:UPDATEVALUES(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("UPDATEVALUES should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "UpdateValues",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["inmvalues"] = arg["hist"],
		["farg"] = {
			["AFBufferOption"] = arg["AFBufferOption"] or 1,
			["AFUpdateOption"] = arg["AFUpdateOption"] or 0
		}
	}
	if type(arg.inmvalues) == "table" and type(arg.tags) == "table" then
		local valuesToWrite = {}
		for index, pitagname in ipairs(arg.tags) do
			-- local tagparts = syslib.split(pitagname, "\\")
			-- local tagname = tagparts[#tagparts]
			local tagname = self:_gettagname(arg.disluaclean or false,pitagname,"\\")
			local tagdata = {[self.alias.PIPoint] = tagname, [self.alias.Values] = {}}
			local historydata = arg.inmvalues[index]
			if type(historydata[1].T) == "table" then
				for i = 1, #historydata[1].T do
					local qualityconversionOPCintoPI = self:_opcqualitiesintopiqualities(historydata[1].Q[i])
					if
						type(historydata[1].V[i]) ~= "nil" and
							(qualityconversionOPCintoPI == nil or qualityconversionOPCintoPI == 305 or historydata[1].Q[i] == 0)
					 then
						table.insert(
							tagdata[self.alias.Values],
							{
								[self.alias.AFtime] = tostring(historydata[1].T[i]),
								[self.alias.Value] = historydata[1].V[i],
								[self.alias.SystemState] = nil
							}
						)
					elseif (qualityconversionOPCintoPI ~= 305 or historydata[1].Q[i] ~= 0 or qualityconversionOPCintoPI == nil) then
						local qvalue = self:_convertopcqualitiesintopiqualities(historydata[1].Q[i])
						table.insert(
							tagdata[self.alias.Values],
							{
								[self.alias.AFtime] = tostring(historydata[1].T[i]),
								[self.alias.Value] = tostring(qvalue),
								[self.alias.SystemState] = qualityconversionOPCintoPI
							}
						)
					end
				end
			else
				for _, datarow in ipairs(historydata) do
					local qualityconversionOPCintoPI = self:_opcqualitiesintopiqualities(datarow.Q)
					if
						type(datarow.V) ~= "nil" and
							(qualityconversionOPCintoPI == nil or qualityconversionOPCintoPI == 305 or datarow.Q == 0)
					 then
						table.insert(
							tagdata[self.alias.Values],
							{
								[self.alias.AFtime] = tostring(datarow.T),
								[self.alias.Value] = datarow.V,
								[self.alias.SystemState] = nil
							}
						)
					elseif (qualityconversionOPCintoPI ~= 305 or datarow.Q ~= 0 or qualityconversionOPCintoPI ~= nil) then
						local qvalue = self:_convertopcqualitiesintopiqualities(datarow.Q)
						table.insert(
							tagdata[self.alias.Values],
							{
								[self.alias.AFtime] = tostring(datarow.T),
								[self.alias.Value] = tostring(qvalue),
								[self.alias.SystemState] = qualityconversionOPCintoPI
							}
						)
					end
				end
			end
			table.insert(valuesToWrite, tagdata)
		end
		call["farg"]["valuesToWrite"] = valuesToWrite
		local ok, tcpex = self:_tcpsend(call)
		if ok then
			local result, exception = self:_tcpreceive()
			return result, exception --or {exception = "no exception returned by function '_tcpreceive' in 'UPDATEVALUES'"}
		end
		return nil, tcpex
	elseif type(arg.valuesToWrite) == "table" then
		call["farg"]["valuesToWrite"] = arg.valuesToWrite
		local ok, tcpex = self:_tcpsend(call)
		if ok then
			local result, exception = self:_tcpreceive()
			return result, exception --or {exception = "no exception returned by function '_tcpreceive' in 'UPDATEVALUES'"}
		end
		return nil, tcpex
	else
		return nil, {["msg"] = "Error call arguments"}
	end
end
-- @md
function lib:FINDPIBATCHES(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("FINDPIBATCHES should be called using colon ':' notation", 2)
	end
	--local rt = syslib.now()                      -- todo: runtime
	local call = {
		["sys"] = "OSI",
		["func"] = "FindPIBatches",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["farg"] = {
			["SearchStartTime"] = arg["SearchStartTime"],
			["SearchEndTime"] = arg["SearchEndTime"],
			["BatchIDMask"] = arg["BatchIDMask"] or "*",
			["ProductMask"] = arg["ProductMask"] or "*",
			["RecipeMask"] = arg["RecipeMask"] or "*",
			["PIAsyncStatus"] = arg["PIAsyncStatus"],
			["PIBatchUniqueID"] = arg["PIBatchUniqueID"] or ""
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception, pc = self:_tcpreceive() -- todo: return: result.farg.ValuesRetrived or nil
		if type(result) == "table" then
			if type(result["farg"]) == "table" then
				if type(result["farg"]["ValuesRetrieved"]) == "table" then
					return result["farg"]["ValuesRetrieved"], exception, pc
				end
			end
		end
		return result, exception, pc
	end
	return nil, tcpex
end

-- Sends the call data to pibridge with over tcp connection. Before sending it checkts if connected
function lib:_tcpsend(call)
	local ok, ex = self:_ensureconnect()
	if ok then
		self:_send(call)
		return true
	end
	return false, ex
end
-- Sends the call data to pibridge with over tcp connection.
function lib:_send(call)
	local rt = syslib.now()
	local callstring = ""
	if type(call) == "table" then
		callstring = J.encode(call, {indent = false})
	elseif type(call) == "number" then
		callstring = tostring(call)
	elseif type(call) == "string" then
		callstring = call
	end
	callstring = callstring .. "xEOFx"
	self.tcp:send(callstring)
end
-- Waits for the data that the tibridge sends over tcp
-- until it recives a xEOFx that marks the end of the string thats beeing sent
function lib:_tcpreceive()
	local rt = syslib.now()
	local timeout = self.tcpconfig.timeout * 1000
	local count = 1
	local receivestring = ""
	local timestart = syslib.now()
	local run = true
	local exception = nil
	local performanceCounter = nil
	while run do
		local s, status, partial = self.tcp:receive(self.buffersize or 2048)
		if type(s) == "string" then
			receivestring = receivestring .. s
		end
		if type(partial) == "string" then
			if partial:sub(-5) == "xEOFx" then
				if #partial > 5 then
					receivestring = receivestring .. partial:sub(#partial - 5)
				end
				break
			end
		end
		if status then
			self.tcp:close()
			self.tcp = nil
			exception = {["msg"] = "Error during TCP connection", ["tcp"] = status}
			break
		end
		if status == "closed" then
			self.tcp:close()
			self.tcp = nil
			exception = {["msg"] = "Error during TCP connection", ["tcp"] = "closed"}
			break
		end
		if receivestring:sub(-5) == "xEOFx" then
			break
		end
		local currentrun = syslib.now() - timestart
		if currentrun > timeout then
			self.tcp:close()
			self.tcp = nil
			exception = {["msg"] = "Error during TCP connection", ["tcp"] = "timeout"}
			break
		end
		count = count + 1
	end
	local tableresponse =
		J.decode(receivestring:gsub("xEOFx", "")) or
		{
			["error"] = {["Topic"] = "JSON decode"},
			{["Data"] = receivestring}
		}

	if type(tableresponse) == "table" then
		exception = exception or tableresponse["errors"]
		exception = exception or tableresponse["error"]
		tableresponse["errors"], tableresponse["error"] = nil, nil
	else
		exception =
			exception or
			{
				["error"] = {["Topic"] = "tableresponse not type 'table'"},
				{["Data"] = tableresponse}
			}
	end

	return tableresponse, exception
end
--@md
function lib:FINDELEMENTATTRIBUTESBYPATH(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("FINDELEMENTATTRIBUTESBYPATH should be called using colon ':' notation", 2)
	end
	--local rt = syslib.now()		-- todo: runtime
	local call = {
		["sys"] = "OSI",
		["func"] = "FindElementAttributesByPath",
		["afserver"] = arg["afserver"] or self.alias.afserver,
		["afdatabase"] = arg["afdatabase"] or self.alias.afdatabase,
		["farg"] = {
			["AttributeElements"] = arg["AttributeElements"] or {}
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()
		if type(result) == "table" then
			if type(result["farg"]) == "table" then
				return result["farg"], exception
			end
		end
		return result, exception
	end
	return nil, tcpex
end
--@md
function lib:FINDELEMENTSCHILDS(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("FINDELEMENTSCHILDS should be called using colon ':' notation", 2)
	end
	--local rt = syslib.now()		-- todo: runtime
	local call = {
		["sys"] = "OSI",
		["func"] = "FindElementsChilds",
		["afserver"] = arg["afserver"] or self.alias.afserver,
		["afdatabase"] = arg["afdatabase"] or self.alias.afdatabase,
		["farg"] = {
			["Elements"] = arg["Elements"] or {{["ElementPath"] = ""}}
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()
		if type(result) == "table" then
			if type(result["farg"]) == "table" then
				return result["farg"], exception
			end
		end
		return result, exception
	end
	return nil, tcpex
end
--@md
function lib:FINDEVENTFRAMES(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("FINDEVENTFRAMES should be called using colon ':' notation", 2)
	end
	--local rt = syslib.now()		-- todo: runtime
	local guid = nil
	if type((arg["EF"]["guid"])) == "table" then
		guid = arg["EF"]["guid"]
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "FindEventFrames",
		["afserver"] = arg["afserver"] or self.alias.afserver,
		["afdatabase"] = arg["afdatabase"] or self.alias.afdatabase,
		["farg"] = {
			["guid"] = guid,
			["AFEventFrameRoot"] = arg["EF"]["AFEventFrameRoot"] or "",
			["EventFrameFilter"] = arg["EF"]["EventFrameFilter"] or " ",
			["AFSearchField"] = arg["EF"]["AFSearchField"] or 1,
			["SearchFullHierarchy"] = arg["EF"]["SearchFullHierarchy"] or false,
			["AFSortField"] = arg["EF"]["AFSortField"] or 1,
			["AFSortOrder"] = arg["EF"]["AFSortOrder"] or 0,
			["StartIndex"] = arg["EF"]["StartIndex"] or 0,
			["MaxCount"] = arg["EF"]["MaxCount"] or 50,
			["GetChildren"] = arg["EF"]["GetChildren"] or 0,
			["GetAttributes"] = arg["EF"]["GetAttributes"] or false,
			["GetTemplateName"] = arg["EF"]["GetTemplateName"] or false
		}--arg["EF"] or {}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()
		if type(result) == "table" then
			if type(result["farg"]) == "table" then
				if type(result["farg"]["ValuesToRead"]) == "table" then
					return result["farg"]["ValuesToRead"], exception, result["TimeProcessPerformance"] or {}
				end
			end
			return {}, exception , result["TimeProcessPerformance"] or {}
		end
		return result, exception
	end
	return nil, tcpex
end
--@md
function lib:FINDELEMENTATTRIBUTES(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("FINDELEMENTATTRIBUTES should be called using colon ':' notation", 2)
	end
	--local rt = syslib.now()		-- todo: runtime
	local call = {
		["sys"] = "OSI",
		["func"] = "FindElementAttributes",
		["afserver"] = arg["afserver"] or self.alias.afserver,
		["afdatabase"] = arg["afdatabase"] or self.alias.afdatabase,
		["farg"] = {
			["AFNameElementRoot"] = arg["EA"]["AFNameElementRoot"] or "",
			["AFElementNameFilter"] = arg["EA"]["AFElementNameFilter"] or "",
			["AFNameElementCategory"] = arg["EA"]["AFNameElementCategory"] or "",
			["AFElementTemplate"] = arg["EA"]["AFElementTemplate"] or "",
			["sAFElementType"] = arg["EA"]["sAFElementType"] or -1,
			["AFattributeNameFilter"] = arg["EA"]["AFattributeNameFilter"] or "",
			["attributeCategory"] = arg["EA"]["attributeCategory"] or "",
			["AFattributeType"] = arg["EA"]["AFattributeType"] or 0,
			["SearchFullHierarchy"] = arg["EA"]["SearchFullHierarchy"] or true,
			["AFSortOrder"] = arg["EA"]["AFSortOrder"] or 0,
			["AFSortField"] = arg["EA"]["AFSortField"] or 1,
			["StartIndex"] = arg["EA"]["StartIndex"] or 0
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()
		if type(result) == "table" then
			if type(result["farg"]) == "table" then
				if type(result["farg"]["ValuesToRead"]) == "table" then
					return result["farg"]["ValuesToRead"], exception, result["TimeProcessPerformance"] or {}
				end
			end
			return {}, exception , result["TimeProcessPerformance"] or {}
		end
		return result, exception
	end
	return nil, tcpex
end
--@md
function lib:CREATEPIPOINTS(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("CREATEPIPOINTS should be called using colon ':' notation", 2)
	end
	--local rt = syslib.now()		-- todo: runtime
	local call = {
		["sys"] = "OSI",
		["func"] = "CreatePIPoints",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["farg"] = {
			["PIPoints"] = arg["PIPoints"]
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()
		return result, exception
	end
	return nil, tcpex
end
--@md
function lib:CREATEAFHIERARCHY(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("CREATEAFHIERARCHY should be called using colon ':' notation", 2)
	end
	--local rt = syslib.now()		-- todo: runtime
	local call = {
		["sys"] = "OSI",
		["func"] = "CreateAFHierarchy",
		["afserver"] = arg["afserver"] or self.alias.afserver,
		["afdatabase"] = arg["afdatabase"] or self.alias.afdatabase,
		["farg"] = {
			["hierarchies"] = arg["hierarchies"] or {}
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()
		if type(result) == "table" then
			if type(result["farg"]) == "table" then
				return result["farg"], exception
			end
		end
		return result, exception
	end
	return nil, tcpex
end
--@md
function lib:CREATEAFATTRIBUTES(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("CREATEAFATTRIBUTES should be called using colon ':' notation", 2)
	end
	--local rt = syslib.now()		-- todo: runtime
	local call = {
		["sys"] = "OSI",
		["func"] = "CreateAFAttributes",
		["afserver"] = arg["afserver"] or self.alias.afserver,
		["afdatabase"] = arg["afdatabase"] or self.alias.afdatabase,
		["farg"] = {
			["hierarchy"] = arg["hierarchy"] or {},
			["afattributes"] = arg["afattributes"] or {}
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()
		if type(result) == "table" then
			if type(result["farg"]) == "table" then
				return result["farg"], exception
			end
		end
		return result, exception
	end
	return nil, tcpex
end
--@md
function lib:GETPITAGSCONFIG(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("GETPITAGSCONFIG should be called using colon ':' notation", 2)
	end
	-- version 0.6.0
	--local rt = syslib.now()		-- todo: runtime
	local call = {
		["sys"] = "OSI",
		["func"] = "GetPITagsConfig",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["afdatabase"] = arg["afdatabase"] or self.alias.afdatabase,
		["farg"] = {
			["P"] = {}
		}
	}
	if type(arg["tagnames"]) == "nil" then
		return nil, {["msg"] = "Warning: Function argument 'tagnames' is nil!"}
	end
	for _, tagpath in pairs(arg["tagnames"]) do
		-- local tagparts = syslib.split(tagpath, "\\")
		-- local tagname = tagparts[#tagparts]
		local tagname = self:_gettagname(arg.disluaclean or false,tagpath,"\\")
		table.insert(call["farg"]["P"], tagname)
	end
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()
		if type(result) == "table" then
			if type(result["farg"]) == "table" then
				return result["farg"], exception
			end
		end
		return result, exception
	end
	return nil, tcpex
end

--@md
function lib:DATAPIPESSUBSCRIBE(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("DATAPIPESSUBSCRIBE should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "DataPipesSubscribe",
		["piserver"] = arg["piserver"] or self.alias.piserver
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()
		if type(result) == "table" then
			if type(result["farg"]) == "table" then
				if type(result["farg"]["handle"]) == "string" then
					return result["farg"]["handle"],exception
				end
			end
		end
		return result, exception
	end
	return nil, tcpex
end

--@md
function lib:GETSNAPSHOTSIGNUPSFROMPIDATAPIPE(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("GETSNAPSHOTSIGNUPSFROMPIDATAPIPE should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "GetSnapshotSignups",
			["piserver"] = arg["piserver"] or self.alias.piserver,
			["farg"] = {
			["handle"] = arg["handle"]
			}
		}

	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()
		if type(result["farg"]) == "table" then
				if type(result["farg"]["PIPoints"]) == "table" then
					return result["farg"]["PIPoints"], exception
				end
			end
		return result, exception
	end
	return nil, tcpex
end

--@md
function lib:GETARCHIVESIGNUPSFROMPIDATAPIPE(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("GETARCHIVESIGNUPSFROMPIDATAPIPE should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "GetArchiveSignups",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["farg"] = {
			["handle"] = arg["handle"]
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()
		if type(result["farg"]) == "table" then
				if type(result["farg"]["PIPoints"]) == "table" then
					return result["farg"]["PIPoints"], exception
				end
			end
		return result, exception
	end
	return nil, tcpex
end

--@md
function lib:GETSIGNUPSFROMAFDATAPIPE(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("GETSIGNUPSFROMAFDATAPIPE should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "GetAFSignups",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["farg"] = {
			["handle"] = arg["handle"]
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()
		if type(result) == "table" then
			if type(result["farg"]) == "table" then
				if type(result["farg"]["AFAttributes"]) == "table" then
					return result["farg"]["AFAttributes"], exception
				end
			end
		end
		return result, exception
	end
	return nil, tcpex
end

--@md
function lib:GETSIGNUPSFROMAFDATAPIPEBYPISERVER(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("GETSIGNUPSFROMAFDATAPIPEBYPISERVER should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "GetAFSignupsByPiServer",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["farg"] = {
			["handle"] = arg["handle"],
			["server"] = arg["server"]
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()
		if type(result["farg"]) == "table" then
				if type(result["farg"]["AFAttributes"]) == "table" then
					return result["farg"]["AFAttributes"], exception
				end
			end
		return result, exception
	end
	return nil, tcpex
end

--@md
function lib:GETARCHIVESIGNUPSFROMPIDATAPIPEBYPISERVER(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("GETARCHIVESIGNUPSFROMPIDATAPIPEBYPISERVER should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "GetArchiveSignupsByPiServer",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["farg"] = {
			["handle"] = arg["handle"],
			["server"] = arg["server"]
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()
		if type(result["farg"]) == "table" then
				if type(result["farg"]["PIPoints"]) == "table" then
					return result["farg"]["PIPoints"], exception
				end
			end
		return result, exception
	end
	return nil, tcpex
end


--@md
function lib:GETSNAPSHOTSIGNUPSFROMPIDATAPIPEBYPISERVER(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("GETSNAPSHOTSIGNUPSFROMPIDATAPIPEBYPISERVER should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "GetSnapshotSignupsByPiServer",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["farg"] = {
			["handle"] = arg["handle"],
			["server"] = arg["server"]
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()
		if type(result["farg"]) == "table" then
				if type(result["farg"]["PIPoints"]) == "table" then
					return result["farg"]["PIPoints"], exception
				end
			end
		return result, exception
	end
	return nil, tcpex
end

--@md
function lib:GETTIMESERIESSIGNUPSFROMPIDATAPIPEBYPISERVER(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("GETTIMESERIESSIGNUPSFROMPIDATAPIPEBYPISERVER should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "GetTimeSeriesSignupsByPiServer",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["farg"] = {
			["handle"] = arg["handle"],
			["server"] = arg["server"]
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()
		if type(result["farg"]) == "table" then
				if type(result["farg"]["PIPoints"]) == "table" then
					return result["farg"]["PIPoints"], exception
				end
			end
		return result, exception
	end
	return nil, tcpex
end

--@md
function lib:GETTIMESERIESSIGNUPSFROMPIDATAPIPE(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("GETTIMESERIESSIGNUPSFROMPIDATAPIPE should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "GetTimeSeriesSignups",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["farg"] = {
			["handle"] = arg["handle"]
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()
		if type(result["farg"]) == "table" then
				if type(result["farg"]["PIPoints"]) == "table" then
					return result["farg"]["PIPoints"], exception
				end
			end
		return result, exception
	end
	return nil, tcpex
end

--@md
function lib:DATAPIPESUNSUBSCRIBE(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("DATAPIPESUNSUBSCRIBE should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "DataPipesUnsubscribe",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["farg"] = {
			["handle"] = arg["handle"]
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()

		return result, exception
	end
	return nil, tcpex
end

--@md
function lib:ADDSIGNUPSWITHINITEVENTSTOAFDATAPIPE(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("ADDSIGNUPSWITHINITEVENTSTOAFDATAPIPE should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "AddAFSignupsWithInitEvents",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["afserver"] = arg["afserver"] or self.alias.afserver,
		["afdatabase"] = arg["afdatabase"] or self.alias.afdatabase,
		["farg"] = {
			["handle"] = arg["handle"],
			["AT"] = arg["attributes"]
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()

		return result, exception
	end
	return nil, tcpex
end

--@md
function lib:ADDSIGNUPSTOAFDATAPIPE(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("ADDSIGNUPSTOAFDATAPIPE should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "AddSignupsToAFDataPipe",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["afserver"] = arg["afserver"] or self.alias.afserver,
		["afdatabase"] = arg["afdatabase"] or self.alias.afdatabase,
		["farg"] = {
			["handle"] = arg["handle"],
			["AT"] = arg["attributes"]
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()

		return result, exception
	end
	return nil, tcpex
end

--@md
function lib:UPDATEATTRIBUTE(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("UPDATEATTRIBUTE should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "UpdateAttribute",
		["afserver"] = arg["afserver"] or self.alias.afserver,
		["afdatabase"] = arg["afdatabase"] or self.alias.afdatabase,
		["farg"] = {
			["AT"] = arg["attributepath"],
			["V"] = arg["value"]
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()

		return result, exception
	end
	return nil, tcpex
end

--@md
function lib:ADDARCHIVESIGNUPSTOPIDATAPIPE(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("ADDARCHIVESIGNUPSTOPIDATAPIPE should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "AddSignupsToPIDataPipe",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["farg"] = {
			["handle"] = arg["handle"],
			["type"] = "archive",
			["P"] = arg["tags"]
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()

		return result, exception
	end
	return nil, tcpex
end

--@md
function lib:REMOVESIGNUPSFROMAFDATAPIPE(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("REMOVESIGNUPSFROMAFDATAPIPE should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "RemoveSignupsFromAFDataPipe",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["afserver"] = arg["afserver"] or self.alias.afserver,
		["afdatabase"] = arg["afdatabase"] or self.alias.afdatabase,
		["farg"] = {
			["handle"] = arg["handle"],
			["AT"] = arg["attributes"]
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()

		return result, exception
	end
	return nil, tcpex
end

--@md
function lib:REMOVEARCHIVESIGNUPSFROMPIDATAPIPE(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("REMOVEARCHIVESIGNUPSFROMPIDATAPIPE should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "RemoveSignupsFromPIDataPipe",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["farg"] = {
			["handle"] = arg["handle"],
			["type"] = "archive",
			["P"] = arg["tags"]
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()

		return result, exception
	end
	return nil, tcpex
end

--@md
function lib:REMOVESNAPSHOTSIGNUPSFROMPIDATAPIPE(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("REMOVESNAPSHOTSIGNUPSFROMPIDATAPIPE should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "RemoveSignupsFromPIDataPipe",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["farg"] = {
			["handle"] = arg["handle"],
			["type"] = "snapshot",
			["P"] = arg["tags"]
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()

		return result, exception
	end
	return nil, tcpex
end

--@md
function lib:REMOVETIMESERIESSIGNUPSFROMPIDATAPIPE(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("REMOVETIMESERIESSIGNUPSFROMPIDATAPIPE should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "RemoveSignupsFromPIDataPipe",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["farg"] = {
			["handle"] = arg["handle"],
			["type"] = "timeseries",
			["P"] = arg["tags"]
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()

		return result, exception
	end
	return nil, tcpex
end

function lib:ADDTIMESERIESSIGNUPSWITHINITEVENTSTOPIDATAPIPE(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("ADDTIMESERIESSIGNUPSWITHINITEVENTSTOPIDATAPIPE should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "AddTimeSeriesSignupsWithInitEvents",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["farg"] = {
			["handle"] = arg["handle"],
			["P"] = arg["tags"]
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()

		return result, exception
	end
	return nil, tcpex
end

function lib:ADDSNAPSHOTSIGNUPSTOPIDATAPIPE(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("ADDSNAPSHOTSIGNUPSTOPIDATAPIPE should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "AddSignupsToPIDataPipe",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["farg"] = {
			["handle"] = arg["handle"],
			["type"] = "snapshot",
			["P"] = arg["tags"]
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()

		return result, exception
	end
	return nil, tcpex
end

function lib:ADDTIMESERIESSIGNUPSTOPIDATAPIPE(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("ADDTIMESERIESSIGNUPSTOPIDATAPIPE should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "AddSignupsToPIDataPipe",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["farg"] = {
			["handle"] = arg["handle"],
			["type"] = "timeseries",
			["P"] = arg["tags"]
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()

		return result, exception
	end
	return nil, tcpex
end

--@md
function lib:GETEVENTSFROMAFDATAPIPE(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("GETEVENTSFROMAFDATAPIPE should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "GetEventsFromAFDataPipe",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["farg"] = {
			["handle"] = arg["handle"]
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()
		if type(result) == "table" then
			if type(result["farg"]) == "table" then
				if type(result["farg"]["events"]) == "table" then
					return result["farg"], exception
				end
			end
		end
		return result, exception
	end
	return nil, tcpex
end

--@md
function lib:GETARCHIVEEVENTSFROMPIDATAPIPE(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("GETARCHIVEEVENTSFROMPIDATAPIPE should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "GetArchiveEventsFromPIDataPipe",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["farg"] = {
			["handle"] = arg["handle"]
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()
		if type(result["farg"]) == "table" then
				if type(result["farg"]["events"]) == "table" then
					return result["farg"], exception
				end
			end
		return result, exception
	end
	return nil, tcpex
end

--@md
function lib:GETSNAPSHOTEVENTSFROMPIDATAPIPE(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("GETSNAPSHOTEVENTSFROMPIDATAPIPE should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "GetSnapshotEventsFromPIDataPipe",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["farg"] = {
			["handle"] = arg["handle"]
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()
		if type(result["farg"]) == "table" then
				if type(result["farg"]["events"]) == "table" then
					return result["farg"], exception
				end
			end
		return result, exception
	end
	return nil, tcpex
end

--@md
function lib:GETTIMESERIESEVENTSFROMPIDATAPIPE(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("GETTIMESERIESEVENTSFROMPIDATAPIPE should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "GetTimeSeriesEventsFromPIDataPipe",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["farg"] = {
			["handle"] = arg["handle"]
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()
		if type(result["farg"]) == "table" then
				if type(result["farg"]["events"]) == "table" then
					return result["farg"], exception
				end
			end
		return result, exception
	end
	return nil, tcpex
end

--@md
function lib:DELETEPITAGS(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("DELETEPITAGS should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "DeletePITags",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["afserver"] = arg["afserver"] or self.alias.afserver,
		["farg"] = {
			["P"] = arg["tagsToDelete"]
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()
		if type(result) == "table" then
			if type(result["farg"]) == "table" then
				if type(result["farg"]["PIPoints"]) == "table" then
					return result["farg"]["PIPoints"],exception
				end
			end
		end
		return result, exception
	end
	return nil, tcpex
end
--@md
function lib:DELETEAFELEMENTS(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("DELETEAFELEMENTS should be called using colon ':' notation", 2)
	end
	--local rt = syslib.now()		-- todo: runtime
	local call = {
		["sys"] = "OSI",
		["func"] = "DeleteAFElements",
		["afserver"] = arg["afserver"] or self.alias.afserver,
		["afdatabase"] = arg["afdatabase"] or self.alias.afdatabase,
		["farg"] = {
			["AT"] = arg["elementspaths"]
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()
		if type(result) == "table" then
			if type(result["farg"]) == "table" then
				if type(result["farg"]["AT"]) == "table" then
					return result["farg"]["AT"], exception
				end
			end
		end
		return result, exception
	end
	return nil, tcpex
end
--@md
function lib:DELETEAFATTRIBUTES(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("DELETEAFATTRIBUTES should be called using colon ':' notation", 2)
	end
	--local rt = syslib.now()		-- todo: runtime
	local call = {
		["sys"] = "OSI",
		["func"] = "DeleteAFAttributes",
		["afserver"] = arg["afserver"] or self.alias.afserver,
		["afdatabase"] = arg["afdatabase"] or self.alias.afdatabase,
		["farg"] = {
			["AT"] = arg["attributepaths"]
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()
		if type(result) == "table" then
			if type(result["farg"]) == "table" then
				if type(result["farg"]["AT"]) == "table" then
					return result["farg"]["AT"], exception
				end
			end
		end
		return result, exception
	end
	return nil, tcpex
end
--@md
function lib:UPDATEPITAGSCONFIG(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("UPDATEPITAGSCONFIG should be called using colon ':' notation", 2)
	end
	--local rt = syslib.now()		-- todo: runtime
	local call = {
		["sys"] = "OSI",
		["func"] = "UpdatePITagsConfig",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["farg"] = {
			["PIPoints"] = arg["PIPoints"]
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()
		return result, exception
	end
	return nil, tcpex
end
--@md
function lib:AFELEMENTSEXISTS(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("AFELEMENTSEXISTS should be called using colon ':' notation", 2)
	end
	--local rt = syslib.now()		-- todo: runtime
	local call = {
		["sys"] = "OSI",
		["func"] = "AFElementsExists",
		["afserver"] = arg["afserver"] or self.alias.afserver,
		["afdatabase"] = arg["afdatabase"] or self.alias.afdatabase,
		["farg"] = {
			["AT"] = arg["afpaths"]
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()
		if type(result) == "table" then
			if type(result["farg"]) == "table" then
				if #result["farg"]["E"] == 1 then
					return result["farg"]["E"][1], exception
				else
					return result["farg"], exception
				end
			end
		end
		return result, exception
	end
	return nil, tcpex
end
--@md
function lib:GETAFELEMENTSCONFIG(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("GETAFELEMENTSCONFIG should be called using colon ':' notation", 2)
	end
	--local rt = syslib.now()		-- todo: runtime
	local call = {
		["sys"] = "OSI",
		["func"] = "GetAFElementsConfig",
		["afserver"] = arg["afserver"] or self.alias.afserver,
		["afdatabase"] = arg["afdatabase"] or self.alias.afdatabase,
		["farg"] = {
			["AT"] = arg["elementspaths"] or {},
			["GetAnalysis"] = arg["GetAnalysis"] or false,
			["GetPorts"] = arg["GetPorts"] or false,
			["GetNotifications"] = arg["GetNotifications"] or false,
			["GetExtendedProperties"] = arg["GetExtendedProperties"] or false,
			["GetChildren"] = arg["GetChildren"],
			["GetAttributes"] = arg["GetAttributes"]
		}
	}

	-- error(J.encode{arg=arg,call=call},3)
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()
		if type(result) == "table" then
			if type(result["farg"]) == "table" then
				if type(result["farg"]["AT"]) == "table" then
					return result["farg"]["AT"], exception
				end
			end
		end
		return result, exception
	end
	return nil, tcpex
end
--@md
function lib:PITAGSEXISTS(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("PITAGSEXISTS should be called using colon ':' notation", 2)
	end
	--local rt = syslib.now()		-- todo: runtime
	local call = {
		["sys"] = "OSI",
		["func"] = "PITagsExists",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["afserver"] = arg["afserver"] or self.alias.afserver,
		["farg"] = {
			["P"] = arg["tags"]
		}
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception = self:_tcpreceive()
		--return result, exception
		if type(result) == "table" then
			if type(result["farg"]) == "table" then
				if #result["farg"]["E"] == 1 then
					return result["farg"]["E"][1]
				else
					return result["farg"], exception
				end
			end
		end
		return result, exception
	end
	return nil, tcpex
end
--@md
function lib:FINDPIBATCHHEADERS(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("FINDPIBATCHHEADERS should be called using colon ':' notation", 2)
	end
	--local rt = syslib.now()                      -- todo: runtime
	local farg = {
		["SearchStartTime"] = arg["SearchStartTime"],
		["SearchEndTime"] = arg["SearchEndTime"],
		["BatchIDMask"] = arg["BatchIDMask"] or "*",
		["ProductMask"] = arg["ProductMask"] or "*",
		["RecipeMask"] = arg["RecipeMask"] or "*",
		["PIAsyncStatus"] = arg["PIAsyncStatus"],
		["PIBatchUniqueID"] = arg["PIBatchUniqueID"] or ""
	}
	local call = {
		["sys"] = "OSI",
		["func"] = "FindPIBatchHeaders",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["farg"] = farg
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception, pc = self:_tcpreceive()
		if type(result) == "table" then
			if type(result["farg"]) == "table" then
				if type(result["farg"]["ValuesRetrieved"]) == "table" then
					return result["farg"]["ValuesRetrieved"], exception, pc
				end
			end
		end
		return result, exception
	end
	return nil, tcpex
end

function lib:FINDPIUNITBATCHES(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("FINDPIUNITBATCHES should be called using colon ':' notation", 2)
	end
	--local rt = syslib.now()                      -- todo: runtime
	local farg = {
		["SearchStartTime"] = arg["SearchStartTime"],
		["SearchEndTime"] = arg["SearchEndTime"],
		["ModuleNameMask"] = arg["ModuleNameMask"] or "*",
		["BatchIDMask"] = arg["BatchIDMask"] or "*",
		["ProductMask"] = arg["ProductMask"] or "*",
		["ProcedureMask"] = arg["ProcedureMask"] or "*",
		["SubBatchMask"] = arg["SubBatchMask"] or "*",
		["UnitBatchUniqueID"] = arg["UnitBatchUniqueID"] or "",
		["ModuleUniqueID"] = arg["ModuleUniqueID"] or ""
	}
	local call = {
		["sys"] = "OSI",
		["func"] = "FindPIUnitBatches",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["farg"] = farg
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local result, exception, pc = self:_tcpreceive()
		if type(result) == "table" then
			if type(result["farg"]) == "table" then
				if type(result["farg"]["ValuesRetrieved"]) == "table" then
					return result["farg"]["ValuesRetrieved"], exception, pc
				end
			end
		end
		return result, exception
	end
	return nil, tcpex
end

function lib:PIPOINTSUMMARIES(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("PIPOINTSUMMARIES should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "PIPointSummaries",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["farg"] = {
			["ValuesToRead"] = {},
		}
	}
	if type(arg["tags"]) == "table" or type(arg["tagstimes"]) == "table" then
		if type(arg["StartTime"]) == "number" and type(arg["EndTime"]) == "number" and type(arg["summaryduration"]) == "string"
		 and type(arg["typ"]) == "number" and type(arg["calcbasis"]) == "number" and type(arg["calcbasis"]) == "number" then
			for _, tagpath in ipairs(arg["tags"]) do
				local tagname = self:_gettagname(arg.disluaclean or false,tagpath,"\\")
				table.insert(
					call["farg"]["ValuesToRead"],
					{
						["P"] = tagname,
						["T"] = {
							["t1"] = arg["StartTime"],
							["t2"] = arg["EndTime"]
						},
						["summaryduration"] = arg["summaryduration"],
						["typ"] = arg["typ"],
						["calcbasis"] = arg["calcbasis"],
						["timecalc"] = arg["timecalc"],
					}
				)
				-- end
			end
		elseif type(arg["tagstimes"]) == "table" then
			for i = 1, #arg["tagstimes"] do
				table.insert(
					call["farg"]["ValuesToRead"],
					{
						["P"] = arg["tagstimes"][i]["tag"],
						["T"] = {
							["t1"] = arg["tagstimes"][i]["StartTime"],
							["t2"] = arg["tagstimes"][i]["EndTime"]
						},
						["summaryduration"] = arg["tagstimes"][i]["summaryduration"],
						["typ"] = arg["tagstimes"][i]["typ"],
						["calcbasis"] = arg["tagstimes"][i]["calcbasis"],
						["timecalc"] = arg["tagstimes"][i]["timecalc"]
					}
				)
			end
		else
			return nil, {["msg"] = "Wrong table names! Check mandatory function parameters!"}
		end
		local ok, tcpex = self:_tcpsend(call)
		if ok then
			local dataresponse, exception = self:_tcpreceive()
			if exception == nil then
				if type(dataresponse["farg"]) == "table" then
					arg["response"] = arg["response"] or "inmation"
					if arg["response"] == "raw" and type(dataresponse["farg"]) == "table" then
						return dataresponse["farg"]["ValuesToRead"]
					elseif arg["response"] == "inmation" then
						local response = {}
						local responseindex = 1
						for _, tagandvalue in ipairs(dataresponse["farg"]["ValuesToRead"]) do
							local tag = tagandvalue["P"]
							local valuetable = {}
							local qualitytable = {}
							local timestamptable = {}
							local timeRangeStart = {}
							local timeRangeEnde = {}
							for _, value in ipairs(tagandvalue["V"]) do
								table.insert(valuetable, value["v"])
								table.insert(timestamptable, value["t"])
								table.insert(timeRangeStart, value["start"])
								table.insert(timeRangeEnde, value["ende"])
								if value["q"] == true then
									table.insert(qualitytable, 0)
								else
									table.insert(qualitytable, 80000000)
								end
							end
							if type(arg["tags"]) == "table" then
								for i = responseindex, #arg["tags"] do
									local tagname = self:_gettagname(arg.disluaclean or false,arg["tags"][i],"\\")
									if tagname ~= tag then
										table.insert(
											response,
											{
												{
													["V"] = {},
													["Q"] = {},
													["T"] = {}
												}
											}
										)
									else
										table.insert(
											response,
											{
												["P"] = tag,
												{
													["V"] = valuetable,
													["Q"] = qualitytable,
													["T"] = timestamptable,
													["START"] = timeRangeStart,
													["ENDE"] = timeRangeEnde
												}
											}
										)
										responseindex = i + 1
										break
									end
								end
							elseif type(arg["tagstimes"]) == "table" then
								for i = responseindex, #arg["tagstimes"] do
									if LUATYPE(arg["tagstimes"][i]["tag"]) ~= LUATYPE(tag) then
										table.insert(
											response,
											{
												["V"] = {},
												["Q"] = {},
												["T"] = {}
											}
										)
									else
										table.insert(
											response,
											{
												["V"] = valuetable,
												["Q"] = qualitytable,
												["T"] = timestamptable,
												["START"] = timeRangeStart,
												["ENDE"] = timeRangeEnde
											}
										)
										responseindex = i + 1
										break
									end
								end
							else
								--dataresponse = nil
								return nil, {["msg"] = "Wrong table names! Check mandatory function parameters!"}
							end
						end
						--dataresponse = nil
						return response
					else
						return dataresponse, {["msg"] = "Warning: no valid response type! Standard response was returned."}
					end
				end
			end
			return nil, {
				["tcp"] = exception,
				["msg"] = "Warning: no valid response type! Standard response was returned.",
				["dataresponse"] = dataresponse
			}
		end
		return nil, tcpex
	end
	return nil, {["msg"] = "Error call arguments"}
end

function lib:PIPOINTSUMMARY(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("PIPOINTSUMMARY should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "PIPointSummary",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["farg"] = {
			["ValuesToRead"] = {},
		}
	}
	if type(arg["tags"]) == "table" or type(arg["tagstimes"]) == "table" then
		if type(arg["StartTime"]) == "number" and type(arg["EndTime"]) == "number"
		 and type(arg["typ"]) == "number" and type(arg["calcbasis"]) == "number" and type(arg["calcbasis"]) == "number" then
			for _, tagpath in ipairs(arg["tags"]) do
				local tagname = self:_gettagname(arg.disluaclean or false,tagpath,"\\")
				table.insert(
					call["farg"]["ValuesToRead"],
					{
						["P"] = tagname,
						["T"] = {
							["t1"] = arg["StartTime"],
							["t2"] = arg["EndTime"]
						},
						["typ"] = arg["typ"],
						["calcbasis"] = arg["calcbasis"],
						["timecalc"] = arg["timecalc"],
					}
				)
				-- end
			end
		elseif type(arg["tagstimes"]) == "table" then
			for i = 1, #arg["tagstimes"] do
				table.insert(
					call["farg"]["ValuesToRead"],
					{
						["P"] = arg["tagstimes"][i]["tag"],
						["T"] = {
							["t1"] = arg["tagstimes"][i]["StartTime"],
							["t2"] = arg["tagstimes"][i]["EndTime"]
						},
						["typ"] = arg["tagstimes"][i]["typ"],
						["calcbasis"] = arg["tagstimes"][i]["calcbasis"],
						["timecalc"] = arg["tagstimes"][i]["timecalc"]
					}
				)
			end
		else
			return nil, {["msg"] = "Wrong table names! Check mandatory function parameters!"}
		end
		local ok, tcpex = self:_tcpsend(call)
		if ok then
			local dataresponse, exception = self:_tcpreceive()
			if exception == nil then
				if type(dataresponse["farg"]) == "table" then
					arg["response"] = arg["response"] or "inmation"
					if arg["response"] == "raw" and type(dataresponse["farg"]) == "table" then
						return dataresponse["farg"]["ValuesToRead"]
					elseif arg["response"] == "inmation" then
						local response = {}
						local responseindex = 1
						for _, tagandvalue in ipairs(dataresponse["farg"]["ValuesToRead"]) do
							local tag = tagandvalue["P"]
							local valuetable = {}
							local qualitytable = {}
							local timestamptable = {}
							for _, value in ipairs(tagandvalue["V"]) do
								table.insert(valuetable, value["v"])
								table.insert(timestamptable, value["t"])
								if value["q"] == true then
									table.insert(qualitytable, 0)
								else
									table.insert(qualitytable, 80000000)
								end
							end
							if type(arg["tags"]) == "table" then
								for i = responseindex, #arg["tags"] do
									local tagname = self:_gettagname(arg.disluaclean or false,arg["tags"][i],"\\")
									if tagname ~= tag then
										table.insert(
											response,
											{
												{
													["V"] = {},
													["Q"] = {},
													["T"] = {}
												}
											}
										)
									else
										table.insert(
											response,
											{
												["P"] = tag,
												{
													["V"] = valuetable,
													["Q"] = qualitytable,
													["T"] = timestamptable,
												}
											}
										)
										responseindex = i + 1
										break
									end
								end
							elseif type(arg["tagstimes"]) == "table" then
								for i = responseindex, #arg["tagstimes"] do
									if LUATYPE(arg["tagstimes"][i]["tag"]) ~= LUATYPE(tag) then
										table.insert(
											response,
											{
												["V"] = {},
												["Q"] = {},
												["T"] = {}
											}
										)
									else
										table.insert(
											response,
											{
												["V"] = valuetable,
												["Q"] = qualitytable,
												["T"] = timestamptable,
											}
										)
										responseindex = i + 1
										break
									end
								end
							else
								--dataresponse = nil
								return nil, {["msg"] = "Wrong table names! Check mandatory function parameters!"}
							end
						end
						--dataresponse = nil
						return response
					else
						return dataresponse, {["msg"] = "Warning: no valid response type! Standard response was returned."}
					end
				end
			end
			return nil, {
				["tcp"] = exception,
				["msg"] = "Warning: no valid response type! Standard response was returned.",
				["dataresponse"] = dataresponse
			}
		end
		return nil, tcpex
	end
	return nil, {["msg"] = "Error call arguments"}
end

function lib:FINDPIPOINTS(arg)
	if self == nil or type(self) ~= "table" or self.tcpconfig == nil then
		error("FINDPIPOINTS should be called using colon ':' notation", 2)
	end
	local call = {
		["sys"] = "OSI",
		["func"] = "FindPIPoints",
		["piserver"] = arg["piserver"] or self.alias.piserver,
		["namefilter"] = arg["namefilter"] or "*",
		["sourcefilter"] = arg["sourcefilter"]
	}
	local ok, tcpex = self:_tcpsend(call)
	if ok then
		local dataresponse, exception = self:_tcpreceive()
		if exception == nil then
			if type(dataresponse) == "table" then
				if type(dataresponse["farg"]) == "table" then
					if #dataresponse["farg"]["PIPoints"] then
						return dataresponse["farg"]
					else
						return dataresponse["farg"], exception
					end
				end
			end
		else
			return nil, {
				["tcp"] = exception,
				["msg"] = "Warning: no valid response type! Standard response was returned.",
				["dataresponse"] = dataresponse
			}
		end
	else
		return nil, tcpex
	end
	return nil, {["msg"] = "Error call arguments"}
end

	local piqualitiesintoopcqualities = {
		[193] = 0,
        [194] = 2147483648,
        [195] = 2147483648,
        [196] = 2147483648,
        [197] = 2147483648,
        [198] = 1073741824,
        [199] = 2147483648,
        [200] = 1073741824,
        [201] = 1073741824,
        [202] = 1073741824,
        [203] = 1073741824,
        [210] = 2149515264,
        [211] = 2147483648,
        [212] = 2147483648,
        [213] = 2156593152,
        [214] = 2147483648,
        [215] = 2156593152,
        [216] = 2147483648,
        [217] = 2147811328,
        [218] = 2151415808,
        [219] = 2157641728,
        [220] = 0,
        [221] = 0,
        [222] = 0,
        [223] = 0,
        [224] = 2147483648,
        [225] = 2147483648,
        [226] = 2147483648,
        [227] = 2147483648,
        [230] = 0,
        [231] = 0,
        [232] = 2147483648,
        [233] = 2147811328,
        [234] = 2147483648,
        [235] = 2147483648,
        [237] = 2156593152,
        [238] = 2156462080,
        [239] = 2156462080,
        [240] = 2156462080,
        [241] = 2147483648,
        [242] = 2147483648,
        [243] = 1073741824,
        [244] = 1073741824,
        [245] = 2156462080,
        [246] = 2148139008,
        [247] = 2147483648,
        [248] = 2157641728,
        [249] = 2156462080,
        [250] = 2165440512,
        [251] = 2151415808,
        [252] = 2151415808,
        [253] = 2156462080,
        [254] = 2148270080,
        [255] = 2147483648,
        [256] = 2147483648,
        [257] = 0,
        [258] = 2151415808,
        [259] = 2151415808,
        [260] = 2151415808,
        [261] = 2151415808,
        [262] = 2151415808,
        [263] = 2151415808,
        [264] = 2151415808,
        [265] = 2151415808,
        [266] = 1073741824,
        [267] = 1073741824,
        [268] = 0,
        [269] = 0,
        [270] = 0,
        [271] = 2151415808,
        [272] = 2151415808,
        [273] = 2151415808,
        [274] = 2151415808,
        [275] = 2151415808,
        [276] = 2151415808,
        [277] = 2151415808,
        [278] = 2151415808,
        [279] = 1073741824,
        [280] = 1073741824,
        [281] = 0,
        [282] = 0,
        [289] = 0,
        [290] = 2147483648,
        [291] = 2156462080,
        [292] = 2148139008,
        [293] = 2147483648,
        [294] = 2151415808,
        [295] = 1073741824,
        [296] = 1073741824,
        [297] = 1073741824,
        [298] = 1073741824,
        [299] = 2148073472,
        [300] = 2148139008,
        [301] = 1073741824,
        [302] = 1073741824,
        [303] = 2147483648,
        [305] = 0,
        [306] = 2147483648,
        [307] = 2147483648,
        [308] = 1073741824,
        [309] = 2156462080,
        [310] = 2165440512,
        [311] = 2147811328,
        [312] = 2156724224,
        [313] = 2147811328,
        [314] = 2156527616,
        [315] = 2147483648,
        [316] = 2147483648,
        [317] = 2153971712,
        [318] = 2149777408,
	}

-- contains all PI errors and with their translating OPC error
function lib._piqualitiesintoopcqualities(_, arg)
	return piqualitiesintoopcqualities[arg]
end

	local opcqualitiesintopiqualities = {
        [2147483648] = 307,
        [2161770496] = 240,
        [2161508352] = 255,
        [2161377280] = 290,
        [2161442816] = 290,
        [2165637120] = 307,
        [2153250816] = 210,
        [2155216896] = 307,
        [2150957056] = 299,
        [2161573888] = 307,
        [2161639424] = 307,
        [2152529920] = 240,
        [2153840640] = 240,
        [2153775104] = 240,
        [2165112832] = 210,
        [2148925440] = 240,
        [2148663296] = 299,
        [2149318656] = 240,
        [2149449728] = 210,
        [2148859904] = 242,
        [2149122048] = 210,
        [2165571584] = 242,
        [2149253120] = 240,
        [2149384192] = 210,
        [2148794368] = 242,
        [2149187584] = 210,
        [2148990976] = 314,
        [2149056512] = 210,
        [2147811328] = 313,
        [2157445120] = 307,
        [2160852992] = 307,
        [2161180672] = 307,
        [2161049600] = 307,
        [2161115136] = 307,
        [2157510656] = 307,
        [2161246208] = 307,
        [2156462080] = 240,
        [2158886912] = 314,
        [2158755840] = 210,
        [2152202240] = 240,
        [2152333312] = 240,
        [2151153664] = 240,
        [2151219200] = 240,
        [2157772800] = 248,
        [2148597760] = 309,
        [2157838336] = 248,
        [2156789760] = 299,
        [2147942400] = 290,
        [2162360320] = 290,
        [2156593152] = 215,
        [2160918528] = 307,
        [2160984064] = 299,
        [2158821376] = 314,
        [2152792064] = 314,
        [2162229248] = 290,
        [2154168320] = 210,
        [2147876864] = 290,
        [2148007936] = 250,
        [2159017984] = 313,
        [2157903872] = 307,
        [2152136704] = 240,
        [2157576192] = 307,
        [2159738880] = 307,
        [2159280128] = 307,
        [2160328704] = 240,
        [2160394240] = 240,
        [2152005632] = 240,
        [2160263168] = 240,
        [2152267776] = 240,
        [2160132096] = 240,
        [2160197632] = 240,
        [2154889216] = 240,
        [2154954752] = 240,
        [2160459776] = 307,
        [2149580800] = 210,
        [2149646336] = 210,
        [2151022592] = 299,
        [2151088128] = 240,
        [2155610112] = 307,
        [2147614720] = 307,
        [2158690304] = 299,
        [2154233856] = 240,
        [2158952448] = 299,
        [2149777408] = 318,
        [2159869952] = 299,
        [2165178368] = 210,
        [2165243904] = 210,
        [2165309440] = 210,
        [2154823680] = 307,
        [2159476736] = 312,
        [2155544576] = 307,
        [2155151360] = 299,
        [2151874560] = 240,
        [2151940096] = 240,
        [2151809024] = 299,
        [2151743488] = 240,
        [2150694912] = 313,
        [2152398848] = 240,
        [2157641728] = 248,
        [2159083520] = 248,
        [2153906176] = 240,
        [2153709568] = 240,
        [2153644032] = 240,
        [2150825984] = 240,
        [2153578496] = 210,
        [2150891520] = 240,
        [2154364928] = 210,
        [2152595456] = 313,
        [2157969408] = 307,
        [2154758144] = 307,
        [2149842944] = 210,
        [2155413504] = 313,
        [2156527616] = 314,
        [2165374976] = 240,
        [2151546880] = 240,
        [2148466688] = 307,
        [2151677952] = 307,
        [2151284736] = 313,
        [2151481344] = 307,
        [2160590848] = 240,
        [2151350272] = 313,
        [2153316352] = 210,
        [2165440512] = 310,
        [2151612416] = 307,
        [2159214592] = 307,
        [2147680256] = 312,
        [2151415808] = 294,
        [2156724224] = 312,
        [2153447424] = 307,
        [2159935488] = 240,
        [2154692608] = 250,
        [2154299392] = 240,
        [2153512960] = 210,
        [2152464384] = 240,
        [2157379584] = 307,
        [2150367232] = 242,
        [2153381888] = 307,
        [2150236160] = 240,
        [2156134400] = 246,
        [2162425856] = 290,
        [2165506048] = 290,
        [2156199936] = 313,
        [2159542272] = 252,
        [2152923136] = 240,
        [2147745792] = 312,
        [2159607808] = 252,
        [2156265472] = 313,
        [2149711872] = 210,
        [2156331008] = 313,
        [2148728832] = 210,
        [2162556928] = 240,
        [2152988672] = 210,
        [2153054208] = 210,
        [2152857600] = 240,
        [2156658688] = 215,
        [2156396544] = 307,
        [2155479040] = 307,
        [2148401152] = 213,
        [2154430464] = 240,
        [2152726528] = 240,
        [2148335616] = 314,
        [2152660992] = 314,
        [2148204544] = 240,
        [2149974016] = 314,
        [2149908480] = 210,
        [2150039552] = 242,
        [2161311744] = 313,
        [2148270080] = 254,
        [2154037248] = 240,
        [2160001024] = 307,
        [2152071168] = 240,
        [2150105088] = 240,
        [2159411200] = 307,
        [2154102784] = 240,
        [2156068864] = 314,
        [2156003328] = 313,
        [2155872256] = 313,
        [2155741184] = 299,
        [2155937792] = 313,
        [2155806720] = 313,
        [2155675648] = 313,
        [2148139008] = 246,
        [2158034944] = 307,
        [2150301696] = 242,
        [2162491392] = 250,
        [2154627072] = 250,
        [2161836032] = 250,
        [2148532224] = 250,
        [2155347968] = 313,
        [2153119744] = 307,
        [2155282432] = 312,
        [2153971712] = 317,
        [2155085824] = 307,
        [2147549184] = 307,
        [2148073472] = 299,
        [2149515264] = 210,
        [2153185280] = 210,
        [2154496000] = 240,
        [2160721920] = 240,
        [2160656384] = 240,
        [2160787456] = 242,
        [2150760448] = 238,
        [2159149056] = 313,
        [2159345664] = 307,
        [2155020288] = 307,
        [0] = 305,
        [11075584] = 305,
        [3145728] = 305,
        [10944512] = 305,
        [3014656] = 305,
        [14221312] = 305,
        [14680064] = 305,
        [14417920] = 305,
        [10616832] = 305,
        [10682368] = 305,
        [9830400] = 305,
        [10878976] = 305,
        [10813440] = 305,
        [11141120] = 305,
        [3080192] = 305,
        [14483456] = 305,
        [12189696] = 305,
        [11010048] = 305,
        [2949120] = 305,
        [1073741824] = 308,
        [1084489728] = 290,
        [1088552960] = 290,
        [1088290816] = 305,
        [1083441152] = 294,
        [1083310080] = 290,
        [1083179008] = 290,
        [1083113472] = 313,
        [1086324736] = 313,
        [1086062592] = 240,
        [1080819712] = 312,
        [1083375616] = 215,
        [1083506688] = 294,
        [1083244544] = 308,
	}

-- contains all OPC errors and with their translating PI error
function lib._opcqualitiesintopiqualities(_, arg)
	return opcqualitiesintopiqualities[arg]
end

	local convertpiqualitiesintoopcqualities = {
		["No Alarm"] = 0,
		["High Alarm"] = 2147483648,
		["Low Alarm"] = 2147483648,
		["Hi Alarm/Ack"] = 2147483648,
		["Lo Alarm/Ack"] = 2147483648,
		["NoAlrm/UnAck"] = 1073741824,
		["Bad Quality"] = 2147483648,
		["Rate Alarm"] = 1073741824,
		["Rate Alm/Ack"] = 1073741824,
		["Dig Alarm"] = 1073741824,
		["Dig Alm/Ack"] = 1073741824,
		["AccessDenied"] = 2149515264,
		["No Sample"] = 2147483648,
		["No Result"] = 2147483648,
		["Unit Down"] = 2156593152,
		["Sample Bad"] = 2147483648,
		["Equip Fail"] = 2156593152,
		["No Lab Data"] = 2147483648,
		["Trace"] = 2147811328,
		["GreaterMM"] = 2151415808,
		["Bad Lab Data"] = 2157641728,
		["Good-Off"] = 0,
		["Good-On"] = 0,
		["Alarm-Off"] = 0,
		["Alarm-On"] = 0,
		["Bad_Quality"] = 2147483648,
		["BadQ-On"] = 2147483648,
		["BadQ-Alrm-Of"] = 2147483648,
		["BadQ-Alrm-On"] = 2147483648,
		["Manual"] = 0,
		["Auto"] = 0,
		["Casc/Ratio"] = 2147483648,
		["DCS failed"] = 2147811328,
		["Manual Lock"] = 2147483648,
		["CO Bypassed"] = 2147483648,
		["Bad Output"] = 2156593152,
		["Scan Off"] = 2156462080,
		["Scan On"] = 2147483648,
		["Configure"] = 2156462080,
		["Failed"] = 2147483648,
		["Error"] = 2147483648,
		["Execute"] = 1073741824,
		["Filtered"] = 1073741824,
		["Calc Off"] = 2156462080,
		["I/O Timeout"] = 2148139008,
		["Set to Bad"] = 2147483648,
		["No Data"] = 2157641728,
		["Calc Failed"] = 2156593152,
		["Calc Overflw"] = 1083441152,
		["Under Range"] = 2151415808,
		["Over Range"] = 2151415808,
		["Pt Created"] = 2156462080,
		["Shutdown"] = 2148270080,
		["Bad Input"] = 2147483648,
		["Bad Total"] = 2147483648,
		["No_Alarm"] = 0,
		["Over UCL"] = 1083441152,
		["Under LCL"] = 1083441152,
		["Over WL"] = 1083441152,
		["Under WL"] = 1083441152,
		["Over 1 Sigma"] = 1083441152,
		["Under 1Sigma"] = 1083441152,
		["Over Center"] = 1083441152,
		["Under Center"] = 1083441152,
		["Stratified"] = 1073741824,
		["Mixture"] = 1073741824,
		["Trend Up"] = 0,
		["Trend Down"] = 0,
		["No Alarm#"] = 0,
		["Over UCL#"] = 1083441152,
		["Under LCL#"] = 1083441152,
		["Over WL#"] = 1083441152,
		["Under WL#"] = 1083441152,
		["Over 1Sigma#"] = 1083441152,
		["Under 1Sigm#"] = 1083441152,
		["Over Center#"] = 1083441152,
		["Under Centr#"] = 1083441152,
		["Stratified#"] = 1073741824,
		["Mixture#"] = 1073741824,
		["Trend Up#"] = 0,
		["Trend Down#"] = 0,
		["ActiveBatch"] = 0,
		["Bad Data"] = 2147483648,
		["Calc Crash"] = 2156593152,
		["Calc Timeout"] = 2148139008,
		["Bad Narg"] = 2147483648,
		["Inp OutRange"] = 2151415808,
		["Not Converge"] = 1073741824,
		["DST Forward"] = 1073741824,
		["DST Back"] = 1073741824,
		["Substituted"] = 1073741824,
		["Invalid Data"] = 2147483648,
		["Scan Timeout"] = 2148139008,
		["No_Sample"] = 1073741824,
		["Arc Off-line"] = 1073741824,
		["ISU Saw No Data"] = 2147483648,
		["Good"] = 0,
		["_SUBStituted"] = 2147483648,
		["Bad"] = 2147483648,
		["Doubtful"] = 1073741824,
		["Wrong Type"] = 2156462080,
		["Overflow_st"] = 1083441152,
		["Intf Shut"] = 2147811328,
		["Out of Serv"] = 2156527616,
		["Comm Fail"] = 2147811328,
		["Not Connect"] = 2156527616,
		["Coercion Failed"] = 2147483648,
		["snapfix"] = 2147483648,
		["Invalid Float"] = 1083441152,
		["Future Data Unsupported"] = 1083441152
	}

-- contains all PI errors and with their translating OPC error
function lib._convertpiqualitiesintoopcqualities(_, arg)
	return convertpiqualitiesintoopcqualities[arg]
end

local convertopcqualitiesintopiqualities = {
		[2147483648] = "Bad",
		[2161770496] = "Configure",
		[2161508352] = "Bad Input",
		[2161377280] = "Bad Data",
		[2161442816] = "Bad Data",
		[2165637120] = "Bad",
		[2153250816] = "AccessDenied",
		[2155216896] = "Bad",
		[2150957056] = "Invalid Data",
		[2161573888] = "Bad",
		[2161639424] = "Bad",
		[2152529920] = "Configure",
		[2153840640] = "Configure",
		[2153775104] = "Configure",
		[2165112832] = "AccessDenied",
		[2148925440] = "Configure",
		[2148663296] = "Invalid Data",
		[2149318656] = "Configure",
		[2149449728] = "AccessDenied",
		[2148859904] = "Error",
		[2149122048] = "AccessDenied",
		[2165571584] = "Error",
		[2149253120] = "Configure",
		[2149384192] = "AccessDenied",
		[2148794368] = "Error",
		[2149187584] = "AccessDenied",
		[2148990976] = "Not Connect",
		[2149056512] = "AccessDenied",
		[2147811328] = "Comm Fail",
		[2157445120] = "Bad",
		[2160852992] = "Bad",
		[2161180672] = "Bad",
		[2161049600] = "Bad",
		[2161115136] = "Bad",
		[2157510656] = "Bad",
		[2161246208] = "Bad",
		[2156462080] = "Configure",
		[2158886912] = "Not Connect",
		[2158755840] = "AccessDenied",
		[2152202240] = "Configure",
		[2152333312] = "Configure",
		[2151153664] = "Configure",
		[2151219200] = "Configure",
		[2157772800] = "No Data",
		[2148597760] = "Wrong Type",
		[2157838336] = "No Data",
		[2156789760] = "Invalid Data",
		[2147942400] = "Bad Data",
		[2162360320] = "Bad Data",
		[2156593152] = "Equip Fail",
		[2160918528] = "Bad",
		[2160984064] = "Invalid Data",
		[2158821376] = "Not Connect",
		[2152792064] = "Not Connect",
		[2162229248] = "Bad Data",
		[2154168320] = "AccessDenied",
		[2147876864] = "Bad Data",
		[2148007936] = "Calc Overflw",
		[2159017984] = "Comm Fail",
		[2157903872] = "Bad",
		[2152136704] = "Configure",
		[2157576192] = "Bad",
		[2159738880] = "Bad",
		[2159280128] = "Bad",
		[2160328704] = "Configure",
		[2160394240] = "Configure",
		[2152005632] = "Configure",
		[2160263168] = "Configure",
		[2152267776] = "Configure",
		[2160132096] = "Configure",
		[2160197632] = "Configure",
		[2154889216] = "Configure",
		[2154954752] = "Configure",
		[2160459776] = "Bad",
		[2149580800] = "AccessDenied",
		[2149646336] = "AccessDenied",
		[2151022592] = "Invalid Data",
		[2151088128] = "Configure",
		[2155610112] = "Bad",
		[2147614720] = "Bad",
		[2158690304] = "Invalid Data",
		[2154233856] = "Configure",
		[2158952448] = "Invalid Data",
		[2149777408] = "Future Data Unsupported",
		[2159869952] = "Invalid Data",
		[2165178368] = "AccessDenied",
		[2165243904] = "AccessDenied",
		[2165309440] = "AccessDenied",
		[2154823680] = "Bad",
		[2159476736] = "Out of Serv",
		[2155544576] = "Bad",
		[2155151360] = "Invalid Data",
		[2151874560] = "Configure",
		[2151940096] = "Configure",
		[2151809024] = "Invalid Data",
		[2151743488] = "Configure",
		[2150694912] = "Comm Fail",
		[2152398848] = "Configure",
		[2157641728] = "No Data",
		[2159083520] = "No Data",
		[2153906176] = "Configure",
		[2153709568] = "Configure",
		[2153644032] = "Configure",
		[2150825984] = "Configure",
		[2153578496] = "AccessDenied",
		[2150891520] = "Configure",
		[2154364928] = "AccessDenied",
		[2152595456] = "Comm Fail",
		[2157969408] = "Bad",
		[2154758144] = "Bad",
		[2149842944] = "AccessDenied",
		[2155413504] = "Comm Fail",
		[2156527616] = "Not Connect",
		[2165374976] = "Configure",
		[2151546880] = "Configure",
		[2148466688] = "Bad",
		[2151677952] = "Bad",
		[2151284736] = "Comm Fail",
		[2151481344] = "Bad",
		[2160590848] = "Configure",
		[2151350272] = "Comm Fail",
		[2153316352] = "AccessDenied",
		[2165440512] = "Overflow_st",
		[2151612416] = "Bad",
		[2159214592] = "Bad",
		[2147680256] = "Out of Serv",
		[2151415808] = "Inp OutRange",
		[2156724224] = "Out of Serv",
		[2153447424] = "Bad",
		[2159935488] = "Configure",
		[2154692608] = "Calc Overflw",
		[2154299392] = "Configure",
		[2153512960] = "AccessDenied",
		[2152464384] = "Configure",
		[2157379584] = "Bad",
		[2150367232] = "Error",
		[2153381888] = "Bad",
		[2150236160] = "Configure",
		[2156134400] = "I/O Timeout",
		[2162425856] = "Bad Data",
		[2165506048] = "Bad Data",
		[2156199936] = "Comm Fail",
		[2159542272] = "Over Range",
		[2152923136] = "Configure",
		[2147745792] = "Out of Serv",
		[2159607808] = "Over Range",
		[2156265472] = "Comm Fail",
		[2149711872] = "AccessDenied",
		[2156331008] = "Comm Fail",
		[2148728832] = "AccessDenied",
		[2162556928] = "Configure",
		[2152988672] = "AccessDenied",
		[2153054208] = "AccessDenied",
		[2152857600] = "Configure",
		[2156658688] = "Equip Fail",
		[2156396544] = "Bad",
		[2155479040] = "Bad",
		[2148401152] = "Unit Down",
		[2154430464] = "Configure",
		[2152726528] = "Configure",
		[2148335616] = "Not Connect",
		[2152660992] = "Not Connect",
		[2148204544] = "Configure",
		[2149974016] = "Not Connect",
		[2149908480] = "AccessDenied",
		[2150039552] = "Error",
		[2161311744] = "Comm Fail",
		[2148270080] = "Shutdown",
		[2154037248] = "Configure",
		[2160001024] = "Bad",
		[2152071168] = "Configure",
		[2150105088] = "Configure",
		[2159411200] = "Bad",
		[2154102784] = "Configure",
		[2156068864] = "Not Connect",
		[2156003328] = "Comm Fail",
		[2155872256] = "Comm Fail",
		[2155741184] = "Invalid Data",
		[2155937792] = "Comm Fail",
		[2155806720] = "Comm Fail",
		[2155675648] = "Comm Fail",
		[2148139008] = "I/O Timeout",
		[2158034944] = "Bad",
		[2150301696] = "Error",
		[2162491392] = "Calc Overflw",
		[2154627072] = "Calc Overflw",
		[2161836032] = "Calc Overflw",
		[2148532224] = "Calc Overflw",
		[2155347968] = "Comm Fail",
		[2153119744] = "Bad",
		[2155282432] = "Out of Serv",
		[2153971712] = "Invalid Float",
		[2155085824] = "Bad",
		[2147549184] = "Bad",
		[2148073472] = "Invalid Data",
		[2149515264] = "AccessDenied",
		[2153185280] = "AccessDenied",
		[2154496000] = "Configure",
		[2160721920] = "Configure",
		[2160656384] = "Configure",
		[2160787456] = "Error",
		[2150760448] = "Scan Off",
		[2159149056] = "Comm Fail",
		[2159345664] = "Bad",
		[2155020288] = "Bad",
		[0] = "Good",
		[11075584] = "Good",
		[3145728] = "Good",
		[10944512] = "Good",
		[3014656] = "Good",
		[14221312] = "Good",
		[14680064] = "Good",
		[14417920] = "Good",
		[10616832] = "Good",
		[10682368] = "Good",
		[9830400] = "Good",
		[10878976] = "Good",
		[10813440] = "Good",
		[11141120] = "Good",
		[3080192] = "Good",
		[14483456] = "Good",
		[12189696] = "Good",
		[11010048] = "Good",
		[2949120] = "Good",
		[1073741824] = "Doubtful",
		[1084489728] = "Bad Data",
		[1088552960] = "Bad Data",
		[1088290816] = "Good",
		[1083441152] = "Inp OutRange",
		[1083310080] = "Bad Data",
		[1083179008] = "Bad Data",
		[1083113472] = "Comm Fail",
		[1086324736] = "Comm Fail",
		[1086062592] = "Configure",
		[1080819712] = "Out of Serv",
		[1083375616] = "Equip Fail",
		[1083506688] = "Inp OutRange",
		[1083244544] = "Doubtful",
	}

function lib._gettagname(_,disableclean,pathtosplit,seperator)
	local tagname
	if disableclean then
		tagname =pathtosplit
	else
		local tagparts = syslib.split(pathtosplit, seperator)
		tagname = tagparts[#tagparts]
	end

	return tagname
end

-- contains all OPC errors and with their translating PI error
function lib._convertopcqualitiesintopiqualities(_, arg)
	 return convertopcqualitiesintopiqualities[arg]
end

pcall(function()
	local config = require('esi-pibridge-config')
	for k,v in pairs(config.piqualitiesintoopcqualities)do
		piqualitiesintoopcqualities[k] = v
	end
	for k,v in pairs(config.opcqualitiesintopiqualities)do
		opcqualitiesintopiqualities[k] = v
	end
	for k,v in pairs(config.convertpiqualitiesintoopcqualities)do
		convertpiqualitiesintoopcqualities[k] = v
	end
	for k,v in pairs(config.convertopcqualitiesintopiqualities)do
		convertopcqualitiesintopiqualities[k] = v
	end
end)

return lib
