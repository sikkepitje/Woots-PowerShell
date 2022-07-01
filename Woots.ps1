<#
    Woots.psm1
    8-5-2022 p.wiegmans@svok.nl

    Een PowerShell module voor het besturen van de Woots web API

    Snelle vertaling tussen API en PS module:
    [GET] List users     :  Get-WootsAllUsers
    [POST] Create User   :  Add-WootsUser
    [GET] show user      :  Get-WootsUser
    [PATCH] update user  :  Set-WootsUser
    [DELETE] delete user :  Remove-WootsUser
    [GET] Search users   :  Search-WootsUser

    Wijzigingen:
    24-6-2022
    * New-WootsFunction hernoemd naar Add-WootsFunction
    * verwijderd -MaxItems parameters;  niet nodig
    * toegevoegd generieke functie Get-WootsResourceById 
    1-7-2022
    * Search-WootsResource accepteert meer dan één zoekkenmerk
    * toegevoegd: Add-ResourceItem
    * toegevoegd: Get-ResourceItem
    * generieke parameternamen $parameter
    
#>
$script:apiurl = $null # "https://app.woots.nl/api/v2"
$script:school_id = $null
$script:requestheader = $null
$verbose = $True

# ====================== UTILITY FUNCTIONS ======================
#region utility functions
function Get-FunctionName ([int]$StackNumber = 1) {
    return [string]$(Get-PSCallStack)[$StackNumber].FunctionName
}
function Initialize-Woots ($hostname, $school_id, $token) {
    if ($hostname) {
        $script:apiurl =  "https://$hostname/api/v2"
    }
    $script:school_id = $school_id
    $script:requestheader = @{
        "accept" = "application/json"
        "authorization" = "Bearer $token" 
    }
    $ProgressPreference = 'SilentlyContinue'    # Subsequent calls do not display UI. Inschakelen voor hele script ??
}
function Initialize-WootsIniFile ($Path) {
    if (!(test-path -path $Path)) {
        Throw "$(Get-FunctionName): Path not found: $Path "
    }
    $config = Get-Content -Path $Path | ConvertFrom-StringData
    Initialize-Woots -hostname $config.hostname -School_Id $config.School_id -Token $config.Token    
}
function Assert-WootsInitialized(){
    if (!$script:school_id) { Throw "Geen School_id"}
    if (!$script:requestheader) { Throw "Geen token"}
    if (!$script:apiurl) { Throw "Geen APIURL"} 
}
function Show-Status($StatusCode, $StatusDescription, $count) {
    if ($verbose) {
        Write-Host (" {0} {1} ({2} records)" -f ($StatusCode, $StatusDescription, $count)) -ForegroundColor Blue
    }
}
function boolstring($b) { if ($b) {"true"} else {"false"}}
function Write-HeaderInfo ($resphead) {
    Write-Host ("Pages:{0,6} {1,6} {2,6} " -f 
        $resphead["current-page"], $resphead["page-items"], $resphead["total-pages"]) -NoNewline
    Write-Host ("Rates:{0,6} {1,6} {2,6}" -f 
        $resphead["ratelimit-limit"], $resphead["ratelimit-remaining"], $resphead["ratelimit-reset"])
}
function Get-ReponseLinks ($resphead) {
    $links = @{}
    $resphead["link"] -split ',' | ForEach-Object { # construct links hash table
        $link = $_.trim(" ") -split ";"
        $tag = ($link[1] -split "=")[1].Trim("`"")
        $links[$tag] = $link[0].trim("< >")
    }
    return $links    
}
function Limit-Rate ($resphead) {
    # beperk het tarief (vertaling voor "rate limit")
    if ($resphead["ratelimit-remaining"] -le 0) {
        $hersteltijd = [int]$resphead["ratelimit-reset"]
        if ($verbose) {Write-host ("Snelheidslimiet bereikt, wacht {0} seconden ..." -f $hersteltijd) -ForegroundColor Yellow}
        Start-Sleep $hersteltijd
    }
}
Function NotYetImplemented {
    Throw "{0} is not yet implemented" -f (Get-FunctionName -StackNumber 2)
}
function Invoke-MultiPageGet($nextlink) {
    Assert-WootsInitialized
    #if ($verbose) {Write-Host " $(Get-FunctionName) " -NoNewline -ForegroundColor Blue}
    $getpage = 1
    $data = @()
    $done = $False
    while (!$done) {
        if ($verbose) {write-host "." -NoNewline -ForegroundColor Blue}
        $ProgressPreference = 'SilentlyContinue' 
        Try {
            $response = Invoke-WebRequest -Uri $nextlink -Method 'GET' -Headers $requestheader 
        }
        catch [System.Net.WebException] {
            Write-Error ("{0}: Exception caught! {1} {2}" -f (
                (Get-FunctionName), $_.Exception.Response.StatusCode, $_.Exception.Response.StatusDescription))
            return $null
        }
        if ($response.content.Contains("<!DOCTYPE html>")) {
            Write-Error "Onverwacht antwoord; niet ingelogd of een andere fout"
            return $data
        } 
        $data += $response.content | ConvertFrom-Json
        $links = Get-ReponseLinks $response.Headers
        Limit-Rate $response.Headers
        $getpage = [int]($response.Headers["current-page"]) + 1    
        if ($getpage -gt [int]$response.Headers["total-pages"]) {$done = $true}
        if ($links.Keys -notcontains "next") {$done = $true} else {
            $nextlink = $links["next"]
        }
    }
    Show-Status $response.StatusCode $response.StatusDescription $data.count 
    return $data
}
#endregion
# ====================== PROTOTYPE FUNCTIONS ======================
#region prototype functions
Function Search-WootsResource($resource, $parameter) {
    <#
        GET /api/v2/search/{resource}/?query={name}:"{value}" {name}:{value}
        $parameters is een hashtable met zoekkenmerken, bijvoorbeeld: @{
            name = "5H Tuareg"
            trashed = "false"
        }
    #>    
    $query = ($parameter.GetEnumerator() | ForEach-Object { "{0}:`"{1}`"" -f ($_.name, $_.value)}) -join " "
    if ($verbose) {Write-Host "$(Get-FunctionName): ($resource) $query" -NoNewline -ForegroundColor Blue}
    $data = Invoke-MultiPageGet -nextlink ("$apiurl/search/$resource/?query=$query" -f ($name, $value))
    return $data
}

Function Get-WootsSchoolResources ($resource) {
    # GET /api/v2/school/{school_id}/{resource}
    # haal data op, gebruik pagination, respecteer de ratelimit
    # $resource is één van:  roles, labels, classes, courses, departments, locations, periods, users
    Assert-WootsInitialized
    if ($resource -notin $validGetSchoolResources) {
        Throw "Invalid resource: $resource"
    }
    if ($verbose) {Write-Host "$(Get-FunctionName) : $resource " -NoNewline -ForegroundColor Blue}
    return Invoke-MultiPageGet -nextlink "$apiurl/schools/$school_id/$resource"
}
Function Add-WootsSchoolResource ($resource, $parameter) {
    # POST /api/v2/schools/{school_id}/{resource} $parameter
    Assert-WootsInitialized
    if ($verbose) {Write-Host (Get-FunctionName) -NoNewline -ForegroundColor Blue}
    $ProgressPreference = 'SilentlyContinue' 
    Try {
        $response = Invoke-WebRequest -Uri "$apiurl/schools/$school_id/$resource" -Method 'POST' -Headers $requestheader -Body $parameter
    }
    catch [System.Net.WebException] {
        Write-Error ("{0}: Exception caught! {1} {2}" -f (
            (Get-FunctionName), $_.Exception.Response.StatusCode, $_.Exception.Response.StatusDescription))
        return $null
    }
    Show-Status $response.StatusCode $response.StatusDescription $response.content.count
    Limit-Rate $response.Headers
    return $response.content | ConvertFrom-Json
}
Function Get-WootsResourceById ($resource, $id) {
    # GET /api/v2/{resource}/{id}
    Assert-WootsInitialized
    if ($verbose) {Write-Host (Get-FunctionName) -NoNewline -ForegroundColor Blue}
    if ($resource -notin @($validGetResources)) {
        Throw "$(Get-FunctionName) Invalid resource: $resource. Must be one of: $($validGetResources -join ',')"
    }
    $ProgressPreference = 'SilentlyContinue' 
    Try {
        $response = Invoke-WebRequest -Uri "$apiurl/$resource/$id" `
            -Method 'GET' -Headers $requestheader
    }
    catch [System.Net.WebException] {
        Write-Error ("{0}: Exception caught! {1} {2}" -f (
            (Get-FunctionName), $_.Exception.Response.StatusCode, $_.Exception.Response.StatusDescription))
        return $null
    }
    Show-Status $response.StatusCode $response.StatusDescription $response.content.count
    Limit-Rate $response.Headers
    return $response.content | ConvertFrom-Json
}

Function Set-WootsResourceById($resource, $id, $parameter) {
    # PATCH /api/v2/{resource}/{id} $parameter
    Assert-WootsInitialized
    if ($verbose) {Write-Host (Get-FunctionName) -NoNewline -ForegroundColor Blue}
    if ($resource -notin @($validSetResources)) {
        Throw "$(Get-FunctionName) Invalid resource: $resource. Must be one of: $($validSetResources -join ',')"
    }
    $ProgressPreference = 'SilentlyContinue' 
    Try {
        $response = Invoke-WebRequest -Uri "$apiurl/$resource/$id" `
            -Method 'PATCH' -Headers $requestheader -body $parameter
    }
    catch [System.Net.WebException] {
        Write-Error ("{0}: Exception caught! {1} {2}" -f (
            (Get-FunctionName), $_.Exception.Response.StatusCode, $_.Exception.Response.StatusDescription))
        return $null
    }
    Show-Status $response.StatusCode $response.StatusDescription $response.content.count
    Limit-Rate $response.Headers
    return $response.content | ConvertFrom-Json
}
function Remove-WootsResourceById ($resource, $id) {
    # DELETE /api/v2/{resource}/{id}
    Assert-WootsInitialized
    if ($verbose) {Write-Host (Get-FunctionName) -NoNewline -ForegroundColor Blue}
    if ($resource -notin @($validRemoveResources)) {
        Throw "$(Get-FunctionName) Invalid resource: $resource. Must be one of: $($validRemoveResources -join ',')"
    }
    $ProgressPreference = 'SilentlyContinue' 
    Try {
        $response = Invoke-WebRequest -Uri "$apiurl/$resource/$id" `
            -Method 'DELETE' -Headers $requestheader
    }
    catch [System.Net.WebException] {
        Write-Error ("{0}: Exception caught! {1} {2}" -f (
            (Get-FunctionName), $_.Exception.Response.StatusCode, $_.Exception.Response.StatusDescription))
        return $null
    }
    Show-Status $response.StatusCode $response.StatusDescription $response.content.count
    Limit-Rate $response.Headers
    return $response.content | ConvertFrom-Json
}

Function Get-WootsResourceItem($Resource, $id, $ItemType) {
    # GET /api/v2/{resource}/{resource_id}/{itemtype} ; List resource items
    if ($verbose) {Write-Host "$(Get-FunctionName): $resource $id $itemtype" -NoNewline -ForegroundColor Blue}
    $url = "$apiurl/$Resource/$id/$ItemType"
    if ($verbose) {Write-Host "[$url]"  -NoNewline -ForegroundColor Blue}
    return Invoke-MultiPageGet -nextlink $url
}
Function Add-WootsResourceItem($resources, $id, $itemtype, $parameter) {
    # POST /api/v2/{resource}/{resource_id}/{itemtype} $parameter ; Add item to resource
    Assert-WootsInitialized
    if ($verbose) {Write-Host (Get-FunctionName) -NoNewline -ForegroundColor Blue}
    $ProgressPreference = 'SilentlyContinue' 
    Try {
        $response = Invoke-WebRequest -Uri "$apiurl/$resources/$id/$itemtype" -Method 'POST' -Headers $requestheader -Body $parameter
    }
    catch [System.Net.WebException] {
        Write-Error ("{0}: Exception caught! {1} {2}" -f (
            (Get-FunctionName), $_.Exception.Response.StatusCode, $_.Exception.Response.StatusDescription))
        return $null
    }
    Show-Status $response.StatusCode $response.StatusDescription $response.content.count
    Limit-Rate $response.Headers
    return $response.content | ConvertFrom-Json
}

#endregion

<#  Add-WootsClass, Remove-WootsClass, Set-WootsClass
Ik kan dit niet testen. Ik mag blijkbaar Add-WootsClass, Remove-WootsClass en Set-WootsClass
niet gebruiken in een Wootsomgeving waar klassen zijn gesynchroniseerd met Magister #>

# ====================== CODE GENERATOR OUTPUT ======================

. (Join-Path $PSScriptRoot "Woots-generatedcode.ps1")

# ====================== NOG MEER CODE ======================
