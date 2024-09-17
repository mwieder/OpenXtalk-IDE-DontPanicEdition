script "revStandaloneSettingsGeneralBehavior"
on preOpenCard
   local tStandaloneSettingsA,tList,tCount,tHilite
   put getSettings() into tStandaloneSettingsA
   put tStandaloneSettingsA["name"] into field "standalone name"
   
   if tStandaloneSettingsA["inclusions"] is "select" then
      set the hilitedButtonName of group "inclusions" of me to "select"
      enable button "inclusions" of group "cards" of this card of me
   else
      set the hilitedButtonName of group "inclusions" of me to "search"
      disable button "inclusions" of group "cards" of this card of me
   end if
   
   if tStandaloneSettingsA["includeProfiles"] <> "" then
      set the hilitedButtonName of group "profiles" to "include"
      enable group "include profiles"
      if tStandaloneSettingsA["includeProfiles"] = "*" then
         set the hilitedButtonName of group "include profiles" to "all"
      else
         set the hilitedButtonName of group "include profiles" to "selected"
         put 1 into tCount
         put "" into tHilite
         put field "include profiles" into tList
         repeat for each line tLine in tList
            if tLine is among the lines of tStandaloneSettingsA["includeProfiles"] then put tCount & "," after tHilite
            add 1 to tCount
         end repeat
         set the hilitedLines of field "include profiles" to char 1 to -2 of tHilite
      end if
   else
      disable group "include profiles"
      if tStandaloneSettingsA["setToProfile"] <> "" then
         enable button "set objects"
         set the hilitedButtonName of group "profiles" to "set"
         set the label of button "set objects" to tStandaloneSettingsA["setToProfile"]
      else
         disable button "set objects"
         set the hilitedButtonName of group "profiles" to "remove"
      end if
   end if
   
   # OK-2009-05-22 : Added ability to save default build folder
   set the text of field "Default Build Folder" of me to tStandaloneSettingsA["defaultBuildFolder"]
   set the hilite of button "Automatically Build here" of me to (tStandaloneSettingsA["automaticallyBuildInDefaultFolder"] is true)
   
   enable group "profiles"
   pass preOpenCard
end preOpenCard
