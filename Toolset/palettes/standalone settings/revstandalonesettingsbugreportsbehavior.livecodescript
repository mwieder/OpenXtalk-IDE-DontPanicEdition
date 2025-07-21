script "revStandaloneSettingsBugReportsBehavior"
on preOpenCard
   local tStandaloneSettingsA
   put getSettings() into tStandaloneSettingsA
   set the hilite of button "errorDialog" to tStandaloneSettingsA["errorDialog"] = true
   set the enabled of group "errorDialog" to tStandaloneSettingsA["errorDialog"] = true
   put tStandaloneSettingsA["errorDialog,htmlText"] into field "htmlText"
   put tStandaloneSettingsA["errorDialog,icon"] into field "icon"
   put tStandaloneSettingsA["errorDialog,email"] into field "email"
   set the hilite of button "comments" to tStandaloneSettingsA["errorDialog,comments"] = true
   set the hilite of button "save" to tStandaloneSettingsA["errorDialog,save"] = true
   set the hilite of button "email1" to tStandaloneSettingsA["errorDialog,email"] <> ""
   set the enabled of group "email" to tStandaloneSettingsA["errorDialog,email"] <> ""
   set the enabled of button "errorDialog" to not tStandaloneSettingsA["ios"]
   pass preOpenCard
end preOpenCard
