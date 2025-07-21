script "revxmlrpclibrary"

on extensionInitialize
   if the target is me then
      insert the script of me into back
   end if
end extensionInitialize

on extensionFinalize
   if the target is me then
      remove the script of me from back
   end if
end extensionFinalize

----- LiveCode XML-RPC library ------

/*
* Version history :
* -----------------
*
* Date      Who  Version  Comments
* --------  ---  -------  ------------------------------------------------------------------
* 20040516  js   2.3a3    first alpha version of the library
* 20040615  js   2.3a4    fixed a few issues upon code review
* 20040802  js   2.3b2    fixed a few issues ; improved error checking
*                         added GetHost, GetPort, GetPath, GetProtocol, GetMethod, GetSocket,
*                               GetResponse, GetRequest, GetHeaders functions
*                         added SetPort, DeleteDocument and DeleteAllDocuments handlers
* 20040803  js   2.3b2    added Documents function
* 20110523 mw 4.6.1-dp-1    changed Revolution to LiveCode
*
*/

constant kXMLRPC_SimpleTypes = "base64,boolean,dateTime.iso8601,double,i4,int,string"
constant kXMLRPC_ComplexTypes = "array,struct"
constant kXMLRPC_DefaultHost = "localhost"
constant kXMLRPC_DefaultPort = "80"
constant kXMLRPC_DefaultPath = "RPC2"
constant kXMLRPC_DefaultProtocol = "http"

local sXMLRPC_Data

function revXMLRPC_CreateRequest pHost, pPort, pPath, pProtocol
   local tXMLText,tXMLTree
   put "<?xml version=" & quote & "1.0" & quote & "?>" & cr & \
         "<methodCall><methodName /><params /></methodCall>" into tXMLText
   put revCreateXMLTree(tXMLText,false,true,false) into tXMLTree
   -- save the XML tree ID in the local data variable
   revXMLRPC_SetID tXMLTree, tXMLTree
   -- now set the additional information if extra params are sent
   revXMLRPC_SetHost tXMLTree, pHost, pPort
   revXMLRPC_SetPath tXMLTree, pHost, pPath
   revXMLRPC_SetProtocol tXMLTree, pProtocol
   return tXMLTree
end revXMLRPC_CreateRequest

command revXMLRPC_DeleteDocument pXMLRPCDocID
   if revXMLRPC_GetID(pXMLRPCDocID) is empty then return "xmlrpcerr : bad document id:" && pXMLRPCDocID && "doesn't exist"
   ## introduced this as prefered synonym for revXMLRPC_Free in 2.5b2 for consistency with XML-library
   local tKeys, tKey
   -- clean up the local variables
   put the keys of sXMLRPC_Data into tKeys
   filter tKeys with (pXMLRPCDocID & ",*")
   repeat for each line tKey in tKeys
      delete local sXMLRPC_Data[tKey]
   end repeat
   -- delete the xml tree
   revDeleteXMLTree pXMLRPCDocID
end revXMLRPC_DeleteDocument

command revXMLRPC_DeleteAllDocuments
   ## introduced this call in 2.5b2 for ease of use
   local tDocuments, tDocument
   -- clean up all documents
   put revXMLRPC_Documents() into tDocuments
   repeat for each line tDocument in tDocuments
      revXMLRPC_DeleteDocument tDocument
   end repeat
end revXMLRPC_DeleteAllDocuments

command revXMLRPC_Free pXMLRPCDocID
   if revXMLRPC_GetID(pXMLRPCDocID) is empty then return "xmlrpcerr : bad document id" && pXMLRPCDocID
   ## reworked this to a synonym for revXMLRPC_DeleteDocument in 2.5b2 for consistency with XML-library
   revXMLRPC_DeleteDocument pXMLRPCDocID
end revXMLRPC_Free

command revXMLRPC_FreeAll
   ## introduced this synonym to revXMLRPC_DeleteAllDocuments call in 2.5b2 for ease of use
   revXMLRPC_DeleteAllDocuments
end revXMLRPC_FreeAll

function revXMLRPC_Documents
  ## introduced this call in 2.5b2 for ease of use
  local tKeys, tKey, tDocuments
  put the keys of sXMLRPC_Data into tKeys
  filter tKeys with ("*,id")
  repeat for each line tKey in tKeys
    put sXMLRPC_Data[tKey] & cr after tDocuments
  end repeat
  return char 1 to -2 of tDocuments -- without the trailing return
end revXMLRPC_Documents

command revXMLRPC_AddParam pXMLRPCDocID, pParamType, pParamValue
   if revXMLRPC_GetID(pXMLRPCDocID) is empty then
      return "xmlrpcerr : bad document id" && pXMLRPCDocID
   end if
   ## if it is a valid doc ID, proceed
   local tHiType,tLoType,tParamData,tKeys,tKey
   local tParamsNode
   set the itemDelimiter to ":"
   put item 1 of pParamType into tHiType
   put item 2 of pParamType into tLoType
   set the itemDelimiter to comma
   switch tHiType
      case "array"
         -- open the value, array and data tags
         put "<value><array><data>" into tParamData
         -- default data type in arrays is string
         if tLoType is empty then put "string" into tLoType
         if tLoType is not among the items of kXMLRPC_SimpleTypes then
            return "xmlrpcerr : received unknown parameter type" && pParamType
         end if
         -- add all the values
         put the keys of pParamValue into tKeys
         sort lines in tKeys numeric
         repeat for each line tKey in tKeys
            put "<value><" & tLoType & ">" & pParamValue[tKey] & "</" & tLoType & "></value>" after tParamData
         end repeat
         -- close the value, array and data tags
         put "</data></array></value>" after tParamData
         break
      case "xml"
         -- the parameter is raw xml ; surround with value tag
         put "<value>" & pParamValue & "</value>" into tParamData
         break
      default
         if tHiType is among the items of kXMLRPC_SimpleTypes
         then put "<value><" & tHiType & ">" & pParamValue & "</" & tHiType & "></value>" into tParamData
         else return "xmlrpcerr : received unknown parameter type" && pParamType
         break
   end switch
   -- add the data into the xml tree, and pass any error if applicable
   put "/" & revXMLRootNode(pXMLRPCDocID) & "/params" into tParamsNode
   revAppendXML pXMLRPCDocID, tParamsNode, "<param>" & tParamData & "</param>"
   if the result is not empty then return the result
end revXMLRPC_AddParam

command revXMLRPC_DeleteParam pXMLRPCDocID, pParamNumber
   if revXMLRPC_GetID(pXMLRPCDocID) is empty then
      return "xmlrpcerr : bad document id" && pXMLRPCDocID
   end if
   ## if it is a valid doc ID, proceed
   local tParamNode
   put "/" & revXMLRootNode(pXMLRPCDocID) & "/params/param[" & pParamNumber & "]" into tParamNode
   -- delete the param node from the xml tree, and pass any error if applicable
   revDeleteXMLNode pXMLRPCDocID, tParamNode
   if the result is not empty then return the result
end revXMLRPC_DeleteParam

function revXMLRPC_GetParamCount pXMLRPCDocID
   if revXMLRPC_GetID(pXMLRPCDocID) is empty then
      return "xmlrpcerr : bad document id" && pXMLRPCDocID
   end if
   ## if it is a valid doc ID, proceed
   local tParamsNode
   put "/" & revXMLRootNode(pXMLRPCDocID) & "/params" into tParamsNode
   return revXMLNumberOfChildren(pXMLRPCDocID, tParamsNode,,0)
end revXMLRPC_GetParamCount

function revXMLRPC_GetParam pXMLRPCDocID, pParamNumber, pType
   if revXMLRPC_GetID(pXMLRPCDocID) is empty then
      return "xmlrpcerr : bad document id" && pXMLRPCDocID
   end if
   ## if it is a valid doc ID, proceed
   local tParamCount, tValueNode, tValueType, tDataNode
   put revXMLRPC_GetParamCount(pXMLRPCDocID) into tParamCount
   if pParamNumber > tParamCount then
      return "xmlrpcerr : there are only" && tParamCount && "params"
   end if
   put "/" & revXMLRootNode(pXMLRPCDocID) & "/params/param[" & pParamNumber & "]/value" into tValueNode
   put revXMLChildNames(pXMLRPCDocID,tValueNode,return,,false) into tValueType
   put tValueNode & "/" & tValueType into tDataNode
   
   local tParamData
   if pType is "xml" or pType is empty then
      put revXMLText(pXMLRPCDocID,tDataNode) into tParamData
   else if pType is not tValueType then
      put "xmlrpcerr : requested type" && pType && "does not match the value type" && tValueType into tParamData
   else if pType is among the items of kXMLRPC_ComplexTypes then
      put revXMLText(pXMLRPCDocID,tDataNode) into tParamData
   else if pType is among the items of kXMLRPC_SimpleTypes then
      put revXMLNodeContents(pXMLRPCDocID,tDataNode) into tParamData
   else -- if we got all the way here, it is an unkown data type
      put "xmlrpcerr : encountered unknown data type" && tValueType && "while parsing response data" into tParamData
   end if
   return tParamData
end revXMLRPC_GetParam

function revXMLRPC_GetParamType pXMLRPCDocID, pParamNumber
   if revXMLRPC_GetMethod(pXMLRPCDocID) is empty then
      return "xmlrpcerr : bad document id" && pXMLRPCDocID
   end if
   ## if it is a valid doc ID, proceed
   local tParamCount, tValueNode
   put revXMLRPC_GetParamCount(pXMLRPCDocID) into tParamCount
   if pParamNumber > tParamCount then
      return "xmlrpcerr : there are only" && tParamCount && "params"
   end if
   
   put "/" & revXMLRootNode(pXMLRPCDocID) & "/params/param[" & pParamNumber & "]/value" into tValueNode
   return revXMLChildNames(pXMLRPCDocID,tValueNode,cr,,false)
end revXMLRPC_GetParamType

function revXMLRPC_GetParamNode pXMLRPCDocID, pParamNumber
   if revXMLRPC_GetMethod(pXMLRPCDocID) is empty then
      return "xmlrpcerr : bad document id" && pXMLRPCDocID
   end if
   ## if it is a valid doc ID, proceed
   local tParamCount
   put revXMLRPC_GetParamCount(pXMLRPCDocID) into tParamCount
   if pParamNumber > tParamCount then
      return "xmlrpcerr : there are only" && tParamCount && "params"
   end if
   return "/" & revXMLRootNode(pXMLRPCDocID) & "/params/param[" & pParamNumber & "]"
end revXMLRPC_GetParamNode

command revXMLRPC_SetMethod pXMLRPCDocID, pMethodName
   if pMethodName is not empty then
      xmlSetRPCProperty pXMLRPCDocID, "/methodCall/methodName", pMethodName
   end if
end revXMLRPC_SetMethod

function revXMLRPC_GetMethod pXMLRPCDocID
  return xmlRPCProperty(pXMLRPCDocID, "/methodCall/methodName")
end revXMLRPC_GetMethod

command revXMLRPC_SetHost pXMLRPCDocID, pHost, pPort
   if pHost is not empty then
      xmlSetRPCProperty pXMLRPCDocID, "host", pHost
   end if
   if pPort is not empty then
      revXMLRPC_SetPort pXMLRPCDocID, pPort
   end if
end revXMLRPC_SetHost

function revXMLRPC_GetHost pXMLRPCDocID
  return xmlRPCProperty(pXMLRPCDocID, "host")
end revXMLRPC_GetHost

command revXMLRPC_SetPort pXMLRPCDocID, pPort
   if pPort is not empty then
      xmlSetRPCProperty pXMLRPCDocID, "port", pPort
   end if
end revXMLRPC_SetPort

function revXMLRPC_GetPort pXMLRPCDocID
  return xmlRPCProperty(pXMLRPCDocID, "port")
end revXMLRPC_GetPort

command revXMLRPC_SetPath pXMLRPCDocID, pPath
   if pPath is not empty then
      xmlSetRPCProperty pXMLRPCDocID, "path", pPath
   end if
end revXMLRPC_SetPath

function revXMLRPC_GetPath pXMLRPCDocID
  return xmlRPCProperty(pXMLRPCDocID, "path")
end revXMLRPC_GetPath

command revXMLRPC_SetProtocol pXMLRPCDocID, pProtocol
   if pProtocol is not empty then
      xmlSetRPCProperty pXMLRPCDocID, "protocol", pProtocol
   end if
end revXMLRPC_SetProtocol

function revXMLRPC_GetProtocol pXMLRPCDocID
  return xmlRPCProperty(pXMLRPCDocID, "protocol")
end revXMLRPC_GetProtocol

command revXMLRPC_SetSocket pXMLRPCDocID, pSocket
   if pSocket is not among the lines of the openSockets then
      return "xmlrpcerr :" && pSocket && "is not an open socket"
   end if
   if pSocket is not empty then
      xmlSetRPCProperty pXMLRPCDocID, "socket", pSocket
   end if
end revXMLRPC_SetSocket

function revXMLRPC_GetSocket pXMLRPCDocID
  return xmlRPCProperty(pXMLRPCDocID, "socket")
end revXMLRPC_GetSocket

function revXMLRPC_Execute pXMLRPCDocID
   if xmlIDIsValid?(pXMLRPCDocID) is false then
      return "xmlrpcerr : bad document id" && pXMLRPCDocID
   end if
   
   if revXMLRPC_GetRequest(pXMLRPCDocID) is not empty then
      return "xmlrpcerr : document id" && pXMLRPCDocID && "is a response"
   end if
   
   ## if it is a valid doc ID, proceed
   local tPath, tSocket, tHost, tPort, tURL, tProtocol
   local tPayload, tHTTPHeaders, tResponseData, tResponseID
   -- collect the host, port, path and protocol information
   put revXMLRPC_GetHost(pXMLRPCDocID) into tHost
   if tHost is empty then put kXMLRPC_DefaultHost into tHost
   put revXMLRPC_GetPort(pXMLRPCDocID) into tPort
   if tPort is empty then put kXMLRPC_DefaultPort into tPort
   put revXMLRPC_GetPath(pXMLRPCDocID) into tPath
   if tPath is empty then put kXMLRPC_DefaultPath into tPath
   put revXMLRPC_GetProtocol(pXMLRPCDocID) into tProtocol
   if tProtocol is empty then put kXMLRPC_DefaultProtocol into tProtocol
   
   -- prepare the POST payload and HTTP headers
   put revXMLText(pXMLRPCDocID) into tPayload
   put "User-Agent: LiveCode/" & revAppVersion() && "(" & the platform & ")" & cr & \
         "Host:" && tHost & cr & \
         "Content-Type: text/xml" & cr & \
         "Content-Length:" && length(tPayload) into tHTTPHeaders
   ## now fork depending on whether using an existing socket or not
   put revXMLRPC_GetSocket(pXMLRPCDocID) into tSocket
   if tSocket is not empty then
      -- use the existing connection
      if tSocket is not among the lines of the openSockets then
         return "xmlrpcerr :" && tSocket && "is not an open socket"
      end if
      -- make sure the connection stays open
      put cr & "Connection: Keep-Alive" after tHTTPHeaders
      replace cr with CRLF in tHTTPHeaders
      write "POST /" & tPath && toUpper(tProtocol) &"/1.1" & CRLF & \
            tHTTPHeaders & CRLF & CRLF & tPayload to socket tSocket
      read from socket tSocket until CRLF
      -- save the response and check the server status code
      local tServerResponse
      put it into tServerResponse
      if word 2 of line 1 of tServerResponse is not "200" then
         -- make sure to read all the data, even if we ignore it
         read from socket tSocket until empty
         revXMLRPCSetError pXMLRPCDocID, "xmlrpcerr :" && word 2 to -1 of tServerResponse
         return revXMLRPC_Error(pXMLRPCDocID)
      end if
      -- read the headers
      read from socket tSocket until (CRLF & CRLF)
      local tSRHTTPHeaders
      put it into tSRHTTPHeaders
      replace CRLF with cr in tSRHTTPHeaders
      if line -1 of tSRHTTPHeaders is empty then delete line -1 of tSRHTTPHeaders
      -- read the response data for parsing
      read from socket tSocket until empty
      put it into tResponseData
   else
      -- use POST command from libURL
      put toLower(tProtocol) & "://" & tHost & ":" & tPort & "/" & tPath into tURL
      -- now post the payload to the URL
      local tSaveHTTPHeaders
      put the httpHeaders into tSaveHTTPHeaders #mf 03/08/2005 Bug 2444
      set the httpHeaders to tHTTPHeaders
      post tPayload to URL tURL
      -- save the response and check the result
      put it into tResponseData
      if the result is not empty then
         revXMLRPC_SetError pXMLRPCDocID, the result
         
         # OK-2009-06-19 : Bug 8121 - Ensure httpHeaders global property is not changed by failed execution
         set the httpheaders to tSaveHTTPHeaders
         
         return revXMLRPC_Error(pXMLRPCDocID)
      end if
      -- don't forget to fetch the remote HTTP headers
      put libURLLastRHHeaders() into tSRHTTPHeaders
      set the httpHeaders to tSaveHTTPHeaders #mf 03/08/2005 Bug 2444
   end if
   -- parse the response
   put revCreateXMLTree(tResponseData,true,true,false) into tResponseID
   if tResponseID is not a number then
      revXMLRPC_SetError pXMLRPCDocID, tResponseID
      return tResponseID
   end if
   revXMLRPC_SetID tResponseID, tResponseID
   -- save the related information with the response tree
   revXMLRPC_SetRequest tResponseID, pXMLRPCDocID
   
   -- copy the necessary connection information
   if tSocket is not empty then
      revXMLRPC_SetSocket tResponseID, tSocket
   else
      revXMLRPC_SetHost tResponseID, tHost
      revXMLRPC_SetPort tResponseID, tPort
   end if
   #put tPath into sXMLRPC_Data[tResponseID,"path"]
   revXMLRPC_SetPath tResponseID, tPath
   -- save the response HTTP-headers
   revXMLRPC_SetHeaders tResponseID, tSRHTTPHeaders
   -- save a link to the response tree with the request information
   revXMLRPC_SetResponse pXMLRPCDocID, tResponseID
   -- finally return the response tree
   return tResponseID
end revXMLRPC_Execute

command revXMLRPC_SetError pXMLRPCDocID, pError
   xmlSetRPCProperty pXMLRPCDocID, "error", pError
end revXMLRPC_SetError

function revXMLRPC_Error pXMLRPCDocID
  return xmlRPCProperty(pXMLRPCDocID, "error")
end revXMLRPC_Error

command revXMLRPC_SetResponse pXMLRPCDocID, pResponse
   xmlSetRPCProperty pXMLRPCDocID, "response", pResponse
end revXMLRPC_SetResponse

function revXMLRPC_GetResponse pXMLRPCDocID
  return xmlRPCProperty(pXMLRPCDocID, "response")
end revXMLRPC_GetResponse

command revXMLRPC_SetRequest pXMLRPCDocID, pRequest
   xmlSetRPCProperty pXMLRPCDocID, "request", pRequest
end revXMLRPC_SetRequest

function revXMLRPC_GetRequest pXMLRPCDocID
  return xmlRPCProperty(pXMLRPCDocID, "request")
end revXMLRPC_GetRequest

command revXMLRPC_SetHeaders pXMLRPCDocID, pHeaders
   xmlSetRPCProperty pXMLRPCDocID, "headers", pHeaders
end revXMLRPC_SetHeaders

function revXMLRPC_GetHeaders pXMLRPCDocID
  return xmlRPCProperty(pXMLRPCDocID, "headers")
end revXMLRPC_GetHeaders

command revXMLRPC_SetID pXMLRPCDocID, pID
   xmlSetRPCProperty pXMLRPCDocID, "id", pID
end revXMLRPC_SetID

function revXMLRPC_GetID pXMLRPCDocID
  return xmlRPCProperty(pXMLRPCDocID, "id")
end revXMLRPC_GetID

private function xmlRPCProperty pXMLRPCDocID, pKey
  if xmlIDIsValid?(pXMLRPCDocID) then
    ## if it is a valid doc ID, proceed
    return sXMLRPC_Data[pXMLRPCDocID,pKey]
  else
    return "xmlrpcerr : bad document id" && pXMLRPCDocID && "getting" && pKey
  end if
end xmlRPCProperty

private command xmlSetRPCProperty pXMLRPCDocID, pKey, pValue
  if xmlIDIsValid?(pXMLRPCDocID) then
    ## if it is a valid doc ID, proceed
    put pValue into sXMLRPC_Data[pXMLRPCDocID,pKey]
  else
    return "xmlrpcerr : bad document id" && pXMLRPCDocID && "setting" && pKey && "to" pValue
  end if
end xmlSetRPCProperty

private function xmlIDIsValid? pXMLRPCDocID
   if sXMLRPC_Data[pXMLRPCDocID,"id"] is empty then
      return false
   end if
   return true
end xmlIDIsValid?
--
