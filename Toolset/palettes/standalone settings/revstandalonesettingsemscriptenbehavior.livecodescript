script "revStandaloneSettingsEmscriptenBehavior"
on preOpenCard
   initialize
   pass preOpenCard
end preOpenCard

on initialize
   # Check whether HTML5 deployment is requested for the target stack
   local tStandaloneSettingsA
   local tPlatforms
   put getSettings() into tStandaloneSettingsA
   
   --dispatch function "SBPlatformArchitectures" to stack "revSBLibrary" with "Emscripten"
   --put the result into tPlatforms
   put SBPlatformArchitectures("Emscripten") into tPlatforms
   repeat for each item tItem in tPlatforms
      set the hilite of button ("Emscripten"&tItem) of group "platforms" of me to (tStandaloneSettingsA["Emscripten"&tItem] is true)
      set the visible of button ("Emscripten"&tItem) of group "platforms" of me to true
      set the enabled of button ("Emscripten"&tItem) of group "platforms" of me to true
   end repeat
end initialize
