<#
    .SYNOPSIS
    Een PowerShell module voor het besturen van de Woots web API
    .DESCRIPTION
    .NOTES
        FunctionName : 
        Created by   : Paul Wiegmans
        Date Coded   : 8-5-2022
    .LINK
        https://github.com/sikkepitje/Woots-PowerShell
    .NOTES 
        change 
        20230802 : added "charset=utf-8" to contenttype of Invoke-WebRequest.
        20231013: 
          Limit-Rate: detectie van lege header.
          Invoke-WootsApiCall: detectie van lege content.
          Betere afhandeling van HTTP errors.

#>
$script:apiurl = $null
$script:school_id = $null
$script:authorizationheader = $null
$script:verbose = $False
$timeout = 5 # Invoke-Webrequest timeout seconden

# ====================== UTILITY Functions (voor intern gebruik) ======================
#region utility Functions
Function Get-FunctionName ([int]$StackNumber = 1) {
    return [string]$(Get-PSCallStack)[$StackNumber].FunctionName
}
Function Assert-WootsInitialized() {
    $msg = "Er is geen {0} gedefinieerd. Initializeer Woots eerst!"
    if (!$school_id) { Throw ($msg -f "school_id") }
    if (!$authorizationheader) { Throw ($msg -f "token") }
    if (!$apiurl) { Throw ($msg -f "Hostname") } 
}
Function Show-Status($respons, $count) {
    if ($verbose) {
        Write-Host (" {0} {1} ({2} records)" -f ($response.StatusCode, $response.StatusDescription, $count)) -ForegroundColor Blue
    }
}
Function Limit-Rate ($resphead) {
    if ($resphead) {
        if ($resphead["ratelimit-remaining"][0] -le 0) {
            Write-Host "." -ForegroundColor Red -NoNewline 
            $hersteltijd = 1 + $resphead["ratelimit-reset"][0]
            if ($verbose) { 
                Write-host ("Snelheidslimiet bereikt, wacht {0} seconden ..." -f $hersteltijd) -ForegroundColor Yellow 
            }
            Write-Host "Rate limiting is actief, delay is ($hersteltijd)"
            Start-Sleep $hersteltijd
        }
    }
}
Function NotYetImplemented {
    Throw "{0} is not yet implemented" -f (Get-FunctionName -StackNumber 2)
}
Function Invoke-MultiPageGet($Nextlink, $MaxItems = -1) {
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
    Assert-WootsInitialized
    $getpage = 1
    $data = @()
    $done = $False
    while (!$done) {
        if ($verbose) { write-host "." -NoNewline -ForegroundColor Blue }
        $ProgressPreference = 'SilentlyContinue' 
        Try {
            $response = Invoke-WebRequest -Uri $nextlink -Method 'GET' -Headers $authorizationheader -TimeoutSec $timeout -ErrorAction:Stop
        }
        catch [System.Net.WebException] {
            $fout = "{0}: WebException {1} {2}" -f (
                (Get-FunctionName -StackNumber 3), 
                $_.Exception.Response.StatusCode, 
                $_.Exception.Response.StatusDescription)
            Set-WootsLastError -Status $fout
            return $null
        }
        Catch [System.Net.Http.HttpRequestException] {
            $fout = "{0}: HTTP error {1} {2} {3}" -f (
            (Get-FunctionName -StackNumber 3), 
                $_.Exception.Response.StatusCode.value__, 
                $_.Exception.Response.StatusCode, 
                $_)
            Set-WootsLastError -Status $fout
            return $null
        }    
        if ($response.content.Contains("<!DOCTYPE html>")) {
            Write-Error "Onverwacht antwoord; niet ingelogd of een andere fout"
            return $data
        } 
        $data += $response.content | ConvertFrom-Json
        $links = @{}
        $response.Headers["link"] -split ',' | ForEach-Object { # construct links hash table
            $link = $_.trim(" ") -split ";"
            $tag = ($link[1] -split "=")[1].Trim("`"")
            $links[$tag] = $link[0].trim("< >")
        } 
    
        Limit-Rate $response.Headers
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            $currentpage = $response.Headers["current-page"][0] -as [int]
            $totalpages = $response.Headers["total-pages"][0] -as [int]
        }
        else {
            $currentpage = $response.Headers["current-page"] -as [int]
            $totalpages = $response.Headers["total-pages"] -as [int]
        }
        $getpage = $currentpage + 1    
        if ($getpage -gt $totalpages) { Break }
        if ($links.Keys -notcontains "next") { Break } 
        $nextlink = $links["next"]
        if ($MaxItems -ge 0 -and $data.count -gt $MaxItems) { Break }
    }
    Show-Status $response $data.count 
    if ($MaxItems -ge 0 -and $data.count -gt $MaxItems) {
        return ($data | Select-Object -First $MaxItems)
    }
    return $data
}
Function Invoke-WootsApiCall($Uri, $Method, $Body = $null) {
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
    Assert-WootsInitialized
    $ProgressPreference = "SilentlyContinue"
    $response = $null
    Try {
        $response = Invoke-WebRequest -Uri $Uri -Method $Method `
            -Headers $authorizationheader `
            -Body ($Body | ConvertTo-Json) -ContentType "application/json; charset=utf-8" -TimeoutSec $timeout -ErrorAction:Stop
    }
    catch [System.Net.WebException] {
        $fout = "{0}: WebException {1} {2}" -f (
            (Get-FunctionName -StackNumber 3), 
            $_.Exception.Response.StatusCode, 
            $_.Exception.Response.StatusDescription)
        Set-WootsLastError -Status $fout
        return $null
    } 
    Catch [System.Net.Http.HttpRequestException] {
        $fout = "{0}: HTTP error {1} {2} {3}" -f (
            (Get-FunctionName -StackNumber 3), 
            $_.Exception.Response.StatusCode.value__, 
            $_.Exception.Response.StatusCode, 
            $_)
        Set-WootsLastError -Status $fout
        return $null
    }
    Show-Status $response $response.content.count
    Limit-Rate $response.Headers
    if ($response.content) {
        return $response.content | ConvertFrom-Json
    }
    return $null
}
#endregion
# ====================== PROTOTYPE FunctionS ======================
#region prototype Functions
Function Search-WootsResource($Resource, $Parameter, $MaxItems = -1) {
    <#
        GET /api/v2/search/{resource}/?query={name}:"{value}" {name}:{value}
        $parameters is een hashtable met zoekkenmerken, bijvoorbeeld: @{
            name = "5H Tuareg"
            trashed = "false"
        }
    #>    
    Try {
        $query = ($Parameter.GetEnumerator() | ForEach-Object { "{0}:`"{1}`"" -f ($_.name, $_.value) }) -join " "
    } 
    Catch {
        # bescherm tegen verouderde functieparameters
        Throw "Verkeerde parameters. Gebruik Search-WootsResource(`$Resource, `$Parameter)"
    }
    if ($verbose) { Write-Host "$(Get-FunctionName -StackNumber 2): ($query)" -NoNewline -ForegroundColor Blue }
    return Invoke-MultiPageGet -Nextlink ("$apiurl/search/$resource/?query=$query" -f ($name, $value)) -MaxItems $MaxItems
}

Function Get-WootsAllResources ($Resource, $MaxItems = -1) {
    # GET /api/v2/school/{school_id}/{resource}
    # haal data op, gebruik pagination, respecteer de ratelimit
    # $resource is één van:  roles, labels, classes, courses, departments, locations, periods, users
    if ($verbose) { Write-Host "$(Get-FunctionName -StackNumber 2) " -NoNewline -ForegroundColor Blue }
    return Invoke-MultiPageGet -Nextlink "$apiurl/schools/$school_id/$Resource"  -MaxItems $MaxItems
}
Function Get-WootsResource ($Resource, $id) {
    # GET /api/v2/{resource}/{id}
    if ($verbose) { Write-Host " $(Get-FunctionName -StackNumber 2) : ($id) " -NoNewline -ForegroundColor Blue }
    return Invoke-WootsApiCall -Uri "$apiurl/$Resource/$id" -Method 'GET' 
}
Function Add-WootsResource ($Resource, $Parameter) {
    # POST /api/v2/schools/{school_id}/{resource} $Parameter
    if ($verbose) { Write-Host " $(Get-FunctionName -StackNumber 2) " -NoNewline -ForegroundColor Blue }
    return Invoke-WootsApiCall -Uri  "$apiurl/schools/$school_id/$Resource" -Method 'POST' -Body $Parameter
}
Function Set-WootsResource($Resource, $Id, $Parameter) {
    # PATCH /api/v2/{resource}/{id} $Parameter
    if ($verbose) { Write-Host " $(Get-FunctionName -StackNumber 2) : ($Id)  " -NoNewline -ForegroundColor Blue }
    return Invoke-WootsApiCall -Uri "$apiurl/$Resource/$id" -Method 'PATCH' -Body $Parameter
}
Function Remove-WootsResource ($Resource, $Id) {
    # DELETE /api/v2/{resource}/{id}
    if ($verbose) { Write-Host " $(Get-FunctionName -StackNumber 2) : ($Id)  " -NoNewline -ForegroundColor Blue }
    return Invoke-WootsApiCall -Uri "$apiurl/$Resource/$Id" -Method 'DELETE' -Body ""
}
Function Get-WootsResourceItem($Resource, $Id, $ItemType, $MaxItems = -1) {
    # GET /api/v2/{resource}/{resource_id}/{itemtype} ; List resource items
    if ($verbose) { Write-Host "$(Get-FunctionName -StackNumber 2): $Resource #$Id $itemtype" -NoNewline -ForegroundColor Blue }
    return Invoke-MultiPageGet -nextlink "$apiurl/$Resource/$Id/$ItemType" -MaxItems $MaxItems
}
Function Add-WootsResourceItem($Resource, $Id, $Itemtype, $Parameter) {
    # POST /api/v2/{resource}/{resource_id}/{itemtype} $Parameter ; Add item to resource
    if ($verbose) { Write-Host "$(Get-FunctionName -StackNumber 2): $Resource #$Id $itemtype" -NoNewline -ForegroundColor Blue }
    return Invoke-WootsApiCall -Uri "$apiurl/$Resource/$Id/$itemtype" -Method 'POST' -Body $Parameter
}
Function Get-WootsNoIdResource ($Resource, $MaxItems = -1) {
    # GET /api/v2/{resource}
    if ($verbose) { Write-Host "$(Get-FunctionName -StackNumber 2): $resource " -NoNewline -ForegroundColor Blue }
    return Invoke-MultiPageGet -nextlink "$apiurl/$Resource" -MaxItems $MaxItems
}
Function Add-WootsNoIdResource ($Resource, $parameter) {
    # POST /api/v2/{resource} $parameter
    if ($verbose) { Write-Host "$(Get-FunctionName -StackNumber 2): $resource " -NoNewline -ForegroundColor Blue }
    return Invoke-WootsApiCall -Uri  "$apiurl/$Resource" -Method 'POST' -Body $parameter
}
Function Get-WootsLogsResource ($Resource, $Id, $MaxItems = -1) {
    # GET /api/v2/logs/{resource}/{id}
    # haal data op, gebruik pagination, respecteer de ratelimit
    # $resource is één van:  assignments, courses, courses_users, responses, results, schools, submissions, subsets, users
    if ($verbose) { Write-Host "$(Get-FunctionName -StackNumber 2) " -NoNewline -ForegroundColor Blue }
    return Invoke-MultiPageGet -Nextlink "$apiurl/logs/$Resource/$Id"  -MaxItems $MaxItems
}

#endregion

<#  Add-WootsClass, Remove-WootsClass, Set-WootsClass
Ik kan dit niet testen. Ik mag blijkbaar Add-WootsClass, Remove-WootsClass en Set-WootsClass
niet gebruiken in een Wootsomgeving waar klassen zijn gesynchroniseerd met Magister #>

# ====================== PUBLISHED FUNCTIONS ======================
#region public function
Function Initialize-Woots ($hostname, $school_id, $token) {
    <#
    .SYNOPSIS
        Intialiseer parameters nodig om te kunnen werken met de Woots API.
    .DESCRIPTION
    .PARAMETER hostname
        Dit is de hostname deel van de Woots API endpoint URL. In geval van https://app.woots.nl/api/v2,
        dan is dit het deel "app.woots.nl".
    .PARAMETER school_id
        Dit is het unieke nummer van de schoolomgeving in Woots. De school_id is zichtbaar in de Wootsportal
        onder Mijn account > API-token.
    .PARAMETER token
        Dit is een hexadecimale string van 30 tekens waarmee toegang tot de Woots API wordt geauthoriseerd. 
        Je kunt deze aanmaken in de Wootsportal  onder Mijn account > API-token. 
    .EXAMPLE
    .INPUTS
    .OUTPUTS
    #>
    if ($hostname) {
        $script:apiurl = "https://$hostname/api/v2"
    }
    $script:school_id = $school_id
    $script:authorizationheader = @{
        "accept"        = "application/json"
        "authorization" = "Bearer $token" 
    }
    $ProgressPreference = 'SilentlyContinue'    # Subsequent calls do not display UI. Inschakelen voor hele script ??
}
Function Set-WootsLastError ($Status) {
    $global:wootslasterror = $status
}
Function Get-WootsLastError {
    return $global:wootslasterror 
}
#endregion
# ====================== INCLUDE CODE GENERATOR OUTPUT ======================

. (Join-Path $PSScriptRoot "Woots-generatedcode.ps1")

# ====================== THAT'S ALL FOLKS ======================
