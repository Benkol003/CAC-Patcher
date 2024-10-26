# iterate over files in new dir
# compare to old dir
# either is a new file to be copied, or requires an xdelta patch
# remove old files? but which ones to ignore eg. mod folder and root dir bikeys


#tool will create xdelta patches for changed files in delta\, new files in cp\

########## TODOS ##########
# add .patch extensions? (and remove this in unpacker)
# be able to have patch dir in same folder as dir to update to/from or throw error if this is the case

param (
    [string] $oldDir,
    [string] $newDir,
    [string] $patchDir
)

$ErrorActionPreference = "Inquire"

###############
function Create-PatchDiff {
	param (
    [string]$SourceFile,
    [string]$TargetFile,
    [string]$PatchFile
)

$sourceHash = (Get-FileHash -Path $SourceFile -Algorithm MD5).Hash
$targetHash = (Get-FileHash -Path $TargetFile -Algorithm MD5).Hash	

if ($sourceHash -ne $targetHash) {
    # Create a patch if the files are different

    #make sure subdirectories are created
    $null = New-Item -f $PatchFile
    $null = Remove-Item $PatchFile
    $null = .\hdiffz.exe -s-512 -p-16 $SourceFile $TargetFile $PatchFile
}

}
###############

if($oldDir -eq "" -or $newDir -eq "" -or $patchDir -eq "" ){
    Write-Output "missing parameters."
    exit
}

#has to exist for Resolve-Path to work
if(-Not (Test-Path -LiteralPath $patchDir) ){
    $null = new-Item -ItemType "directory" -Path $patchDir
}


#make sure paths are ok and get absolute path
$newDir = (Resolve-Path -LiteralPath ($newDir + "\") ).Path
$oldDir = (Resolve-Path -LiteralPath ($oldDir + "\") ).Path
$patchDir = (Resolve-Path -LiteralPath ($patchDir + "\") ).Path


if($patchDir -like "$newDir*"){
    Remove-Item $patchDir
    Write-Output "Patch directory cannot be in new version directory."
    exit
}



$files = Get-ChildItem -File -Recurse $newDir

#iterate over files in the new dir, so miss extra files in the old dir that dont need to be overwritten e.g. CAC Launcher
for($i = 0; $i -lt $files.Count; ++$i){

    $file = $files[$i].FullName

    #otherwise printing to console will be the bottleneck
    if ($i % 50 -eq 0){
        Write-Progress -Activity "Generating Patch" `
        -PercentComplete (($i + 1) / $files.Count * 100)
    }


    $relFilePath = $file.substring($newDir.Length, $file.Length - $newDir.Length)

    if(Test-Path -LiteralPath $($oldDir + $relFilePath)){ #need LiteralPath otherwise breaks with special characters such as []
        Create-PatchDiff ($oldDir + $relFilePath) ($newDir + $relFilePath) ($patchDir + "patches\" + $relFilePath)
    } else{
        #we have a new file not in old dir, so just copy
        $patchFile = $patchDir + "copy\" + $relFilePath
        #create dirs
        $null = New-Item -f $PatchFile
        $null = Remove-Item $PatchFile

        $null = Copy-Item $file $patchFile
    }
    
    
}

#TODO copy xdelta and a unpack script
Copy-Item .\hpatchz.exe $patchDir
Copy-Item .\Patcher.ps1 $patchDir
Copy-Item .\Patcher.bat $patchDir
Copy-Item .\readme.md $patchDir

#TODO delete patch if fails
