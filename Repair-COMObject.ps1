# Remove the COM+ Application which was hosting the UpdateNotify.Object
Write-Host "Remove the OfficeC2RCom COM+ App if exists"
$comCatalog = New-Object -ComObject COMAdmin.COMAdminCatalog
$appColl = $comCatalog.GetCollection("Applications")
$appColl.Populate()

foreach($app in $appColl)
{
    if ($app.Name -eq "OfficeC2RCom")
    {
      $appColl.Remove($index)
      $appColl.SaveChanges()
    }
    $index++
}

# Create a COM+ application to host UpdateNotify.Object
$comAdmin = New-Object -comobject COMAdmin.COMAdminCatalog
$apps = $comAdmin.GetCollection("Applications")
$apps.Populate();


$newComPackageName = "OfficeC2RCom"

$app = $apps | Where-Object {$_.Name -eq $newComPackageName}

if ($app) 
{
    # OfficeC2RCom app already exists. Output some info about it
    Write-Output ""
    $appname = $app.Value("Name")
    "This COM+ Application already exists : $appname"
    Write-Output ""

    "ID: " +  $app.Value("ID")
    "Identity: " +  $app.Value("Identity")
    "ApplicationDirectory: " + $app.Value("ApplicationDirectory")
    "ConcurrentApps:" + $app.Value("ConcurrentApps")
    "RecycleCallLimit:" + $app.Value("RecycleCallLimit")
    "Activation:" + $app.Value("Activation")
    "ApplicationAccessChecksEnabled:" + $app.Value("ApplicationAccessChecksEnabled")
    Write-Output ""
}
Else
{
    # OfficeC2RCom app doesn't exist, create the App object

    Write-Output "Adding OfficeC2RCom COM+ Application..."

    Try
    {
      $app = $apps.Add()
      $app.Value("Name") = $newComPackageName
      $app.Value("Identity") = "NT AUTHORITY\LocalService"
      $app.Value("ApplicationAccessChecksEnabled") = 1
      $app.Value("ID") = "{F6B836D9-AF6A-4D05-9A19-E906A0F34770}"
      $saveChangesResult = $apps.SaveChanges()
      "Results of the Apps SaveChanges operation : $saveChangesResult"

      $appid = $app.Value("ID")

      # Adding roles
      Write-Output "Adding Administrator role to $newComPackageName"
      $roles = $apps.GetCollection("Roles", $app.Key)
      $roles.Populate()
      $role = $roles.Add()
      $role.Value("Name") = "Administrator"
      $saveChangesResult = $roles.SaveChanges()
      "Results of the Roles SaveChanges operation : $saveChangesResult"

      # Get the localized string of the Builtin\Administrators
      $id = [System.Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid
      $Account = New-Object System.Security.Principal.SecurityIdentifier($id, $null)
      $localizedAdministrators = $Account.Translate([System.Security.Principal.NTAccount]).Value
      "Results of the localized administrators string : $localizedAdministrators"
      # Adding BUILTIN\Administrators to the Administrator Role
      $users = $roles.GetCollection("UsersInRole", $role.Key)
      $users.Populate()
      $user = $users.Add()
      $user.Value("User") = $localizedAdministrators
      $saveChangesResult = $users.SaveChanges()
      "Results of the Users SaveChanges operation : $saveChangesResult"
    }
    catch
    {
      Write-Output "Failed to add OfficeC2RCom as COM+ application."
      exit
    }

    Write-Output "Successfully added COM+ application: $newComPackageName, id: $appid"
}

# Adding the UpdateNotify.Object as the component of OfficeC2RCom
$comps = $apps.GetCollection("Components", $app.Key)
$comps.Populate()
$newCompName = "UpdateNotify.Object.1"

$comp = $comps | Where-Object {$_.Name -eq "UpdateNotify.Object.1"}

if ($comp)
{
  "The $newCompName already exists!"
}
Else
{
  Try
  {
    $comAdmin.ImportComponent($newComPackageName, $NewCompName)
  }
  catch
  {
      Write-Output "Failed to add $newCompName to $newComPackageName"
      exit
  }
  Write-Output "Successfully added $newCompName to $newComPackageName"
} 