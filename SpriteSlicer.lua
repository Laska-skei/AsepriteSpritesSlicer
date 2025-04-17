
local json = dofile("modules/json.lua") --import json

local fragments = {}
local dialog

local function rectToString(rect)
	return '(' .. rect.x .. ", " .. rect.y .. ", " .. rect.width .. ", " .. rect.height .. ')'
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

local function saveFragments(jsonPath)
	local file = io.open(jsonPath, "w") -- "w" write mode
	if not file then return app.alert("Failed to open write file: " ..jsonPath) end

	local formatted = {}
	for id, rect in ipairs(fragments) do
		if rect then 
			formatted[id] = rectToString(rect)
		end
	end
	local text = json.encode(formatted)

	
	file:write(text)
	file:close()
end

local function openSaveFragmentsDialog()
	local exportDialog = Dialog{
		title="Save fragments",
		parent=dialog,
	}
	exportDialog:file{
		id="file",
		label="Fragments data save location",
		title="Select fragments data save location",
		open=false,
		save=true,
		filename= "Fragmetns.json",
		filetypes={ "json" },
		onchange=function ()
			saveFragments(exportDialog.data.file)
			exportDialog:close()
		end,
	}
	exportDialog:show()
end


--MAIN--
dialog = Dialog{
	title="Fragments",
}

dialog:button{
	id="add",
	text="Add from selection",
	selected=true,
	onclick=createFragment
}
dialog:button{ 
	id="save", 
	text="Save", 
	onclick=openSaveFragmentsDialog
}

dialog:separator()

dialog:show{ wait=false }
dialog.bounds = Rectangle(690, 40, 200, 200)