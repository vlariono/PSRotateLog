function Compress-File
{
    #region Params
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateScript( {Test-Path -Path $_ -PathType 'leaf'})]
        [System.String]
        $InputFile,
        [Parameter(Position = 1, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $OutputFile
    )
    #endregion

    try
    {
        #Creating buffer with size 8MB
        $bytesGZipFileBuffer = New-Object -TypeName byte[](8192)

        $streamGZipFileInput = New-Object -TypeName System.IO.FileStream($InputFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
        $streamGZipFileOutput = New-Object -TypeName System.IO.FileStream($OutputFile, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
        $streamGZipFileArchive = New-Object -TypeName System.IO.Compression.GZipStream($streamGZipFileOutput, [System.IO.Compression.CompressionMode]::Compress)

        for ($iBytes = $streamGZipFileInput.Read($bytesGZipFileBuffer, 0, $bytesGZipFileBuffer.Count);
            $iBytes -gt 0;
            $iBytes = $streamGZipFileInput.Read($bytesGZipFileBuffer, 0, $bytesGZipFileBuffer.Count))
        {

            $streamGZipFileArchive.Write($bytesGZipFileBuffer, 0, $iBytes)
        }

        $streamGZipFileArchive.Dispose()
        $streamGZipFileInput.Close()
        $streamGZipFileOutput.Close()

        Get-Item $OutputFile
    }
    catch { throw $_ }
}
