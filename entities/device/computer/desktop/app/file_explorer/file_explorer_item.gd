extends Resource
class_name FileExplorerItem

enum ItemType{
	FOLDER,
	FILE
}

@export var type: ItemType
@export var file_or_folder_name: String
