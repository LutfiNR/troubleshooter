extends Tree

const COLOR: Dictionary = {
	false: Color.CRIMSON,
	true: Color.GREEN,
}

func _ready() -> void:
	clear()
	populate_ui_tree()
	NetworkDeviceManager.device_updated.connect(_on_device_updated)

func _on_device_updated(_device_id: String) -> void:
	clear()
	populate_ui_tree()

func populate_ui_tree() -> void:
	var root = create_item()
	var data = MissionManager.get_mission_tree_data()
	for dev in data.keys():
		_populate_device(root, data[dev])

# --- Helper Functions ---
func _create_tree_item(parent: TreeItem, text: String, status: bool = true, collapsed: bool = false) -> TreeItem:
	var item = create_item(parent)
	item.set_text(0, text)
	item.set_custom_color(0, COLOR.get(status))
	item.collapsed = collapsed
	return item

func _add_verify_item(parent: TreeItem, label: String, data: Dictionary) -> void:
	_create_tree_item(parent, "%s [%s]" % [label, str(data["correct"])], data["status"])

func _create_section(parent: TreeItem, title: String) -> TreeItem:
	return _create_tree_item(parent, title)

func _set_section_status(tree: TreeItem, status: bool) -> void:
	tree.set_custom_color(0, COLOR.get(status))

# --- Core Population Logic ---
func _populate_device(parent: TreeItem, device: Dictionary) -> void:
	var tree = _create_tree_item(parent, device["device_id"], device["status"], true)
	_populate_device_power(tree, device.get("power", {}))
	_populate_device_hostname(tree, device.get("hostname", {}))
	if device.has("ip_allocation"):
		_add_verify_item(tree, "IP Allocation", device["ip_allocation"])
	if device.has("total_ports"):
		_add_verify_item(tree, "Total Ports", device["total_ports"])
	if device.has("dns") and device.has("gateway"):
		_add_verify_item(tree, "Def Gateway", device["gateway"])
		_add_verify_item(tree, "IP DNS", device["dns"])
	if device.get("interfaces", {}).has("results"):
		_populate_interfaces(tree, device.get("interfaces"))
	if device.get("dhcp_relays", {}).has("results"):
		_populate_dhcp_relays(tree, device.get("dhcp_relays"))

	var services: Dictionary = {
		"dhcp_service": "DHCP",
		"dns_service": "DNS",
		"web_service": "Web",
		"ftp_service": "FTP",
		"remote_service": "Remote",
		"samba_service": "Samba",
		"mariadb_service": "MariaDB",
		"mail_service": "Mail",
	}
	for key in services:
		if device.has(key) \
		and device[key].has("details") \
		and not device[key]["details"].is_empty():
			_populate_server_service(tree, services[key], device[key])

# --- General Config ---
func _populate_device_hostname(parent: TreeItem, hostname: Dictionary) -> void:
	_add_verify_item(parent, "Hostname", hostname)

func _populate_device_power(parent: TreeItem, power: Dictionary) -> void:
	_create_tree_item(parent, "%s [%s]" % ["State", power["correct"]], power["status"])

func _populate_interfaces(parent: TreeItem, interfaces: Dictionary) -> void:
	var iface_tree = _create_tree_item(parent, "Interfaces", interfaces["status"], true)
	for iface in interfaces["results"]:
		_populate_interface(iface_tree, iface, interfaces["results"][iface])

func _populate_interface(parent: TreeItem, id: String, interface: Dictionary) -> void:
	var i_tree = _create_tree_item(parent, id, interface["status"])
	_create_tree_item(i_tree, "%s [%s]" % ["State", interface["state"]["correct"]], interface["state"]["status"])
	_add_verify_item(i_tree, "MAC Address", interface["mac_address"])
	
	if interface.get("ip", {}).has("address"):
		_add_verify_item(i_tree, "IP Address", interface["ip"]["address"])
		_add_verify_item(i_tree, "Subnet Mask", interface["ip"]["subnet_mask"])

# --- Server Config ---
func _populate_server_service(parent: TreeItem, service_name: String, service_result: Dictionary) -> void:
	var service_tree = _create_tree_item(parent, "%s Service" % service_name, service_result["status"], true)
	_create_tree_item(service_tree, "%s [%s]" % ["State", service_result["service_state"]["correct"]], service_result["service_state"]["status"])

	var details = service_result.get("details", {})
	match service_name:
		"DHCP": _populate_dhcp_service_details(service_tree, details)
		"DNS": _populate_dns_service_details(service_tree, details)
		"Web": _populate_web_service_details(service_tree, details)
		"FTP": _populate_ftp_service_details(service_tree, details)
		"Remote": _populate_remote_service_details(service_tree, details)
		"Samba": _populate_samba_service_details(service_tree, details)
		"MariaDB": _populate_mariadb_service_details(service_tree, details)
		"Mail": _populate_mail_service_details(service_tree, details)

func _populate_users(parent: TreeItem, users: Dictionary, show_home_directory := false, title: String = "Users") -> void:
	var users_tree = create_item(parent)
	users_tree.set_text(0, title)
	var status := true
	
	for username in users:
		var user_data = users[username]
		var user_tree = _create_tree_item(users_tree, username, user_data["status"], true)
		status = status and user_data["status"]
		
		_add_verify_item(user_tree, "Username", user_data["username"])
		_add_verify_item(user_tree, "Password", user_data["password"])
		if show_home_directory:
			_add_verify_item(user_tree, "Home Directory", user_data["home_directory"])
			
	users_tree.set_custom_color(0, COLOR.get(status))

# Router config
func _populate_dhcp_relays(parent: TreeItem, dhcp_relays: Dictionary) -> void:
	var relays_tree = _create_tree_item(parent, "DHCP Relays", dhcp_relays["status"], true)
	for relay_id in dhcp_relays["results"]:
		var relay_data = dhcp_relays["results"][relay_id]
		var r_tree = _create_tree_item(relays_tree, relay_id, relay_data["status"])
		_add_verify_item(r_tree, "Interface ID", relay_data["interface_id"])
		# IP Address verification inside the relay
		if relay_data.has("ip_address") and relay_data["ip_address"].has("address"):
			_add_verify_item(r_tree, "IP Address", relay_data["ip_address"]["address"])

# --- Service Specific Details ---
func _populate_dhcp_service_details(parent: TreeItem, pools: Dictionary) -> void:
	var pools_tree = create_item(parent)
	pools_tree.set_text(0, "DHCP Pool")
	var status = true
	
	for pool in pools:
		var pool_data = pools[pool]
		var pool_tree = _create_tree_item(pools_tree, pool, pool_data["status"], true)
		status = status and pool_data["status"]

		_add_verify_item(pool_tree, "Pool Name", pool_data["pool_name"])
		_add_verify_item(pool_tree, "Start Ip Address", pool_data["start_ip_address"])
		_add_verify_item(pool_tree, "Subnet Mask", pool_data["subnet_mask"])
		_add_verify_item(pool_tree, "Default Gateway", pool_data["default_gateway"])
		_add_verify_item(pool_tree, "DNS Server", pool_data["dns_server"])
		_add_verify_item(pool_tree, "Pool Size", pool_data["pool_size"])
		
	pools_tree.set_custom_color(0, COLOR.get(status))

func _populate_dns_service_details(parent: TreeItem, records: Dictionary) -> void:
	var records_tree = create_item(parent)
	records_tree.set_text(0, "DNS Record")
	var status = true
	
	for record in records:
		var record_data = records[record]
		var dns_tree = _create_tree_item(records_tree, record, record_data["status"], true)
		status = status and record_data["status"]

		_add_verify_item(dns_tree, "Domain Name", record_data["domain_name"])
		_add_verify_item(dns_tree, "Type", record_data["type"])
		_add_verify_item(dns_tree, "Target", record_data["target"])
		
	records_tree.set_custom_color(0, COLOR.get(status))

func _populate_web_service_details(parent: TreeItem, vhosts: Dictionary) -> void:
	var vhost_tree = create_item(parent)
	vhost_tree.set_text(0, "VHosts")
	var status = true
	
	for vhost in vhosts:
		var vhost_data = vhosts[vhost]
		var web_tree = _create_tree_item(vhost_tree, vhost, vhost_data["status"], true)
		status = status and vhost_data["status"]

		_add_verify_item(web_tree, "Domain Name", vhost_data["name"])
		_add_verify_item(web_tree, "Protocol", vhost_data["protocol"])
		_add_verify_item(web_tree, "Server Name", vhost_data["server_name"])
		_add_verify_item(web_tree, "Root Directory", vhost_data["document_root"])
		
	vhost_tree.set_custom_color(0, COLOR.get(status))

func _populate_ftp_service_details(parent: TreeItem, details: Dictionary) -> void:
	_add_verify_item(parent, "FTPS State", details["ftps_state"])
	_add_verify_item(parent, "Local Enable", details["local_enable"])
	_add_verify_item(parent, "Anonymous Enable", details["anonymous_enable"])
	_add_verify_item(parent, "Write Enable", details["write_enable"])
	_populate_users(parent, details["users"], true)
	
func _populate_remote_service_details(parent: TreeItem, details: Dictionary) -> void:
	_add_verify_item(parent, "Telnet State", details["telnet_state"])
	_add_verify_item(parent, "SSH State", details["ssh_state"])
	_add_verify_item(parent, "SSH Port", details["ssh_port"])
	_add_verify_item(parent, "Permit Root Login", details["permit_root_login"])
	_populate_users(parent, details["users"])

func _populate_samba_service_details(parent: TreeItem, details: Dictionary) -> void:
	_populate_users(parent, details["users"])

	var shares_tree = create_item(parent)
	shares_tree.set_text(0, "Shares")
	var shares_status := true
	
	for share_name in details["shares"]:
		var share_data: Dictionary = details["shares"][share_name]
		var share_tree = _create_tree_item(shares_tree, share_name, share_data["status"], true)
		shares_status = (shares_status and share_data["status"])

		_add_verify_item(share_tree, "Share Name", share_data["share_name"])
		_add_verify_item(share_tree, "Folder Path", share_data["folder_path"])
		_add_verify_item(share_tree, "Writeable", share_data["writeable"])
		_add_verify_item(share_tree, "Guest OK", share_data["guest_ok"])
		_add_verify_item(share_tree, "Security", share_data["security"])

		# Reuse user populator for Valid Users
		_populate_users(share_tree, share_data["valid_users"], false, "Valid Users")

	shares_tree.set_custom_color(0, COLOR.get(shares_status))

func _populate_mariadb_service_details(parent: TreeItem, details: Dictionary) -> void:
	_add_verify_item(parent, "Root Password", details["root_password"])

	# Databases
	var databases_tree = create_item(parent)
	databases_tree.set_text(0, "Databases")
	var databases_status := true

	for db_name in details["databases"]:
		var db_data: Dictionary = details["databases"][db_name]
		_create_tree_item(databases_tree, db_name, db_data["status"], true)
		databases_status = databases_status and db_data["status"]
		# Adding children to the newly created DB tree (fetch last child added)
		var db_tree = databases_tree.get_child(databases_tree.get_child_count() - 1)
		_add_verify_item(db_tree, "Database Name", db_data["db_name"])

	databases_tree.set_custom_color(0, COLOR.get(databases_status))

	# Users
	var users_tree = create_item(parent)
	users_tree.set_text(0, "Users")
	var users_status := true

	for username in details["users"]:
		var user_data: Dictionary = details["users"][username]
		var user_tree = _create_tree_item(users_tree, username, user_data["status"], true)
		users_status = users_status and user_data["status"]

		_add_verify_item(user_tree, "Username", user_data["username"])
		_add_verify_item(user_tree, "Password", user_data["password"])

		var privileges_tree = create_item(user_tree)
		privileges_tree.set_text(0, "Privileges")
		var privileges_status := true

		for db_name in user_data["privileges"]:
			var privilege_data: Dictionary = user_data["privileges"][db_name]
			var formatted_text = "%s [%s]" % [db_name, ", ".join(privilege_data["correct"])]
			_create_tree_item(privileges_tree, formatted_text, privilege_data["status"])
			privileges_status = privileges_status and privilege_data["status"]

		privileges_tree.set_custom_color(0, COLOR.get(privileges_status))
	users_tree.set_custom_color(0, COLOR.get(users_status))
	
func _populate_mail_service_details(parent: TreeItem, details: Dictionary) -> void:
	_add_verify_item(parent, "Domain Name", details["domain_name"])
	_add_verify_item(parent, "Mailbox Format", details["mailbox_format"])
	_add_verify_item(parent, "Use SSL/TLS", details["use_ssl_tls"])
	_populate_users(parent, details["users"])
