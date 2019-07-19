Import-Module ActiveDirectory
Install-Module -Name GeneratePassword
Add-Type -AssemblyName System.Web

#### L'utilisateur entre le nom
$NomEntre = Read-Host -Prompt 'Entrer le nom de l utilisateur'
$Num = 0
$Nom = $NomEntre + "-0" + $Num
$Choix = 0

#### L'utilisateur doit entrer 1 ou 2 pour entrer le mot de passe ou le generer aleatoirement
Do{
Write-host "1 - Pour entrer un mot de passe manuellement"
Write-host "2 - Pour generer un mot de passe aleatoirement"
$Choix = Read-Host 
}

#### Le choix de l utilisateur est invalide
Until (($Choix -eq 1) -or ($Choix -eq 2))

#### L utilisateur a choisi d entrer le mot de passe
If ($Choix -eq 1){
$Mdp = Read-Host -Prompt 'Entrer le mot de passe:'
$Password    = (ConvertTo-SecureString -AsPlainText '$Mdp' -Force)
}
#### L utilisateur a choisi de generer le mot de passe aleatoirement
elseif($Choix -eq 2)
{
$RandomMdp = [System.Web.Security.Membership]::GeneratePassword(10,3)
Write-host 'Le mot de passe est :' $RandomMdp
$Password    = (ConvertTo-SecureString -AsPlainText '$RandomMdp' -Force)
}


#### On verifie que l'utilisateur n'existe pas
For($i=0;$i -le 10; $i ++){
    If ((Get-ADuser -LDAPFilter "(SAMAccountName=$Nom)") -eq $null){}

#### S il existe, on le supprime et on ajoute 1 au nom
Else{
    Remove-ADUser -Identity $Nom -Confirm:$false
    $Num++
    $Nom = $NomEntre + "-0" + $Num
}

#### Les variable sont enregistrees dans les parametre
$Parameters = @{

    'Name'                  = $Nom
    'SamAccountName'        = $Nom
    'AccountPassword'       = $Password  
    'Enabled'               = $true 
}}

#### L utilisateur est cree avec les parametres definis
New-ADUser @Parameters