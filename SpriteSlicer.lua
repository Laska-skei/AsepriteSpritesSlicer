local fragments = {}
local dialog

local function assetType(name, value, type --[[string]]) 
	assert(type(value) == type, name.." must be " ..type.. ", was " .. type(value))
end

local function rectToStringNoBrackets(rect --[[Rectangle]]) --> string
	--assert(type(rect) == "Rectangle")
	return rect.x .. ", " .. rect.y .. ", " .. rect.width .. ", " .. rect.height
end
local function rectToString(rect --[[int]]) --> string
	--assert(type(rect) == "Rectangle")
	return '(' .. rectToStringNoBrackets(rect) .. ')'
end

local function removeFragment(rect)
	local pos = -1 
	for i, r in ipairs(fragments) do
		if r == rect then 
			pos = i
			break
		end
	end

	if pos == -1 then return end --rect not found

	table.remove(fragments, pos)


	local bounds = dialog.bounds

	dialog:modify{ id="frag_"..rectToString(rect),
	visible=false }
	dialog:modify{ id="del_"..rectToString(rect),
	visible=false }

	dialog.bounds = bounds -- return previous bounds
end

local function addFragment(rect)
	local pos = #fragments + 1
	table.insert(fragments, pos, rect)

	dialog:newrow() 
	dialog:button{
		id="frag_"..rectToString(rect),
		text=rectToString(rect),
		onclick=function()
			local sprite = app.activeSprite
			if not sprite then return end
			
			local selection = sprite and sprite.selection
			selection:deselect()
			selection:select(rect)
			
			app.refresh() --!
		end
	}

	dialog:button{
		id="del_"..rectToString(rect),
		text="X",
		onclick=function()
			removeFragment(rect)
			app.refresh()
		end
	}
	--repaint dialog
	local bounds =dialog.bounds
	dialog.bounds = Rectangle(bounds.x, bounds.y, bounds.width+1, bounds.height)
	dialog.bounds = bounds
end

local function createFragment()
	local sprite = app.activeSprite
	  local selection = sprite and sprite.selection

	  if not sprite or not selection or selection.isEmpty then
		app.alert("No active sprite or selection.")
		return
	  end
	  addFragment(selection.bounds)
end

local function saveFragments(path --[[string]])
	local file = io.open(path, "w") -- "w" write mode
	if not file then return app.alert("Failed to open write file: " ..path) end

	--local formatted = {}
	local text = ""
	for id, rect in ipairs(fragments) do
		if rect then 
			text = text .. rectToStringNoBrackets(rect) .. '\n'
		end
	end

	file:write(text)
	file:close()
end

local function loadFragments(path --[[string]])
	--assetType()

	local file = io.open(path, "r") -- "r" read mode
	if not file then return app.alert("Failed to open read file: " ..path) end

	local loadedFragments = {}
	while true do
		local line = file:read("l")
		if not line or line == nil or line == "" then break end
		
		local values = {}
		for num in line:gmatch("%-?%d+") do
			table.insert(values, tonumber(num))
		end
		if #values ~= 4 then
			error("Found " .. #values .." numbers in line, must be 4.")
		end

		local x, y, width, height = table.unpack(values)
		table.insert(loadedFragments, Rectangle(x, y, width, height))
	end
	
	file:close()

	fragments = {}
	for i, frag in ipairs(loadedFragments) do
		addFragment(frag)
	end

end

local function openSaveFragmentsDialog()
	local saveDialog = Dialog{
		title="Save slice data",
		parent=dialog,
	}
	saveDialog:file{
		id="file",
		label="Slice data save location",
		title="Select slice data save location",
		open=false,
		save=true,
		filename= "SliceData",
		filetypes={ "" },
		onchange=function ()
			saveFragments(saveDialog.data.file)
			saveDialog:close()
		end,
	}
	saveDialog:show()
end
local function openLoadFragmentsDialog()
	local loadDialog = Dialog{
		title="Load slice data",
		parent=dialog,
	}
	loadDialog:file{
		id="file",
		label="Slice data location",
		title="Select slice data location to load",
		open=true,
		filetypes={ "" },
		onchange=function ()
			loadFragments(loadDialog.data.file)
			loadDialog:close()
		end,
	}
	loadDialog:show()
end


---------MAIN---------
dialog = Dialog{
	title="Slice data",
}

dialog:button{
	id="add",
	text="Add",
	selected=true,
	onclick=createFragment
}

dialog:button{ 
	id="load", 
	text="Load", 
	onclick=openLoadFragmentsDialog
}
dialog:button{ 
	id="save", 
	text="Save", 
	onclick=openSaveFragmentsDialog
}

dialog:separator()

dialog:show{ wait=false }
dialog.bounds = Rectangle(690, 40, 200, 200)