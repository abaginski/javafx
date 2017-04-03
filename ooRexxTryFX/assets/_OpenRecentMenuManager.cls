::class OpenRecentMenuManager public
  /* this method will load the 5 latest files to the open recent menu */
::method init
  expose desiredItems OpenRecentMenu config
  use arg desiredItems=5
  OpenRecentMenu = .my.app~ooRexxTryFX.fxml~openRecentMenu
  config = .stream~new("assets/recent_files.conf")
  self~loadMenu

::method loadMenu
  expose desiredItems OpenRecentMenu config
  config~open
  itemlist = .array~new
  OpenRecentMenu~getItems~remove(0, OpenRecentMenu~getItems~size) -- arguments: from index, to index
  do i=1 to config~lines
    filepath = config~lineIn
    itemlist~insert(filepath)
    MenuItem = .bsf~new("javafx.scene.control.MenuItem", filepath)
    rexxproxy = bsfCreateRexxProxy(.openFile~new(filepath,self),,"javafx.event.EventHandler")
    MenuItem~setOnAction(rexxproxy)   -- attach an event handler to open the desired file and update the "open recent" Menu
    OpenRecentMenu~items~add(MenuItem)
  end
  config~close
  .my.app~openRecentItemList = itemlist   -- save the array in the main directory, in case new files get opened or stored later on


/* this method will put the new item to the menu, update the config file "recent_files.conf" and rearrange the order of the items */
::method updateMenu
  expose desiredItems OpenRecentMenu config
  use arg newItem
  config~open("write replace")      -- open the stream to start writing at position 1 of the document
  config~lineOut(newItem)           -- write the latest filepath in the first line
  do i=1 to desiredItems-1          -- shift the array by 1 item
      item = .my.app~openRecentItemList~at(i)
      if item <> "" & item <> .nil then   -- only write to stream if the entry is not empty
         config~lineOut(item)
  end
  config~close
  self~loadMenu


::class openFile public
::method init
  expose filepath OpenRecentMenuManager
  use arg filepath, OpenRecentMenuManager
::method handle
  expose filepath OpenRecentMenuManager
  if \SysFileExists(filepath) then return
  slotDir = .directory~new
  slotDir~userData = .directory~new
  slotDir~userData~useSpecificFile = filepath
  call loadFile slotDir
  OpenRecentMenuManager~updateMenu(filepath)

::requires "fxml/ooRexxTryFXController.rxj"     -- used by "call loadFile .." in class "openFile"