script "revStandaloneSettingsEmscriptenBehavior"
on preOpenCard
   initialize
   pass preOpenCard
end preOpenCard

on initialize
   local tEnableHTML5Button, tEnableWASMButton
   put the long id of button "Emscripten" of group "platforms" into tEnableHTML5Button
   put the long id of button "EmscriptenWASM" of group "platforms" into tEnableWASMButton
   
   -- Check whether HTML5 deployment is requested for the target stack
   local tStandaloneSettingsA
   put getSettings() into tStandaloneSettingsA
   
   if revEngineCheck?("Emscripten") then
      set the visible of tEnableHTML5Button to true
      set the visible of tEnableWASMButton to true
      set the enabled of tEnableHTML5Button to true
      set the enabled of tEnableWASMButton to true
   end if
   set the hilite of tEnableHTML5Button to (tStandaloneSettingsA["EmscriptenHTML5"] is true)
   set the hilite of tEnableWASMButton to (tStandaloneSettingsA["EmscriptenWASM"] is true)
end initialize

