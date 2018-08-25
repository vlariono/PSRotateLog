function Compress-IISLog
{

    <#
    .SYNOPSIS
    Performs gzip compression of IIS logs
    .DESCRIPTION
    Reads original logs from source directory and saves compressed logs to destination directory. The original files will be deleted after compression. The script won't rotate files which have been modified today.
    .EXAMPLE
    Compress-IISLogs -SourceDirectory D:\Log -DestinationDirectory D:\Archive
    #>
    #region Params
    [CmdletBinding()]
    param(
        # Source directory to read files from
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateScript( {Test-Path -Path $_ -PathType 'container'})]
        [System.IO.DirectoryInfo]
        $Path,
        # Destination directory to write archives to
        [Parameter(Position = 1, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Destination
    )
    #endregion

    $SourceDirectory = $Path
    $DestinationDirectory = $Destination

    Get-ChildItem -Path $SourceDirectory -Recurse -Exclude "*.gz"|ForEach-Object {
        if ($($_.Attributes -band [System.IO.FileAttributes]::Directory) -ne [System.IO.FileAttributes]::Directory)
        {
            #Current file
            $curFile = $_

            #Check the file wasn't modified today
            if ($curFile.LastWriteTime.Date -ne [System.DateTime]::Today)
            {

                $containedDir = $curFile.Directory.FullName.Replace($SourceDirectory, $DestinationDirectory)

                #if target directory doesn't exist - create
                if ($(Test-Path -Path "$containedDir") -eq $false)
                {
                    New-Item -Path "$containedDir" -ItemType directory|Out-Null
                }

                try
                {

                    Compress-File -InputFile $curFile -OutputFile "$containedDir\$($curFile.Name).gz"
                    Remove-Item -Path $curFile
                }
                catch {throw $_}
            }
        }
    }
}
