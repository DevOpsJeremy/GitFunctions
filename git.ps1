<#
.SYNOPSIS
    A short one-line action-based description, e.g. 'Tests if a function is valid'
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.
.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
#>

function gitACP {
    param (
        [Parameter(
            Mandatory = $true
        )]
        [string] $Message,
        [switch] $Submodules
    )
    git status -s
    if ($?){
        if ($Submodules){
            git submodule update --remote --recursive 
        }
        git add -A
        git status -s
        git commit -m $Message
        git push
    }
}
function gitSwitchBack {
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [string]$DestinationBranch,
        [Parameter(
            Position = 1
        )]
        [string]$SourceBranch
    )
    if (!$PSBoundParameters.ContainsKey('SourceBranch')){
        $SourceBranch = git rev-parse --abbrev-ref HEAD
    }
    if ($?){
        git switch $DestinationBranch
        if ($?){
            $Msg = "`nPress Enter to switch back to '{0}'" -f $SourceBranch
            Read-Host $Msg | Out-Null
            git switch $SourceBranch
        }
    }
}
function gitSingleFile {
    param (
        [ValidateScript({
            if (!($_ -match "\.git$")){
                throw [System.Management.Automation.ParameterBindingException] "Invalid repository path."
            } else {
                $true
            }
        })]
        $RepoPath,
        $FilePath
    )
    $CurrentEA = $ErrorActionPreference
    $ErrorActionPreference = "Stop"
    $CurrentDir = $(Get-Location).Path
    [System.Collections.ArrayList]$RepoNameSplit = (Split-Path $RepoPath -Leaf).Split('.')
    $RepoNameSplit.Remove($RepoNameSplit[-1])
    [string]$RepoName = $RepoNameSplit -join '.'
    git clone -n $RepoPath --depth 1
    Set-Location "$CurrentDir/$RepoName"
    git checkout HEAD "./$FilePath"
    Set-Location $CurrentDir
    $ErrorActionPreference = $CurrentEA
    return (Get-Item "$CurrentDir/$RepoName/$FilePath")
}