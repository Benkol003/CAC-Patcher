
#param (
#    [string] $oldDir,
#    [string] $patchDir
#)

$ErrorActionPreference = "Inquire"

$oldDir = $PSScriptRoot + "\..\"
$patchDir = $PSScriptRoot

if($oldDir -eq "" -or $patchDir -eq "" ){
    Write-Output "missing parameters."
    exit
}

if(-not ((Test-Path -LiteralPath $patchDir) -and (Test-Path -LiteralPath ($patchDir +"\copy\")) -or (Test-Path -LiteralPath ($patchDir +"\patches\")) ) ){
    Write-Output "no patch inside the specified patch dir."
	exit
}

#make sure paths are ok and get absolute path
$oldDir = (Resolve-Path -LiteralPath ($oldDir + "\") ).Path
$patchDir = (Resolve-Path -LiteralPath ($patchDir + "\") ).Path

$patchDeltaDir = $patchDir+"patches\"
$files = Get-ChildItem -File -Recurse ($patchDeltaDir)

#check files to patch exist
$toExit = $false
foreach($fileObj in $files){
    $file = $fileObj.FullName
    $relFilePath = $file.substring($patchDeltaDir.Length, $file.Length - $patchDeltaDir.Length)
    $toPatchFile = ($oldDir + $relFilePath)
    if(-not (Test-Path -LiteralPath $toPatchFile)){
        Write-Output "Missing file: $toPatchFile"
        $toExit = $true
    }
}
if($toExit) {
    Write-Output "Will not attempt upgrade due to missing files."
    pause;
    exit;
}

##patch existing files - do this first so that if already patched will error rather than copying everything again
if((Test-Path -LiteralPath ($patchDir +"patches\"))){
    for($i = 0; $i -lt $files.Count; ++$i){
        $file = $files[$i].FullName
    
        #otherwise printing to console will be the bottleneck
        if ($i % 10 -eq 0){
            Write-Progress -Activity "Patching existing files" `
            -PercentComplete (($i + 1) / $files.Count * 100)
        }
    
        $relFilePath = $file.substring($patchDeltaDir.Length, $file.Length - $patchDeltaDir.Length)


        $null = .\hpatchz.exe ($oldDir + $relFilePath) ($patchDeltaDir + $relFilePath) ($oldDir + $relFilePath + ".patched")
        Move-Item -Force ($oldDir + $relFilePath + ".patched") ($oldDir + $relFilePath)
    }
}

### copy new files
if((Test-Path -LiteralPath ($patchDir +"copy\"))){
    $patchCopyDir = $patchDir+"copy\"
    $files = Get-ChildItem -File -Recurse ($patchCopyDir)
    for($i = 0; $i -lt $files.Count; ++$i){
        $file = $files[$i].FullName
    
        #otherwise printing to console will be the bottleneck
        if ($i % 50 -eq 0){
            Write-Progress -Activity "Copying new files" `
            -PercentComplete (($i + 1) / $files.Count * 100)
        }
    
        $relFilePath = $file.substring($patchCopyDir.Length, $file.Length - $patchCopyDir.Length)
    
        #create dirs
        $null = New-Item -f ($oldDir + $relFilePath)
        $null = Remove-Item ($oldDir + $relFilePath)
    
        $null = Copy-Item $file ($oldDir + $relFilePath)
    
    }
}




#TODO remove patch folder after success