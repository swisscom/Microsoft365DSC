function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        [ValidateLength(1, 256)]
        $DisplayName,

        [Parameter()]
        [System.String]
        $GroupID,

        [Parameter()]
        [System.String]
        [ValidateLength(1, 1024)]
        $Description,

        [Parameter()]
        [System.String]
        $MailNickName,

        [Parameter()]
        [System.String[]]
        $Owner,

        [Parameter()]
        [System.String]
        [ValidateSet("Public", "Private")]
        $Visibility,

        [Parameter()]
        [System.Boolean]
        $AllowAddRemoveApps,

        [Parameter()]
        [System.Boolean]
        $AllowGiphy,

        [Parameter()]
        [ValidateSet("Strict", "Moderate")]
        [System.String]
        $GiphyContentRating,

        [Parameter()]
        [System.Boolean]
        $AllowStickersAndMemes,

        [Parameter()]
        [System.Boolean]
        $AllowCustomMemes,

        [Parameter()]
        [System.Boolean]
        $AllowUserEditMessages,

        [Parameter()]
        [System.Boolean]
        $AllowUserDeleteMessages,

        [Parameter()]
        [System.Boolean]
        $AllowOwnerDeleteMessages,

        [Parameter()]
        [System.Boolean]
        $AllowCreateUpdateRemoveConnectors,

        [Parameter()]
        [System.Boolean]
        $AllowCreateUpdateRemoveTabs,

        [Parameter()]
        [System.Boolean]
        $AllowCreateUpdateChannels,

        [Parameter()]
        [System.Boolean]
        $AllowDeleteChannels,

        [Parameter()]
        [System.Boolean]
        $AllowTeamMentions,

        [Parameter()]
        [System.Boolean]
        $AllowChannelMentions,

        [Parameter()]
        [System.Boolean]
        $AllowGuestCreateUpdateChannels,

        [Parameter()]
        [System.Boolean]
        $AllowGuestDeleteChannels,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount
    )
    Write-Verbose -Message "Getting configuration of Team $DisplayName"

    #region Telemetry
    $data = [System.Collections.Generic.Dictionary[[String], [String]]]::new()
    $data.Add("Resource", $MyInvocation.MyCommand.ModuleName)
    $data.Add("Method", $MyInvocation.MyCommand)
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $nullReturn = @{
        DisplayName                       = $DisplayName
        GroupId                           = $GroupID
        Description                       = $Description
        Owner                             = $Owner
        MailNickName                      = $MailNickName
        Visibility                        = $Visibility
        Ensure                            = "Absent"
        AllowAddRemoveApps                = $AllowAddRemoveApps
        AllowGiphy                        = $AllowGiphy
        GiphyContentRating                = $GiphyContentRating
        AllowStickersAndMemes             = $AllowStickersAndMemes
        AllowCustomMemes                  = $AllowCustomMemes
        AllowUserEditMessages             = $AllowUserEditMessages
        AllowUserDeleteMessages           = $AllowUserDeleteMessages
        AllowOwnerDeleteMessages          = $AllowOwnerDeleteMessages
        AllowCreateUpdateRemoveConnectors = $AllowCreateUpdateRemoveConnectors
        AllowCreateUpdateRemoveTabs       = $AllowCreateUpdateRemoveTabs
        AllowCreateUpdateChannels         = $AllowCreateUpdateChannels
        AllowDeleteChannels               = $AllowDeleteChannels
        AllowTeamMentions                 = $AllowTeamMentions
        AllowChannelMentions              = $AllowChannelMentions
        AllowGuestCreateUpdateChannels    = $AllowGuestCreateUpdateChannels
        AllowGuestDeleteChannels          = $AllowGuestDeleteChannels
        GlobalAdminAccount                = $GlobalAdminAccount
        ApplicationId                     = $ApplicationId
        TenantId                          = $TenantId
        CertificateThumbprint             = $CertificateThumbprint
    }

    Write-Verbose -Message "Checking for existence of Team $DisplayName"

    $ConnectionMode = $null
    if (-not [String]::IsNullOrEmpty($ApplicationId) -and `
        -not [String]::IsNullOrEmpty($TenantId) -and `
        -not [String]::IsNullOrEmpty($CertificateThumbprint))
    {
        Write-Verbose -Message "Connecting to Microsoft Teams using ApplicationId {$ApplicationId}"
        Test-MSCloudLogin -Platform MicrosoftTeams -ApplicationId $ApplicationId -TenantId $TenantId -CertificateThumbprint $CertificateThumbprint
        $ConnectionMode = "ServicePrincipal"
    }
    else
    {
        Write-Verbose -Message "Connecting to Microsoft Teams using Credentials"
        Test-MSCloudLogin -CloudCredential $GlobalAdminAccount `
            -Platform MicrosoftTeams
        $ConnectionMode = "Credential"
    }

    $CurrentParameters = $PSBoundParameters

    try
    {
        ## will only return 1 instance
        if ($CurrentParameters.ContainsKey("GroupID"))
        {
            $team = Get-Team -GroupId $GroupID
            if ($null -eq $team)
            {
                Write-Verbose -Message "Teams with GroupId $($GroupID) doesn't exist"
                return $nullReturn
            }
        }
        else
        {
            ## Can retreive multiple Teams since displayname is not unique
            $team = Get-Team -DisplayName $DisplayName
            if ($null -eq $team)
            {
                Write-Verbose -Message "Teams with displayname $DisplayName doesn't exist"
                return $nullReturn
            }
            if ($team.Length -gt 1)
            {
                throw "Duplicate Teams name $DisplayName exist in tenant"
            }
        }

        $Owners = Get-TeamUser -GroupId $team.GroupId | Where-Object { $_.Role -eq "owner" }
        $OwnersArray = @()
        if ($null -ne $Owners)
        {
            foreach ($owner in $Owners.User)
            {
                $OwnersArray += $owner[0].ToString()
            }
        }
        Write-Verbose -Message "Found Team $($team.DisplayName)."

        $result = @{
            DisplayName                       = $team.DisplayName
            GroupID                           = $team.GroupId
            Description                       = $team.Description
            Owner                             = $OwnersArray
            MailNickName                      = $team.MailNickName
            Visibility                        = $team.Visibility
            AllowAddRemoveApps                = $team.AllowAddRemoveApps
            AllowGiphy                        = $team.AllowGiphy
            GiphyContentRating                = $team.GiphyContentRating
            AllowStickersAndMemes             = $team.AllowStickersAndMemes
            AllowCustomMemes                  = $team.AllowCustomMemes
            AllowUserEditMessages             = $team.AllowUserEditMessages
            AllowUserDeleteMessages           = $team.AllowUserDeleteMessages
            AllowOwnerDeleteMessages          = $team.AllowOwnerDeleteMessages
            AllowCreateUpdateRemoveConnectors = $team.AllowCreateUpdateRemoveConnectors
            AllowCreateUpdateRemoveTabs       = $team.AllowCreateUpdateRemoveTabs
            AllowTeamMentions                 = $team.AllowTeamMentions
            AllowChannelMentions              = $team.AllowChannelMentions
            AllowGuestCreateUpdateChannels    = $team.AllowGuestCreateUpdateChannels
            AllowGuestDeleteChannels          = $team.AllowGuestDeleteChannels
            AllowCreateUpdateChannels         = $team.AllowCreateUpdateChannels
            AllowDeleteChannels               = $team.AllowDeleteChannels
            Ensure                            = "Present"
        }

        if ($ConnectionMode -eq "ServicePrincipal")
        {
            $result.Add("ApplicationId", $ApplicationId)
            $result.Add("TenantId", $TenantId)
            $result.Add("CertificateThumbprint", $CertificateThumbprint)
        }
        else
        {
            $result.Add("GlobalAdminAccount", $GlobalAdminAccount)
        }
        return $result
    }
    catch
    {
        Write-Verbose "Returning empty results due to error: $_"
        return $nullReturn
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        [ValidateLength(1, 256)]
        $DisplayName,

        [Parameter()]
        [System.String]
        $GroupID,

        [Parameter()]
        [System.String]
        [ValidateLength(1, 1024)]
        $Description,

        [Parameter()]
        [System.String]
        $MailNickName,

        [Parameter()]
        [System.String[]]
        $Owner,

        [Parameter()]
        [System.String]
        [ValidateSet("Public", "Private")]
        $Visibility,

        [Parameter()]
        [System.Boolean]
        $AllowAddRemoveApps,

        [Parameter()]
        [System.Boolean]
        $AllowGiphy,

        [Parameter()]
        [ValidateSet("Strict", "Moderate")]
        [System.String]
        $GiphyContentRating,

        [Parameter()]
        [System.Boolean]
        $AllowStickersAndMemes,

        [Parameter()]
        [System.Boolean]
        $AllowCustomMemes,

        [Parameter()]
        [System.Boolean]
        $AllowUserEditMessages,

        [Parameter()]
        [System.Boolean]
        $AllowUserDeleteMessages,

        [Parameter()]
        [System.Boolean]
        $AllowOwnerDeleteMessages,

        [Parameter()]
        [System.Boolean]
        $AllowCreateUpdateRemoveConnectors,

        [Parameter()]
        [System.Boolean]
        $AllowCreateUpdateRemoveTabs,

        [Parameter()]
        [System.Boolean]
        $AllowCreateUpdateChannels,

        [Parameter()]
        [System.Boolean]
        $AllowDeleteChannels,

        [Parameter()]
        [System.Boolean]
        $AllowTeamMentions,

        [Parameter()]
        [System.Boolean]
        $AllowChannelMentions,

        [Parameter()]
        [System.Boolean]
        $AllowGuestCreateUpdateChannels,

        [Parameter()]
        [System.Boolean]
        $AllowGuestDeleteChannels,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount
    )

    Write-Verbose -Message "Setting configuration of Team $DisplayName"

    #region Telemetry
    $data = [System.Collections.Generic.Dictionary[[String], [String]]]::new()
    $data.Add("Resource", $MyInvocation.MyCommand.ModuleName)
    $data.Add("Method", $MyInvocation.MyCommand)
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $ConnectionMode = $null
    if (-not [String]::IsNullOrEmpty($ApplicationId) -and `
                    -not [String]::IsNullOrEmpty($TenantId) -and `
                    -not [String]::IsNullOrEmpty($CertificateThumbprint))
    {
        $ConnectionMode = "ServicePrincipal"
    }
    else
    {
        $ConnectionMode = "Credential"
    }

    $team = Get-TargetResource @PSBoundParameters

    $CurrentParameters = $PSBoundParameters
    $CurrentParameters.Remove("Ensure")

    if ($Ensure -eq "Present" -and ($team.Ensure -eq "Present"))
    {
        ## Can't pass Owner parm into set opertaion
        if ($CurrentParameters.ContainsKey("Owner"))
        {
            $CurrentParameters.Remove("Owner")
        }
        if (-not $CurrentParameters.ContainsKey("GroupID"))
        {
            $CurrentParameters.Add("GroupID", $team.GroupID)
        }
        Set-Team @CurrentParameters
        Write-Verbose -Message "Updating team $DisplayName"
    }
    elseif ($Ensure -eq "Present" -and ($team.Ensure -eq "Absent"))
    {
        ## GroupID not used on New-Team cmdlet
        if ($CurrentParameters.ContainsKey("GroupID"))
        {
            $CurrentParameters.Remove("GroupID")
        }
        Write-Verbose -Message "Creating team $DisplayName"
        if ($null -ne $Owner)
        {
            $CurrentParameters.Owner = [array]$Owner[0]
        }

        if ($ConnectionMode -eq "ServicePrincipal")
        {
            Test-MSCloudLogin -Platform AzureAD -ApplicationId $ApplicationId -TenantId $TenantId -CertificateThumbprint $CertificateThumbprint
            $group = New-AzureADMSGroup -DisplayName $DisplayName -GroupTypes "Unified" -MailEnabled $true -SecurityEnabled $true -MailNickname $MailNickName
            $currentOwner = (($CurrentParameters.Owner)[0])
            Write-Verbose -Message "Retrieving Group Owner {$currentOwner}"
            $ownerUser = Get-AzureADUser -SearchString $currentOwner
            Write-Verbose -Message "Adding Owner {$($ownerUser.ObjectId)} to Group {$($group.Id)}"
            try
            {
                Add-AzureADGroupOwner -ObjectId $group.Id -RefObjectId $ownerUser.ObjectId -ErrorAction Stop
            }
            catch
            {
                Write-Verbose -Message "Adding Owner - Sleeping for 15 seconds"
                Start-Sleep -Seconds 15
                Add-AzureADGroupOwner -ObjectId $group.Id -RefObjectId $ownerUser.ObjectId
            }

            try
            {
                New-Team -GroupId $group.Id -ErrorAction Stop
            }
            catch
            {
                Write-Verbose -Message "Creating Team - Sleeping for 15 seconds"
                Start-Sleep -Seconds 15
                New-Team -GroupId $group.Id
            }
        }
        else
        {
            New-Team @CurrentParameters
        }
    }
    elseif ($Ensure -eq "Absent" -and ($team.Ensure -eq "Present"))
    {
        Write-Verbose -Message "Removing team $DisplayName"
        Remove-team -GroupId $team.GroupId
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        [ValidateLength(1, 256)]
        $DisplayName,

        [Parameter()]
        [System.String]
        $GroupID,

        [Parameter()]
        [System.String]
        [ValidateLength(1, 1024)]
        $Description,

        [Parameter()]
        [System.String]
        $MailNickName,

        [Parameter()]
        [System.String[]]
        $Owner,

        [Parameter()]
        [System.String]
        [ValidateSet("Public", "Private")]
        $Visibility,

        [Parameter()]
        [System.Boolean]
        $AllowAddRemoveApps,

        [Parameter()]
        [System.Boolean]
        $AllowGiphy,

        [Parameter()]
        [ValidateSet("Strict", "Moderate")]
        [System.String]
        $GiphyContentRating,

        [Parameter()]
        [System.Boolean]
        $AllowStickersAndMemes,

        [Parameter()]
        [System.Boolean]
        $AllowCustomMemes,

        [Parameter()]
        [System.Boolean]
        $AllowUserEditMessages,

        [Parameter()]
        [System.Boolean]
        $AllowUserDeleteMessages,

        [Parameter()]
        [System.Boolean]
        $AllowOwnerDeleteMessages,

        [Parameter()]
        [System.Boolean]
        $AllowCreateUpdateRemoveConnectors,

        [Parameter()]
        [System.Boolean]
        $AllowCreateUpdateRemoveTabs,

        [Parameter()]
        [System.Boolean]
        $AllowCreateUpdateChannels,

        [Parameter()]
        [System.Boolean]
        $AllowDeleteChannels,

        [Parameter()]
        [System.Boolean]
        $AllowTeamMentions,

        [Parameter()]
        [System.Boolean]
        $AllowChannelMentions,

        [Parameter()]
        [System.Boolean]
        $AllowGuestCreateUpdateChannels,

        [Parameter()]
        [System.Boolean]
        $AllowGuestDeleteChannels,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount
    )

    Write-Verbose -Message "Testing configuration of Team $DisplayName"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-M365DscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-M365DscHashtableToString -Hashtable $PSBoundParameters)"

    If (!$PSBoundParameters.ContainsKey('Ensure')) {
        $PSBoundParameters.Add('Ensure',$Ensure)
    }
    $ValuesToCheck = $PSBoundParameters
    $ValuesToCheck.Remove('GlobalAdminAccount') | Out-Null
    $ValuesToCheck.Remove('GroupID') | Out-Null

    if ($null -eq $CurrentValues.Owner)
    {
        $ValuesToCheck.Remove("Owner") | Out-Null
    }

    $TestResult = Test-Microsoft365DSCParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck $ValuesToCheck.Keys

    Write-Verbose -Message "Test-TargetResource returned $TestResult"

    return $TestResult
}

function Export-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount
    )
    $InformationPreference = 'Continue'

    #region Telemetry
    $data = [System.Collections.Generic.Dictionary[[String], [String]]]::new()
    $data.Add("Resource", $MyInvocation.MyCommand.ModuleName)
    $data.Add("Method", $MyInvocation.MyCommand)
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $ConnectionMode = $null
    if (-not [String]::IsNullOrEmpty($ApplicationId) -and `
        -not [String]::IsNullOrEmpty($TenantId) -and `
        -not [String]::IsNullOrEmpty($CertificateThumbprint))
    {
        Write-Verbose -Message "Connecting to Microsoft Teams using ApplicationId {$ApplicationId}"
        Test-MSCloudLogin -Platform MicrosoftTeams -ApplicationId $ApplicationId -TenantId $TenantId -CertificateThumbprint $CertificateThumbprint
        $ConnectionMode = "ServicePrincipal"
        $organization = Get-M365DSCTenantDomain -ApplicationId $ApplicationId -TenantId $TenantId -CertificateThumbprint $CertificateThumbprint
    }
    else
    {
        Write-Verbose -Message "Connecting to Microsoft Teams using Credentials"
        Test-MSCloudLogin -CloudCredential $GlobalAdminAccount `
            -Platform MicrosoftTeams
        $ConnectionMode = "Credential"
        $organization = $GlobalAdminAccount.UserName.Split('@')[1]
    }

    $teams = Get-Team
    $i = 1
    $content = ""
    foreach ($team in $teams)
    {
        Write-Information "    - [$i/$($teams.Length)] $($team.DisplayName)"
        $params = @{
            DisplayName           = $team.DisplayName
            GlobalAdminAccount    = $GlobalAdminAccount
            ApplicationId         = $ApplicationId
            TenantId              = $TenantId
            CertificateThumbprint = $CertificateThumbprint
        }
        $result = Get-TargetResource @params

        if ($ConnectionMode -eq 'Credential')
        {
            $result.GlobalAdminAccount = Resolve-Credentials -UserName "globaladmin"
        }

        $result.Remove("GroupID")
        if ("" -eq $result.Owner)
        {
            $result.Remove("Owner")
        }
        $content += "        TeamsTeam " + (New-GUID).ToString() + "`r`n"
        $content += "        {`r`n"
        $currentDSCBlock = Get-DSCBlock -Params $result -ModulePath $PSScriptRoot
        if ($ConnectionMode -eq 'Credential')
        {
            $partialContent = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName "GlobalAdminAccount"
        }
        else
        {
            $partialContent = $currentDSCBlock
        }
        $partialContent += "        }`r`n"
        if ($partialContent.ToLower().Contains("@" + $organization.ToLower()))
        {
            $partialContent = $partialContent -ireplace [regex]::Escape("@" + $organization), "@`$OrganizationName"
        }
        $content += $partialContent
        $i++
    }

    return $content
}

Export-ModuleMember -Function *-TargetResource
