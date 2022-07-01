<#
    codegenerator-v2.ps1
    1-7-2022 p.wiegmans@svok.nl

    The smart code generator for the Woots PowerShell module. 
    INPUT:
    Woots-api-calls.csv : ';' delimited list of (Resource,Method, URI, Description) 

    OUTPUT:
    woots-generatedcode.ps1 : a PowerShell function for every Woots API call, to be part of the PowerShell Woots module Woots.ps1.
#>

$Template1SearchResource = 'Function Search-Woots{resource}($parameter) {return Search-WootsResource -resource "{resources}" -parameter $parameter}'
$Template2GetSchoolResources = 'Function Get-WootsAll{resource}($id) { return Get-WootsSchoolResources -resource "{resources}" }'
$Template3AddSchoolResource = 'Function Add-Woots{resource}($parameter) {return Add-WootsSchoolResource -resource "{resources}" -parameter $parameter}'
$Template4GetResource = 'Function Get-Woots{resource}($id) { return Get-WootsResourceById -resource "{resources}" -id $id }'
$Template5SetResource = 'Function Set-Woots{resource}($id,$parameter) {return Set-WootsResourceById -resource "{resources}" -id $id -parameter $parameter}'
$Template6RemoveResource = 'Function Remove-Woots{resource}($id,$parameter) {return Remove-WootsResourceById -resource "{resources}" -id $id -parameter $parameter}'
$Template7GetResourceItem = 'Function Get-Woots{resource}{itemtype}($id) { return Get-WootsResourceItem -resource "{resources}" -id $id -itemtype "{itemtypes}"}'
$Template8AddResourceItem = 'Function Add-Woots{resource}{itemtype}($id,$parameter) {return Add-WootsResourceItem -resource "{resources}" -id $id -itemtype "{itemtypes}" -parameter $parameter}'
$Template9SetResourceItem = 'Function Set-Woots{resource}{itemtype}($id,$parameter) {return Set-WootsResourceItem -resource "{resources}" -id $id -itemtype "{itemtypes}" -parameter $parameter}'
$Template999NotYetImplemented = 'Function Invoke-Woots{apicall}() { Throw "This function is not yet implemented"}'

$code = @()
Function Write-Code($text) {
    #Write-Host "Code " -NoNewline -ForegroundColor Green
    #Write-Host $text 
    $script:code += "$text" 
}

Function Get-SingleTag($tag) {
    if ($tag.substring($tag.length-1) -eq "s") {
        $tag = $tag.substring(0,$tag.length-1)
        if ($tag.substring($tag.length-2) -eq "ie") {
            $tag = $tag.substring(0,$tag.length-2) + "y"
        } elseif ($tag.substring($tag.length-1) -eq "e") {
            if (!($tag.substring($tag.length-2) -eq "ve") `
                -and !($tag.contains("exercis")) `
                -and !($tag.contains("course"))) {
                $tag = $tag.substring(0,$tag.length-1)
            }
        }
    }
    $tag = (Get-Culture).TextInfo.ToTitleCase($tag)
    $tag = $tag -replace "_",""
    return $tag
}

Write-Host "========  $(Split-Path -Leaf $MyInvocation.MyCommand.Definition)  ========"
$herePath = Split-Path -parent $MyInvocation.MyCommand.Definition
$codefile = (Join-Path $herepath "Woots-generatedcode.ps1")
$api = import-csv -path (Join-Path $herepath "Woots-api-calls.csv") -Delimiter ";" -Encoding UTF8

Write-Code ("##")
Write-Code ("##   following code is generated by: $(Split-Path -Leaf $MyInvocation.MyCommand.Definition)")
Write-Code ("##   by Paul Wiegmans (p.wiegmans@svok.nl)")
Write-Code ("##")
Write-Code ("")
Write-Code ("")


# Splits de URI
$api | Add-Member -MemberType NoteProperty -Name "Deel1" -Value "" 
$api | Add-Member -MemberType NoteProperty -Name "Deel2" -Value "" 
$api | Add-Member -MemberType NoteProperty -Name "Deel3" -Value "" 
$api | Add-Member -MemberType NoteProperty -Name "Deel4" -Value "" 
$api | Add-Member -MemberType NoteProperty -Name "Code" -Value "" 

foreach ($call in $api) {
    $parts = $call.uri -split "/"
    $call.deel1 = $parts[3]
    $call.deel2 = $parts[4]
    $call.deel3 = $parts[5]
    $call.deel4 = $parts[6]
}

Write-Code ""

# verzamel alle namen, maak tabel met enkelvoudnamen
$tags = @()
foreach ($call in $api) {
    $tags += $call.deel1
    $tags += $call.deel2
    $tags += $call.deel3
}
$tags = $tags | Sort-Object -Unique | Where-Object {!$_.contains("{")} | Where-Object {$_}
$singletons = @{}
foreach ($tag in $tags) {
    $singletons[$tag] = Get-SingleTag -tag $tag
}

# genereer functies
foreach ($call in $api) {
    if ($call.deel1 -eq "search") {
        # GET /api/v2/search/{resources}
        $call.code = $Template1SearchResource.replace("{resources}",$call.deel2).replace("{resource}",$singletons[$call.deel2])
    } elseif ($call.deel2 -eq "{school_id}") {
        $resource = $singletons[$call.deel3]
        if ($call.Method -eq "GET") {  
            # GET /api/v2/schools/{school_id}/{resource}
            $call.code = $Template2GetSchoolResources.replace("{resources}", $call.deel3).replace("{resource}", $resource)
        } elseif ($call.Method -eq "POST") {
            # POST /api/v2/schools/{school_id}/{resource}
            $call.code = $Template3AddSchoolResource.replace("{resources}", $call.deel3).replace("{resource}", $resource)
        }
    } elseif ($call.deel2 -eq "{id}") {
        $resource = $singletons[$call.deel1]
        if ($call.Method -eq "GET") {  
            # GET /api/v2/{resource}/{id}
            $call.code = $Template4GetResource.replace("{resources}", $call.deel1).replace("{resource}", $resource)
        } elseif ($call.Method -eq "PATCH") {
            # PATCH /api/v2/{resource}/{id}
            $call.code = $Template5SetResource.replace("{resources}", $call.deel1).replace("{resource}", $resource)
        } elseif ($call.Method -eq "DELETE") {
            # DELETE /api/v2/{resource}/{id}
            $call.code = $Template6RemoveResource.replace("{resources}", $call.deel1).replace("{resource}", $resource)
        }
    } elseif ($call.deel3 -and !$call.deel4 -and ($call.deel3 -ne "{id}")) {
        $resource = $singletons[$call.deel1]
        $itemtype = $singletons[$call.deel3]        
        if ($call.Method -eq "GET") {  
            # GET /api/v2/{resource}/{id}
            $call.code = $Template7GetResourceItem.replace("{resources}", $call.deel1).replace("{resource}", $resource).replace("{itemtypes}", $call.deel3).replace("{itemtype}", $itemtype)
        } elseif ($call.Method -eq "POST") {
            # POST /api/v2/{resource}/{id}
            $call.code = $Template8AddResourceItem.replace("{resources}", $call.deel1).replace("{resource}", $resource).replace("{itemtypes}", $call.deel3).replace("{itemtype}", $itemtype)
        } elseif ($call.Method -eq "PATCH") {
            # PATCH /api/v2/{resource}/{id}
            $call.code = $Template9SetResourceItem.replace("{resources}", $call.deel1).replace("{resource}", $resource).replace("{itemtypes}", $call.deel3).replace("{itemtype}", $itemtype)
        }
    }
    if (!$call.Code) {
        $apicall = $call.Method + "_" + $call.URI.Replace("/","_").Replace("{","_").Replace("}","_")
        $call.code = $Template999NotYetImplemented.replace("{apicall}", $apicall)
    }
}

# Check: are there any duplicate functions? 
$api | Add-Member -MemberType NoteProperty -Name "Function" -Value "" 
ForEach ($call in $api) {    
    $call.Function = ($call.code -split " ")[1] # pak alleen functienaam uit code
}
$functionlist = $api | Select-Object -ExpandProperty Function | Sort-Object
$difflist = Compare-Object -ReferenceObject $functionlist -DifferenceObject ($functionlist | Sort-Object -Unique)
if ($difflist) {
    Write-Host "Warning: Duplicate function names found for:" -ForegroundColor Red
    Write-host $difflist.InputObject
} else {
    Write-Host "No Duplicate function names" -ForegroundColor Green
}

# output 
$api = $api | Sort-Object -Property URI
$implementedcounter = 0
foreach ($call in $api) {
    if ($call.Code) {
        # generate a comment line for every function
        write-code ("# {0}: {1} {2} ({3})" -f ($call.Resource, $call.Method, $call.URI, $call.Description))
        Write-Code $call.code
        $implementedcounter++
    }
}

Write-Code ("# {0} functions implemented" -f $implementedcounter)
Write-Host ("{0} functions implemented" -f $implementedcounter)
$code | Set-Content -Path $codefile -Force 
Write-Host "Generated code in file: $codefile"