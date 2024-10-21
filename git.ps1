<#
.SYNOPSIS
    An assortment of functions for working with Git.
.EXAMPLE
    . .\git.ps1
    Imports the Git functions.
#>

function gitACP {
    <#
        .SYNOPSIS
        Runs `git add -A`, `git commit -m $Message`, and `git push` in one command.
        .EXAMPLE
        gitACP 'Added new file'
        This runs `git add -A` to add all modified files to the commit. It then runs `git commit -m 'Added new file'`. Finally, it pushes the changes to the remote destination with `git push`.
        .EXAMPLE
        gitACP 'Added new file' -Submodules
        With the `-Submodules` switch, this pulls in all new updates from any submodules. It then runs `git add -A` to add all modified files to the commit. It then runs `git commit -m 'Added new file'`. Finally, it pushes the changes to the remote destination with `git push`.
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true
        )]
        [string] $Message,
        [switch] $Submodules
    )
    git status -s
    if (!$?){
        return
    }
    if ($Submodules){
        git submodule update --remote --recursive 
    }
    git add -A
    git status -s
    git commit -m $Message
    git push
}
function gitSquash {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            Alias = 'SquashMessage'
        )]
        [string] $Message,
        [string] $SourceBranch = 'main'
    )
    git status -s
    if (!$?){
        return
    }
    git reset $(git merge-base $SourceBranch $(git branch --show-current))
    git add -A
    git commit -m $Message
    git push --force-with-lease
}
function gitSwitchBack {
    <#
        .SYNOPSIS
        Switches to the specified branch, then waits for instruction to switch back to the original branch.
    #>
    [CmdletBinding()]
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
    <#
        .SYNOPSIS
        Clones a single file from a repository.
    #>
    [CmdletBinding()]
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
    Push-Location -Path "$CurrentDir/$RepoName"
    git checkout HEAD "./$FilePath"
    Pop-Location
    $ErrorActionPreference = $CurrentEA
    return (Get-Item "$CurrentDir/$RepoName/$FilePath")
}
