local fragments = {}
local dialog

local function rectToStringNoBrackets(rect)
	return rect.x .. ", " .. rect.y .. ", " .. rect.width .. ", " .. rect.height
end
local function rectToString(rect)
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

local function saveFragments(path)
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


--MAIN--
dialog = Dialog{
	title="Slice data",
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