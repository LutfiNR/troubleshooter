class_name MariaDBDatabase extends Resource
@export var db_name: String = ""

func verify_configuration(correct_db: MariaDBDatabase) -> Dictionary:
	if not correct_db:
		return { "status": false }
	var is_correct = db_name == correct_db.db_name
	return { "status": is_correct, "db_name": { "status": is_correct } }
