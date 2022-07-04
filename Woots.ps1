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
    
    https://www.youtube.com/watch?v=7mEmQgGowMY
    gebruik Invoke-RestMethod 
    try {
        Invoke-RestMethod
    }
    Catch {
        $_.exception.response
    }
#>
$apiurl = $null # "https://app.woots.nl/api/v2"
$school_id = $null
$authorizationheader = $null
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
    $script:authorizationheader = @{
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
    if (!$school_id) { Throw "Geen School_id"}
    if (!$authorizationheader) { Throw "Geen token"}
    if (!$apiurl) { Throw "Geen APIURL"} 
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

<#
.SYNOPSIS
    Invoke-WootsApiCall neemt een URI, doet herhaaldelijk een Invoke-WebRequest naar de API endpoint, 
    totdat alle beschikbare items zijn opgehaald en retourneert alle items. Het doet rate limiting,
    en vangt excepties af.
.PARAMETER Nextlink
    URI inclusief query parameters
.PARAMETER MaxItems
    Aantal maximaal op te halen items. LET OP: dit is niet exact, maar afgerond naar boven tot 
    het aantal items per pagina vermenigvuldigd met het aantal opgehaalde paginas. 
.OUTPUTS 
    retourneert een lijst (array) met items.
#>
function Invoke-MultiPageGet($Nextlink, $MaxItems = 50) {
    Assert-WootsInitialized
    #if ($verbose) {Write-Host " $(Get-FunctionName -StackNumber 3) " -NoNewline -ForegroundColor Blue}
    $getpage = 1
    $data = @()
    $done = $False
    while (!$done) {
        if ($verbose) {write-host "." -NoNewline -ForegroundColor Blue}
        $ProgressPreference = 'SilentlyContinue' 
        Try {
            $response = Invoke-WebRequest -Uri $nextlink -Method 'GET' -Headers $authorizationheader 
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
        if ($getpage -gt [int]$response.Headers["total-pages"]) {Break}
        if ($links.Keys -notcontains "next") {Break} 
        $nextlink = $links["next"]
        if ($data.count -gt $MaxItems) {Break}
    }
    Show-Status $response.StatusCode $response.StatusDescription $data.count 
    if ($data.count -gt $MaxItems) {
        return ($data | Select-Object -First $MaxItems)
    }
    return $data
}
<#
.SYNOPSIS
    Invoke-WootsApiCall neemt enkele parameters, doet een Invoke-WebRequest naar de API endpoint, 
    en retourneert een enkel item. Het doet rate limiting en vangt excepties af.
.PARAMETER Uri 
    Uri is het endpoint van de API.
.PARAMETER Method
    Method bevat httpd-method, één van: GET, POST, PUT, PATCH, DELETE
.PARAMETER Body
    Body is een hashtable. Deze wordt meegestuurd in body van de aanvraag.
.OUTPUTS
    [PSCustomObject]  single item
#>
Function Invoke-WootsApiCall($Uri, $Method, $Body=$null) {
    Assert-WootsInitialized
    #if ($verbose) {Write-Host " $(Get-FunctionName -StackNumber 3) " -NoNewline -ForegroundColor Blue}
    $ProgressPreference = "SilentlyContinue"
    Try {
        $response = Invoke-WebRequest -Uri $Uri -Method $Method `
            -Headers $authorizationheader `
            -Body ($Body | ConvertTo-Json) -ContentType "application/json"
    }
    catch [System.Net.WebException] {
        Write-Error ("{0}: Exception caught! {1} {2}" -f (
            (Get-FunctionName -StackNumber 2), $_.Exception.Response.StatusCode, $_.Exception.Response.StatusDescription))
        return $null
    }
    Show-Status $response.StatusCode $response.StatusDescription $response.content.count
    Limit-Rate $response.Headers
    return $response.content | ConvertFrom-Json
}
#endregion
# ====================== PROTOTYPE FUNCTIONS ======================
#region prototype functions
Function Search-WootsResource($resource, $parameter, $MaxItems = 50) {
    <#
        GET /api/v2/search/{resource}/?query={name}:"{value}" {name}:{value}
        $parameters is een hashtable met zoekkenmerken, bijvoorbeeld: @{
            name = "5H Tuareg"
            trashed = "false"
        }
    #>    
    Try {
        $query = ($parameter.GetEnumerator() | ForEach-Object { "{0}:`"{1}`"" -f ($_.name, $_.value)}) -join " "
    } 
    Catch { # bescherm tegen verouderde functieparameters
        Throw "Verkeerde parameters. Gebruik Search-WootsResource(`$resource, `$parameter)"
    }
    if ($verbose) {Write-Host "$(Get-FunctionName -StackNumber 2): ($query)" -NoNewline -ForegroundColor Blue}
    return Invoke-MultiPageGet -Nextlink ("$apiurl/search/$resource/?query=$query" -f ($name, $value)) -MaxItems $MaxItems
}

Function Get-WootsSchoolResources ($resource, $MaxItems = 50) {
    # GET /api/v2/school/{school_id}/{resource}
    # haal data op, gebruik pagination, respecteer de ratelimit
    # $resource is één van:  roles, labels, classes, courses, departments, locations, periods, users
    if ($verbose) {Write-Host "$(Get-FunctionName -StackNumber 2) " -NoNewline -ForegroundColor Blue}
    return Invoke-MultiPageGet -Nextlink "$apiurl/schools/$school_id/$resource"  -MaxItems $MaxItems
}
Function Get-WootsResourceById ($resource, $id) {
    # GET /api/v2/{resource}/{id}
    if ($verbose) {Write-Host " $(Get-FunctionName -StackNumber 2) : ($id) " -NoNewline -ForegroundColor Blue}
    return Invoke-WootsApiCall -Uri "$apiurl/$resource/$id" -Method 'GET' 
}

Function Add-WootsSchoolResource ($resource, $parameter) {
    # POST /api/v2/schools/{school_id}/{resource} $parameter
    return Invoke-WootsApiCall -Uri  "$apiurl/schools/$school_id/$resource"  `
        -Method 'POST' -Body $parameter
}
Function Set-WootsResourceById($resource, $id, $parameter) {
    # PATCH /api/v2/{resource}/{id} $parameter
    return Invoke-WootsApiCall -Uri "$apiurl/$resource/$id" -Method 'PATCH' -Body $parameter
}

function Remove-WootsResourceById ($resource, $id) {
    # DELETE /api/v2/{resource}/{id}
    return Invoke-WootsApiCall -Uri "$apiurl/$resource/$id" -Method 'DELETE'
}

Function Get-WootsResourceItem($Resource, $id, $ItemType, $MaxItems = 50) {
    # GET /api/v2/{resource}/{resource_id}/{itemtype} ; List resource items
    if ($verbose) {Write-Host "$(Get-FunctionName): $resource $id $itemtype" -NoNewline -ForegroundColor Blue}
    $url = "$apiurl/$Resource/$id/$ItemType"
    if ($verbose) {Write-Host "[$url]"  -NoNewline -ForegroundColor Blue}
    return Invoke-MultiPageGet -nextlink $url -MaxItems $MaxItems
}
Function Add-WootsResourceItem($resources, $id, $itemtype, $parameter) {
    # POST /api/v2/{resource}/{resource_id}/{itemtype} $parameter ; Add item to resource
    return Invoke-WootsApiCall -Uri "$apiurl/$resources/$id/$itemtype" -Method 'PATCH' -Body $parameter
}
#endregion

<#  Add-WootsClass, Remove-WootsClass, Set-WootsClass
Ik kan dit niet testen. Ik mag blijkbaar Add-WootsClass, Remove-WootsClass en Set-WootsClass
niet gebruiken in een Wootsomgeving waar klassen zijn gesynchroniseerd met Magister #>

# ====================== CODE GENERATOR OUTPUT ======================

. (Join-Path $PSScriptRoot "Woots-generatedcode.ps1")

# ====================== NOG MEER CODE ======================
