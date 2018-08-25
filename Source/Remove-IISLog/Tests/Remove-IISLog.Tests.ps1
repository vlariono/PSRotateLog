$here = (SplIt-Path -Parent $MyInvocation.MyCommand.Path) -replace '\\Tests', ''
$sut = (SplIt-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
Get-ChildItem -Path $here -Recurse -Include "*.ps1" -Exclude '*.Tests.ps1'|ForEach-Object {
    . $_.FullName
}


Describe "Remove-IISLog.ps1" {

    mock -CommandName Get-ChildItem -MockWIth {
        Import-Clixml "$here\Tests\LogFolder.xml"
    } -ParameterFilter {$Path -eq "D:\LogFolder"}

    mock -CommandName Test-Path -MockWIth { $true }
    mock -CommandName Remove-Item -MockWIth {  }

    Context "Get-FileList: Files lookup" {

        It "Output contains u_ex160924_x.log" {

            $referenceItem = Import-Clixml -Path "$here\Tests\u_ex160924_x.log.xml"

            $foundItem = Get-FileList -Path D:\LogFolder|Where-Object FullName -eq $referenceItem.FullName

            Compare-Object -ReferenceObject $referenceItem -DifferenceObject $foundItem|should BeNullOrEmpty
        }

        It "Output contains 6" {
            $foundItem = Get-FileList -Path D:\LogFolder
            $foundItem.Count|Should -BeExactly 6
        }
    }

    Context "Get-FileList: Empty folders" {

        mock -CommandName Get-ChildItem -MockWIth {
            Import-Clixml "$here\Tests\EmptyFolder.xml"
        } -ParameterFilter {$Path -eq "D:\EmptyFolder"}

        mock -CommandName Get-ChildItem -MockWIth {
            param($Path)
            Import-Clixml "$here\Tests\EmptyFolder.xml"|Where-Object FullName -Like "$Path\*"
        } -ParameterFilter {$Path -like "C:\Test\*"}

        It "Should return empty folders 'ListEmptyFolders=true'" {
            $foundItem = Get-FileList -Path D:\EmptyFolder -ListEmptyFolders $true
            $foundItem.BaseName -contains "Empty"|Should -BeTrue
            $foundItem.BaseName -contains "EmptySubfolder"|Should -BeTrue
        }

        It "Should NOT return empty folders 'ListEmptyFolders=false'" {
            $foundItem = Get-FileList -Path D:\EmptyFolder -ListEmptyFolders $false
            $foundItem.BaseName -contains "Empty"|Should -BeFalse
            $foundItem.BaseName -contains "EmptySubfolder"|Should -BeFalse
        }

        It "Should not return full folder" {
            $foundItem = Get-FileList -Path D:\EmptyFolder -ListEmptyFolders $true
            $foundItem.BaseName -contains "NotEmpty"|Should -BeFalse
        }
    }

    Context "Get-FileList: Ignore symlinks" {

        mock -CommandName Get-ChildItem -MockWIth {
            Import-Clixml "$here\Tests\SymlinkFolder.xml"
        } -ParameterFilter {$Path -eq "D:\SymlinkFolder"}

        mock -CommandName Get-ChildItem -MockWIth {
            param($Path)
            Import-Clixml "$here\Tests\SymlinkFolder.xml"|Where-Object FullName -Like "$Path\*"
        } -ParameterFilter {$Path -like "C:\Test\*"}

        It "Should not return dummy in symlink" {
            $foundItem = Get-FileList -Path D:\SymlinkFolder -ListEmptyFolders $true
            $foundItem.FullName -contains "C:\Test\SymlinkFolder\dummy.txt"|Should -BeFalse
            $foundItem.FullName -contains "C:\Test\SymlinkFolderFolder"|Should -BeFalse
        }

        It "Should not return symlink to empty folder" {
            $foundItem = Get-FileList -Path D:\SymlinkFolder -ListEmptyFolders $true
            $foundItem.FullName -contains "C:\Test\SymlinkFolderFolder"|Should -BeFalse
        }
    }

    Context "Remove-IISLog" {


        It "Remove-IISLogSize should remove 3 files" {
            $shouldItems = Import-Clixml -Path "$here\Tests\Remove-IISLogSize.xml"
            $removedItems = Remove-IISLogSize -Path D:\LogFolder -Size 393662502
            Compare-Object -ReferenceObject $shouldItems -DifferenceObject $removedItems|should BeNullOrEmpty
            Assert-MockCalled -CommandName Remove-Item -Times 3 -Exactly -Scope It
        }

        It "Remove-IISLogCount should remove 2 files" {
            $shouldItems = Import-Clixml -Path "$here\Tests\Remove-IISLogCount.xml"
            $removedItems = Remove-IISLogCount -Path D:\LogFolder -KeepFiles 4
            Compare-Object -ReferenceObject $shouldItems -DifferenceObject $removedItems|should BeNullOrEmpty
            Assert-MockCalled -CommandName Remove-Item -Times 2 -Exactly -Scope It
        }

        It "Remove-IISLogCount should remove no files" {
            Remove-IISLogCount -Path D:\LogFolder -KeepFiles 7|should BeNullOrEmpty
            Assert-MockCalled -CommandName Remove-Item -Times 0 -Exactly -Scope It
        }

        It "Remove-IISLogOlder should remove 4 files" {
            $freshDate = (Get-Date -Year 2016 -Month 9 -Day 30 -Hour 0 -Minute 0 -Second 0)
            $shouldItems = Import-Clixml -Path "$here\Tests\Remove-IISLogOlder.xml"
            $removedItems = Remove-IISLogOlder -Path D:\LogFolder -Older $freshDate
            Compare-Object -ReferenceObject $shouldItems -DifferenceObject $removedItems|should BeNullOrEmpty
            Assert-MockCalled -CommandName Remove-Item -Times 4 -Exactly -Scope It
        }

        It "Remove-IISLogOlder should remove no files" {
            $freshDate = (Get-Date -Year 2014 -Month 9 -Day 30)
            Remove-IISLogOlder -Path D:\LogFolder -Older $freshDate|should BeNullOrEmpty
            Assert-MockCalled -CommandName Remove-Item -Times 0 -Exactly -Scope It
        }

    }
}