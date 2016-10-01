local copas = require("copas")
local http = {}

function http.get(url, body, headers)
	headers = headers or {}
	if body then
		headers["Content-Length"] = #body
	end
	local t = {}
	local success, code, hdrs, status = copas.http.request({
		url = url;
		headers = headers;
		sink = ltn12.sink.table(t);
		source = body and ltn12.source.string(body);
	})
	if success == nil then
		return success, code
	end
	return table.concat(t), code, hdrs, status
end

function http.post(url, body, headers)
	headers = headers or {}
	if body then
		headers["Content-Length"] = #body
	end
	local t = {}
	local success, code, hdrs, status = copas.http.request({
		url = url;
		headers = headers;
		sink = ltn12.sink.table(t);
		source = body and ltn12.source.string(body);
		method = "POST";
	})
	if success == nil then
		return success, code
	end
	return table.concat(t), code, hdrs, status
end

return http
