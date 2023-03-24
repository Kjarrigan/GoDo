# GoDo

A simple **Go**dot To**Do** app inspired by quire.io, which is unfortunately not available as self-hosted service. 
You can nest as deeply as you want, there is no hardcoded limit.

## Controls

1. <kbd>Enter</kbd> - Create a new entry on the same level as the selected item (or top level if nothing is selected)
2. <kbd>⇧ Shift</kbd> + <kbd>Enter</kbd> - Create a new entry on as child-task of the selected item (or top level if nothing is selected)
3. <kbd>LBM</kbd> Select an item
4. <kbd>LBM</kbd> Deselect the active item
5. **[not yet implemented]** `Drag & Drop` items to reorder and/or regroup them

## Storage

Data is loaded and saved automatically in user://godo.json, ẁith `user://` being depend of the OS. For linux it's
`~/.local/share/godot/app_userdata/GoDo/godo.json`

