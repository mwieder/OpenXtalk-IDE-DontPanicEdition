script "revStandaloneSettingsEmscriptenBehavior"
on preOpenCard
   initialize
   pass preOpenCard
end preOpenCard

on initialize
   --local tEnableButton
   --put the long id of button "Emscripten" of group "platforms" into tEnableButton
   
   -- Check whether HTML5 deployment is requested for the target stack
   local tStandaloneSettingsA
   put getSettings() into tStandaloneSettingsA
   
   -- Decide whether user is permitted to do HTML5 deployment
   local tHaveLicense
   put true into tHaveLicense
   
   -- Hide the license prompt if a license is available
   local tEnabled
   repeat for each item tItem in revSBPlatformArchitectures("Emscripten")
      set the hilite of button ("Emscripten"&tItem) of group "platforms" of me to (tStandaloneSettingsA["Emscripten",tItem] is true)
      set the visible of button ("Emscripten"&tItem) of group "platforms" of me to revEngineCheck?("Emscripten" && tItem)
      if tStandaloneSettingsA["Emscripten",tItem] then
         put true into tEnabled
      end if
      
      set the enabled of button ("Emscripten"&tItem) of group "platforms" of me to true
   end repeat
   
   if not tEnabled and tStandaloneSettingsA["Emscripten"] is true then
      set the hilite of button "EmscriptenJS" of group "platforms" of me to true
      put true into tStandaloneSettingsA["Emscripten,js"]
      setSettings tStandaloneSettingsA
   end if
   
   
   --tipDisplayUpdate
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
