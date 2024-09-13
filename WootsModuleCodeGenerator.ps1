<#
    WootsModuleCodeGenerator.ps1
    1-7-2022 Paul Wiegmans
    Code generator for Woots PowerShell module. 

    INPUT
    Woots-api-calls.csv : ';' delimited list of (Resource,Method, URI, Description) of Woots API,
    extracted manually from https://stage.woots.nl/api/docs/index.html#/

    OUTPUT
    woots-generatedcode.ps1 : a PowerShell function for every Woots API call, to be part of the PowerShell Woots module Woots.ps1.

    CHANGES
    20230815
    * Extract api calls automatically from  https://stage.woots.nl/api/docs/v2/swagger.yaml
    * Added generation date and openapi version umber in generated code
    * added API call for logs
    * output code sorted and grouped by category 

    TO DO    
    * HTML documentatie, die PS functie koppelt aan URI/method
#>

$herePath = Split-Path -parent $MyInvocation.MyCommand.Definition
$codefile = (Join-Path $herepath "Woots-generatedcode.ps1")
$htmlfile = (Join-Path $herepath "Woots-documentatie.html")

# download en analyseer swagger.yaml van Woots website
$swaggerurl = 'https://app.woots.nl/api/docs/v2/swagger.yaml'
$teller = 0
$api = @() 
$code = @()
$allowedmethods = 'get', 'post', 'put', 'patch', 'delete'

$Template20SearchResource = 'Function Search-Woots{resource}($Parameter,$MaxItems=-1) {return Search-WootsResource -resource "{resources}" -parameter $Parameter -MaxItem $MaxItems}'
$Template30GetResource = 'Function Get-Woots{resource}($id) { return Get-WootsResource -resource "{resources}" -id $id }'
$Template31GetResourceItem = 'Function Get-Woots{resource}{itemtype}($id) { return Get-WootsResourceItem -resource "{resources}" -id $id -itemtype "{itemtypes}"}'
$Template32GetNoIdResources = 'Function Get-WootsAll{resource}($MaxItems=-1) {return Get-WootsNoIdResource -resource "{resources}" -MaxItems $MaxItems}'
$Template35GetSchoolResources = 'Function Get-WootsAll{resource}($MaxItems=-1) { return Get-WootsAllResources -resource "{resources}" -MaxItems $MaxItems}'
$Template36GetLogsResources = 'Function Get-WootsLogs{resources}($id) {return Get-WootsLogsResource -resource "{resources}" -id $id}'
$Template41AddResourceItem = 'Function Add-Woots{resource}{itemtype}($id,$Parameter) {return Add-WootsResourceItem -resource "{resources}" -id $id -itemtype "{itemtypes}" -parameter $Parameter}'
$Template42AddNoIdResources = 'Function Add-WootsNoId{resource}() {return Add-WootsNoIdResource -resource "{resources}" -parameter $Parameter}'
$Template45AddSchoolResource = 'Function Add-Woots{resource}($Parameter) {return Add-WootsResource -resource "{resources}" -parameter $Parameter}'
$Template50SetResource = 'Function Set-Woots{resource}($id,$Parameter) {return Set-WootsResource -resource "{resources}" -id $id -parameter $Parameter}'
$Template51SetResourceItem = 'Function Set-Woots{resource}{itemtype}($id,$Parameter) {return Set-WootsResourceItem -resource "{resources}" -id $id -itemtype "{itemtypes}" -parameter $Parameter}'
$Template61RemoveResource = 'Function Remove-Woots{resource}($id) {return Remove-WootsResource -resource "{resources}" -id $id}'
$Template99NotYetImplemented = 'Function Invoke-Woots{apicall}() { Throw "This function is not yet implemented"}'

Function Write-Code($text) {
    $script:code += "$text" 
}

Function Get-SingleTag($tag) {
    if ($tag.substring($tag.length - 1) -eq "s") {
        $tag = $tag.substring(0, $tag.length - 1)
        if ($tag.substring($tag.length - 2) -eq "ie") {
            $tag = $tag.substring(0, $tag.length - 2) + "y"
        }
        elseif ($tag.substring($tag.length - 1) -eq "e") {
            if (!($tag.substring($tag.length - 2) -eq "ve") `
                    -and !($tag.endswith("exercise")) `
                    -and !($tag.endswith("response")) `
                    -and !($tag.endswith("course")) `
                    -and !($tag.endswith("role"))) {
                $tag = $tag.substring(0, $tag.length - 1)
            }
        }
    }
    $tag = (Get-Culture).TextInfo.ToTitleCase($tag)
    $tag = $tag -replace "_", ""
    return $tag
}

function Find-Method ($url, $method, $call) {
    $script:teller += 1
    $entry = [PSCustomObject]@{
        Resource    = $call['tags'][0]
        Method      = $method
        URI         = $url
        Description = $call['summary']
    }
    $script:api += $entry
}
function ToTitleCase($s) {
    (Get-Culture).TextInfo.ToTitleCase($s)
}

# ===================== MAIN ==========================================================
Write-Host "========  $(Split-Path -Leaf $MyInvocation.MyCommand.Definition)  ========" -ForegroundColor Cyan

Write-Host 'Swagger YAML ophalen...'
Try {
    $response = Invoke-WebRequest -Uri $swaggerurl -Method 'GET'
}
catch [System.Net.WebException] {
    Write-Error ("Downloading Swagger.yaml failed: {1} {2}" -f (
            $_.Exception.Message, $_.Exception.Response.StatusDescription))
    return
}
Write-Host 'Omzetten YAML...'
$swag = $response.content | ConvertFrom-Yaml
Write-Host "OpenAPI $($swag.openapi)"

foreach ($url in $swag.paths.Keys) {
    foreach ($method in $allowedmethods) {
        if ($swag.paths[$url][$method] ) { 
            find-method -Url $url -Method $method -Call $swag.paths[$url][$method]
        }
    }
}
Write-Host "Aantal functies in API: $teller"

# start codegeneratie
Write-Code ("##")
Write-Code ("##   Woots PowerShell Module")
Write-Code ("##   by Paul Wiegmans (p.wiegmans@svok.nl)")
Write-Code ("##")
Write-Code ("##   Swagger URL : $swaggerurl")
Write-Code ("##   openapi     : $($swag.openapi)")
Write-Code ("##   Generated by: $(Split-Path -Leaf $MyInvocation.MyCommand.Definition)")
Write-Code ("##   Generated   : $(Get-Date -format 's')")
Write-Code ("")

# Splits de URI
$api | Add-Member -MemberType NoteProperty -Name "Deel1" -Value "" 
$api | Add-Member -MemberType NoteProperty -Name "Deel2" -Value "" 
$api | Add-Member -MemberType NoteProperty -Name "Deel3" -Value "" 
$api | Add-Member -MemberType NoteProperty -Name "Deel4" -Value "" 
$api | Add-Member -MemberType NoteProperty -Name "Code" -Value "" 
$api | Add-Member -MemberType NoteProperty -Name "Category" -Value 0 
$api | Add-Member -MemberType NoteProperty -Name "Methodindex" -Value 0
foreach ($call in $api) {
    $parts = $call.uri -split "/"
    $call.Deel1 = $parts[3]
    $call.Deel2 = $parts[4]
    $call.Deel3 = $parts[5]
    $call.Deel4 = $parts[6]
    $call.Methodindex = $allowedmethods.IndexOf($call.Method)
}

# Verzamel alle namen, maak tabel met enkelvoudnamen
$tags = @()
foreach ($call in $api) {
    $tags += $call.Deel1
    $tags += $call.Deel2
    $tags += $call.Deel3
}
$tags = $tags | Sort-Object -Unique | Where-Object { !$_.contains("{") } | Where-Object { $_ }
$singletons = @{}
foreach ($tag in $tags) {
    $singletons[$tag] = Get-SingleTag -tag $tag
}

# Genereer functies
foreach ($call in $api) {
    if ($call.Deel1 -eq "search") {
        # GET /api/v2/search/{resources}
        $call.code = $Template20SearchResource.replace("{resources}", $call.Deel2).replace("{resource}", $singletons[$call.Deel2])
        $call.category = 20
    }
    elseif ($call.Deel1 -eq "logs") {
        # GET /api/v2/logs/{resources}/{id}
        $call.code = $Template36GetLogsResources.replace("{resources}", (ToTitleCase $call.Deel2)).replace("{resource}", $singletons[$call.Deel3])
        $call.category = 36
    }
    elseif ($call.Deel2 -eq "{school_id}") {
        $resource = $singletons[$call.Deel3]
        if ($call.Method -eq "GET") {  
            # GET /api/v2/schools/{school_id}/{resource}
            $call.code = $Template35GetSchoolResources.replace("{resources}", $call.Deel3).replace("{resource}", $resource)
            $call.category = 35
        }
        elseif ($call.Method -eq "POST") {
            # POST /api/v2/schools/{school_id}/{resource}
            $call.code = $Template45AddSchoolResource.replace("{resources}", $call.Deel3).replace("{resource}", $resource)
            $call.category = 45
        }
    }
    elseif ($call.Deel2 -eq "{id}") {
        $resource = $singletons[$call.Deel1]
        if ($call.Method -eq "GET") {  
            # GET /api/v2/{resource}/{id}
            $call.code = $Template30GetResource.replace("{resources}", $call.Deel1).replace("{resource}", $resource)
            $call.category = 30
        }
        elseif ($call.Method -eq "PATCH") {
            # PATCH /api/v2/{resource}/{id}
            $call.code = $Template50SetResource.replace("{resources}", $call.Deel1).replace("{resource}", $resource)
            $call.category = 50
        }
        elseif ($call.Method -eq "DELETE") {
            # DELETE /api/v2/{resource}/{id}
            $call.code = $Template61RemoveResource.replace("{resources}", $call.Deel1).replace("{resource}", $resource)
            $call.category = 61
        }
    }
    elseif ($call.Deel3 -and !$call.Deel4 -and ($call.Deel3 -ne "{id}")) {
        $resource = $singletons[$call.Deel1]
        $itemtype = $singletons[$call.Deel3]        
        if ($call.Method -eq "GET") {  
            # GET /api/v2/{resource}/{id}
            $call.code = $Template31GetResourceItem.replace("{resources}", $call.Deel1).replace("{resource}", $resource).replace("{itemtypes}", $call.Deel3).replace("{itemtype}", $itemtype)
            $call.category = 31
        }
        elseif ($call.Method -eq "POST") {
            # POST /api/v2/{resource}/{id}
            $call.code = $Template41AddResourceItem.replace("{resources}", $call.Deel1).replace("{resource}", $resource).replace("{itemtypes}", $call.Deel3).replace("{itemtype}", $itemtype)
            $call.category = 41
        }
        elseif ($call.Method -eq "PATCH") {
            # PATCH /api/v2/{resource}/{id}
            $call.code = $Template51SetResourceItem.replace("{resources}", $call.Deel1).replace("{resource}", $resource).replace("{itemtypes}", $call.Deel3).replace("{itemtype}", $itemtype)
            $call.category = 51
        }
    }
    elseif (!$call.Deel2) {
        $resource = $singletons[$call.Deel1]
        if ($call.Method -eq "GET") {  
            $call.code = $Template32GetNoIdResources.replace("{resources}", $call.Deel1).replace("{resource}", $resource)
            $call.category = 32
        }
        elseif ($call.Method -eq "POST") {
            $call.code = $Template42AddNoIdResources.replace("{resources}", $call.Deel1).replace("{resource}", $resource)
            $call.category = 42
        }
    }
    if (!$call.Code) {
        write-host ("NIET GEIMPLEMENTEERD: [{0}] {1}/{2}/{3}" -f ($call.Method.ToUpper(), $call.Deel1, $call.Deel2, $call.Deel3))
        $apicall = $call.Method + "_" + $call.URI.Replace("/", "_").Replace("{", "_").Replace("}", "_")
        $call.code = $Template99NotYetImplemented.replace("{apicall}", $apicall)
    }
}

# Controle op dubbele functies
$api | Add-Member -MemberType NoteProperty -Name "Function" -Value "" 
ForEach ($call in $api) {    
    $call.Function = ($call.code -split " ")[1] # pak alleen functienaam uit code
}
$functionlist = $api | Select-Object -ExpandProperty Function | Sort-Object
$difflist = Compare-Object -ReferenceObject $functionlist -DifferenceObject ($functionlist | Sort-Object -Unique)
if ($difflist) {
    Write-Host "Duplicaten gevonden voor functies:" -ForegroundColor Red
    Write-host $difflist.InputObject
}
else {
    Write-Host "Geen duplicaten in functienamen" -ForegroundColor Green
}

# Genereer uitvoer 
$api = $api | Sort-Object -Property Resource, Methodindex
$resourcelabel = ""
$implementedcounter = 0
foreach ($call in $api) {
    if ($call.Code) {
        if ($resourcelabel -ne $call.Resource) {
            $resourcelabel = $call.Resource
            Write-Code "# -------- $resourcelabel --------"
        }
        Write-Code $call.code
        $implementedcounter++
    }
}

Write-Code ("# {0} functions implemented" -f $implementedcounter)
Write-Host ("{0} functies geimplementeerd" -f $implementedcounter)
$code | Set-Content -Path $codefile -Force 
Write-Host "Regels code geschreven: $($code.count)"
Write-Host "Code geschreven naar bestand: $codefile"
