
/*----------------------------------------------------------------------------*/
/*                                                                            */
/* Description: Class to encode and decode ooRexx objects in JSON.            */
/*                                                                            */
/* Copyright (c) 2010-2016 Rexx Language Association. All rights reserved.    */
/*                                                                            */
/* This program and the accompanying materials are made available under       */
/* the terms of the Common Public License v1.0 which accompanies this         */
/* distribution. A copy is also available at the following address:           */
/* http://www.ibm.com/developerworks/oss/CPLv1.0.htm                          */
/*                                                                            */
/* Redistribution and use in source and binary forms, with or                 */
/* without modification, are permitted provided that the following            */
/* conditions are met:                                                        */
/*                                                                            */
/* Redistributions of source code must retain the above copyright             */
/* notice, this list of conditions and the following disclaimer.              */
/* Redistributions in binary form must reproduce the above copyright          */
/* notice, this list of conditions and the following disclaimer in            */
/* the documentation and/or other materials provided with the distribution.   */
/*                                                                            */
/* Neither the name of Rexx Language Association nor the names                */
/* of its contributors may be used to endorse or promote products             */
/* derived from this software without specific prior written permission.      */
/*                                                                            */
/* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS        */
/* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT          */
/* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS          */
/* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT   */
/* OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,      */
/* SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED   */
/* TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,        */
/* OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY     */
/* OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING    */
/* NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS         */
/* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.               */
/*                                                                            */
/* Author: Brandon W. Cherry                                                  */
/*                                                                            */
/*----------------------------------------------------------------------------*/

/* changes: author Rony G. Flatscher (2016)
            - the toJSON-methods got renamed from "parse" to "process"

            - package name translated into uppercase, now: "JSON.CLS"; reason: allows
              using the name with or without quotes (important on Unix)

            - toJSON-methods:
              - changed "instance of" tests to isA() in method processObject()
              - generalized processing: Array->OrderedCollection, Directory->MapCollection
              - using indentations and CR-LF to make produced JSON files legible for humans :)
                - added "level" and "indent" (string to use for indentations) attributes
              - if the Rexx object has no makestring method, then its objectname gets returned
                instead of the string "null"
              - MapCollection entries are sorted by their index

            - Added new class "JSON_Boolean" to explicitly distinguish JSON boolean
              values from Rexx logical strings when creating the JSON encoded text file

            - removed "()" after message names as ooRexx allows to leave them out, if
              no arguments are supplied with the message

            - added table "rexx2json" to allow changeStr() to be used instead of inspecting
              each char individually from Rexx

            - added class attribute "version" in the form: major*100+minor || "." || yyyymmdd
              to class JSON and JsonBoolean

   references: - JSON RFC, as of July 2006: <http://tools.ietf.org/html/rfc-4627>

*/


parse version "ooRexx_" rexxVersion "("
.local~json.useRexxV5=(rexxVersion>=5)  -- determine whether to use ooRexx version 5 features
if .json.useRexxV5 then .local~json.dirClass=.stringTable -- use .stringTable, new in 5.0
                   else .local~json.dirClass=.directory    -- use .directory, availabe in 4.x and higher


bDebug=.false -- .true      -- show debug output in prolog code?
if bDebug then
do
   parse source s
   .traceOutput~say("***  source:" s "***")
   parse version v
   .traceOutput~say("*** version:" v "***")
   .traceOutput~say("*** .json~version: " .json~version "***")
   .traceOutput~say("*** .json.dirClass:" .json.dirClass "***")
end


/* ========================================================================= */

/** This class implements <code>RFC 4627</code> and allows to encode Rexx objects as JSON strings and
*   parse JSON strings into Rexx objects. This version does no Unicode related encoding or decoding.
*   (Rexx programmers can do Unicode related processing e.g. by taking advantage of Java via the
*   <a href="https://sourceforge.net/projects/bsf4oorexx/">BSF4ooRexx</a>
*   package. The routines <code>getEncoding()</code> and <code>getJsonBOM()</code> are implemented
*   in this package to support such an endeavor.)
*
* @author Brandon W. Cherry (original author)
* @author Rony G. Flatscher (adapted code to ooRexx 4.2.0 and 5.0.0)
*/
::class  JSON public

/* ========================================================================= */

/** Class getter attribute method that returns the version information of this class.
*
* @return version as a string, formatted as: major*100+minor || "." || yyyymmdd
*/

::attribute version get class
  use strict arg           -- no argument allowed!
  return "100.20160804"    -- version in the form: major*100+minor || "." || yyyymmdd

/** Determines the encoding by inspecting the first four bytes of a JSON string, cf.
*   cf. <https://www.ietf.org/rfc/rfc4627.txt>
*
* @param string optional JSON string in which the first four bytes may be a BOM (byte order mark)
*
* @return "UTF-8", "UTF-16BE", "UTF-16LE", "UTF-32BE", "UTF-32LE", depending on the BOM
*/
::method getEncoding class    -- determine UTF-encoding, return UTF-8, UTF-16LE, UTF-16BE, UTF-32LE, UTF-32BE
  use strict arg string=""

  select
     when string~left(3)    ="00 00 00"x                     then return "UTF-32BE"
     when string~substr(2,3)="00 00 00"x                     then return "UTF-32LE"
     when string~substr(1,1)="00"x, string~substr(3,1)="00"x then return "UTF-16BE"
     when string~substr(2,1)="00"x, string~substr(4,1)="00"x then return "UTF-16LE"
     otherwise return "UTF-8"  -- default encoding
  end

/** Returns the JSON BOM (byte order mark) characters according to the desired encoding,
*   cf. <https://www.ietf.org/rfc/rfc4627.txt>.
*
* @param encoding optional, one of "UTF-8", "UTF-16BE", "UTF-16LE", "UTF-32BE", "UTF-32LE"
*
* @return the empty string for "UTF-8" or unknown encoding or a four-character string formatted
*         as a JSON BOM
*/
::method getJsonBOM class  -- determine UTF-encoding, return UTF-8, UTF-16LE, UTF-16BE, UTF-32LE, UTF-32BE
  use strict arg encoding="UTF-8"

  select
     when encoding="UTF-8"    then return ""    -- default, in JSON no explicit BOM
     when encoding="UTF-32BE" then return "00 00 00 FF"x
     when encoding="UTF-32LE" then return "FF 00 00 00"x
     when encoding="UTF-16BE" then return "00 FF 00 FF"x
     when encoding="UTF-16LE" then return "FF 00 FF 00"x
     otherwise return ""   -- use default encoding, ie. UTF-8
  end

::method unescape class -- unescape Unicode escape strings in the form


/** Constructor. */
::method init
    expose eJS uJS whitespace ctrl level indent rexx2json

    eJS = .json.dirClass~new   -- escape Javascript
    eJS['\']   = '\\'   -- escape for: backslash character
    eJS['08'x] = '\b'   -- escape for: backspace character
    eJS['09'x] = '\t'   -- escape for: tab character
    eJS['0A'x] = '\n'   -- escape for: newline (line feed) character
    eJS['0C'x] = '\f'   -- escape for: form feed character
    eJS['0D'x] = '\r'   -- escape for: carriage return character
    eJS['"']   = '\"'   -- escape for: double quote character
    eJS['/']   = '\/'   -- escape for: slash character

    uJS = .json.dirClass~new   -- unescape Javascript
    do index over eJS
        uJS[eJS[index]] = index
    end

      -- rgf, 2016-07-24: sequence to be applied in changeStr(): first must be "\" -> "\\" as "\" is the escape char
    rexx2json =.array~of(.array~of('\'  , '\\'), - -- escape for: backslash character
                         .array~of('08'x, '\b'), - -- escape for: backspace character
                         .array~of('09'x, '\t'), - -- escape for: tab character
                         .array~of('0A'x, '\n'), - -- escape for: newline (line feed) character
                         .array~of('0C'x, '\f'), - -- escape for: form feed character
                         .array~of('0D'x, '\r'), - -- escape for: carriage return character
                         .array~of('"'  , '\"'), - -- escape for: double quote character
                         .array~of('/'  , '\/'), - -- escape for: slash character
                        )
-- <---

    whitespace = .set~new  -- allowed whitespace chars
    whitespace~put('09'x)  -- TAB character
    whitespace~put('0A'x)  -- LF (line feed) character
    whitespace~put('0D'x)  -- CR (carriage-return) character
    whitespace~put(' '  )  -- space/blank

    ctrl = whitespace~copy -- chars that end a value
    ctrl~put('}')
    ctrl~put(']')
    ctrl~put(',')

    --- rgf, 2016-07-17: indentation related to ease reading generated JSON files
    level =0      -- start out with level 0
    indent="  "   -- use two spaces per level for indentation




/**
 * Converts a Rexx object to JSON formatting to pass to eval()
 *
 * @param  rexxObject   The object to converts directory, array,
 *                      or string objects. Otherwise, it calls
 *                      the makearray method for the object.
 * @return a string that represents the JSON encoding of the supplied <code>rexxObject</code>
 */
::method toJSON
    expose buffer level
    use strict arg rexxObject

    buffer = .mutablebuffer~new
    self~encodeRexxObject(rexxObject)
    return buffer~string

/** Control method that determines which method should encode the supplied Rexx object.
*
* @param  rexxObject the Rexx object to encode
*/
::method encodeRexxObject private    -- rgf, 2016-07-17
    expose buffer
    use arg rexxObject

    select
        when rexxObject~isA(.OrderedCollection) then do  -- e.g. .array, .list, ...
            self~encodeOrderedCollection(rexxObject)
        end
        when rexxObject~isA(.MapCollection) then do      -- e.g. .directory, .relation
            self~encodeMapCollection(rexxObject)
        end
        when rexxObject~isA(.string) then do             -- a plain string in hand
            self~encodeRexxString(rexxObject)
        end
        when rexxObject~isA(.JsonBoolean) then do       -- a JSON Boolean
             buffer~append(rexxObject~makeJSON)          -- no quotes
        end
        when rexxObject=.nil then do
            buffer~append('null')                        -- no quotes
        end
        otherwise
            if rexxObject~hasMethod('makearray') then
               self~encodeRexxObject(rexxObject~makearray)   -- recursive call
            else        -- use rexxObject's objectname
            do
               if .json.useRexxV5 then
                  buffer~append('"', rexxObject~objectName, '"')
               else
                  buffer~~append('"')~~append(rexxObject~objectName)~append('"')
            end
    end


/** Encodes any ooRexx ordered collection, including array objects.
*
* @param  rexxObject the Rexx object to encode
*/
::method encodeOrderedCollection private   -- rgf, 2016-07-17: instead of parseRexxArray
    expose buffer level indent
    use arg rexxObject

    strIndent1=indent~copies(level)       -- create outer indentation string once
    strIndent2=indent~copies(level+1)     -- create inner indentation string once

    if .json.useRexxV5 then
       buffer~append(strIndent1, '[')
    else
       buffer~~append(strIndent1) ~append('[')

    sup=rexxObject~supplier
    level+=1                  -- increase level

    do while sup~available    -- iterate and encode item entries only
         buffer~append(.endOfLine)
         self~encodeRexxObject(sup~item)  -- encode item object (recursive call)
         sup~next             -- position on next item
         if sup~available then
         do
            if .json.useRexxV5 then
               buffer~append(strIndent2, ',')
            else
               buffer~~append(strIndent2) ~append(',')
         end
    end
    level-=1                  -- decrease level

    if .json.useRexxV5 then
       buffer~append(strIndent1, ']', .endOfLine)
    else
       buffer~~append(strIndent1) ~~append(']') ~append(.endOfLine)



/** Encodes any ooRexx unordered collection, including directory objects.
*   The index objects are sorted caselessly in ascending order to ease human
*   analysis of the encoded data.
*
*   If an unordered collection possesses the <code>ALLAT</code> method, then multiple
*   entries per index are expected (like the ooRexx <code>.Relation</code> class),
*   which will cause the encoding of multiple index entries, one per item. If the
*   index is not a string object, then the <code>MAKESTRING</code> method is used to
*   get a string object rendering representing the index object. If a
*   <code>MAKESTRING</code> method is not available then the object name and its
*   identity hash value (encoded as hexadecimal value) are used instead to represent
*   the index object.
*
* @param  rexxObject the Rexx object to encode
*/
::method encodeMapCollection private -- rgf, 2016-07-18: sort by index to allow easier checks for humans in the resulting JSON file
    expose buffer level indent
    use arg rexxObject

    bHasAllAt=rexxObject~hasMethod("ALLAT")        -- e.g. a .relation
    tmpIdx=.set~new~union(rexxObject~allIndexes)~allindexes -- create an array with unique index objects
    tmpDir=.json.dirClass~new
    do idx over tmpIdx
       select  -- turn idx into a string, if necessary
          when idx~isA(.string)      then strIdx=idx
          when idx~isA(.JsonBoolean) then strIdx=idx~value  -- use logical value as string value
          when idx~hasMethod("MAKESTRING") then       -- use the request-protocol to obtain a string value
               strIdx=idx~request("STRING")
          otherwise
               strIdx=idx~objectName"@"idx~identityHash~d2x
       end

       if bHasAllAt then      -- per index more than one item?
          tmpDir[strIdx]=rexxObject~allAt(idx)  -- will return an .array of items associated with index
       else
          tmpDir[strIdx]=.array~of(rexxObject~at(idx))
    end
    tmpIdx~sortWith(.caselessComparator~new) -- sort caselessly in ascending order

    strIndent1=indent~copies(level)       -- create outer indentation string once
    strIndent2=indent~copies(level+1)     -- create inner indentation string once

    if .json.useRexxV5 then
       buffer~append(strIndent1, '{', .endOfLine)
    else
       buffer~~append(strIndent1) ~~append('{') ~append(.endOfLine)

    level+=1                     -- increase level
    nrIdx=tmpIdx~size
    do i=1 to nrIdx
       strIdx=tmpIdx~at(i)
       items=tmpDir~at(strIdx)      -- get array object
       do item over items
               -- index part
          buffer ~append(strIndent2)
          self~encodeRexxString(strIdx, .true)
          buffer~append(': ')
               -- item part
          self~encodeRexxObject(item) -- encode item portion (recursive call)

          if i<nrIdx then buffer~append(',')
          buffer~append(.endofline)
       end
    end
    level-=1                     -- decrease level

    if .json.useRexxV5 then
       buffer~append(strIndent1, '}', .endOfLine)
    else
       buffer ~~append(strIndent1) ~~append('}') ~append(.endOfLine)


/** Encodes a Rexx string, applying the JSON character escaping strings.
*
* @param  rexxObject the Rexx object to encode
*/
::method encodeRexxString private      -- rgf, 2016-07-17
    expose buffer eJS level indent rexx2json
    use strict arg rexxObject, bQuote=.false

    if rexxObject=="" 0 then           -- empty string?
       buffer~append('""')
    else
    do
        if rexxObject~dataType('n') then  -- a numeric value?
        do
           if bQuote=.true then
           do
              if .json.useRexxV5 then
                 buffer~append('"', rexxObject, '"')
              else
                 buffer~~append('"') ~~append(rexxObject)~append('"')
           end
           else
              buffer~append(rexxObject)
        end
        else   -- rgf, 2016-07-24): create a MutableBuffer from Rexx string, use changeStr()
        do
-- TODO: (rgf) escape "00"x-"1F"x as "\u00XX" chars; if BSF4ooRexx available one could also use java.util.Properties
            mb=.mutableBuffer~new(rexxObject,rexxObject~length*2)
            do arr over rexx2json   -- iterate over replacement pairs
               mb~changeStr(arr[1],arr[2])
            end

            if .json.useRexxV5 then
               buffer~append('"', mb~string, '"')
            else
               buffer~~append('"')~~append(mb~string)~append('"')
        end
    end


/* ========================================================================= */


-- rgf, 2016-07-24: all methods controlled by fromJSON rely on character-by-character based parsing
/**
 * Converts a JSON encoded string to Rexx objects.
 *
 * @param  jsonString   some JSON encoded string
 */
::method fromJSON
    expose jsonString jsonPos jsonStringLength
    use strict arg jsonString

    signal on syntax
    .ArgUtil~validateClass("jsonString", jsonString, .string)  -- check for correct type

    if jsonString="" then return jsonString              -- return received empty string

    signal on user parseError

      -- determine starting character position
    if self~class~getEncoding(jsonString)="UTF-8" then jsonPos=1 -- no BOM characters
                                                  else jsonPos=5 -- skip the four BOM characters

    jsonStringLength = jsonString~length
    self~trimLeadingWhitespace
    rexxObject = self~parseJSONvalue
    if jsonPos >= jsonStringLength then return rexxObject
    else do
        self~trimLeadingWhitespace
        if jsonPos >= jsonStringLength then return rexxObject
        message = 'Expected end of input'
        signal extraChars
    end
    return .nil

parseError:
    c = condition('o')
    message = c['ADDITIONAL'][1]
extraChars:
    raise syntax 3.900 array(message 'at position ['jsonPos"]: ["jsonString~substr(jsonPos, 25)"]..., jsonString~length=["jsonString~length"]")

syntax: raise propagate


/** Control method that determines which parse method gets used.
 *
 *  @return the Rexx object that results from parsing the entire JSON encoded string and representing it
 */
::method parseJSONvalue private
    expose jsonString jsonPos
    signal on user parseError

    parse value jsonString with =(jsonPos) char +1
    select
        when char == '{' then do          -- an unordered JSON collection
            jsonPos = jsonPos + 1
            return self~parseJSONobject
        end
        when char == '[' then do          -- a JSON array
            jsonPos = jsonPos + 1
            return self~parseJSONarray
        end
        when char == '"' then do          -- a JSON string
            jsonPos = jsonPos + 1
            return self~parseJSONstring
        end
        otherwise return self~parseJSONother
    end
    return
parseError: raise propagate

/**
 * Converts a JSON object into a Rexx <code>Directory</code> object or - starting
 * with ooRexx 5.0 - into a <code>StringTable</code> object.
 *
 */
::method parseJSONobject private
    expose jsonString jsonPos
    signal on user parseError

    rexxDirectory = .json.dirClass~new

    parse value jsonString with =(jsonPos) char +1
    if char == '}' then do
        jsonPos = jsonPos + 1
        return rexxDirectory
    end
    else self~parseJSONobjectValue(rexxDirectory)

    do forever
        self~trimLeadingWhitespace
        parse value jsonString with =(jsonPos) char +1
        select
            when char == '}' then do
                jsonPos = jsonPos + 1
                return rexxDirectory
            end
            when char == ',' then do
                jsonPos = jsonPos + 1
                self~parseJSONobjectValue(rexxDirectory)
            end
            otherwise raise user parseError array('Expected end of a JSON object or a new "name:value" pair')
        end
    end
return
parseError: raise propagate

/**
 * Converts and stores a JSON <code>name:value</code> pairs as an <code>index</code>/<code>item</code> pair
 * in the Rexx directory object.
 *
 * @param  rexxDirectory   A Rexx directory object to store the JSON "name:value" pair as "index:item" pair
 */
::method parseJSONobjectValue private
    expose jsonString jsonPos
    signal on user parseError
    use arg rexxDirectory

    self~trimLeadingWhitespace
    parse value jsonString with =(jsonPos) char +1
    if char == '"' then do
        jsonPos = jsonPos + 1
        index = self~parseJSONstring
    end
    else raise user parseError array('JSON object name must start with a quote, which is missing')

    self~trimLeadingWhitespace
    parse value jsonString with =(jsonPos) char +1
    if char == ':' then do
        jsonPos = jsonPos + 1
        self~trimLeadingWhitespace
        rexxDirectory[index] = self~parseJSONvalue
    end
    else raise user parseError array('Expected colon separating JSON object name and value is missing') -- rgf, made text a little bit clearer
return
parseError: raise propagate

/**
 * Converts a JSON array into a Rexx array object.
 *
 * @return returns the Rexx array representing the parsed JSON array
 *
 */
::method parseJSONarray private
    expose jsonString jsonPos
    signal on user parseError

    rexxArray = .array~new

    parse value jsonString with =(jsonPos) char +1
    if char == ']' then do
        jsonPos = jsonPos + 1
        return rexxArray
    end
    else self~parseJSONarrayValue(rexxArray)

    do forever
        self~trimLeadingWhitespace
        parse value jsonString with =(jsonPos) char +1
        select
            when char == ']' then do
                jsonPos = jsonPos + 1
                return rexxArray
            end
            when char == ',' then do
                jsonPos = jsonPos + 1
                self~parseJSONarrayValue(rexxArray)
            end
            otherwise raise user parseError array('Expected end of a JSON array or a new "name:value" pair')
        end
    end
return
parseError: raise propagate

/**
 * Converts a JSON array value and appends it to a Rexx array.
 *
 * @param rexxArray a Rexx array to which the JSON array value gets appended
 *
 */
::method parseJSONarrayValue private
    expose jsonString
    signal on user parseError
    use arg rexxArray

    self~trimLeadingWhitespace
    index = rexxArray~last
    if .nil == index then index = 0
    rexxArray[index + 1] = self~parseJSONvalue
return
parseError: raise propagate

/**
 * Converts a quoted JSON string into a Rexx string. Any JSON character escapes are
 * converted to the characters they represent.
 *
 * @return the Rexx string representing the JSON string
 */
::method parseJSONstring private
    expose jsonString uJS jsonPos jsonStringLength
    signal on user parseError

    rexxString = .mutablebuffer~new
    do forever
-- TODO: (rgf) unescape "\uXXXX" chars, if "\u0000"-"\u001F" and UTF-8, ignore leading "00"
        parse value jsonString with =(jsonPos) char +1
        if char == '\' then do
            parse value jsonString with =(jsonPos) char2 +2
            if uJS~hasIndex(char2) then do
                jsonPos = jsonPos + 2
                rexxString~append(uJS[char2])
            end
            else do
                jsonPos = jsonPos + 1
                rexxString~append(char)
            end
        end
        else do
            jsonPos = jsonPos + 1
            if char == '"' then return rexxString~string -- TODO: (rgf) unescape string; if BSF4ooRexx available one could also use java.util.Properties
            else rexxString~append(char)
        end
        if jsonPos >= jsonStringLength then raise user parseError array('Expected end of a quoted string, ending quote not found')
    end
    return
parseError: raise propagate

/**
 * Converts other json types into Rexx objects.
 *
 */
::method parseJSONother private
    expose jsonString ctrl jsonPos jsonStringLength
    signal on user parseError

    length = jsonStringLength + 1
    do i = jsonPos while i \== length
        parse value jsonString with =(i) char +1
        if ctrl~hasIndex(char) then leave
    end
    parse value jsonString with =(jsonPos) string +(i - jsonPos)
    if string~datatype('n') then do
        jsonPos = jsonPos + string~length
        return string
    end
    else do
        select
            when string == 'false' then do
                jsonPos = jsonPos + 5 -- string~length
                -- return .false
                -- return .json_Boolean~new(.false)
                return .JsonBoolean~false
            end
            when string == 'true' then do
                jsonPos = jsonPos + 4 -- string~length
                -- return .json_Boolean~new(.true)
                return .JsonBoolean~true
            end
            when string == 'null' then do
                jsonPos = jsonPos + 4 -- string~length
                return .nil
            end
            otherwise nop
        end
    end

    raise user parseError array('Invalid JSON value, jsonPos=['jsonPos'], jsonStringLength=['jsonStringLength']')

parseError: raise propagate


/**
 * Removes allowed whitespace between values.
 *
 */
::method trimLeadingWhitespace private
    expose jsonString whitespace jsonPos jsonStringLength

    do while jsonPos \== jsonStringLength
        parse value jsonString with =(jsonPos) char +1
        if whitespace~hasIndex(char) then jsonPos = jsonPos + 1
        else leave
    end



/* ========================================================================= */

/*
*   -- rgf, 2016-07-17: define a class to explicitly represent a JSON boolean to ease generating correct JSON files
*   -- rgf, 2016-07-23: - as Orderable is broken as of 4.2.0 and unclear whether 5.0.0 gets it corrected, this class
*                         explicilty defines the methods "=", "\=", "<>" and "><" to get correct comparison results
*                       - removing inheriting form orderable altogether
*                       - inherit comparable (indicates that compareTo is implemented), allows sorting
*/

/** ooRexx class to represent a JSON boolean (logical) value. It inherits from the ooRexx mixinclass
*   <code>Comparable</code> and therefore implements its abstract method <code>compareTo</code>.
*
*/
::class "JsonBoolean" public inherit comparable

/** Class getter attribute method that returns the version information of this class.
*
* @return version as a string, formatted as: major*100+minor || "." || yyyymmdd
*/

::attribute version get class
  use strict arg           -- no argument allowed!
  return "100.20160804"    -- version in the form: major*100+minor || "." || yyyymmdd

/** Class getter attribute method that refers to the sentinel object that represents the value <code>.true</code>.
*/
::attribute true  get class   -- true sentinel, class getter method

/** Class getter attribute method that refers to the sentinel object that represents the value <code>.false</code>.
*/
::attribute false get class   -- false sentinel, class getter method

/** Finalizes the class initialization by creating the two sentinel class attribute values <code>true</code>
*   and <code>false</code>.
*/
::method    activate  class   -- initialization of class object complete, we now can use everything
  expose true false
  true =self~new(.true)       -- create and store true value
  false=self~new(.false)      -- create and store false value

/** Controls the creation of instances of this class, makes sure that the sentinel values get created
*   and cached, otherwise returns the requested object.
*
* @param val a string representing a Boolean/logical value, i.e. one of &quot;0&quot;,
*            &quot;1&quot;, &quot;true&quot;, &quot;false&quot;,
*            &quot;.true&quot; or &quot;.false&quot; in any case.
*/
::method new class   -- make sure we hand out only the sentinel objects for "true" and "false", do not create more instances
  expose true false        -- expose class attributes
  use strict arg val

  if "0 1 true false .true .false"~caselessWordPos(val)=0 then -- check for acceptable values
     raise syntax 88.900 array ("Argument must be one of '0', 'false', '.false', '1', 'true' or '.true', found:" val)

  value=("0 false .false"~caselessWordPos(val)=0)  -- .true, if no false values supplied
  if value=.true then
  do
     if \var('TRUE') then  -- attribute not set yet?
     do
        forward class (super) array (.true) continue -- let superclass create and carry out initialisation
        true=result        -- assign created object to class attribute
     end
     return true           -- return the true sentinel object
  end

  if \var('FALSE') then    -- attribute not set yet?
  do
     forward class (super) array (.false) continue -- let superclass create and carry out initialisation
     false=result          -- assign created object to class attribute
  end
  return false             -- return the false sentinel object

/** Getter attribute method that returns the Rexx string representing the logical value.
*/
::attribute value get   -- getter method

/** Constructor.
* @param value mandatory Rexx string representing the logical value
*/
::method init private   -- make constructor method inaccessible to other classes, own metaclass is allowed to access directly
  expose value
  use strict arg value  -- assign boolean value

/** Equal comparison method.
* @param other the other object representing a Boolean/logical value
* @return <code>.true</code>, if this object and <code>other</code> can be reqarded to be equal, <code>.false</code> else
*/
::method "="            -- equal method
  use strict arg other  -- other must be a Boolean value
  return self~compareTo(other)=0

/** Unequal comparison method.
* @param other the other object representing a Boolean/logical value
* @return <code>.true</code>, if this object and <code>other</code> cannot be reqarded to be equal, <code>.false</code> else
*/
::method "\="           -- unequal method
  use strict arg other  -- other must be a Boolean value
  return self~compareTo(other)\=0

/** Unequal comparison method, forwarding to method <code>&quot;\=&quot;</code>.
*/
::method "<>"           -- synonym for "\="
  forward message ("\=")

/** Unequal comparison method, forwarding to method <code>&quot;\=&quot;</code>.
*/
::method "><"           -- synonym for "\="
  forward message ("\=")

/** Implements the abstract method inherited from the mixinclass <code>Comparable</code>.
*/
::method compareTo   -- implementation for .orderable class: must return -1 if other greater, 0 if same, 1 otherwise
  expose value
  use strict arg other  -- other must be a Boolean value

  if other~isA(.JsonBoolean) then  -- get Rexx string representing logical value
     otherValue=other~value
  else
     otherValue=other~request("string") -- request the string value

  if otherValue=.nil then
     raise syntax 88.900 array ("Argument ""other"" ["other"] has no 'MAKESTRING' method")

  if value < otherValue then return -1    -- self smaller than other
  if value = otherValue then return  0    -- self equal to other
  return                             1    -- self greater than other

/** Renders the object as a Rexx string representing its logical value.
* @return a Rexx string representing its logical value, either &quot;<code>0</code>&quot; or
*         &quot;<code>1</code>&quot;
*/
::method makestring  -- allow instances of this class to be a plug in replacement for Rexx logical values
  expose value
  return value


/** Renders the object as a JSON string representing its logical value.
* @return a string representing its logical value JSON encoded, either &quot;<code>false</code>&quot;
*         or &quot;<code>true</code>&quot;
*/
::method makeJSON    -- creates the string "true" or "false", depending on the attribute "value"
  expose value
  if value=.true then return "true"
  return "false"

