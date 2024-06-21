{ config, ... }:

{
	boot.resumeDevice = "/dev/dm-0";
	boot.kernelParams = [
		"resume_offset=10134041"
	];
}
