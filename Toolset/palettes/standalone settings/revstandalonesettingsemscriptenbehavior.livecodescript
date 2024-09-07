script "revStandaloneSettingsEmscriptenBehavior"
on preOpenCard
   initialize
   pass preOpenCard
end preOpenCard

on initialize
	local tEnableButton
	put the long id of button "Emscripten" of group "platforms" into tEnableButton

	-- Check whether HTML5 deployment is requested for the target stack
	local tStandaloneSettingsA
	put getSettings() into tStandaloneSettingsA
   
	set the visible of tEnableButton to revEngineCheck("Emscripten")
	set the hilite of tEnableButton to (tStandaloneSettingsA["Emscripten"] is true)
   
	-- Decide whether user is permitted to do HTML5 deployment
	local tHaveLicense
	put true into tHaveLicense
   
	-- Disable the checkbox if no license is available
	set the enabled of tEnableButton to tHaveLicense
   
	-- Hide the license prompt if a license is available
	--set the visible of group "emscriptenLicenseTip" to not tHaveLicense
   repeat for each item tItem in revSBPlatformArchitectures("Emscripten")
      set the hilite of button ("Emscripten" && tItem) of group "platforms" of me to tSettings["Emscripten",tItem] is true
      set the visible of button ("Emscripten" && tItem) of group "platforms" of me to revEngineCheck("Emscripten" && tItem)
      if tSettings["Emscripten",tItem] then
         put true into tEnabled
      end if
      
      -- Disable the checkbox if no license is available
      set the enabled of button ("Emscripten" && tItem) of group "platforms" of me to tHaveLicense
   end repeat
   
   if not tEnabled and tSettings["Emscripten"] is true then
      set the hilite of button "Emscripten js" of group "platforms" of me to true
      put true into tSettings["Emscripten,js"]
      setSettings tSettings
   end if
   
   
	tipDisplayUpdate
end initialize

on updateEmscriptenChecked pChecked
   set the visible of button "Emscriptenchecked" to pChecked
   set the opaque of button "Emscriptenchecked" to false
end updateEmscriptenChecked

on updateEmscriptenArch pArch, pBuild
   local tSettingsA
   put getSettings() into tSettingsA
   
   put pBuild into tSettingsA["Emscripten",pArch]
   
   local tEnabled = false
   repeat for each item tItem in revSBPlatformArchitectures("Emscripten")
      if tSettingsA["Emscripten",tItem] then
         put true into tEnabled
         exit repeat
      end if
   end repeat
   put tEnabled into tSettingsA["Emscripten"]
   setSettings tSettingsA
   
   if tEnabled then
      buildForEnabled "emscripten"
   end if
   
   revSetEdit
   updateEmscriptenChecked tEnabled
end updateEmscriptenArch

on tipDisplayUpdate
   --set the backColor of graphic "emscriptenNoLicenseBackground" to ideCoreEditionColour()
   set the backColor of graphic "emscriptenNoLicenseBackground" to revIDEColor()
   
   if the visible of group "emscriptenLicenseTip" then
      set the topLeft of group "emscriptenSettings" to 12,136
   else 
      set the topLeft of group "emscriptenSettings" to -1,67
   end if
   set the cSize of this card to 567,371
   
   updateCardSize
   
end tipDisplayUpdate

on emscriptenBuyNow
   launch url "https://livecode.com/products/livecode-platform/html5-purchase-info"
end emscriptenBuyNow
