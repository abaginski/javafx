/*    author:     Rony G. Flatscher
      date:       2016-11-26
      purpose:    generic ooRexx program which stores the GLOBAL_SCOPE entries in .local as a directory
                  with the name of the FXML-file it got invoked from;

      explanation: this program is invoked by the JavaFX FXMLLoader when loading a FXML document and
                   instantiating the JavaFX controls using the RexxScript support, which means that
                   a proper Rexx interpreter instance gets created in which this program executes;
                   to share data with other Rexx interpreter instances we use .environment (shared
                   among all Rexx interpreter instances) rather than .local (unique per Rexx interpreter
                   instance);

                   FXMLLoader will create a new RexxScriptEngine for each FXML document it processes!

                   FXMLLoader will put all JavaFX objects with a fx:id attribute into the ScriptContext's
                   Bindings for the global scope, such that we can fetch these objects from there and
                   save it in a directory named after the FXML location (file name) that defines them for
                   later retrieval by other Rexx programs
*/

parse source . . thisProg
thisProg=filespec("Name", thisProg)

     -- make sure we have a directory with the environment symbol ".my.app" available to everyone which
     -- is to receive information about those JavaFX objects that have a unique "fx:id" value;
if \.environment~hasEntry("my.app") then
   .environment~setEntry("my.app", .directory~new)
if \.environment~entry("my.app")~hasEntry("keepCapitalizationInDirKey") then
   .my.app~setEntry("keepCapitalizationInDirKey", .false)
	 
bDebug=(.my.app~bDebug=.false)  -- set debug mode

if bDebug then say .dateTime~new " ==> ---> arrived in Rexx program '"thisProg"' ..."

use arg slotDir  -- fetch the slotDir argument (BSF4ooRexx adds this as the last argument at the Java side)
scriptContext=slotDir~scriptContext   -- get the slotDir (the last) argument, get the entry "SCRIPTCONTEXT"


if bDebug then
do
   tab="09"x
     -- make sure we have access to 'rgf_util2.rex' (supplied via BSF4ooRexx)
   .context~package~addPackage(.package~new('rgf_util2.rex'))
   call dump2 slotDir, "slotDir"
   if slotDir~hasEntry("REXXCOMPILEDSCRIPT") then
      rse=slotDir~RexxCompiledScript~getRexxScriptEngine
   else
      rse=slotDir~RexxScriptEngine

   if slotDir~hasEntry("RexxCompiledScript") then
       say tab "---> fetched RexxScriptEngine via slotDir's 'RexxCompiledScript' entry, then '~getRexxScriptEngine'"
   else
       say tab "---> fetched RexxScriptEngine via slotDir's 'RexxScriptEngine' entry"

   say tab "---> RexxEngine:" pp(rse) "--->" "BSFEngine:" pp(rse~getBSFRexxEngine) "---> rii_id:" pp(rse~getBSFRexxEngine~get_rii_id) "<---"

   if slotDir~hasEntry("RexxCompiledScript") then
       rse=rse~toString "(via RexxCompiledScript entry)"
end


  -- get and save all entries in GLOBAL_SCOPE in .my.app, entry name is the FXML file name
  -- (FXMLLoader places all JavaFX objects with a fx:id into the GLOBAL_SCOPE Bindings)
url= scriptContext~getAttribute("location", .jsr223~global_scope)
if bDebug then say "location:" pp(url~toString) "getFile:" pp(filespec("name",url~getFile)) -- make sure we get the file-name only
fxmlFileName=filespec("name",url~getFile)      -- get filename, make sure we get unqualified file-name
dir2obj =.directory~new         -- all GLOBAL_SCOPE entries, mapping uppercase attribute names to Java-values
.my.app~setEntry(fxmlFileName, dir2obj)

bindings=.jsr223~getBindings(scriptContext,.jsr223~global_scope)  -- get the Bindings for the global scope
keys=bindings~keySet~makearray -- get the kay values as a Rexx array
do key over keys
	val=bindings~get(key)       -- fetch the key's value
	if \.my.app~keepCapitalizationInDirKey then
		key = key~upper					 -- translate the KEY to uppercase
	dir2obj ~put(val,key)      -- save it in our directory
end

if bDebug then
do
      /* show the currently defined attributes in all ScriptContext's scopes   */
   say "getting all attributes from all ScriptContext's scopes..."
   dir=.directory~new
   dir[.jsr223~engine_scope]="ENGINE_SCOPE"
   dir[.jsr223~global_scope]="GLOBAL_SCOPE"
   arr=.array~of(.jsr223~engine_scope, .jsr223~global_scope)
   do sc over arr
       say "ScriptContext scope:" pp(sc) "("dir~entry(sc)"), available attributes:"
       bin=.jsr223~getBindings(scriptContext,sc)
       if bin=.nil then iterate -- inexistent scope
       keys=bin~keySet          -- get kay values
       it=keys~makearray        -- get the keys as a Rexx array
       do key over it~sortWith(.CaselessComparator~new) -- sort keys (attributes) caselessly
          val=bin~get(key)      -- fetch the key's value
          str=""
          if val~isA(.bsf) then str="~toString:" pp(val~toString)
          say "  " pp(key)~left(35,".") pp(val) str
       end
       say "-"~copies(79)
   end
end

if bDebug then
do
   say .dateTime~new " <== <--- returning from program '"thisProg"'."
   say
end


/*
      ------------------------ Apache Version 2.0 license -------------------------
         Copyright 2016 Rony G. Flatscher

         Licensed under the Apache License, Version 2.0 (the "License");
         you may not use this file except in compliance with the License.
         You may obtain a copy of the License at

             http://www.apache.org/licenses/LICENSE-2.0

         Unless required by applicable law or agreed to in writing, software
         distributed under the License is distributed on an "AS IS" BASIS,
         WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
         See the License for the specific language governing permissions and
         limitations under the License.
      -----------------------------------------------------------------------------
*/
