function Remove-IISLog
{
    <#
    .SYNOPSIS
        Removes logs
    .DESCRIPTION
        Log removing based on directory size, files count, files age
    .EXAMPLE
        C:\PS> Remove-IISLog -Path C:\Inetpub\Logs -FolderSize 100MB
        Removes old files and keeps only 100MB of the newest files
    .EXAMPLE
        C:\PS> Remove-IISLog -Path C:\Inetpub\Logs -KeepFiles 10
        Keeps 10 newest files
    .EXAMPLE
        C:\PS> Remove-IISLog -Path D:\Logs2 -Older ([datetime]::now.AddDays(-10))
        Removes files older 10 days
    #>
    [CmdletBinding(DefaultParameterSetName = 'FolderSize')]
    [OutputType([System.IO.FileInfo])]
    #region Param
    Param(
        # Path to log directory
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $false,
            Position = 0)]
        [ValidateScript( {{Test-Path -Path $_ -PathType 'container'}})]
        [System.IO.DirectoryInfo]
        $Path,
        # Folder size to keep
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $false,
            Position = 1,
            ParameterSetName = 'FolderSize')]
        [ValidateNotNullOrEmpty()]
        [System.Int64]
        $FolderSize,
        # Number of files to keep
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $false,
            Position = 1,
            ParameterSetName = 'FilesNumber')]
        [ValidateNotNullOrEmpty()]
        [System.Int64]
        $KeepFiles,
        # Remove files older than specified
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $false,
            Position = 1,
            ParameterSetName = 'FilesAge')]
        [ValidateNotNullOrEmpty()]
        [System.DateTime]
        $Older,
        [Parameter(Position = 1, Mandatory = $false)]
        [switch]
        $RemoveEmptyFolders
    )
    switch ($PSCmdlet.ParameterSetName)
    {
        'FolderSize'
        {
            Remove-IISLogSize -Path $Path -Size $FolderSize
            break
        }
        'FilesNumber'
        {
            Remove-IISLogCount -Path $Path -KeepFiles $KeepFiles
            break
        }
        'FilesAge'
        {
            Remove-IISLogOlder -Path $Path -Older $Older -RemoveEmptyFolders $RemoveEmptyFolders
            break
        }
    }
    #endregion
}
