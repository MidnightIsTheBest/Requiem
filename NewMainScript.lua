local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file)
	writefile(file, '')
end

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/MidnightIsTheBest/Requiem/'..readfile('requiem/profiles/commit.txt')..'/'..select(1, path:gsub('requiem/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after requiem updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function wipeFolder(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if file:find('loader') then continue end
		if isfile(file) and select(1, readfile(file):find('--This watermark is used to delete the file if its cached, remove it to make the file persist after requiem updates.')) == 1 then
			delfile(file)
		end
	end
end

for _, folder in {'requiem', 'requiem/games', 'requiem/profiles', 'requiem/assets', 'requiem/libraries', 'requiem/guis'} do
	if not isfolder(folder) then
		makefolder(folder)
	end
end

if not shared.VapeDeveloper then
	local _, subbed = pcall(function()
		return game:HttpGet('https://api.github.com/repos/MidnightIsTheBest/Requiem/commits/compiled')
	end)

	local assetVer = '1'
	local commit = type(subbed) == 'string' and subbed:match('"sha"%s*:%s*"(%x+)"') or nil
	commit = commit and #commit == 40 and commit or 'compiled'

	if commit == 'compiled' or (isfile('requiem/profiles/commit.txt') and readfile('requiem/profiles/commit.txt') or '') ~= commit then
		wipeFolder('requiem')
		wipeFolder('requiem/games')
		wipeFolder('requiem/guis')
		wipeFolder('requiem/libraries')
	end

	if (isfile('requiem/profiles/asset.txt') and readfile('requiem/profiles/asset.txt') or '') ~= assetVer then
		wipeFolder('requiem/assets')
	end

	writefile('requiem/profiles/asset.txt', assetVer)
	writefile('requiem/profiles/commit.txt', commit)
end

return loadstring(downloadFile('requiem/main.lua'), 'main')()