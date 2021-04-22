#------------------------------------------------------------------------------
# FILE:         action.ps1
# CONTRIBUTOR:  Jeff Lill
# COPYRIGHT:    Copyright (c) 2005-2021 by neonFORGE LLC.  All rights reserved.
#
# The contents of this repository are for private use by neonFORGE, LLC. and may not be
# divulged or used for any purpose by other organizations or individuals without a
# formal written and signed agreement with neonFORGE, LLC.

# Verify that we're running on a properly configured neonFORGE jubrunner 
# and import the deployment and action scripts from neonCLOUD.
      
# NOTE: This assumes that the required [$NC_ROOT/Powershell/*.ps1] files
#       in the current clone of the repo on the runner are up-to-date
#       enough to be able to obtain secrets and use GitHub Action functions.
#       If this is not the case, you'll have to manually pull the repo 
#       first on the runner.
      
$ncRoot = $env:NC_ROOT
      
if (![System.IO.Directory]::Exists($ncRoot))
{
    throw "Runner Config: neonCLOUD repo is not present."
}
      
$ncPowershell = [System.IO.Path]::Combine($ncRoot, "Powershell")
      
Push-Location $ncPowershell
. ./includes.ps1
Pop-Location
      
# Fetch the credentials
      
$masterPassword = $env:MASTER_PASSWORD

if ($masterPassword -eq $null)
{
    throw "MASTER_PASSWORD is required."
}

$username    = GetSecretValue "NEONFORGE_LOGIN[username]" -MasterPassword $masterPassword
$password    = GetSecretPassword "SMTP_PASSWORD" -MasterPassword $masterPassword
$credentials = New-Object -TypeName System.Net.NetworkCredential -ArgumentList $username, $password
      
# Fetch the inputs
      
$to          = "${{ inputs.to }}"
$cc          = "${{ inputs.cc }}"
$bcc         = "${{ inputs.bcc }}"
$subject     = "${{ inputs.subject }}"
$body        = "${{ inputs.body }}"
$bodyAsHtml  = "${{ inputs.bodyAsHtml }}"
$attachment0 = "${{ inputs.attachment0 }}"
$attachment1 = "${{ inputs.attachment1 }}"
$attachment2 = "${{ inputs.attachment2 }}"
$attachment3 = "${{ inputs.attachment3 }}"
$attachment4 = "${{ inputs.attachment4 }}"
$attachment5 = "${{ inputs.attachment5 }}"
$attachment6 = "${{ inputs.attachment6 }}"
$attachment7 = "${{ inputs.attachment7 }}"
$attachment8 = "${{ inputs.attachment8 }}"
$attachment9 = "${{ inputs.attachment9 }}"
     
# Construct the email message

$message = New-Object System.Net.Mail.MailMessage
      
if ([System.String]::IsNullOrEmpty($to))
{
    throw "The [to] argument cannot be null or empty."
}
        
ForEach ($address in $to.Split(",", [System.StringSplitOptions]::RemoveEmptyEntries))
{
    $address = $address.Trim()
    if ($address -ne "")
    {
        $address = New-Object -TypeName System.Net.Mail.MailAddress -ArgumentList $address
        $message.To.Add($address)
    }
}
      
if (![System.String]::IsNullOrEmpty($cc))
{
    ForEach ($address in $cc.Split(",", [System.StringSplitOptions]::RemoveEmptyEntries))
    {
        $address = $address.Trim()
        if ($address -ne "")
        {
            $address = New-Object -TypeName System.Net.Mail.MailAddress -ArgumentList $address
            $message.CC.Add($address)
        }
    }
}
      
if (![System.String]::IsNullOrEmpty($bcc))
{
    ForEach ($address in $bcc.Split(",", [System.StringSplitOptions]::RemoveEmptyEntries))
    {
        $address = $address.Trim()
        if ($address -ne "")
        {
            $address = New-Object -TypeName System.Net.Mail.MailAddress -ArgumentList $address
            $message.Bcc.Add($address)
        }
    }
}
      
$message.From       = New-Object -TypeName System.Net.Mail.MailAddress -ArgumentList $username
$message.Subject    = $subject
$message.Body       = $body
$message.IsBodyHtml = $bodyAsHtml
      
# Add any attachments
      
$attachments = New-Object -TypeName System.Collections.ArrayList
      
function AddAttachment
{ 
    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=0)]
        [string]$attachmentPath = $null
    )
          
    if (![System.String]::IsNullOrEmpty($attachmentPath))
    {
        if (![System.IO.File]::Exists($attachmentPath))
        {
            throw "Attachment file [$attachmentPath] does not exist."
        }
          
        $fileMode         = [System.IO.FileMode]::Open
        $fileAccess       = [System.IO.FileAccess]::Read
        $stream           = New-Object -TypeName System.IO.FileStream -ArgumentList $attachmentPath, $fileMode, $fileAccess
        $contentType      = New-Object -TypeName System.Net.Mime.ContentType
        $contentType.Name = [System.IO.Path]::GetFileName($attachmentPath)
        $attachment       = New-Object -TypeName System.Net.Mail.Attachment -ArgumentList $stream, $contentType
              
        $message.Attachments.Add($attachment)
        $attachments.Add($attachment)
    }
}
      
AddAttachment $attachment0
AddAttachment $attachment1
AddAttachment $attachment2
AddAttachment $attachment3
AddAttachment $attachment4
AddAttachment $attachment5
AddAttachment $attachment6
AddAttachment $attachment7
AddAttachment $attachment8
AddAttachment $attachment9

# Send the message
        
$smtp             = New-Object Net.Mail.SmtpClient("smtp.office365.com", 587)
$smtp.Credentials = $credentials
$smtp.EnableSsl   = $true
$smtp.Send($message)
      
# Cleanup by disposing any attachments
      
ForEach ($attachment in $attachments)
{
    $attachment.Dispose()
}
 