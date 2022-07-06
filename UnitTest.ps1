<#
    UnitTest.ps1

    dit moet de module Woots testen. Hoe doen we dat?
    Eigen testfuncties
#>

$herePath = Split-Path -parent $MyInvocation.MyCommand.Definition
. "$herepath\WootsInit-Staging.ps1"

Function Resultaat($tekst, $is, $verwacht) {
    Write-Host "Controle: $tekst, " -NoNewline -ForegroundColor yellow
    Write-Host "Is $is " -NoNewline -ForegroundColor yellow 
    write-host "Verwacht $verwacht " -NoNewline -ForegroundColor cyan
    if ($is -eq $verwacht) {
        write-host "Slaagt" -ForegroundColor Green
    } else {
        write-host "Faalt" -ForegroundColor red 
    }
}

# ======== MAIN ========

# test enkele bulkopdrachten
$result = Get-WootsAllQuestionBank

$result = Get-WootsAllBackgroundJob
$result = Get-WootsAllComment

$result = Get-WootsAllNotification
$result = Get-WootsAllWebhook
$result = Get-WootsAllRole

return

$users = Search-WootsUser @{last_name = "Abernathy"}
Resultaat "Search-WootsUser zoek users" $users.count "6"

# Bewerkingen op users
$uid = 1428571 # Wilbur van der Abernathy
$nummer = Get-Random 1000
$result = Set-WootsUser -id $uid @{student_number = $nummer}
$user = Get-WootsUser -id $uid
Resultaat "Set-User student_nummer" ($user.student_number -as [int]) $nummer
Resultaat "Set-User student_nummer" (0 + $user.student_number) $nummer

# Bewerkingen op courses
$courses = Search-WootsCourse @{trashed="false"} -MaxItems 20
Resultaat "Search-WootsCourse aantal items" $courses.count 20
$courses = Get-WootsAllCourse -MaxItems 1MB
Resultaat "Get-WootsAllCourse aantal is meer dan 300" ($courses.count -gt 300) $True
$cid = ($courses | Select-Object -first 1).id 
$result = Set-WootsCourse -id $cid -parameter @{name = "5V Tuareg"; course_code = "Naam gewijzigd"}
$result = Get-WootsCourse -id $cid
Resultaat "Course course_code gewijzigd" $result.course_code "Naam gewijzigd"
$result = Set-WootsCourse -id $cid -parameter @{name = "5H Tuareg"; course_code = ""}
$result = Get-WootsCourse -id $cid
Resultaat "Course naam gewijzigd" $result.name "5H Tuareg"

# undelete/delete course
$cid = 160972  # trashed course "5H Tuareg"
$result = Get-WootsCourse -id $cid
Resultaat "Get-WootsCourse trashed=true" $result.trashed $True

$result = set-WootsCourse -id $cid @{ trashed = "false"}
$result = Get-WootsCourse -id $cid
Resultaat "Set-WootsCourse trashed=false" $result.trashed $False

$result = Remove-WootsCourse -id $cid
$result = Get-WootsCourse -id $cid
Resultaat "Remove-WootsCourse" $result.trashed $True

