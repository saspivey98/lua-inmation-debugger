-- esi-lcurl-http-client
-- inmation Script Library Lua Script
--
-- 2022 inmation
--
-- HTTP Client to perform HTTP requests using the lcurl library.
-- Using lcurl library http://lua-curl.github.io/lcurl/modules/lcurl.html
-- Supports HTTPS requests via proxy using optional proxy credentials.
--
-- Version history:
--
-- 20220506.8  Fixed: timeout option passing.
-- 20211207.7  Fixed: Request with method set to 'POST' and having an empty body are not sent as 'GET' anymore.
-- 20210603.6  Added: HEADERVALUEBYNAME function.
--             Fixed: case-insensitive response header name inspection e.g. "Content-Type" vs "content-type".
-- 20201208.5  TFS code synchronisation
-- 20191106.4  Added optional debug callback, added NTLM authentication
-- 20181125.3  Added callback 'ONENCODEDRESPONSEDATA' which will be invoked when response contains
--             'Content-Encoding' in the header. This is typically used for compression.
-- 20181029.2  Only try to parse when 'Content-Type' of the response contains 'application/json'.
-- 20180807.1  Initial release.
-- ----------------------------
local Version = {1,0,8}

local JSON = require('dkjson')
local cURL = require('lcurl')
local mime = require('mime')
local Dependencies = {
	{
		modulename = 'dkjson'
    },
    {
        modulename = 'lcurl',
        info = cURL.version_info()
    },
    {
		modulename = 'mime'
	}
}

local HEADER_NAME = {
    ACCEPT = "Accept",
    ACCEPT_ENCODING = "Accept-Encoding",
    AUTHORIZATION = "Authorization",
    CONTENT_LENGTH = "Content-Length",
    CONTENT_ENCODING = "Content-Encoding",
    CONTENT_TYPE = "Content-Type",
    PROXY_AUTHORIZATION = "Proxy-Authorization"
}

local HEADER_VALUE = {
    APPLICATION_X_WWW_FORM_URLENCODED = "application/x-www-form-urlencoded",
    APPLICATION_JSON = "application/json",
    DEFLATE = 'deflate'
}

local METHOD_NAME = {
    DELETE = "DELETE",
    GET = "GET",
    HEAD = "HEAD",
    OPTIONS = 'OPTIONS',
    PATCH = 'PATCH',
    POST = "POST",
    PUT = "PUT"
}

local HTTPClient = {}

HTTPClient.HEADER_NAME = HEADER_NAME
HTTPClient.METHOD_NAME = METHOD_NAME
HTTPClient.HEADER_VALUE = HEADER_VALUE

HTTPClient.__index = HTTPClient

-- #region Public

function HTTPClient.NEW(options)
    local o = {}
    setmetatable(o, HTTPClient)
    o._options = options or {}
    return o
end
HTTPClient.new = HTTPClient.NEW

function HTTPClient.INFO()
    local fields = {}
    for field, val in pairs(HTTPClient) do
        if type(field) == 'string' then
            -- Skip 'private' functions
            if not string.match(field, "^_") then
                fields[field] = type(val)
            end
        end
    end
    return {
		version = {
			major = Version[1],
			minor = Version[2],
			revision = Version[3]
		},
		contacts = {
			{
                name = "Marc van de Langenberg",
                company = "inmation",
				email = "marc.vandelangenberg@inmation.com"
			}
		},
		library = {
            modulename = "esi-lcurl-http-client",
            filename = "esi-lcurl-http-client.lua",
            description = "HTTP Client to perform HTTP requests using the lcurl library.",
            dependencies = Dependencies,
            fields = fields
		}
	}
end

-- #region callbacks

function HTTPClient.ONENCODEDRESPONSEDATA(encoded, encoding)
    if encoding == 'identity' then
        return encoded
    end
    return encoded
    --return inmation.asciitoutf8(encoded)
end

-- #endregion callbacks

function HTTPClient.ISSUCCESS(_, code)
    return type(code) == 'number' and code >= 200 and code < 300
end

function HTTPClient.BASE64(_, str, ...)
    return mime.b64(string.format(str, ...))
end

function HTTPClient.UNBASE64(_, b64Str)
    return mime.unb64(b64Str)
end

function HTTPClient.HEADERVALUEBYNAME(_, headers, name)
    if type(headers) == 'table' then
        local value = headers[name]
        if value ~= nil then return value end

        -- Check with lowercase
        name = string.lower(name)
        value = headers[name]
        if value ~= nil then return value end

        -- Do case-insensitive search
        for hName, hValue in pairs(headers) do
            hName = string.lower(hName)
            if name == hName then
                return hValue
            end
        end
    end
end

--- Sends out a HTTP Request.
-- @param method like 'GET', 'POST', etc. Can also be a table contain the arguments as fields.
-- @param url string containing the URL.
-- @param headers (optional) table.
-- @param reqData (optional) Request Data can be a string or a table.
-- @usage local url = 'http://inmationwebapi.company.com:8002/api/checkstatus'
-- @usage local res = httpClient:REQUEST('GET, url)
-- @usage return res.ok, res.code, res.data, res.headers
-- @return table with res.ok, res.code (HTTP Response Codes) and optional res.data and res.headers
function HTTPClient:REQUEST(method, url, headers, reqData, debugfunction)
    local options = self._options

    -- check whether this function or one of the Request methods like get, post, etc is invoked with an argument table.
    local arg = nil
    if type(method) == 'table' then
        arg = method
    elseif type(url) == 'table' then
        arg = url
        -- Don't allow method override in this case.
        arg.method = method
    end
    if type(arg) == 'table' then
        method = arg.method
        url = arg.url
        headers = arg.headers
        reqData = arg.reqdata or arg.reqData
    end

    local preErr = nil
    if type(url) ~= 'string' then preErr = "Missing URL" end
    if preErr then return 0, 0, preErr end

    if type(headers) ~= 'table' then headers = {} end

    local reqbody = reqData or ''
	if type(reqData) == 'table' then
	    reqbody = JSON.encode(reqData)
        headers[HEADER_NAME.CONTENT_TYPE] = HEADER_VALUE.APPLICATION_JSON
        headers[HEADER_NAME.ACCEPT] = HEADER_VALUE.APPLICATION_JSON
    end

    local resBody = {}
    local resHeaders = {}
    local resHeadersSet = false

    local init = {
        url = url,
        ssl_verifypeer = options.ssl_verifypeer == true,
        writefunction = function(str)
            table.insert(resBody, str)
        end,
        headerfunction = function(str)
            str = string.gsub(str, '\r\n', '')
            if str ~= '' then
                -- Split on ': ' so we can return a proper table.
                local headerFieldname, headerValue = string.match(str, "(.*): (.*)")
                if (headerFieldname or '') ~= '' and (headerValue or '') ~= '' then
                    resHeaders[headerFieldname] = headerValue
                    resHeadersSet = true
                end
            end
        end
    }
    if (debugfunction) then
        init.verbose = 1
        init.debugfunction = debugfunction
    end
    local easy = cURL.easy(init)

    if options.proxy then
        easy:setopt_proxy(options.proxy)
        if options.proxyCred then
			easy:setopt_proxyuserpwd(options.proxyCred)
        end
    end

    if options.httpauth then
        -- see: https://curl.haxx.se/libcurl/c/CURLOPT_HTTPAUTH.html
        --      more types are available, strip the CUR... from the labels in the link
        if (options.httpauth == "NTLM") then
            easy:setopt_httpauth(cURL.AUTH_NTLM)
            easy:setopt_username(options.username)
            easy:setopt_password(options.password)
        end
    end

    if options.timeout then
        if ("number" == type(options.timeout)) then
            easy:setopt_timeout(options.timeout)
        end
    end

    if method ~= METHOD_NAME.GET and method ~= METHOD_NAME.POST then
        easy:setopt_customrequest(method)
    end

    if method == METHOD_NAME.HEAD then
        easy:setopt_nobody(true)
    end

    local reqBodyLen = string.len(reqbody)
    if reqBodyLen >= 0 and method ~= METHOD_NAME.GET then
        headers[HEADER_NAME.CONTENT_LENGTH] = reqBodyLen
        easy:setopt_postfields(reqbody)
    end

    local _headers = {}
    for k,v in pairs(headers) do
        table.insert(_headers, string.format("%s: %s", k, v))
    end
    easy:setopt_httpheader(_headers)

    local ok, errData = easy:perform()
    local code = easy:getinfo_response_code()
    local effective_url = easy:getinfo_effective_url()
    easy:close()

    local result = {
        ok = true,
        code = code or 0,
        url = effective_url,
        data = nil
    }

    if resHeadersSet then
        result.headers = resHeaders
    end

    if not ok then
        -- easy returns ok and errData of type 'userdata'. Make sure to convert them otherwise JSON.encode won't work.
        result.ok = false
        result.error = tostring(errData)
        return result
    end

    local contentTypeIsJSON = function()
        local contentType = self:HEADERVALUEBYNAME(resHeaders, HEADER_NAME.CONTENT_TYPE)
        if type(contentType) == 'string' then
            return contentType:find(HEADER_VALUE.APPLICATION_JSON) ~= nil
        end
        return false
    end

    local resData = nil
    if resBody ~= nil then
        if type(resBody) == 'table' then
            resData = table.concat(resBody)
            if resData ~= '' then
                local encoding = self:HEADERVALUEBYNAME(resHeaders, HEADER_NAME.CONTENT_ENCODING)
                if type(encoding) == 'string' then
                    resData = self.ONENCODEDRESPONSEDATA(resData, encoding)
                end
                if contentTypeIsJSON() then
                    pcall(function()
                        local parsedData = JSON.decode(resData)
                        if parsedData ~= nil then
                            resData = parsedData
                        end
                    end)
                end
            end
        else
            resData = resBody
        end
    end
    result.data = resData

    return result
end

-- #region Request Methods

--- Sends out a HTTP DELETE Request.
-- @param url string containing the URL.
-- @param headers (optional) table.
-- @param reqData (optional) Request Data can be a string or a table.
-- @usage local res = httpClient:DELETE(url)
-- @usage return res.ok, res.code, res.data, res.headers
-- @return table with res.ok, res.code (HTTP Response Codes) and optional res.data and res.headers
function HTTPClient:DELETE(url, headers, body)
	return self:REQUEST(METHOD_NAME.DELETE, url, headers, body)
end

--- Sends out a HTTP GET Request.
-- @param url string containing the URL.
-- @param headers (optional) table.
-- @usage local url = 'http://inmationwebapi.company.com:8002/api/checkstatus'
-- @usage local res = httpClient:GET(url)
-- @usage return res.ok, res.code, res.data, res.headers
-- @return table with res.ok, res.code (HTTP Response Codes) and optional res.data and res.headers
function HTTPClient:GET(url, headers, debugfunction)
	return self:REQUEST(METHOD_NAME.GET, url, headers, nil, debugfunction)
end

--- Sends out a HTTP HEAD Request which is a GET without response body.
-- @param url string containing the URL.
-- @param headers (optional) table.
-- @usage local url = 'http://inmationwebapi.company.com:8002/api/checkstatus'
-- @usage local res = httpClient:HEAD(url)
-- @usage return res.ok, res.code, res.headers
-- @return table with res.ok, res.code (HTTP Response Codes) and optional res.data and res.headers
function HTTPClient:HEAD(url, headers)
	return self:REQUEST(METHOD_NAME.HEAD, url, headers)
end

--- Sends out a HTTP OPTIONS Request.
-- @param url string containing the URL.
-- @param headers (optional) table.
-- @param reqData (optional) Request Data can be a string or a table.
-- @usage local res = httpClient:OPTIONS(url)
-- @usage return res.ok, res.code, res.data, res.headers
-- @return table with res.ok, res.code (HTTP Response Codes) and optional res.data and res.headers
function HTTPClient:OPTIONS(url, headers, reqData)
    return self:REQUEST(METHOD_NAME.OPTIONS, url, headers, reqData)
end

--- Sends out a HTTP PATCH Request.
-- @param url string containing the URL.
-- @param headers (optional) table.
-- @param reqData (optional) Request Data can be a string or a table.
-- @usage local reqData = {
-- @usage   msg = "Hello World!"
-- @usage }
-- @usage local res = httpClient:PATCH(url, {}, reqData)
-- @usage return res.ok, res.code, res.data, res.headers
-- @return table with res.ok, res.code (HTTP Response Codes) and optional res.data and res.headers
function HTTPClient:PATCH(url, headers, reqData)
    return self:REQUEST(METHOD_NAME.PATCH, url, headers, reqData)
end

--- Sends out a HTTP POST Request.
-- @param url string containing the URL.
-- @param headers (optional) table.
-- @param reqData (optional) Request Data can be a string or a table.
-- @usage local reqData = {
-- @usage   msg = "Hello World!"
-- @usage }
-- @usage local res = httpClient:POST(url, {}, reqData)
-- @usage return res.ok, res.code, res.data, res.headers
-- @return table with res.ok, res.code (HTTP Response Codes) and optional res.data and res.headers
function HTTPClient:POST(url, headers, reqData, debugfunction)
    return self:REQUEST(METHOD_NAME.POST, url, headers, reqData, debugfunction)
end

--- Sends out a HTTP PUT Request.
-- @param url string containing the URL.
-- @param headers (optional) table.
-- @param reqData (optional) Request Data can be a string or a table.
-- @usage local reqData = {
-- @usage   msg = "Hello World!"
-- @usage }
-- @usage local res = httpClient:PUT(url, {}, reqData)
-- @usage return res.ok, res.code, res.data, res.headers
-- @return table with res.ok, res.code (HTTP Response Codes) and optional res.data and res.headers
function HTTPClient:PUT(url, headers, reqData)
    return self:REQUEST(METHOD_NAME.PUT, url, headers, reqData)
end

-- #endregion Request Methods

-- #endregion Public

return HTTPClient