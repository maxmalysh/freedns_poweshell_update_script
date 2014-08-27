###############################################################################
# This is a script I wrote for own use on Windows Server 2012R2.              #
#                                                                             #
# Don't forget to set your SHA key and email credentials.                     #
# Put empty line (it's "") into the "$sender_email" variable if you           #                    
# don't want to send notifications.                                           #
#                                                                             #
# Please note that script requires administrator rights to run as it stores   #
# data in registry.                                                           #
#                                                                             #
# iam@maxmalysh.com                                                           #
###############################################################################

$asterics = ("*" * 120) + "`n"

###############################################################################
#                                                                             #
#                    Some definitions (don't forget to set them)              #
#                                                                             #
###############################################################################

# You can get you SHA key here: http://freedns.afraid.org/api/ 
# Click "XML" or "ASCII" and copy-paste it from the address bar
$sha_key = "your_sha_key_here" 

# email credentials 
$smtpServer   = "smtp.gmail.com"
$sender_email = "example@gmail.com"
$password     = "examplePass"
$recipient_list = "example@gmail.com", "johndoe@gmail.com";

# Registry stuff (don't change this)
$hive      = "HKLM:\SOFTWARE\FreeDNS Script"
$hive_ip   = "IP"
$hive_date = "Update date"

###############################################################################
#                                                                             #
#                Creating registry entry (if it doesn't exist)                #
#                                                                             #
###############################################################################
$val = Get-ItemProperty $hive -ErrorAction SilentlyContinue
if ($val -eq $null) {
    Try {
        New-Item -Path "HKLM:\SOFTWARE" -Name 'FreeDNS Script' -ErrorAction Stop

        Set-ItemProperty -Path $hive -Name $hive_ip   -Value "0.0.0.0" -ErrorAction Stop
        Set-ItemProperty -Path $hive -Name $hive_date -Value "null"    -ErrorAction Stop
    }
    Catch [System.Security.SecurityException] {
        Write-Host "Error! We can't access registry."
        Write-Host "You have to run this script with administrator rights."
        exit -2
    }
}

###############################################################################
#                                                                             #
#                                 Getting ip                                  #
#                                                                             #
###############################################################################
Write-Host "Checking ip..."
$server_link = "http://checkip.dyndns.com"
$oldip = (Get-ItemProperty $hive).$hive_ip
$currentip = (New-Object net.webclient).downloadstring($server_link) -replace "[^\d\.]"

if ($currentip -eq $null) {
    Write-Host "Cannot get current ip!"
    exit -1
}

if ($oldip -eq $currentip) {
    Write-Host "IP has not changed."
    exit 0
}

###############################################################################
#                                                                             #
#                  Sending updates to the FreeDNS service...                  #
#                                                                             #
###############################################################################
Write-Host "Accessing FreeDNS API..."

Try {
    $url = "https://freedns.afraid.org/api/?action=getdyndns&sha=$sha_key&style=xml"
    $web = New-Object Net.WebClient
    $doc = New-Object System.Xml.XmlDocument
    $doc.Load($url) 
    $items = $doc.SelectNodes("/xml/item")
    
    foreach ($item in $items) {
        $response += $item.host    + "`n"
        $response += $item.address + "`n"
        $response += $item.url     + "`n"
        $response += "Response: $($web.DownloadString($item.url))" + "`n" 
    }
} 
Catch {
    $response = "Coudn't update ip using FreeDNS API! Error: " + "$($error[0])"
    Write-Host $response
}

$free_dns_response = $response


###############################################################################
#                                                                             #
#                                Sending emails                               #
#                                                                             #
###############################################################################
if ($sender_email -ne "") {
    # building up a message
    $dateString = $(Get-Date -format 'u')
    $subject = "Server IP has changed: $currentip" 
	$body  = $asterics
    $body += "Previous IP was $oldip `n" 
    $body += "New IP is $currentip `n"
    $body += "Date sent: $dateString `n"
	$body += $asterics
    $body += "FreeDNS response: `n`n" + $free_dns_response
	$body += $asterics
	
    # Sending the message to users
    foreach ($recipient in $recipient_list) {
        Write-Host "Sending an email notification to $recipient"
        $smtp = New-Object Net.Mail.SmtpClient($smtpServer, 587) 
        $smtp.EnableSsl   = $true 
        $smtp.Credentials = New-Object System.Net.NetworkCredential($sender_email, $password); 
        $smtp.Send($sender_email, $recipient, $subject, $body)
    }

    # Updating registry values
    Set-ItemProperty -Path $hive -Name $hive_ip   -Value $currentip
    Set-ItemProperty -Path $hive -Name $hive_date -Value $dateString
} 

