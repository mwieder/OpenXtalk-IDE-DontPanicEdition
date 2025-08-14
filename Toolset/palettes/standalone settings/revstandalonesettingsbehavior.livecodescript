script "revStandaloneSettingsBehavior"

------------------------------
# all standalone settings get vectored through these handlers
------------------------------

/**
* getSettings
*
* Return the entire standalonesettings custompropertyset
*/
function getSettings
   return the customProperties["cRevStandaloneSettings"] of getTargetStack()
end getSettings

/**
* setSettings
*
* Set the entire standalonesettings custompropertyset
*/
command setSettings pSettings
   set the customProperties["cRevStandaloneSettings"] of getTargetStack() to pSettings
   revSetEdit
end setSettings

function getSetting pKey
   local tSettingsArray
   put getSettings() into tSettingsArray
   return tSettingsArray[pKey]
end getSetting

command setSetting pKey, pValue
   set the cRevStandaloneSettings[pKey] of getTargetStack() to pValue
   revSetEdit
end setSetting

------------------------------

on preOpenStack
   lock screen
   start using stack "revSaveAsStandalone"
   
   if getTargetStackName() is not among the lines of the mainStacks then
      revStandaloneSettings the mainStack of the topStack
   end if
   
   repeat with X=1 to the number of buttons of group "flavors" of card "Unix"
      set the enabled of button X of group "flavors" of card "Unix" to true
   end repeat
   
   navigateToCard "General"
   repeat with X=1 to the number of buttons of group "cards"
      set the style of button X of group "cards" to "rectangle"
      set the showBorder of button X of group "cards" to false
   end repeat
   helpButtons
   
   if MacEngineIsFat?() then
      show button "MacOSX arm64" of card "OS X"
      
      /* Building for arm64 is not supported on macOS < 10.13 as codesign does
      * not have the required support for the arm64 slice. */
      set the itemDelimiter to "."
      if item 1 to 2 of the systemVersion < 10.13 then
         set the disabled of button "MacOSX arm64" of card "OS X" to true
      end if
      set the itemDelimiter to comma
   else
      hide button "MacOSX arm64" of card "OS X"
   end if
   unlock screen
end preOpenStack

constant kButtonList = "General,Stacks,Copy Files,Inclusions,OS X,Windows,Unix,iOS,Android,Emscripten,Bug Reports"
constant kMacPlatforms = "MacOSX,MacOSX PowerPC-32,MacOSX x86-32,MacOSX x86-64,MacOSX arm64"
constant kWindowsPlatforms = "Windows,Windows x86-64"
constant kLinuxPlatforms = "Linux,Linux x64,Linux ARMv6-hf,Linux ARM64"
constant kWebPlatforms = "EmscriptenJS,EmscriptenWASM"
private command updateTabButtons pSettings
   local tEnableTick?
   
   lock screen
   put false into tEnableTick?
   repeat for each item tItem in kMacPlatforms
      if pSettings[tItem] then
         put true into tEnableTick?
         exit repeat
      end if
   end repeat
   set the visible of button "OSXchecked" of group "checks" of me to tEnableTick?
   
   put false into tEnableTick?
   repeat for each item tItem in kWindowsPlatforms
      if pSettings[tItem] then
         put true into tEnableTick?
         exit repeat
      end if
   end repeat
   set the visible of button "Windowschecked" of group "checks" of me to tEnableTick?
   
   put false into tEnableTick?
   repeat for each item tItem in kLinuxPlatforms
      if pSettings[tItem] then
         put true into tEnableTick?
         exit repeat
      end if
   end repeat
   set the visible of button "UnixChecked" of group "checks" of me to tEnableTick?
   
   set the visible of button "IosChecked" of group "checks" of me to pSettings["ios"] = true
   set the visible of button "AndroidChecked" of group "checks" of me to pSettings["android"] = true
   set the visible of button "BugsChecked" of group "checks" of me to pSettings["errorDialog"] = true
   put false into tEnableTick?
   repeat for each item tItem in kWebPlatforms
      if pSettings[tItem] then
         put true into tEnableTick?
         exit repeat
      end if
   end repeat
   set the visible of button "EmscriptenChecked" of group "checks" of me to tEnableTick?
   
   local tLeft
   put 0 into tLeft
   
   local tV
   put item 2 of the loc of button "OS X" of group "cards" of me -10 into tV
   repeat for each item tItem in kButtonList
      if the visible of button tItem of group "cards" of me then
         set the left of button tItem of group "cards" of me to tLeft
         put the right of button tItem of group "cards" of me into tLeft
      end if
      
      local tCheck
      put replaceText(tItem," ","")&"checked" into tCheck
      if there is a button tCheck of group "checks" of me then
         local tTopLeft
         put (item 1 of the loc of button tItem of group "cards" of me),tV into tTopLeft
         set the topLeft of button tCheck of group "checks" of me to tTopLeft
      end if
      enableButton tItem
   end repeat
   
   unlock screen
end updateTabButtons

private command enableButton pWhichButton
   set the enabled of button pWhichButton of group "cards" of me to true
   set the visible of button pWhichButton of group "cards" of me to true
end enableButton

on buildForEnabled pPlatform
   local tSettings
   put getSettings() into tSettings
   updateTabButtons tSettings
end buildForEnabled

private command helpButtons
   local tShowBorder,tIcon,tHiliteIcon,tShowName
   
   lock screen
   if the platform is "MacOS" then
      put true into tShowBorder
      put 0 into tIcon
      put 0 into tHiliteIcon
      put true into tShowName
   else
      put false into tShowBorder
      put 202009 into tIcon
      put 202010 into tHiliteIcon
      put false into tShowName
   end if
   repeat for each line tCardID in the cardIDs of this stack
      --repeat with tCard =1 to the number of cards
      repeat with tBtn = 1 to the number of buttons of card id tCardID
         if the short name of button tBtn of card id tCardID = "help" then
            set the margins of button tBtn of card id tCardID to 4
            set the hiliteBorder of button tBtn of card id tCardID to false
            set the showBorder of button tBtn of card id tCardID to tShowBorder
            set the icon of button tBtn of card id tCardID to tIcon
            set the hilitedIcon of button tBtn of card id tCardID to tHiliteIcon
            set the showName of button tBtn of card id tCardID to tShowName
            set the textFont of button tBtn of card id tCardID to ""
            set the textSize of button tBtn of card id tCardID to 14
            set the textStyle of button tBtn of card id tCardID to "bold"
         end if
      end repeat
   end repeat
   unlock screen
end helpButtons

on revStandaloneSettings pStack
   lock screen
   replace quote with empty in pStack
   if pStack is empty then
      put the short name of the topStack into pStack
   end if
   put the mainStack of stack pStack into pStack
   set the defaultStack to pStack
   if the fileName of stack pStack is empty then
      revSaveAs pStack
      if the fileName of stack pStack is empty then
         unlock screen
         exit revStandaloneSettings
      end if
   end if
   set the cRevTargetStack of stack "revStandaloneSettings" to pStack
   
   local tSettings
   put getSettings() into tSettings
   dispatch "SBDefaultStandaloneSettings" to stack "revStandaloneSettings" with pStack, tSettings
   setSettings tSettings
   modeless "revStandaloneSettings"
   dispatch "preOpenCard" to this card of stack "revStandaloneSettings"
   updateTabButtons tSettings
   unlock screen
end revStandaloneSettings

on revSetEdit pStack
   if pStack is empty then
      put getTargetStackName() into pStack
   end if
   revIDESetEdited pStack
end revSetEdit

constant kButtonWidth = 66
constant kMargin = 4
--function minCardWidth
--   return the number of buttons of group "Cards" of me * kButtonWidth + kMargin + 24
--end minCardWidth

on preOpenCard
   lock screen
   --updateCardSize
   updateLabel the short name of this card of me
   unlock screen
end preOpenCard

--command updateCardSize
--   if the cSize of this card of me is not empty then
--      local tWidth,tHeight
--      put max(item 1 of the cSize of this card of me, minCardWidth()) into tWidth
--      put item 2 of the cSize of this card of me into tHeight

--      revChangeWindowSize tWidth, tHeight, "snap", ,250
--   end if
--   dispatch "resizeStack" to this card of me
--end updateCardSize

on resumeStack
   if the short name of this stack is "revStandaloneSettings" then
      local tMainstack
      put the mainStack of the topStack into tMainstack
      if tMainstack is getTargetStack() then
         send "preOpenCard" to this card of me in 0 millisecs
      end if
   end if
end resumeStack

# Parameters
#   <none>
# Description
#   Returns the folder containing the current target stack
function utilityTargetStackPath
   set the itemDelimiter to slash
   return item 1 to -2 of the filename of stack (the cRevTargetStack of me) & slash
end utilityTargetStackPath

command layoutCardsGroup
   local tX
   put 2 into tX
   
   local tNumButtons
   put the number of buttons of group "cards" into tNumButtons
   repeat with i = 1 to tNumButtons
      local tWidth
      put kButtonWidth into tWidth
      if i = tNumButtons then
         add kMargin to tWidth
      end if
      set the width of button i of group "cards" to it
      set the left of button i to tX
      add kButtonWidth to tX
   end repeat
end layoutCardsGroup

function getImageDimensions pImageFile
   local tDims
   create invisible image
   set the filename of it to pImageFile
   put (the effective width of it, the effective height of it) into tDims
   delete it
   return tDims
end getImageDimensions

function validateIdentifier pIdentifier
   return matchText(pIdentifier, "(?i)^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$")
end validateIdentifier

/*
* UpdateStandaloneProgress
* dispatched from revSBLibrary
*/
command UpdateStandaloneProgress pMessage
   lock screen
   put pMessage into field 1 of stack "revStandaloneProgress"
   if the mode of stack "revStandaloneProgress" is 0 then
      lock messages
      modeless "revStandaloneProgress"
      set the loc of stack "revStandaloneProgress" to the screenLoc
      unlock messages
   end if
   unlock screen
   wait 0 ticks with messages -- allow for progress update
end UpdateStandaloneProgress

/*
* ConfirmInclusion
* dispatched from revSBLibrary
*/
constant kWARNINGSTACK = "StandaloneInclusionWarning"
command ConfirmInclusion pName, @rInclude?, @rSilenceWarning?
   set the cInclusion of stack kWARNINGSTACK to pName
   modal stack kWARNINGSTACK
   put the cInclude of stack kWARNINGSTACK into rInclude?
   put the cSilenceWarning of stack kWARNINGSTACK into rSilenceWarning?
end ConfirmInclusion

function selectImageFile pDimensions
   local tFile
   answer file "Please choose a png image" with type "PNG Images|png" or type "All files"
   put it into tFile
   if tFile is empty then
      return empty
   end if
   
   if pDimensions is not empty then
      if getImageDimensions(tFile) is not pDimensions then
         answer warning "Image is not of the required dimensions (" & pDimensions & ")"
      end if
   end if
   
   return utilityMakePathRelative(tFile, utilityTargetStackPath())
end selectImageFile

# NOTE: Where is this called from? 10.0.0-dp8
function selectAdaptiveIconsResFolder
   local tResourcesFolder
   answer folder "Please choose the 'res' folder that includes the adaptive icons"
   put it into tResourcesFolder
   if tResourcesFolder is empty then
      return empty
   end if
   
   return utilityMakePathRelative(tResourcesFolder, utilityTargetStackPath())
end selectAdaptiveIconsResFolder

function selectFontMapFile
   local tFile
   answer file "Please choose a font mapping file"
   put it into tFile
   if tFile is empty then
      return empty
   end if
   
   return utilityMakePathRelative(tFile, utilityTargetStackPath())
end selectFontMapFile

function selectKeyStoreFile
   local tFile
   answer file "Please choose a keystore" with type "Java keystores|keystore" or type "All files"
   put it into tFile
   if tFile is empty then
      return empty
   end if
   
   return utilityMakePathRelative(tFile, utilityTargetStackPath())
end selectKeyStoreFile

function stripSuffix pText, pSuffix
   repeat for each item tSuffix in pSuffix
      if pText ends with tSuffix then
         delete char -(the number of chars of tSuffix) to -1 of pText
         return pText
      end if
   end repeat
   return pText
end stripSuffix

function computeDefault pValue, pDefault
   if pValue is empty then
      return pDefault
   end if
   return pValue
end computeDefault

function getTargetStack
   return the long id of stack getTargetStackName()
end getTargetStack

function getTargetStackName
   return the cRevTargetStack of me
end getTargetStackName

function updateIncludeStackFilesList pIncludeList, pPrev
   local tInclude, tMainStack, tChars, tPath
   put line 1 of pPrev into tMainStack
   set the itemDel to "/"
   put item 1 to -2 of tMainStack & "/" into tMainStack
   put the number of chars of tMainStack into tChars
   set the itemDel to ","
   repeat for each line tInclude in pIncludeList
      if there is a stack tInclude then
         if the fileName of stack tInclude is among the lines of pPrev then
            answer error ("<p>"&tInclude&"<p>is already included.") with "OK"
         else
            if char 1 to tChars of the fileName of stack tInclude = tMainStack then
               put char tChars+1 to -1 of the fileName of stack tInclude into tPath
            else
               put the fileName of stack tInclude into tPath
            end if
            set the stackFiles of getTargetStack() to \
                  the short name of stack tInclude,tPath&cr&the stackfiles of getTargetStack()
         end if
      else
         answer error "File "&tInclude&" is not a stack!"
      end if
   end repeat
   
   local tStackFiles
   revSBRelativeStackFilesList getTargetStackName(), tStackFiles
   return tStackFiles
end updateIncludeStackFilesList

on recursiveRemoveStackFiles pStack, pRemoveList, @xStackFileList
   local tNewStackFiles, tRef, tStack, tOldStackFiles
   local tFileName
   
   put the stackFiles of stack pStack into tOldStackFiles
   repeat for each line tRef in the stackFiles of stack pStack
      if there is a stack item 1 of tRef then
         put the effective fileName of stack item 1 of tRef into tFileName
         if tFileName is not among the lines of pRemoveList then
            put tRef&cr after tNewStackFiles
            if tFileName is not among the lines of xStackFileList then
               put tFileName & cr after xStackFileList
               recursiveRemoveStackFiles tFileName, pRemoveList, xStackFileList
            end if
         end if
      end if
   end repeat
   delete char -1 of tNewStackFiles
   if tNewStackFiles <> tOldStackFiles then
      set the stackFiles of stack pStack to tNewStackFiles
      revSetEdit the short name of stack pStack
   end if
   
   put empty into tNewStackFiles
   repeat for each line tStack in the substacks of stack pStack
      put the stackFiles of stack pStack into tOldStackFiles
      repeat for each line tRef in the stackFiles of stack tStack of stack pStack
         if there is a stack item 1 of tRef then
            put the effective fileName of stack item 1 of tRef into tFileName
            if tFileName is not among the lines of pRemoveList then
               put tRef&cr after tNewStackFiles
               if tFileName is not among the lines of xStackFileList then
                  put tFileName & cr after xStackFileList
                  recursiveRemoveStackFiles tFileName, pRemoveList, xStackFileList
               end if
            end if
         end if
      end repeat # for each line tRef
      delete char -1 of tNewStackFiles
      if tNewStackFiles <> tOldStackFiles then
         set the stackFiles of stack tStack of stack pStack to tNewStackFiles
         revSetEdit the mainstack of stack tStack
      end if
      put empty into tNewStackFiles
   end repeat # for each line tStack
end recursiveRemoveStackFiles

on navigateToCard pCardName
   if the short name of this card is "Android" then
      if not androidIdentifierValid() then
         exit navigateToCard
      end if
   end if
   
   lock screen
   go cd pCardName
   
   repeat with X=1 to the number of btns of group "cards" of me
      if the short name of btn X of group "cards" of me <> pCardName then
         set the textStyle of btn X of group "cards" of me to "plain"
         set the textFont of btn X of group "cards" of me to ""
         set the textSize of btn X of group "cards" of me to ""
      else
         set the textStyle of btn X of group "cards" of me to "bold"
      end if
   end repeat
   unlock screen
end navigateToCard

on updateLabel pCardName
   local tCardName
   put the effective label of button pCardName of group "cards" of me \
         into tCardName
   local tLabel
   put "Standalone Application Settings for " & getTargetStackName() & \
         " - " & tCardName into tLabel
   set the title of me to tLabel
end updateLabel

function androidIdentifierValid
   // Check identifier
   local tIdentifier
   lock screen
   put field "identifier" of card "Android" into tIdentifier
   unlock screen
   if not validateIdentifier(tIdentifier) then
      local tError
      put "Invalid Android identifier. The identifier can contain any number" & \
            " of items separated by a '.' character. Each item must only contain" & \
            " letters 'a-z', numbers '0-9' and the following special characters '_'." & \
            " No item can be numerical only. For example com.runrev.app_1 is" & \
            " valid while com.runrev.app.1 is invalid." into tError
      answer error tError
      send "selectIdentifier" to card "Android" in 0 milliseconds
      return false
   end if
   
   return true
end androidIdentifierValid

private command addToListIfNotEmpty pValue, @xList
   if pValue is not empty then
      put pValue & cr after xList
   end if
end addToListIfNotEmpty

private command addProfilesToList pTarget, @xList
   addToListIfNotEmpty the cREVGeneral["profileList"] of pTarget, xList
   addToListIfNotEmpty the cREVGeneral["masterName"] of pTarget, xList
end addProfilesToList

function SBPropertyProfilesList
   local tLine,tStackNames,tStack,tControl,tFinalList,tProfilesList
   
   local tStackFiles
   revSBStackFilesList getTargetStackName(), tStackFiles
   
   repeat for each line tLine in tStackFiles
      put the mainStack of stack tLine into tStackNames
      put cr & the subStacks of stack tStackNames after tStackNames
      lock messages
      repeat for each line tStack in tStackNames
         --stack properties here
         addProfilesToList the long id of stack tStack, tProfilesList
         repeat for each line tCardID in the cardIDs of stack tStack
            --repeat with tCard = 1 to the number of cds in stack tStack
            --card properties here
            addProfilesToList the long id of card id tCardID of stack tStack
            repeat with tControl = 1 to the number of controls on card id tCardID of stack tStack
               addProfilesToList the long id of control tControl of card id tCardID of stack tStack
            end repeat
         end repeat
      end repeat
   end repeat
   unlock messages
   filter tProfilesList without empty
   repeat for each line tLine in tProfilesList
      --if tLine is empty then next repeat
      if tLine is not among the lines of tFinalList then
         put tLine into line (the number of lines in tFinalList)+1 of tFinalList
      end if
   end repeat
   return tFinalList
end SBPropertyProfilesList

function selectStandaloneBuildFolder
   local tFolder
   answer folder "Please choose default folder to build standalone in"
   put it into tFolder
   if there is no folder tFolder then
      return empty
   end if
   setSetting "defaultBuildFolder", tFolder
   return tFolder
end selectStandaloneBuildFolder

command setStandaloneName pName
   set the itemDel to "."
   if item -1 of pName is among the items of "exe.app" then
      put item 1 to -2 of pName into pName
   end if
   
   if folderNameIsIllegal?(pName) then
      put revFolderNameMakeLegal(pName) into pName
   end if
   
   setSetting "name", pName
end setStandaloneName

function relativePathOf pPath
   local tMainstackPath,tChars
   set the itemDel to "/"
   put item 1 to -2 of the effective filename of getTargetStack() & "/" into tMainStackPath
   put the number of chars of tMainStackPath into tChars
   if char 1 to tChars of pPath = tMainStackPath then
      delete char 1 to tChars of pPath
   end if
   return pPath
end relativePathOf

function canIncludeStackFiles
   local tCan
   put true into tCan
   repeat for each item tPlatform in "ios,android,emscripten"
      if getSetting(tPlatform) then
         put false into tCan
      end if
   end repeat
   return tCan
end canIncludeStackFiles

local sMacEngineIsFat?
private function MacEngineIsFat?
   if sMacEngineIsFat? is not empty then

      /* Get the path to the engine used to build for macOS */
      local tPath
      --put revSBEnginePath("MacOSX") into tPath
      dispatch function "revSBEnginePath" to stack "revStandaloneSettings" with "MacOSX"
      put it into tPath

      /* Read the first four bytes of the engine file */
      local tHeader
      open file tPath for binary read
      if the result is empty then
         read from file tPath for 4 bytes
         put it into tHeader
         close file tPath
      end if

      local tHeaderHex
      get binaryDecode("H8", tHeader, tHeaderHex)
      switch tHeaderHex
         case "bebafeca"
         case "cafebabe"
            put true into sMacEngineIsFat?
            break
         default
            put false into sMacEngineIsFat?
            break
      end switch
   end if

   return sMacEngineIsFat?
end MacEngineIsFat?
