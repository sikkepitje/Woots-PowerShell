
#region Get-AllResources-functies
Function Get-WootsAllLabels($id) { return Get-WootsAllSchoolResources -resource "labels" }
Function Get-WootsAllClasses($id) { return Get-WootsAllSchoolResources -resource "classes" }
Function Get-WootsAllCourses($id) { return Get-WootsAllSchoolResources -resource "courses" }
Function Get-WootsAllDepartments($id) { return Get-WootsAllSchoolResources -resource "departments" }
Function Get-WootsAllLocations($id) { return Get-WootsAllSchoolResources -resource "locations" }
Function Get-WootsAllPeriods($id) { return Get-WootsAllSchoolResources -resource "periods" }
Function Get-WootsAllRoles($id) { return Get-WootsAllSchoolResources -resource "roles" }
Function Get-WootsAllUsers($id) { return Get-WootsAllSchoolResources -resource "users" }
#endregion
#region Search-ResourceByValue-functies
Function Search-WootsAssignment($parameter) {return Search-WootsResource -resource "assignments" -parameter $parameter}
Function Search-WootsCourse($parameter) {return Search-WootsResource -resource "courses" -parameter $parameter}
Function Search-WootsGroup($parameter) {return Search-WootsResource -resource "groups" -parameter $parameter}
Function Search-WootsDepartment($parameter) {return Search-WootsResource -resource "departments" -parameter $parameter}
Function Search-WootsQuestion_Bank_Assignment($parameter) {return Search-WootsResource -resource "question_bank_assignments" -parameter $parameter}
Function Search-WootsResult($parameter) {return Search-WootsResource -resource "results" -parameter $parameter}
Function Search-WootsTimeslot($parameter) {return Search-WootsResource -resource "timeslots" -parameter $parameter}
Function Search-WootsUser($parameter) {return Search-WootsResource -resource "users" -parameter $parameter}
#endregion
#region Add-Resource-functies
Function Add-WootsClass($parameter) {return Add-WootsSchoolResource -resource "classes" -parameter $parameter}
Function Add-WootsCourse($parameter) {return Add-WootsSchoolResource -resource "courses" -parameter $parameter}
Function Add-WootsDepartment($parameter) {return Add-WootsSchoolResource -resource "departments" -parameter $parameter}
Function Add-WootsLabel($parameter) {return Add-WootsSchoolResource -resource "labels" -parameter $parameter}
Function Add-WootsLocation($parameter) {return Add-WootsSchoolResource -resource "locations" -parameter $parameter}
Function Add-WootsPeriod($parameter) {return Add-WootsSchoolResource -resource "periods" -parameter $parameter}
Function Add-WootsUser($parameter) {return Add-WootsSchoolResource -resource "users" -parameter $parameter}
#endregion
#region Get-ResourceById-functies
Function Get-WootsAssignment($id) { return Get-WootsResourceById -resource "assignments" -id $id }
Function Get-WootsBackground_Job($id) { return Get-WootsResourceById -resource "background_jobs" -id $id }
Function Get-WootsBlueprint($id) { return Get-WootsResourceById -resource "blueprints" -id $id }
Function Get-WootsClass($id) { return Get-WootsResourceById -resource "classes" -id $id }
Function Get-WootsComment($id) { return Get-WootsResourceById -resource "comments" -id $id }
Function Get-WootsCourse($id) { return Get-WootsResourceById -resource "courses" -id $id }
Function Get-WootsCourses_User($id) { return Get-WootsResourceById -resource "courses_users" -id $id }
Function Get-WootsDepartment($id) { return Get-WootsResourceById -resource "departments" -id $id }
Function Get-WootsDomain($id) { return Get-WootsResourceById -resource "domains" -id $id }
Function Get-WootsExercise($id) { return Get-WootsResourceById -resource "exercises" -id $id }
Function Get-WootsGroup($id) { return Get-WootsResourceById -resource "groups" -id $id }
Function Get-WootsLabel($id) { return Get-WootsResourceById -resource "labels" -id $id }
Function Get-WootsLocation($id) { return Get-WootsResourceById -resource "locations" -id $id }
Function Get-WootsNotification($id) { return Get-WootsResourceById -resource "notifications" -id $id }
Function Get-WootsObjective($id) { return Get-WootsResourceById -resource "objectives" -id $id }
Function Get-WootsPeriod($id) { return Get-WootsResourceById -resource "periods" -id $id }
Function Get-WootsPlan($id) { return Get-WootsResourceById -resource "plans" -id $id }
Function Get-WootsPublication_Timeslot($id) { return Get-WootsResourceById -resource "publication_timeslots" -id $id }
Function Get-WootsQuestion_Bank_Assignment($id) { return Get-WootsResourceById -resource "question_bank_assignments" -id $id }
Function Get-WootsQuestion_Bank_Exercise($id) { return Get-WootsResourceById -resource "question_bank_exercises" -id $id }
Function Get-WootsQuestion_Bank_Label($id) { return Get-WootsResourceById -resource "question_bank_labels" -id $id }
Function Get-WootsQuestion_Bank($id) { return Get-WootsResourceById -resource "question_banks" -id $id }
Function Get-WootsQuestion($id) { return Get-WootsResourceById -resource "questions" -id $id }
Function Get-WootsRequirement($id) { return Get-WootsResourceById -resource "requirements" -id $id }
Function Get-WootsResult($id) { return Get-WootsResourceById -resource "results" -id $id }
Function Get-WootsSchool($id) { return Get-WootsResourceById -resource "schools" -id $id }
Function Get-WootsScore_Mark($id) { return Get-WootsResourceById -resource "score_marks" -id $id }
Function Get-WootsStudy($id) { return Get-WootsResourceById -resource "studies" -id $id }
Function Get-WootsSubmission($id) { return Get-WootsResourceById -resource "submissions" -id $id }
Function Get-WootsSubscription($id) { return Get-WootsResourceById -resource "subscriptions" -id $id }
Function Get-WootsTask($id) { return Get-WootsResourceById -resource "tasks" -id $id }
Function Get-WootsTimeslot($id) { return Get-WootsResourceById -resource "timeslots" -id $id }
Function Get-WootsUser($id) { return Get-WootsResourceById -resource "users" -id $id }
Function Get-WootsWebhook($id) { return Get-WootsResourceById -resource "webhooks" -id $id }
#endregion
#region Set-ResourceById-functies
Function Set-WootsAssignment($id,$parameter) {return Set-WootsResourceById -resource "assignments" -id $id -parameter $parameter}
Function Set-WootsBackground_Job($id,$parameter) {return Set-WootsResourceById -resource "background_jobs" -id $id -parameter $parameter}
Function Set-WootsClass($id,$parameter) {return Set-WootsResourceById -resource "classes" -id $id -parameter $parameter}
Function Set-WootsComment($id,$parameter) {return Set-WootsResourceById -resource "comments" -id $id -parameter $parameter}
Function Set-WootsCourse($id,$parameter) {return Set-WootsResourceById -resource "courses" -id $id -parameter $parameter}
Function Set-WootsCourses_User($id,$parameter) {return Set-WootsResourceById -resource "courses_users" -id $id -parameter $parameter}
Function Set-WootsDepartment($id,$parameter) {return Set-WootsResourceById -resource "departments" -id $id -parameter $parameter}
Function Set-WootsDomain($id,$parameter) {return Set-WootsResourceById -resource "domains" -id $id -parameter $parameter}
Function Set-WootsExercise($id,$parameter) {return Set-WootsResourceById -resource "exercises" -id $id -parameter $parameter}
Function Set-WootsGroup($id,$parameter) {return Set-WootsResourceById -resource "groups" -id $id -parameter $parameter}
Function Set-WootsLabel($id,$parameter) {return Set-WootsResourceById -resource "labels" -id $id -parameter $parameter}
Function Set-WootsLocation($id,$parameter) {return Set-WootsResourceById -resource "locations" -id $id -parameter $parameter}
Function Set-WootsObjective($id,$parameter) {return Set-WootsResourceById -resource "objectives" -id $id -parameter $parameter}
Function Set-WootsPeriod($id,$parameter) {return Set-WootsResourceById -resource "periods" -id $id -parameter $parameter}
Function Set-WootsPlan($id,$parameter) {return Set-WootsResourceById -resource "plans" -id $id -parameter $parameter}
Function Set-WootsPublication_Timeslot($id,$parameter) {return Set-WootsResourceById -resource "publication_timeslots" -id $id -parameter $parameter}
Function Set-WootsQuestion_Bank_Assignment($id,$parameter) {return Set-WootsResourceById -resource "question_bank_assignments" -id $id -parameter $parameter}
Function Set-WootsQuestion_Bank_Exercise($id,$parameter) {return Set-WootsResourceById -resource "question_bank_exercises" -id $id -parameter $parameter}
Function Set-WootsQuestion_Bank_Label($id,$parameter) {return Set-WootsResourceById -resource "question_bank_labels" -id $id -parameter $parameter}
Function Set-WootsQuestion_Bank($id,$parameter) {return Set-WootsResourceById -resource "question_banks" -id $id -parameter $parameter}
Function Set-WootsQuestion($id,$parameter) {return Set-WootsResourceById -resource "questions" -id $id -parameter $parameter}
Function Set-WootsRequirement($id,$parameter) {return Set-WootsResourceById -resource "requirements" -id $id -parameter $parameter}
Function Set-WootsResult($id,$parameter) {return Set-WootsResourceById -resource "results" -id $id -parameter $parameter}
Function Set-WootsSchool($id,$parameter) {return Set-WootsResourceById -resource "schools" -id $id -parameter $parameter}
Function Set-WootsScore_Mark($id,$parameter) {return Set-WootsResourceById -resource "score_marks" -id $id -parameter $parameter}
Function Set-WootsStudy($id,$parameter) {return Set-WootsResourceById -resource "studies" -id $id -parameter $parameter}
Function Set-WootsSubmission($id,$parameter) {return Set-WootsResourceById -resource "submissions" -id $id -parameter $parameter}
Function Set-WootsSubscription($id,$parameter) {return Set-WootsResourceById -resource "subscriptions" -id $id -parameter $parameter}
Function Set-WootsTask($id,$parameter) {return Set-WootsResourceById -resource "tasks" -id $id -parameter $parameter}
Function Set-WootsTimeslot($id,$parameter) {return Set-WootsResourceById -resource "timeslots" -id $id -parameter $parameter}
Function Set-WootsUser($id,$parameter) {return Set-WootsResourceById -resource "users" -id $id -parameter $parameter}
Function Set-WootsWebhook($id,$parameter) {return Set-WootsResourceById -resource "webhooks" -id $id -parameter $parameter}
#endregion
#region Remove-ResourceById-functies
Function Remove-WootsAssignment($id,$parameter) {return Remove-WootsResourceById -resource "assignments" -id $id -parameter $parameter}
Function Remove-WootsClass($id,$parameter) {return Remove-WootsResourceById -resource "classes" -id $id -parameter $parameter}
Function Remove-WootsCourse($id,$parameter) {return Remove-WootsResourceById -resource "courses" -id $id -parameter $parameter}
Function Remove-WootsCourses_User($id,$parameter) {return Remove-WootsResourceById -resource "courses_users" -id $id -parameter $parameter}
Function Remove-WootsDepartment($id,$parameter) {return Remove-WootsResourceById -resource "departments" -id $id -parameter $parameter}
Function Remove-WootsDomain($id,$parameter) {return Remove-WootsResourceById -resource "domains" -id $id -parameter $parameter}
Function Remove-WootsExercise($id,$parameter) {return Remove-WootsResourceById -resource "exercises" -id $id -parameter $parameter}
Function Remove-WootsGroup($id,$parameter) {return Remove-WootsResourceById -resource "groups" -id $id -parameter $parameter}
Function Remove-WootsLabel($id,$parameter) {return Remove-WootsResourceById -resource "labels" -id $id -parameter $parameter}
Function Remove-WootsLocation($id,$parameter) {return Remove-WootsResourceById -resource "locations" -id $id -parameter $parameter}
Function Remove-WootsObjective($id,$parameter) {return Remove-WootsResourceById -resource "objectives" -id $id -parameter $parameter}
Function Remove-WootsPeriod($id,$parameter) {return Remove-WootsResourceById -resource "periods" -id $id -parameter $parameter}
Function Remove-WootsPlan($id,$parameter) {return Remove-WootsResourceById -resource "plans" -id $id -parameter $parameter}
Function Remove-WootsPublication_Timeslot($id,$parameter) {return Remove-WootsResourceById -resource "publication_timeslots" -id $id -parameter $parameter}
Function Remove-WootsQuestion_Bank_Assignment($id,$parameter) {return Remove-WootsResourceById -resource "question_bank_assignments" -id $id -parameter $parameter}
Function Remove-WootsQuestion_Bank_Exercise($id,$parameter) {return Remove-WootsResourceById -resource "question_bank_exercises" -id $id -parameter $parameter}
Function Remove-WootsQuestion_Bank_Label($id,$parameter) {return Remove-WootsResourceById -resource "question_bank_labels" -id $id -parameter $parameter}
Function Remove-WootsQuestion_Bank($id,$parameter) {return Remove-WootsResourceById -resource "question_banks" -id $id -parameter $parameter}
Function Remove-WootsQuestion($id,$parameter) {return Remove-WootsResourceById -resource "questions" -id $id -parameter $parameter}
Function Remove-WootsRequirement($id,$parameter) {return Remove-WootsResourceById -resource "requirements" -id $id -parameter $parameter}
Function Remove-WootsScore_Mark($id,$parameter) {return Remove-WootsResourceById -resource "score_marks" -id $id -parameter $parameter}
Function Remove-WootsStudy($id,$parameter) {return Remove-WootsResourceById -resource "studies" -id $id -parameter $parameter}
Function Remove-WootsSubscription($id,$parameter) {return Remove-WootsResourceById -resource "subscriptions" -id $id -parameter $parameter}
Function Remove-WootsTask($id,$parameter) {return Remove-WootsResourceById -resource "tasks" -id $id -parameter $parameter}
Function Remove-WootsTimeslot($id,$parameter) {return Remove-WootsResourceById -resource "timeslots" -id $id -parameter $parameter}
Function Remove-WootsUser($id,$parameter) {return Remove-WootsResourceById -resource "users" -id $id -parameter $parameter}
Function Remove-WootsWebhook($id,$parameter) {return Remove-WootsResourceById -resource "webhooks" -id $id -parameter $parameter}
#endregion
