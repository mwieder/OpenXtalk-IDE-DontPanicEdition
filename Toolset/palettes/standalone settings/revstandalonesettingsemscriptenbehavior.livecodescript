script "revStandaloneSettingsEmscriptenBehavior"
on preOpenCard
   initialize
   pass preOpenCard
end preOpenCard

on initialize
   # Check whether HTML5 deployment is requested for the target stack
   local tStandaloneSettingsA
   put getSettings() into tStandaloneSettingsA
   
   repeat for each item tItem in revSBPlatformArchitectures("Emscripten")
      set the hilite of button ("Emscripten"&tItem) of group "platforms" of me to (tStandaloneSettingsA["Emscripten"&tItem] is true)
      set the visible of button ("Emscripten"&tItem) of group "platforms" of me to true
      set the enabled of button ("Emscripten"&tItem) of group "platforms" of me to true
   end repeat
end initialize
