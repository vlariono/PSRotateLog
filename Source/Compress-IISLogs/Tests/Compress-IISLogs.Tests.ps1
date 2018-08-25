$here = (Split-Path -Parent $MyInvocation.MyCommand.Path) -replace '\\Tests', ''
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
Get-ChildItem -Path $here -Recurse -Include "*.ps1" -Exclude '*.Tests.ps1'|ForEach-Object {
    . $_.FullName
}

function Get-RandomIPv4
{
    return [IPAddress]::Parse([String] (Get-Random) ).IPAddressToString
}

function Get-FakeLogContent
{
    $logContent = ("{0:yyyy}-{0:MM}-{0:dd} {0:hh}:{0:mm}:{0:ss} " +
        "{1} " +
        "GET /app_data/cache/f/3/a/4/8/b/f3a48b3711a4e3dcc707185318d4b7b360eb42bf.jpg " +
        "- 80 - " +
        "{2} " +
        "Mozilla/5.0+(iPhone;+CPU+iPhone+OS+10_0_1+like+Mac+OS+X)+AppleWebKit/602.1.50+" +
        "(KHTML,+like+Gecko)+Version/10.0+Mobile/14A403+Safari/602.1 " +
        "https://www.domain.com/page " +
        "200 0 0 0") -f (get-date), (RandomIPv4), (RandomIPv4)
    return $logContent
}


Describe "$here\$sut" {

    $logDirectory = New-Item -Path TestDrive:\Log -ItemType Directory
    $archiveDirectory = New-Item -Path TestDrive:\Archive -ItemType Directory

    context "Testing function Compress-File" {

        $log = New-Item -Path "$logDirectory\u_ex160927_x.log" -ItemType File


        1..100|ForEach-Object {
            Get-FakeLogContent|Add-Content -LiteralPath $log
        }

        $compressedFile = Compress-File -InputFile $log -OutputFile "$log.gz"

        it "Compressed file should exist" {
            $compressedFile|should exist
        }

        it "Compressed file shoud be gzip archive" {
            $content = (get-content -raw -Encoding Unknown -path $compressedFile).ToCharArray()[0]
            [convert]::ToInt32($content[0])|should be 35615
        }

        it "Compressed file should be bigger 2 bytes" {
            ($compressedFile.Length -gt 2)|should be $true
        }
    }

    context "Testing function Compress-IISLog" {

        $folder = Import-Clixml "$here\Tests\LogFolder.xml"

        mock Test-Path {
            if ($Path -match ([regex]::Escape($archiveDirectory) + '.+')) { $false }
            else { $true }
        }

        mock Get-ChildItem { $folder }
        mock Compress-File { New-Item "$OutputFile" } -Verifiable
        mock Remove-Item {}

        $result = Compress-IISLog -Path D:\Log -Destination "$archiveDirectory"

        it "Should mock functions" {
            Assert-VerifiableMock
        }

        it "Should remove 5 files. Remove-Item should be called 5 times" {
            Assert-MockCalled -CommandName Remove-Item -Times 5 -Exactly -Scope Context
        }

        it "Should archive 5 files" {
            $result.Count|should be 5

        }
    }
}











