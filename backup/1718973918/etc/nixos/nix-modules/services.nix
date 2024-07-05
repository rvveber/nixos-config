{ config, ... }:

{
	systemd.user.services.login-init = {
		description = "A service for executing scripts after login"
}
