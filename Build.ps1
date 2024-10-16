$lines = Get-Content './README.md'

$urls = @()
$whitelist = @()

$inUrls = $false
$inWhitelist = $false
$regexWhiteList = @()
foreach ($line in $lines) {
    $line = $($line ?? '').Trim()
    if ($line -eq '') {
        continue
    }
    elseif ($line -ieq '## URLS') {
        $inUrls = $true
        $inWhitelist = $false
    }
    elseif ($line -ieq '## Whitelisted') {
        $inUrls = $false
        $inWhitelist = $true
    }
    elseif ($line -imatch '^[a-z0-9]') {
        if ($inUrls) {
            $urls += $line
        }
        elseif ($inWhitelist) {
            $whitelist += $line
        }
    }
    elseif ($line -imatch '^\|[^|]+\|$') {
        if ($inWhitelist) {
            $regexWhiteList += $line.Substring(1, $line.Length - 2)
        }
    }
}

$whitelist += {
    'localhost'
    'localhost.localdomain'
    'local'
    'broadcasthost'
    'ip6-localhost'
    'ip6-loopback'
    'ip6-localnet'
    'ip6-mcastprefix'
    'ip6-allnodes'
    'ip6-allrouters'
    'ip6-allhosts'
    '0.0.0.0'
}

$i = 0
foreach ($url in $urls) {
    try {
        Remove-Item "./$($i).txt" -ErrorAction SilentlyContinue
    }
    catch {}
    Invoke-WebRequest $url -OutFile "./$($i).txt" -ErrorAction Continue
    $i++
}

$progressId = Get-Random -Minimum 1000 -Maximum 2222

$masterOptions = New-Object System.IO.FileStreamOptions

$masterOptions.Access = 3 #System.IO.FileAccess.ReadWrite
$masterOptions.Mode = 2 #System.IO.FileMode.Create
$masterOptions.Options = 134217728 #System.IO.FileOptions.Sequential
$masterOptions.Share = 1 #System.IO.FileShare.Read
$masterOptions.BufferSize = 8192 #Double the default 4096


$strm = New-Object System.IO.StreamWriter('./Master.txt', $masterOptions)
$strm.AutoFlush = $false


$reader = $null
$openOptions = New-Object System.IO.FileStreamOptions
$openOptions.Access = 1 #System.IO.FileAccess.Read
$openOptions.Mode = 3 #System.IO.FileMode.Open
$openOptions.Options = 134217728 #System.IO.FileOptions.Sequential
$openOptions.Share = 1 #System.IO.FileShare.Read
$openOptions.BufferSize = 8192 #Double the default 4096

try {

    $k = 0
    $master = New-Object Collections.Generic.SortedSet[String]  #HOLY FUCK IS THIS QUICKER!
    #$master = New-Object Collections.Generic.List[String]
    $master.clear()

    for ($j = 0; $j -lt $i; $j++) {
        
        $reader = New-Object System.IO.StreamReader("./$($j).txt", $openOptions)

        try {

            do {
                $url = $reader.ReadLine()
                $k++
                if (($k % 10) -eq 0) {
                    Write-Progress 'Building list' `
                        "File $($j + 1) of $($i) | Total lines read $($k) | Entries written $($master.Count) | $([Math]::Round(($master.count / $k) * 100, 1))% of total input" `
                        $progressId `
                        -PercentComplete $(($reader.BaseStream.Position / $reader.BaseStream.Length) * 100)
                }
                
                if (($null -eq $url) -or ($url -eq '')) { continue }

                $url = $url.Trim().ToLowerInvariant()

                if ($url.StartsWith('#')) { continue }

                $split = $url -split ' '
                if ($split.Length -eq 0) { continue }
                if ($split.Length -eq 1) {
                    $url = $split[0]
                }
                else {
                    $url = $split[1]
                }
                if ($whitelist -icontains $url) { 
                    Write-Host "WHITELISTED: $($url)"
                    continue
                }
                else {
                    $isWhiteListed = $false
                    foreach ($rx in $regexWhiteList) {
                        if ($url -imatch $rx) {
                            Write-Host "WHITELISTED: $($url)"
                            $isWhiteListed = $true
                            break;
                        }
                    }
                    if($isWhiteListed){continue}
                }
                if ($master.Contains($url)) { continue }

                $master.Add($url) | Out-Null
                $strm.WriteLine($url)
            }while ($reader.EndOfStream -eq $false)
            
        }
        finally {
            $reader.Close()
        }
    }

}
finally {
    Write-Progress -Id $progressId -Completed
    $strm.Flush()
    $strm.Close()
}