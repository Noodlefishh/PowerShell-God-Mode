#================================================#
#========OUTIL POUR LA CRÉATION DES DFS-P========#
#===============V.7.0 - Janvier 2019 ============#
#================================================#

Import-Module ActiveDirectory

#Spécifie le DC actuel 
$domain = (Get-ADDomainController).hostname
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
                                                                                  
Write-Host ' _____ ______ _____  ___ _____ _____ _____ _   _  ____________ _____       ______ '
Write-Host '/  __ \| ___ \  ___|/ _ \_   _|_   _|  _  | \ | | |  _  \  ___/  ___|      | ___ \'
Write-Host '| /  \/| |_/ / |__ / /_\ \| |   | | | | | |  \| | | | | | |_  \ `--. ______| |_/ /'
Write-Host '| |    |    /|  __||  _  || |   | | | | | | . ` | | | | |  _|  `--. \______|  __/ '
Write-Host '| \__/\| |\ \| |___| | | || |  _| |_\ \_/ / |\  | | |/ /| |   /\__/ /      | |    '
Write-Host ' \____/\_| \_\____/\_| |_/\_/  \___/ \___/\_| \_/ |___/ \_|   \____/       \_|     '                                                                                                                                               
Write-Host  ""                                            
Write-Host ""  


########################################################################
############ 1 - Configuration des groupes niveau 1 et 2 ###############
########################################################################
#Input groupe premier niveau + Vérifications
$namePremierNiveau = Read-Host -Prompt "1/5 : Entrez le nom du groupe AD de niveau 1 (Ex : Prtg-Group-DPESF)  "

if ($namePremierNiveau -like '*PRTG*') {
    $namePremierNiveau = $namePremierNiveau
}
elseif ($namePremierNiveau -notlike '*PRTG*') {
    do {
        Write-Host "Mauvaise nomenclature, le nom doit commencer par PRTG-, recommencez S.V.P" -ForegroundColor Red
        $namePremierNiveau = Read-Host -Prompt "1/5 : Entrez le nom du groupe de premier niveau (Ex : Prtg-Group-DPESF)  "

    } until ($namePremierNiveau -like '*PRTG*')
}
else {
    Write-Host "erreur" -ForegroundColor Red
}

#Vérification si le groupe entré existe déjà
do {
    Write-Host "Working...Verification si le groupe existe" -ForegroundColor Cyan
    Start-Sleep -Seconds 2
    $testNiveau1 = Get-ADGroup -LDAPFilter "(SAMAccountName=$namePremierNiveau)"
    if ($testNiveau1 -ne $null) {
        Write-Host "le groupe existe deja, recommencez S.V.P " -ForegroundColor Red
        $namePremierNiveau = Read-Host -Prompt "1/5 : Entrez le nom du groupe AD de niveau 1 (Ex : Prtg-Group-DPESF)  "
    }
    elseif ($testNiveau1 -eq $null) {  
        Write-Host "Le groupe n'existe pas .. continuons" -ForegroundColor Green  
        Start-Sleep -Seconds 1
    }
    else {
        Write-Host "Erreur..."
    }
} while ($testNiveau1) {
}

#Input groupe second niveaux + Vérifications
$nameDeuxiemeNiveau = Read-Host -Prompt "2/5 : Entrez le nom du groupe AD de niveau 2 (Ex : Niveau-2) "

if (!$nameDeuxiemeNiveau) {
    do {
        Write-Host "Vous devez entrer un nom, Recommencez S.V.P"
        $nameDeuxiemeNiveau = Read-Host -Prompt "2/5 : Entrez le nom du groupe AD de niveau 2 (Ex : Niveau-2) "
    } until ($nameDeuxiemeNiveau)    
}
elseif ($nameDeuxiemeNiveau) {
    $nameDeuxiemeNiveau = $nameDeuxiemeNiveau
}
else {
    Write-Host "erreur" -ForegroundColor Red
}


#####################################
######### 2 - AUTOMATION  ###########
#####################################
#Description AD pour les deux groupes 
$descriptionPremierNiveau = "Donne l'acces au lecteur P: en regroupant les dossiers de niveaux 2" 
$descriptionDeuxiemeNiveau = "Acces au partage de 2 ieme Niveau (P:)"

#Création premier niveau
$OUPath = Read-Host -Prompt "Entrer le full OU Path"
$niveau1 = New-ADGroup -Name $namePremierNiveau -GroupScope Global -Description $descriptionPremierNiveau -GroupCategory Security -Path $OUPath -PassThru -Server $domain 

#Création des 3 groupes de seconds niveaux E, L et P
Write-Host "Working ...Creation des 3 groupes de niveau 2" -ForegroundColor Cyan
Start-Sleep -Seconds 2
$OUPathN2 = Read-Host -Promt "Entrer le full OU Path N2"
$OUPathN2 = Read-Host -Promt "Entrer le full OU Path N3"
$niveauP = New-ADGroup -Name "$namePremierNiveau-$nameDeuxiemeNiveau-P" -GroupScope Global -Description $descriptionDeuxiemeNiveau -GroupCategory Security -Path $OUPathN2 -PassThru -Server $domain
$niveauL = New-ADGroup -Name "$namePremierNiveau-$nameDeuxiemeNiveau-L" -GroupScope Global -Description $descriptionDeuxiemeNiveau -GroupCategory Security -Path $OUPathN2 -PassThru -Server $domain
$niveauE = New-ADGroup -Name "$namePremierNiveau-$nameDeuxiemeNiveau-E" -GroupScope Global -Description $descriptionDeuxiemeNiveau -GroupCategory Security -Path $OUPathN2 -PassThru -Server $domain

#Ajout des 3 groupes de second niveau dans le premier niveau
Write-Host "Working ...Ajout des 3 groupes de niveau 2 dans $namePremierNiveau" -ForegroundColor Cyan
Start-Sleep -Seconds 2
Add-ADGroupMember -Identity $niveau1 -Members $niveauP -Server $domain
Add-ADGroupMember -Identity $niveau1 -Members $niveauE -Server $domain
Add-ADGroupMember -Identity $niveau1 -Members $niveauL -Server $domain

#Configure le managed by du premier niveau avec groupe P
Write-Host "Working ...Configuration du 'Managed By'" -ForegroundColor Cyan
Start-Sleep -Seconds 2
Set-ADGroup -Identity $niveau1 -ManagedBy $niveauP -Server $domain | Out-Null


#################################################################
########  3 - CRÉATION DE LA STRUCTURE NIVEAU 1       ###########
#################################################################

#Input nom du pointeur DFS + Validation des entrées
$fileNiveau1 = Read-Host -Prompt "3/5 : Entrez le nom DFS : (Group - ASSIND) "

if (!$fileNiveau1) {
    do {
        Write-Host "Vous devez entrer un nom, Recommencez S.V.P"
        $fileNiveau1 = Read-Host -Prompt "3/5 : Entrez le nom DFS : (Group - ASSIND) "
    } until ($fileNiveau1)
}

elseif ($fileNiveau1) {
    $fileNiveau1 = $fileNiveau1
}
else {
    Write-Host "erreur" -ForegroundColor Red
}

#Input du path physique ou les données DFS seront hosté
$pathNiveau1 = Read-Host -Prompt "4/5 : Entrez le path physique ; " 
Write-Host "Test du path $pathNiveau1" -ForegroundColor Cyan
Start-Sleep -Seconds 2

do {
    $pathValide = Test-Path -Path $pathNiveau1

    if ($pathValide -eq $true) {

        Write-Host "Le path est valide !" -ForegroundColor Green
        Start-Sleep -Seconds '2'

        Write-Host "Working ... Creation du repertoire niveau 1 sur $pathNiveau1" -ForegroundColor Cyan
        Start-Sleep -Seconds '2'
        New-Item  -ItemType Directory -Path $pathNiveau1\$fileNiveau1 | Out-Null
        Start-Sleep -Seconds '2'
        Write-Host "Working ... Configuration des permissions NTFS sur $pathNiveau1\$fileNiveau1" -ForegroundColor Cyan
        Start-Sleep -Seconds '2'
        Add-NTFSAccess -Path "$pathNiveau1\$fileNiveau1" -Account "DOMAIN\$namePremierNiveau" -AccessRights Read, Traverse  -AppliesTo ThisFolderOnly

        #Desactiver l'heritage
        Write-Host "Working ... Desactivation de l'heritage sur $pathNiveau1\$fileNiveau1" -ForegroundColor Cyan
        Start-Sleep -Seconds '2'
        $SourceACL = Get-ACL -Path $pathNiveau1\$fileNiveau1
        $SourceACL.SetAccessRuleProtection($True, $True)
        Set-Acl -Path $pathNiveau1\$fileNiveau1 -AclObject $SourceACL

        #Retirer les permissions NTFS 
        Write-Host "Working ... Retrait du groupe 'Users' et 'Creator Owner' sur $fileNiveau1" -ForegroundColor Cyan
        Start-Sleep -Seconds '2'
        Remove-NTFSAccess -Path "$pathNiveau1\$fileNiveau1" -Account "BUILTIN\Utilisateurs, BUILTIN\Users" -AccessRights FullControl, Read, ReadAndExecute, ReadAttributes, ReadExtendedAttributes, ReadPermissions , Write, WriteAttributes, WriteExtendedAttributes | Out-Null
        icacls "$pathNiveau1\$fileNiveau1" /remove 'creator owner' everyone | Out-Null   

    }
    elseif ($pathValide -eq $False) {

        Write-Host "Le path est invalide, recommencez" -ForegroundColor Red
        Start-Sleep -Seconds '4'
        $pathNiveau1 = Read-Host -Prompt "5/6 : Entrez le path physique pour la DFS (Ex : \\SRV-DFS-03\DS-1$\Group) "

    }
    else {
        Write-Host "erreur" -ForegroundColor Red
    }
} until ($pathValide -eq $true)


#################################################################
########        4 - CRÉATION DE LA STRUCTURE DFS      ###########
#################################################################
#Creation DFS
Write-Host "Working ... Creation du pointeur DFS \\DOMAIN.qc.ca\partage\$fileNiveau1" -ForegroundColor Cyan
Start-Sleep -Seconds '1'
#setserver name and share path
New-DfsnFolder -Path "\\server\share\$fileNiveau1" -TargetPath "$pathNiveau1\$fileNiveau1" -EnableTargetFailback $false | Out-Null

#Grant DFS access au premier groupe
Write-Host "Working ... Autoriser DFSN Access" -ForegroundColor Cyan
Start-Sleep -Seconds '1'
#setserver name and share path
Grant-DfsnAccess -Path "\\server\share\$fileNiveau1" -AccountName "DOMAIN\$namePremierNiveau" | Out-Null

#Configure la vue explicite dans DFS avec dfsutil car non fonctionnelle en PowerShell
Write-Host "Working ... Configuration de la vue explicite DFS " -ForegroundColor Cyan
Start-Sleep -Seconds '1'
dfsutil property SD grant "\\server\share\$fileNiveau1" $namePremierNiveau:RX Protect | Out-Null

#################################################################
##########    5 - CRÉATION DE LA STRUCTURE NIVEAU 2   ##########
#################################################################
#Création du répertoire niveau 2
Write-Host "Working ... Creation du repertoire niveau 2 $pathNiveau1\$fileNiveau1\$nameDeuxiemeNiveau" -ForegroundColor Cyan
Start-Sleep -Seconds '2'
New-Item  -ItemType Directory -Path $pathNiveau1\$fileNiveau1\$nameDeuxiemeNiveau | Out-Null

#Paramétrage NTFS du niveau 2
Write-Host "Working ... Configuration des permissions NTFS sur $pathNiveau1\$fileNiveau1\$nameDeuxiemeNiveau" -ForegroundColor Cyan
Start-Sleep -Seconds '2'

#Set Domain 
Add-NTFSAccess -Path "$pathNiveau1\$fileNiveau1\$nameDeuxiemeNiveau" -Account "DOMAIN\$namePremierNiveau-$nameDeuxiemeNiveau-L" -AccessRights Read, ReadAndExecute, ReadAttributes, ReadData
Add-NTFSAccess -Path "$pathNiveau1\$fileNiveau1\$nameDeuxiemeNiveau" -Account "DOMAIN\$namePremierNiveau-$nameDeuxiemeNiveau-E" -AccessRights Read, ReadAndExecute, Write, Traverse, DeleteSubdirectoriesAndFiles
Add-NTFSAccess -Path "$pathNiveau1\$fileNiveau1\$nameDeuxiemeNiveau" -Account "DOMAIN\$namePremierNiveau-$nameDeuxiemeNiveau-P" -AccessRights Read, ReadAndExecute, Write, Traverse, DeleteSubdirectoriesAndFiles

#Activer l'héritage niveau 2
Write-Host "Working ... Activation de l'heritage sur $pathNiveau1\$fileNiveau1\$nameDeuxiemeNiveau" -ForegroundColor Cyan
Start-Sleep -Seconds '2'
$SourceACL = Get-ACL -Path $pathNiveau1\$fileNiveau1\$nameDeuxiemeNiveau
$SourceACL.SetAccessRuleProtection($False, $True)
Set-Acl -Path $pathNiveau1\$fileNiveau1\$nameDeuxiemeNiveau -AclObject $SourceACL

#Retirer les permissions NTFS Users
Remove-NTFSAccess -AccessRights FullControl -Account 'BUILTIN\Utilisateurs, BUILTIN\Users, BUILTIN\creator owner'  -Path "$pathNiveau1\$fileNiveau1\$nameDeuxiemeNiveau" | Out-Null

##########################################
#### LOOP AUTRES REPERTOIRE NIVEAU 2 #####
##########################################
#Demande d'ajout d'autres niveau 2
do {
    $reponseNiveau2 = Read-Host -Prompt "5/5 Voullez vous creer un autre repertoire de niveau 2 'O' ou 'N' ?"
    
    if ($reponseNiveau2 -eq 'O') {

        #Loop tant que le user n'entre pas de nom pour le répertoire
        do {
            $file2Niveau2 = Read-Host -Prompt "Entrez le nom du repertoire de niveau 2 (Ex: Actuariat)"
        } until ($file2Niveau2)

        Write-Host "Working ... Creation du repertoire niveau 2 $pathNiveau1\$fileNiveau1\$file2Niveau2" -ForegroundColor Cyan
        Start-Sleep -Seconds '3'
        New-Item  -ItemType Directory -Path $pathNiveau1\$fileNiveau1\$file2Niveau2 | Out-Null

        #Cretion des 3 groupes de seconds niveaux
        Write-Host "Working ...Creation des 3 groupes de niveau 2" -ForegroundColor Cyan
        Start-Sleep -Seconds 2
        $niveauP2 = New-ADGroup -Name "$namePremierNiveau-$file2Niveau2-P" -GroupScope Global -Description $descriptionDeuxiemeNiveau -GroupCategory Security -Path $OUPathN2 -PassThru -Server $domain
        $niveauL2 = New-ADGroup -Name "$namePremierNiveau-$file2Niveau2-L" -GroupScope Global -Description $descriptionDeuxiemeNiveau -GroupCategory Security -Path $OUPathN2 -PassThru -Server $domain
        $niveauE2 = New-ADGroup -Name "$namePremierNiveau-$file2Niveau2-E" -GroupScope Global -Description $descriptionDeuxiemeNiveau -GroupCategory Security -Path $OUPathN2 -PassThru -Server $domain

        #Ajout des 3 groupes de second niveau dans le premier niveau
        Write-Host "Working ...Ajout des 3 groupes de niveau 2 dans $namePremierNiveau" -ForegroundColor Cyan
        Start-Sleep -Seconds 2
        Add-ADGroupMember -Identity $niveau1 -Members $niveauP2 -Server $domain
        Add-ADGroupMember -Identity $niveau1 -Members $niveauE2 -Server $domain
        Add-ADGroupMember -Identity $niveau1 -Members $niveauL2 -Server $domain
            
        #Paramétrage NTFS du niveau 2
        Write-Host "Working ... Configuration des permissions NTFS sur $pathNiveau1\$fileNiveau1\$file2Niveau2" -ForegroundColor Cyan
        Start-Sleep -Seconds '2'

        #Set Domain
        Add-NTFSAccess -Path "$pathNiveau1\$fileNiveau1\$file2Niveau2" -Account "DOMAIN\$namePremierNiveau-$file2Niveau2-L" -AccessRights Read, ReadAndExecute, ReadAttributes, ReadData | Out-String
        Add-NTFSAccess -Path "$pathNiveau1\$fileNiveau1\$file2Niveau2" -Account "DOMAIN\$namePremierNiveau-$file2Niveau2-E" -AccessRights Read, ReadAndExecute, Write, Traverse, DeleteSubdirectoriesAndFiles | Out-String
        Add-NTFSAccess -Path "$pathNiveau1\$fileNiveau1\$file2Niveau2" -Account "DOMAIN\$namePremierNiveau-$file2Niveau2-P" -AccessRights Read, ReadAndExecute, Write, Traverse, DeleteSubdirectoriesAndFiles | Out-String

    } 
    elseif ($reponseNiveau2 -eq 'N') {
        Write-Host "Sortie..."

    }
    else {
        Write-Host "Veuillez choisir 'O' pour OUI ou 'N' pour NON.." -ForegroundColor Red
    }
} until ($reponseNiveau2 -eq 'N')

#Fin du script
Write-Host ""
Write-Host "SCRIPT COMPLETE" -ForegroundColor Cyan
Start-Sleep -Seconds '5' 

