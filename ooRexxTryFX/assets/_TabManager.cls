::class TabManager public
/* variable initialisation */
::method init
  expose allTabs TabPane alreadySavedFilepaths
  TabPane = .my.app~ooRexxTryFX.fxml~TabPane
  allTabs = .array~new
  allTabs~insert(TabPane~getTabs~get(0))
  alreadySavedFilepaths = .array~new


::method getInputArea
    Tab = self~getCurrentTab
    TabAnchorPane = Tab~content                      -- get a reference to the AnchorPane
    TextArea = TabAnchorPane~children~get(0)         -- the textarea is always the first element in the anchorpane
    return TextArea

/**
 ** this method returns a reference of the current tab
 **/
::method getCurrentTab
  expose allTabs
  currentTabIndex = self~getTabIndex()
  Tab = allTabs~at( currentTabIndex + 1 )
  return Tab

/**
 ** this method checks if there is a path assigned for this tab to skip open/save file chooser dialogs
 ** returns the path or a .nil object
 **/
::method alreadySavedFile
  expose allTabs alreadySavedFilepaths
  currentTabIndex = self~getTabIndex()
  alreadySavedFilepath = alreadySavedFilepaths~at( currentTabIndex + 1 )
  return alreadySavedFilepath


::method saveFilepath
  expose allTabs alreadySavedFilepaths
  use arg filepath
  currentTabIndex = self~getTabIndex()
  alreadySavedFilepaths~put(filepath, currentTabIndex+1)


/**
 ** this method returns the 0-based index of the current tab
 **/
::method getTabIndex
  expose TabPane
  SelectionModel = TabPane~getSelectionModel
  TabIndex = SelectionModel~getSelectedIndex
  return TabIndex

::requires bsf.cls