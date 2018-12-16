function Get-FileList
{
    [OutputType([System.IO.FileInfo])]
    #region Param
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateScript( {Test-Path -Path $_ -PathType 'Container'})]
        [System.IO.DirectoryInfo]
        $Path,
        [Parameter(Position = 1, Mandatory = $false)]
        [bool]
        $ListEmptyFolders = $false
    )
    #endregion
    process
    {
        $excludeItems = New-Object -TypeName System.Collections.ArrayList

        Get-ChildItem -Recurse -Force $Path|ForEach-Object {
            $fileCurrent = $_
            $itemIsNotExcluded = $true
            $itemIsFolder = $fileCurrent.Attributes -band [System.IO.FileAttributes]::Directory
            $folderIsEmpty = $itemIsFolder -and $ListEmptyFolders -and @(Get-ChildItem -Path $fileCurrent.FullName|Select-Object -First 1).Count -eq 0
            $itemIsReparsePoint = $fileCurrent.Attributes -band [System.IO.FileAttributes]::ReparsePoint
            $itemToBeRemoved = (!$itemIsFolder -or ($itemIsFolder -and $folderIsEmpty)) -and !$itemIsReparsePoint

            if ($itemIsReparsePoint)
            {
                $itemIsNotExcluded = $false
                $excludeItems.Add($fileCurrent)
            }
            else
            {
                $itemIsNotExcluded = $null -eq ($excludeItems | Where-Object {
                        $fileCurrent.FullName -match [regex]::Escape($_.FullName )
                    })
            }

            if ($itemToBeRemoved -and $itemIsNotExcluded)
            {
                Write-Output $fileCurrent
            }
        }
    }
}

function Remove-IISLogSize
{
    [OutputType([System.IO.FileInfo])]
    #region Param
    Param(
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $false,
            Position = 0)]
        [ValidateScript( {{Test-Path -Path $_ -PathType 'container'}})]
        [System.IO.DirectoryInfo]
        $Path,
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $false,
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [System.Int64]
        $Size
    )
    #endregion

    #Converting to List, otherwise array is fixed size
    $sortedList = [System.Collections.Generic.List`1[[System.Object, mscorlib, Version = 4.0.0.0, Culture = neutral, PublicKeyToken = b77a5c561934e089]]](Get-FileList -Path $Path|Sort-Object CreationTime)
    $folderSize = ($sortedList| Measure-Object -property length -sum).Sum

    while ($folderSize -gt $Size)
    {

        $item = $sortedList[0]

        Remove-Item -Path $item.FullName
        $sortedList.RemoveAt(0)

        $folderSize -= $item.Length
        Write-Output $item
    }
}

function Remove-IISLogCount
{
    #region Param
    Param(
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $false,
            Position = 0)]
        [ValidateScript( {{Test-Path -Path $_ -PathType 'container'}})]
        [System.IO.DirectoryInfo]
        $Path,
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $false,
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [System.Int64]
        $KeepFiles
    )
    #endregion

    $sortedList = Get-FileList -Path $Path|Sort-Object CreationTime
    #Number of files for removing
    $removeCount = $sortedList.Count - $KeepFiles

    if ($removeCount -gt 0)
    {
        $sortedList|Select-Object -First $removeCount|ForEach-Object {
            Remove-Item -Path $_.FullName
            Write-Output $_
        }
    }
}

function Remove-IISLogOlder
{
    #region Param
    Param(
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $false,
            Position = 0)]
        [ValidateScript( {{Test-Path -Path $_ -PathType 'container'}})]
        [System.IO.DirectoryInfo]
        $Path,
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $false,
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [System.DateTime]
        $Older,
        [Parameter(Position = 1, Mandatory = $false)]
        [bool]
        $RemoveEmptyFolders = $false
    )
    #endregion

    Get-FileList -Path $Path -ListEmptyFolders $RemoveEmptyFolders|Where-Object {$_.LastWriteTime -lt $Older}|ForEach-Object {
        Remove-Item -Path $_.FullName
        Write-Output $_
    }
}
