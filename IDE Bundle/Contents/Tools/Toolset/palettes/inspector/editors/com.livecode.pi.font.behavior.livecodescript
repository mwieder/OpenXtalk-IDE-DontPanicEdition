script "com.livecode.pi.font.behavior" with behavior "revInspectorEditorBehavior"
constant kEffectiveTextColor = "127,127,127"
constant kFontMenuLines = 100

on editorInitialize
   set the editorMinWidth of me to 50
   set the editorMaxWidth of me to 0
   
   local tFontNames
   put the fontNames into tFontNames
   sort tFontNames
   set the backgroundColor of button 1 of me to white
   set the textcolor of button 1 of me to black
   repeat with x = 1 to 7
      put backslash before line x of tFontNames
   end repeat
   set the text of button 1 of me to tFontNames
   set the menuLines of button 1 of me to kFontMenuLines   
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   
   set the label of button 1 of me to tValue
   
   set the enabled of me to tEnabled
   if tEffective is true then
      set the textcolor of button 1 of me to black
      -- set the textcolor of button 1 of me to kEffectiveTextColor
      set the textstyle["italic"] of button 1 of me to true
   else
      set the textcolor of button 1 of me to black
      set the textstyle of button 1 of me to empty
   end if
   -- if the optionKey is down then put "do special"
   unlock messages
   unlock screen
end editorUpdate

on editorResize
   lock screen
   lock messages
   set the rect of button 1 of me to the rect of me
   unlock messages
   unlock screen
end editorResize

on valueChanged
   set the editorValue of me to the label of button 1 of me
   updateProperty
end valueChanged

on closeField
   valueChanged
end closeField

--on mouseDown pButtonNumber
--   if the optionKey is down then put "do special"
--end mouseDown
