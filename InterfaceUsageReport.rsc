# Script name: InterfaceTrafficUsageReport
#
#----------SCRIPT INFORMATION---------------------------------------------------
#
# Script:  Mikrotik RouterOS automatic interfaces traffic usage report
# Version: 22.07.15
# Created: 01/09/2023
# Updated: 01/10/2023
# Author:  Pourya Sharifi & Hossein Yeganeh
# Website: https://github.com/pouryash
# You can contact me by e-mail at pouryasharifi78@mail.com
#
# IMPORTANT!
# Minimum supported RouterOS version is v6.43.7
#
#----------MODIFY THIS SECTION AS NEEDED----------------------------------------
## Notification e-mail
## (Make sure you have configurated Email settings in Tools -> Email)
{
:local SMP "traffic analysis"
:local emailAddress "yourmail@example.com";
:local mailSubject  "Mikrotik RouterOS Interfaces Traffic Report";
:local mailBody;
:local mailBodyHeader "Mikrotik interface's traffic usage script were created and attached to this email.";
:local mailBodyCopyright 	"\r\n\r\nMikrotik RouterOS automatic interface report usage \r\nhttps://github.com/pouryash/Mikrotik-RouterOS-automatic-interfaces-traffic-usage-report";
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
:local exportDate              [/system clock get value-name=date];
:local exportTime              [/system clock get value-name=time];

#careate date time without delimiter
:local datetime;
:local month [:tostr ([:find "janfebmaraprmayjunjulaugsepoctnovdec" [:pick $exportDate 0 3]]/3+1)]
  :if ([:tonum $month]<10) do={
    :set month "0$month"
  }
  :set datetime ( \
    [:pick $exportDate 9 11].$month.[:pick $exportDate 4 6]."_". \
    [:pick $exportTime 0 2].[:pick $exportTime 3 5].[:pick $exportTime 6 8] \
  )
  
:local mailAttachmentsName              "TR_$deviceIdentityName_$datetime.txt"
:local mailBodyDeviceInfo	"\r\n\r\nDevice information: \r\nIdentity: $deviceIdentityName \r\nModel: $deviceRbModel \r\nSerial number: $deviceRbSerialNumber \r\nCurrent RouterOS: $deviceOsVerInst ($[/system package update get channel]) $[/system resource get build-time] \r\nCurrent routerboard FW: $deviceRbCurrentFw \r\nDevice uptime: $[/system resource get uptime] \r\nExport date: $exportDate $exportTime";

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

}

#add report generating time
:set $result "$mailSubject\n$mailBodyDeviceInfo\n$result"

:set mailBody "$mailBodyHeader\n$mailBodyCopyright\n$mailBodyDeviceInfo";

# Create file.
    /file print file=$mailAttachmentsName
# Set file's content.
    /file set $mailAttachmentsName contents=$result


##
## SENDING EMAIL
##
# Trying to send email with backups in attachment.


	:log info "$SMP Sending email message, it will take around half a minute...";
	:do {/tool e-mail send to=$emailAddress subject=$mailSubject body=$mailBody file=$mailAttachmentsName;} on-error={
		:delay 5s;
		:log error "$SMP could not send email message ($[/tool e-mail get last-status]). Going to try it again in a while."

		:delay 5s;

		:do {/tool e-mail send to=$emailAddress subject=$mailSubject body=$mailBody file=$mailAttachmentsName;} on-error={
			:delay 5s;
			:log error "$SMP could not send email message ($[/tool e-mail get last-status]) for the second time."

		}
	}
	
	:delay 30s;
	
	:if ([:len $mailAttachmentsName] > 0 and [/tool e-mail get last-status] = "succeeded") do={
		:log info "$SMP File system cleanup."
		/file remove $mailAttachmentsName; 
		:delay 2s;
	}

}

}
