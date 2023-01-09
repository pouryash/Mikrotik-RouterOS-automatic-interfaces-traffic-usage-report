{
:local SMP "traffic analysis"
:local emailAddress "yourmail@example.com";
:local mailSubject  "Traffic Usage Report";
:local mailBody;
:local mailBodyHeader "Mikrotik interface's traffic usage script were created and attached to this email.";
:local mailBodyCopyright 	"\r\n\r\nMikrotik RouterOS automatic backup & update (ver. $scriptVersion) \r\nhttps://github.com/beeyev/Mikrotik-RouterOS-automatic-backup-and-update";
:local deviceOsVerInst 			[/system package update get installed-version];
:local deviceOsVerInstNum 		[$buGlobalFuncGetOsVerNum paramOsVer=$deviceOsVerInst];
:local deviceOsVerAvail 		"";
:local deviceOsVerAvailNum 		0;
:local deviceRbModel			[/system routerboard get model];
:local deviceRbSerialNumber 	[/system routerboard get serial-number];
:local deviceRbCurrentFw 		[/system routerboard get current-firmware];
:local deviceRbUpgradeFw 		[/system routerboard get upgrade-firmware];
:local deviceIdentityName 		[/system identity get name];
:local deviceIdentityNameShort 	[:pick $deviceIdentityName 0 18]
:local deviceUpdateChannel 		[/system package update get channel];

:local mailBodyDeviceInfo	"\r\n\r\nDevice information: \r\nIdentity: $deviceIdentityName \r\nModel: $deviceRbModel \r\nSerial number: $deviceRbSerialNumber \r\nCurrent RouterOS: $deviceOsVerInst ($[/system package update get channel]) $[/system resource get build-time] \r\nCurrent routerboard FW: $deviceRbCurrentFw \r\nDevice uptime: $[/system resource get uptime]";

:local iname;
:local idefName;
:local monitor;
:local rxBytes;
:local txBytes;
:local mbpsRX;
:local mbpsTX;
:local total;
:local result;
:foreach interface in=[/interface find] do={
:set $iname [/interface get $interface name];
:set $monitor [/interface get [find name=$iname]];
:set $idefName ($monitor->"default-name");
:set $rxBytes ($monitor->"rx-byte");
:set $txBytes ($monitor->"tx-byte");
:set $mbpsRX (($rxBytes/1024)/1024);
:set $mbpsTX (($txBytes/1024)/1024);
:set $total (($mbpsTX+$mbpsRX));
:set $result "$result\n\nInterface: $idefName\nName: $iname\nDownload: $mbpsRX MB\nUpload: $mbpsTX MB\nTotal: $total MB";

:set mailBody "$mailBodyHeader\n\n$mailBodyDeviceInfo\n\n$result";

}
# Create file.
#    /file print file=$filename
# Set file's content.
#    /file set $filename contents=$content

##
## SENDING EMAIL
##
# Trying to send email with backups in attachment.


	:log info "$SMP Sending email message, it will take around half a minute...";
	:do {/tool e-mail send to=$emailAddress subject=$mailSubject body=$mailBody;} on-error={
		:delay 5s;
		:log error "$SMP could not send email message ($[/tool e-mail get last-status]). Going to try it again in a while."

		:delay 5s;

		:do {/tool e-mail send to=$emailAddress subject=$mailSubject body=$mailBody} on-error={
			:delay 5s;
			:log error "$SMP could not send email message ($[/tool e-mail get last-status]) for the second time."

		}
	}

	:delay 30s;
	
	:if ([/tool e-mail get last-status] = "succeeded") do={
		:log info "$SMP File system cleanup."
		/file remove $mailAttachments; 
		:delay 2s;
	}
	
}

}
