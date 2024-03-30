$lines = Get-Content './README.md'

$urls = @()
$whitelist = @()

$inUrls = $false
$inWhitelist = $false
foreach($line in $lines){
    if(($null -eq $line) -or ($line -eq '')){
        continue
    }

    if($line -match '^>'){continue}

    $line = $line.Trim()
    if($line -eq '## URLS'){
        $inUrls = $true
        $inWhitelist = $false
    }elseif($line -eq '## Whitelisted'){
        $inUrls = $false
        $inWhitelist = $true
    }elseif($inUrls){
        $urls += $line
    }elseif($inWhitelist){
        $whitelist += $line
    }
}

$i = 0
foreach($url in $urls){
    try{
        Remove-Item "./$($i).txt" -ErrorAction SilentlyContinue
    }catch{}
    Invoke-WebRequest $url -OutFile "./$($i).txt"
    $i++
}

$progressId = get-random -minimum 1000 -Maximum 2222

$strm = New-Object System.IO.StreamWriter('./Master.txt', $false)
$strm.AutoFlush = $false

try{
    $k = 0
    $master = New-Object Collections.Generic.List[String]
    for($j = 0; $j -lt $i; $j++){
        foreach($url in [System.IO.File]::ReadLines("./$($j).txt")){
            $k++
            Write-Progress "Building list" "File $($j + 1) of $($i) | Total lines read $($k) | Lines written $($master.Count) | $([Math]::Round(($k / $master.count) * 100, 1))%"
            if($url -match '^#'){continue}
            if(($null -eq $url) -or ($url -eq '')){continue}
            if($whitelist -icontains $url){continue}
            if($master.Contains($url)){continue}

            $master.Add($url)
            $strm.WriteLine($url)
        }
    }

}finally{
    Write-Progress -Id $progressId -Completed
    $strm.Flush()
    $strm.Close()
}